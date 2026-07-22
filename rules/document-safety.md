# Document Safety (hook + skill)

> The `doc-protection.sh` hook **enforces** document protection: Write on existing docs is blocked (use Edit) + auto-backup to `.backups/`. Checklist via `/checklist` skill (optional, not hook-enforced). Details: `docs/workflows/document-work.md`

## Slides / papers
- Edit the md source first, then propagate to HTML (never the reverse).
- Never regenerate via generate scripts (they overwrite manual edits).
