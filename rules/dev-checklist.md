# Work Checklist (/checklist — optional) + Staging/Ops SSOT

## /checklist is optional (mandate removed 2026-07-22)
- `/checklist` builds a unified code/doc checklist (kind auto-detected). Use it when 주인님 asks for it, or for genuinely large multi-file work where it helps.
- It is NOT required before edits. Why removed: the blanket mandate turned every small task into a multi-turn process (generate checklist → approve → execute → report) and cost more than the mistakes it prevented.
- Details: `skills/checklist/SKILL.md`

## Staging/Ops separation (SSOT)
- **Staging**: `Harness-engineering/` repo (`skills/`, `rules/`, `hooks/`) — edit here first
- **Ops**: `~/.claude/` — what Claude Code actually loads
- After editing staging, always copy to ops (sync responsibility: Harness-engineering project)
- On drift, reconcile deliberately: default is staging wins, but check history first — ops may hold a newer hotfix that must be back-ported to staging before overwriting (observed 2026-07-22 with work-style.md).
