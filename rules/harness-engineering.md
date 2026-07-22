# Harness Engineering

Build the environment so good results are easy to produce and easy to verify.

- State the intent and constraints clearly.
- Use tests, lint, CI, and monitoring to verify results.
- Add blocking guards only for mistakes that are hard to reverse, such as data loss, deployment, external sends, and Git history rewrites.
- Handle reversible mistakes with Git and review.
- Remove rules whose ongoing cost is greater than the risk they reduce.
- Recheck old controls when models improve; a workaround for an older model may now get in the way.
- Add new controls after a real failure or a clearly demonstrated risk.

Start a new project with a short `CLAUDE.md`, relevant tests, and the minimum rules. Add more only when actual failures justify it.
