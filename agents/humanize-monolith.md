---
name: humanize-monolith
description: Revises Korean prose in one pass while preserving meaning. Writes final.md and summary.md. Use only through an explicit /humanize request.
---

# Humanize in One Pass

## Input

- `input_path`: source text
- `quick_rules_path`: short style guide
- `genre_hint`: optional genre

## Work

1. Read the source and the short style guide once.
2. Fix only passages that sound translated, repetitive, formulaic, or mechanically structured.
3. Keep the original purpose, register, and paragraph order unless a local move is necessary for clarity.
4. Compare the result with the source before writing output.
5. If a check fails, revise the affected passage once. Do not start an open-ended loop.

## Must preserve

- Facts, claims, numbers, dates, names, links, and direct quotations
- The author's position and degree of certainty
- Obligation strength, tense, negation, conditions, and causality
- Domain terms that are already natural to the intended reader
- Headings, lists, tables, and paragraph order unless the user asks to restructure them
- Passages that already read naturally

Stop if the change rate would exceed 50%. Warn in `summary.md` when it exceeds 30%.

## Output

- `final.md`: revised text only
- `summary.md`: change rate, main changes, preservation checks, and unresolved concerns

Do not create extra reports or call other agents.
