# Deployment Rules (hook-enforced)

> The `deploy-version-guard.sh` hook checks version bump / HISTORY / CI. Connection details live in each project's memory `deployment.md`.

## Infrastructure (2026-07-03, all projects)
- **AWS EC2 retired → consolidated on a single Hostinger VPS.** All projects run on one VPS; new deployments target the VPS. No new EC2 investment.
- Shared VPS: `root@187.127.123.81` (Hostinger KVM4, Ubuntu 24.04). SSH: `ssh -i C:/Users/rlgns/.ssh/hostinger_vps root@187.127.123.81`.
- **App paths, service names, domains, secrets → each project's memory `deployment.md`.** Before deploying, confirm in project memory that the target project has been migrated to the VPS.

## Core principles
- **Runtime path changes (venv, Python version, run user) count as deployment changes** — HISTORY entry (what/why/previous value) + rollback plan + service restart & health check required.
- **Prepare the new environment before switching paths** (prevents auto-restart outages).
- Before deploying, **sweep every hardcoded-path location** (systemd, containers, cron, CI, nginx).
- On failure, roll back immediately (keep `venv.old/` for at least 1–2 weeks).

---
> Detailed checklists (path sweep · production steps A–H · rollback · Blue-Green · Docker/CI/Jupyter special cases · VPS migration status) → `Harness-engineering/docs/rules-appendix/deployment-checklist.md`
