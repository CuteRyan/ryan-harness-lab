# Work Checklist and Global Sync

- `/checklist` is optional. Use it when 주인님 asks or when a large multi-file change benefits from a written list.
- Reversible work already approved by 주인님 may proceed without another approval round.

## Global sync

- Source: `C:\Python\harness-engineering`.
- Runtime copy: `~/.claude/`.
- Mirror `agents/`, `hooks/`, `rules/`, and `skills/`, excluding backups and test fixtures.
- Edit the source first, copy only the changed files, then compare SHA-256 hashes.
- If the runtime copy contains a newer fix, understand it and bring it into the source before overwriting.
- `settings/CLAUDE.global.md` maps to the runtime `CLAUDE.md`; the project root `CLAUDE.md` does not.
- `settings/settings.template.json` is the shared shape. Runtime `settings.json` is user-specific and requires manual review.
- `skills/feedback/scripts/g3_sample.py` is a test fixture and is not deployed.
