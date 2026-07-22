# Memory: 3-Layer Architecture

## Auto-loaded (every session)
| File | Role | Limit |
|------|------|-------|
| `CLAUDE.md` | project intro + core rules | ≤200 lines |
| `{subdir}/CLAUDE.md` | scoped rules per part | loaded only when working there |
| `.claude/rules/*.md` | detailed rules split out | same priority as CLAUDE.md |
| `memory/MEMORY.md` | pure index (pointers only) | ≤200 lines |

## On-demand
| File | Role |
|------|------|
| `memory/*.md` (topic) | pointer + 3–5 line judgment summary |

## Role separation (absolute)
- **CLAUDE.md + rules/** = enforcement ("do / don't")
- **memory/** = pointers ("this exists here" + 3 lines of why it was decided)
- **docs/** = single source of truth (actual content lives only here)
- No duplication — never copy docs/ content into memory.
- Topic file format: frontmatter (name, description, type) + 3-line judgment summary + docs/ pointer.

## Conventions
- Filenames: English kebab-case (e.g., `news-pipeline.md`); one file = one topic.
- Memory repeated across 2+ projects → promote to global.
- **Language policy (2026-07-22)**: machine-loaded files (CLAUDE.md, rules/, agents, skill instructions) are written in English (fewer tokens, more precise instruction-following); human-facing files (docs/, history, HANDOFF) stay in Korean. Korean examples inside English rules are kept whenever the rule is about Korean output itself.
