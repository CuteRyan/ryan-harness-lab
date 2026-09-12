"""Exercise instruction publishing in temporary directories, never the real home."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "sync_instructions",
    Path(__file__).resolve().parents[1] / "scripts/sync-global-instructions.py",
)
publisher = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(publisher)


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.repository = self.root / "repository"
        self.user = self.root / "user"
        self.source = self.repository / "settings/global-instructions.md"
        self.source.parent.mkdir(parents=True)
        self.source.write_text(
            "# Global Instructions\n\n## Harness\n\nOld rule.\n", encoding="utf-8"
        )
        self.targets = publisher.sync(self.repository, self.user)

    def revise(self):
        self.source.write_text(
            "# Global Instructions\n\n## Harness\n\nNew rule.\n", encoding="utf-8"
        )

    def test_one_edit_updates_all_copies_and_second_sync_is_noop(self):
        settings = self.user / ".claude/settings.json"
        settings.write_text('{"personal": true}', encoding="utf-8")
        self.revise()
        self.assertEqual(len(publisher.sync(self.repository, self.user)), 4)
        expected = publisher.render(self.source.read_text(encoding="utf-8"))
        self.assertTrue(all(path.read_bytes() == expected for path in self.targets))
        self.assertEqual(publisher.sync(self.repository, self.user), [])
        self.assertEqual(settings.read_text(encoding="utf-8"), '{"personal": true}')

    def test_check_detects_outdated_files_without_writing(self):
        before = {path: path.read_bytes() for path in self.targets}
        self.revise()
        self.assertEqual(len(publisher.sync(self.repository, self.user, check=True)), 4)
        self.assertEqual(before, {path: path.read_bytes() for path in self.targets})

    def test_manual_edit_stops_all_writes(self):
        self.targets[-1].write_bytes(
            self.targets[-1].read_bytes() + b"Personal change.\n"
        )
        before = {path: path.read_bytes() for path in self.targets}
        self.revise()
        with self.assertRaisesRegex(ValueError, "locally edited"):
            publisher.sync(self.repository, self.user)
        self.assertEqual(before, {path: path.read_bytes() for path in self.targets})

    def test_unmanaged_file_is_not_adopted_silently(self):
        self.targets[-1].write_text("Handwritten instructions", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Unmanaged"):
            publisher.sync(self.repository, self.user)

    def test_missing_copy_is_restored(self):
        self.targets[-1].unlink()
        self.assertEqual(publisher.sync(self.repository, self.user), [self.targets[-1]])

    def test_failure_restores_previously_written_copies(self):
        before = {path: path.read_bytes() for path in self.targets}
        self.revise()
        writer = publisher.atomic_write

        def fail_on_second(path, content):
            if path == self.targets[1]:
                raise OSError("Simulated write failure")
            writer(path, content)

        with patch.object(publisher, "atomic_write", side_effect=fail_on_second):
            with self.assertRaisesRegex(OSError, "Simulated"):
                publisher.sync(self.repository, self.user)
        self.assertEqual(before, {path: path.read_bytes() for path in self.targets})


if __name__ == "__main__":
    unittest.main()
