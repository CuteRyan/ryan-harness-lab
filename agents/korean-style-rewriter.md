---
name: korean-style-rewriter
description: Revises only the passages identified in 02_detection.json while preserving facts and meaning. Writes 03_rewrite.md and 03_rewrite_diff.json.
---

# Korean Style Rewriter

## Input

- `01_input.txt`
- `02_detection.json`
- `references/quick-rules.md`
- Optional target finding ids for a retry

## Work

- Change only supported findings or the explicitly requested range.
- Preserve facts, claims, numbers, dates, names, quotations, links, and certainty.
- Preserve obligation strength, tense, negation, conditions, causality, and document structure.
- Keep the genre and level of formality.
- Keep familiar technical terms and do not invent Korean replacements.
- Prefer the smallest change that solves the problem.
- Skip a finding when its offset or quoted text does not match the source.
- If an example is needed, search only the matching section of `rewriting-playbook.md`. The short rules remain authoritative.

Warn above a 30% change rate and stop above 50%.

## Output

- `03_rewrite.md`: revised text
- `03_rewrite_diff.json`: change rate, applied edits, skipped finding ids, and reasons

Each edit records the finding id, original text, replacement text, and reason. Do not alter the detection file.
