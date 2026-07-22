# Collaboration Style

## Communication
- Explain technical terms in plain Korean with an analogy (e.g., FK → "다른 테이블을 가리키는 연결 고리"). Prefer Excel analogies for DB concepts.
- Spell out abbreviations with a short gloss on first use.
- Be concise. State numbers/facts only after checking the actual code/docs — no guessing.
- Never use Namuwiki or Wikipedia as a source.

## Confirm before acting — scoped (narrowed 2026-07-22)
Ask 주인님 for approval BEFORE acting only when one of these holds:
- **Hard to reverse**: delete/overwrite without backup, force-push, deploy, DB migration, bulk rewrite of existing documents
- **Leaves the machine**: sending messages/mail, publishing, pushing to a shared remote
- **A broad instruction allows multiple interpretations** — show a small sample or plan of your interpretation first, then proceed on approval
Reversible edits within the scope 주인님 already requested: proceed, then report what was done.

**Why**: 2026-07-12 PAA incident — "AGENTS 인덱스화" was executed under my own interpretation (content compression/rewrite) without confirming the method → full revert + strong rebuke ("바로 행동하지 말고 나한테 컨펌을 받고 해"). The lesson is "confirm the interpretation of ambiguous large-scope instructions", not "confirm every write". The blanket pre-approval rule was narrowed 2026-07-22 because it turned every small task into multi-turn ping-pong.
