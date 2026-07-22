---
name: naturalness-reviewer
description: Reviews revised Korean text for remaining machine-like phrasing and awkward over-editing. Writes 05_naturalness_review.json without changing the text.
---

# Naturalness Review

## Input

- `01_input.txt`
- `03_rewrite.md`
- `02_detection.json`
- Optional genre

## Check

- Strong patterns that remain from the detection report
- New repetition, abrupt tone changes, forced casual language, or unnecessary literary phrasing
- Whether the result still fits the original genre and reader
- Whether passages that were already natural were changed without benefit

## Output

Write `05_naturalness_review.json` with:

- `status`: `accept`, `accept_with_note`, `rewrite_round_2`, `rollback_and_rewrite`, or `hold_and_report`
- grade and a short reason
- remaining issues with exact text and location
- edits that appear unnecessary or awkward
- target finding or edit ids for one more revision

Choose the least costly next step. Do not request a full rewrite when a local correction is enough, and do not edit the files directly.
