---
name: ai-tell-detector
description: Finds specific passages in Korean text that may sound machine-written and writes 02_detection.json. It reports evidence but does not rewrite the text.
---

# Korean Style Detector

## Input

- Source text or `01_input.txt`
- `references/quick-rules.md`
- Optional genre and minimum severity

## Work

- Report only patterns supported by the short rules and the source text.
- Keep exact source text and character offsets for passage-level findings.
- Use a document-level finding when an exact passage would be misleading.
- Do not flag names, numbers, quotations, code, or necessary technical terms merely because they are formal.
- Do not propose changes to certainty, obligation, tense, negation, causality, or document structure.
- If a case is ambiguous, search the matching section of `ai-tell-taxonomy.md`; do not load the whole file by default.
- Do not rewrite the text.

## Output

Write `02_detection.json` with:

- source length, genre, and severity counts
- `findings[]`: id, rule id, severity, exact text, start, end, reason, and a short suggested fix
- document-level findings with `start` and `end` set to `null`
- a short summary of the strongest repeated patterns

If the short rules or source is missing, stop and report the missing path. If the text is not mainly Korean, report that without producing findings.
