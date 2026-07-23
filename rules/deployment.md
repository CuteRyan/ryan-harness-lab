# Deployment

- Read the target project's deployment memory before deploying. Hostnames, paths, services, and secrets belong there, not in global rules.
- Treat changes to Python, virtualenv, runtime user, service files, containers, cron, CI, and nginx as deployment changes.
- Prepare and test the new environment before switching traffic or runtime paths.
- Run the relevant tests and health check, and confirm CI when the project uses it.
- Record what changed, why, and the previous value.
- Keep a tested rollback path and use it immediately when the health check fails.
- Keep deployment checks in the target project's CI or project-local tooling. Global hooks must not encode a project hostname, server address, version file, or release-history filename.
