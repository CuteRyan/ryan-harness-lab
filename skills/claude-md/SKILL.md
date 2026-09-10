---
name: claude-md
description: Create project CLAUDE.md instructions from actual project facts, or review existing instructions without editing them.
trigger: /claude-md
argument-hint: "[init|audit] [path]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Project CLAUDE.md

Use the requested directory, or the current workspace when no path is supplied.

## Init

Read the target's existing instructions, repository status, code, and configuration. Write a project-root `CLAUDE.md` grounded in that project.

Use `C:/Python/harness-engineering/docs/templates/CLAUDE.md.template` as optional writing guidance. Choose the structure the project needs; replace its guidance with verified facts and omit unknown values. Report any missing fact that materially limits the result.

If `CLAUDE.md` already exists, preserve its content and any uncommitted changes. An init request alone does not authorize replacing it; report the relevant findings. When the user has requested updates, edit the affected parts within that scope.

Keep commands and constraints useful to this project. Link to detailed records instead of importing histories or repeating global instructions.

## Audit

Read the instructions and compare their commands, paths, and claims with the actual project. Report stale references, contradictions, duplicated guidance, and constraints that lack a project need. Do not edit files for an audit request.

Assess whether the instructions help the work. A particular length, heading, or template sentence is not a correctness requirement.

## Maintenance

Source: `C:/Python/harness-engineering/skills/claude-md/SKILL.md`.
Claude copy: `~/.claude/skills/claude-md/SKILL.md`.

Edit the source first. Compare the active copy before replacing it, preserve unexplained differences, and verify the copied file by hash.
