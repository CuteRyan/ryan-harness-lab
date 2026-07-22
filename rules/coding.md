# Coding Rules

1. **Default virtualenv: `.venv`** — auto-discovered by VS Code. Direct call: Windows `./.venv/Scripts/python.exe`, POSIX `./.venv/bin/python`. System Python is allowed **only for creating the venv**. Exceptions (Conda, Docker, devcontainer, Poetry external env, …) must be justified in the project CLAUDE.md.
2. **Never commit interpreter paths to VS Code settings** — no concrete executable paths (`.venv/Scripts/python.exe`), no user-global relative paths. If the team needs a shared setting, folder path only (`${workspaceFolder}/.venv`). Default to auto-discovery. Before committing `.vscode/settings.json`, check it for absolute/home/executable paths.
3. **`.env` wins locally only** — local dev may use `load_dotenv(override=True)`. **Production/staging: system env and secret manager take precedence over `.env`** (per-environment strategy in the project CLAUDE.md). Delete stale API keys left in system env.
4. **Test at production scale** — passing a small sample (5 rows) is not "success". Verify at medium scale (100+ rows) including DB persistence.
5. **Run related tests before committing** — locally pass the tests that import/call the modified module, especially on function-signature changes, new phases/steps, or import-path changes.

> Server/CI/container deployment: see `deployment.md`.
> `venv/` → `.venv/` migration procedure → `Harness-engineering/docs/rules-appendix/coding-venv-migration.md`
