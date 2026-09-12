"""Publish one instruction source to the local Claude and Codex copies."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import re
import tempfile


NOTICE = "<!-- Generated from settings/global-instructions.md; run python scripts/sync-global-instructions.py. -->\n"


def render(body: str) -> bytes:
    digest = hashlib.sha256(body.encode("utf-8")).hexdigest()
    return f"{NOTICE}<!-- Content SHA-256: {digest} -->\n\n{body}".encode("utf-8")


def validate_copy(path: Path, raw: bytes) -> None:
    text = raw.decode("utf-8").replace("\r\n", "\n")
    match = re.fullmatch(
        re.escape(NOTICE) + r"<!-- Content SHA-256: ([0-9a-f]{64}) -->\n\n(.*)",
        text,
        re.DOTALL,
    )
    if not match or hashlib.sha256(match[2].encode("utf-8")).hexdigest() != match[1]:
        raise ValueError(
            f"Unmanaged or locally edited instructions: {path}. Reconcile with the source first."
        )


def atomic_write(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        dir=path.parent, prefix=".instructions-", delete=False
    ) as stream:
        temporary = Path(stream.name)
        stream.write(content)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def sync(repository: Path, user_directory: Path, *, check: bool = False) -> list[Path]:
    source = repository / "settings/global-instructions.md"
    body = source.read_text(encoding="utf-8")
    if not body.startswith("# Global Instructions\n") or "## Harness\n" not in body:
        raise ValueError(f"Invalid instruction source: {source}")
    expected = render(body)
    targets = (
        repository / "settings/AGENTS.global.md",
        repository / "settings/CLAUDE.global.md",
        user_directory / ".codex/AGENTS.md",
        user_directory / ".claude/CLAUDE.md",
    )
    previous = {}
    # Validate every destination before changing any of them.
    for path in targets:
        if path.is_symlink():
            raise ValueError(f"Inspect linked instructions before syncing: {path}")
        raw = path.read_bytes() if path.exists() else None
        if raw is not None:
            validate_copy(path, raw)
        previous[path] = raw
    changed = [path for path in targets if previous[path] != expected]
    if check:
        return changed
    written = []
    try:
        for path in changed:
            # Do not overwrite a change made after the preflight read.
            current = path.read_bytes() if path.exists() else None
            if current != previous[path]:
                raise ValueError(f"Instructions changed during sync: {path}")
            atomic_write(path, expected)
            written.append(path)
        if any(path.read_bytes() != expected for path in targets):
            raise OSError("Instruction verification failed")
    except Exception:
        for path in reversed(written):
            # Preserve concurrent edits; restore only the bytes this call wrote.
            if path.read_bytes() == expected:
                if previous[path] is None:
                    path.unlink()
                else:
                    atomic_write(path, previous[path])
        raise
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Check equality without writing files"
    )
    arguments = parser.parse_args()
    try:
        changed = sync(
            Path(__file__).resolve().parents[1], Path.home(), check=arguments.check
        )
    except (OSError, ValueError) as error:
        print(f"Sync stopped: {error}")
        return 1
    if arguments.check and changed:
        print("Out of date: " + ", ".join(str(path) for path in changed))
        return 1
    print(f"Verified all 4 instruction copies; {len(changed)} updated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
