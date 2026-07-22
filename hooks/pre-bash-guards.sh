#!/bin/bash
# PreToolUse(Bash) combined guard — runs all Bash guards in ONE bash process.
# Why: each registered hook costs a full powershell+bash spawn on Windows
# (~0.5s each). 3 separate registrations tripled the latency of every Bash
# call. Consolidated 2026-07-22.
#
# Contract (matches all guards below): guard reads the tool-call JSON on
# stdin; exit 0 = allow (silent stdout), nonzero = block. The first blocking
# guard wins and its stdout/exit code are forwarded. stderr passes through.

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT=$(cat)

for guard in pre-commit-guard.sh doc-protection.sh deploy-version-guard.sh; do
  [ -f "$DIR/$guard" ] || continue
  OUT=$(printf '%s' "$INPUT" | bash "$DIR/$guard")
  CODE=$?
  if [ -n "$OUT" ]; then
    printf '%s\n' "$OUT"
  fi
  if [ "$CODE" -ne 0 ]; then
    exit "$CODE"
  fi
done

exit 0
