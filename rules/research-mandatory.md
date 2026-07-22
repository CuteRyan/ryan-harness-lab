# External Research Mandate (global)

**Core**: never rely on training-data knowledge alone for external facts. When entering territory you cannot verify yourself: **research first → cite sources**. No unsourced assertions. Purpose: block guessing and hallucination.

## Required when any of these apply
- Citing external facts, statistics, markets, news
- Behavior/options/version specs of libraries, frameworks, tools
- Official docs, standards, specifications, papers
- Best practices, industry patterns, design-decision rationale
- Own knowledge is uncertain or may have changed after cutoff (includes AI model specs and pricing — never answer from hardcoded stale info)
- 주인님 asks: "찾아봐 / 리서치해 / 근거 가져와 / 외부로 확인해"

## Tools (priority)
1. **WebSearch** — first (broad, current)
2. **WebFetch** — deep-read a specific URL when results are weak or a URL is given
3. External CLIs (Codex/Gemini via `/feedback`) — code review / second opinion only
4. `/research-knowledge` — when the knowledge is worth persisting for reuse

## Output format (mandatory when citing)
Source URL & title · publish date/version when available · 1–2 lines of **direct quotation** (not a paraphrase).
No hedging ("아마도", "보통", "일반적으로").

## Exception — internal facts need no research
Code names/signatures/paths · project files (CLAUDE.md, docs, skills, rules) · prior-turn decisions, memory, `.todo`, HANDOFF · git history · Task* output · local environment/system state.
→ **Internal: check directly. External: research + cite.**

---
> Origin, 4 sources, application history → `Harness-engineering/docs/rules-appendix/research-mandatory.md`
