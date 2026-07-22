# Premise: Harness Engineering

Every project is designed and managed through harness engineering. Since 2026-07-22 the harness follows one governing principle: **verify outcomes — don't choreograph process.**

## Principles
- The engineer designs the environment, specifies intent, and builds feedback loops; the model does the work. The four jobs remain: environment design (repo structure, CI, linters, per-directory CLAUDE.md), intent specification (rules, prompts, constraints), feedback loops (tests, guards, monitoring), lifecycle management.
- **Guardrails belong only where mistakes are hard to reverse** (data loss, deploys, external sends, git history rewrites). Reversible mistakes are handled by git + review, not by hooks.
- **Every rule must pay rent**: a rule that taxes every action to prevent a rare or reversible mistake gets removed. Prefer one outcome check (test, lint) over N process gates.
- **Re-audit scaffolding when the model generation upgrades** — controls built to compensate for an older model's weaknesses become interference for a newer one.
- Add guardrails after a real incident, not speculatively.

## Applying to a project
- New project: set up CLAUDE.md, tests/lint, and the minimum rules first; grow the harness only from observed failures.
- DevOps principles (CI/CD, IaC, shift-left, observability) fold naturally into the harness.

## History
- 2026-07-22: direction change from process control (mandatory checklists, blanket pre-approval, forced agent hierarchy/model params, per-call audit hooks) to outcome verification — the process layer slowed work more than it prevented errors. Details: `Harness-engineering/docs/history/2026-07-22.md`.
