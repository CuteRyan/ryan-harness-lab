# Harness Engineering

Build the environment so good results are easy to produce and easy to verify.

- State the intent and constraints clearly.
- Use tests, lint, CI, and monitoring to verify results.
- Add blocking guards only for mistakes that are hard to reverse, such as data loss, deployment, external sends, and Git history rewrites.
- Handle reversible mistakes with Git and review.
- Remove rules whose ongoing cost is greater than the risk they reduce.
- Recheck old controls when models improve; a workaround for an older model may now get in the way.
- Add new controls after a real failure or a clearly demonstrated risk.

## No overfitting

One incident is not a design input. Fix the incident with the smallest change that
removes it, and stop there.

- Do not add a mechanism, a layer, a flag, or a rule to prevent a single case that has
  happened once. Fix the case.
- A new control has to pay for itself on cases that have not happened yet. If you
  cannot name those cases, do not build it.
- Prefer deleting or correcting the thing that broke over wrapping it in something new.
- Comments, tests, and documents follow the same rule: keep what a reader must know to
  work here, not a record of every past mistake.
- When proposing a control, say what it costs to keep. If that cost is larger than the
  risk it removes, say so and do not build it.

Start a new project with a short `CLAUDE.md`, relevant tests, and the minimum rules. Add more only when actual failures justify it.
