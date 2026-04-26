---
title: "커뮤니티 리서치 — Claude Code agent team 실사용 사례"
owner: community-researcher
date: 2026-04-22
scope: task #2 of agent-team-skill-redev team
---

# 커뮤니티 리서치 — Claude Code Agent Team 실사용 사례

> 목적: `~/.claude/skills/agent-team-manager/` 개편을 위한 외부 패턴·안티패턴 수집.
> 모든 출처는 2026-04-22 기준 확인.

## 0. Executive Summary

- **공식 Agent Teams**는 `TeamCreate` / `Agent(team_name=...)` / `SendMessage` / `TaskCreate` 네 가지 도구 + `~/.claude/teams/{team}/config.json` 파일 기반으로 돌아가는 **실험적(experimental) 기능**. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필수 (Claude Code v2.1.32+).
- 공개 구현 중 **가장 성숙한 세 가지**:
  1. `wshobson/agents` (34k+★) — plugins/agent-teams: team-lead/reviewer/debugger/implementer + 7 preset + 6 skill
  2. `Yeachan-Heo/oh-my-claudecode` (30k+★) — `/team` (native) vs `/omc-teams` (tmux CLI worker) **2 runtime 분리**
  3. `zircote/claude-team-orchestration` (3★, 젊음) — 7 orchestration pattern(Parallel/Pipeline/Swarm/Research+Impl/Plan-Approval/Multi-File Refactor/RLM) 을 skill 로 코드화
- **흔한 안티패턴**: (a) `broadcast` 남용 → 토큰 N배, (b) 같은 파일 멀티 쓰기 → 충돌, (c) teammate 에게 UUID 로 지칭 → 혼선, (d) lead 가 teammate 대신 구현 시작, (e) `Explore`/`Plan` 읽기전용 에이전트에 구현 할당.
- **주요 리스크 (공식 문서 명시)**: teammate 는 `TeamCreate` 를 **못 쓴다** (nested team 불가). `/resume` 로 team session 복원 불가. 한 세션당 1 team. lead 교체 불가. split-pane 모드는 VS Code/Windows Terminal/Ghostty 에서 지원 X.

## 1. 수집한 사례 (출처/날짜 명시)

### Top 3 참고가치 (우선순위)

#### [1] wshobson/agents — 공식 API 네이티브 플러그인
- **URL**: https://github.com/wshobson/agents
- **Stars**: 34,082 · **Last updated**: 2026-04-22T11:30:58Z (활발)
- **License**: (repo 참조)
- **핵심 구조** (`plugins/agent-teams/`):
  ```
  agents/       team-lead.md, team-reviewer.md, team-debugger.md, team-implementer.md
  commands/     team-spawn.md, team-review.md, team-debug.md, team-feature.md,
                team-delegate.md, team-status.md, team-shutdown.md
  skills/       team-composition-patterns/, team-communication-protocols/,
                task-coordination-strategies/, multi-reviewer-patterns/,
                parallel-debugging/, parallel-feature-development/
  ```
- **팀 정의 포맷** — 각 agent 는 `.md` 1개 (frontmatter `name, description, tools, model, color` + 본문 = system prompt 가이드).
- **Preset 팀 7종**: review, debug, feature, fullstack, research, security, migration (각각 3~4명).
- **Spawn 절차** (team-spawn.md Phase 2 원문):
  1. `TeamCreate(team_name, description)`
  2. 멤버별로 `Agent(team_name, name, subagent_type, prompt)` — subagent_type 은 `general-purpose`/`Explore`/`Plan` 또는 `agent-teams:team-reviewer` 처럼 플러그인-prefix 가능
  3. `TaskCreate` 로 placeholder task 배정
- **우리 스킬에 적용 가능한 idea**:
  - **프리셋 카탈로그** — 자주 쓰는 팀 조합을 미리 정의해 `/agent-team-manager` 호출 시 3~7종 즉시 선택 가능.
  - **역할별 agent md 파일 분리** — team-lead/reviewer/debugger/implementer 4역할 기본 제공, 사용자는 domain-specific 역할만 추가.
  - **skill = 역할별 판단 heuristic 문서** — `team-composition-patterns` 처럼 "언제 몇 명?" "어떤 agent_type?" 같은 의사결정 표를 skill 내부 레퍼런스로 보관.
  - **Pre-flight check** — 스킬 entry point 에서 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 확인, 미설정 시 안내 후 abort.

> ⚠️ API 변경 가능성: Agent Teams 는 experimental, 공식 문서에도 한계 명시. v2.1.32 이전 사용자는 기능 자체가 없음.

#### [2] Yeachan-Heo/oh-my-claudecode — 2-runtime 구분 모델
- **URL**: https://github.com/Yeachan-Heo/oh-my-claudecode
- **Stars**: 30,667 · **Last updated**: 2026-04-22T11:32:30Z (활발)
- **핵심 인사이트** — `/team` (native agent teams API) vs `/omc-teams` (tmux 에서 외부 CLI worker: claude/codex/gemini/cursor-agent) 를 **명시적으로 분리**. SKILL.md 에 둘의 관계표를 직접 명시:
  | Aspect | `/team` | `/omc-teams` |
  | --- | --- | --- |
  | Worker type | Claude Code native team agents | claude / codex / gemini / cursor CLI processes in tmux |
  | Invocation | TeamCreate / Task / SendMessage | `omc team [N:agent]` CLI + status/shutdown/api |
  | Coordination | Native messaging + staged pipeline | tmux runtime + CLI API state files |
  | Use when | Claude-native team orchestration | External CLI worker execution |
- **Phase 0 에서 tmux/cmux/plain-terminal 환경 체크** — 표시 모드 실패를 사전 차단.
- **Error Reference 테이블** — `not inside tmux`, `cmux surface detected`, `Unsupported agent type`, `Team <name> is not running`, `status: failed` 등 + 해결책 표준화.
- **CHANGELOG 실측 이슈** (최근 수개월):
  - v4.13.2 — `fix(team): Clear the owning Ralph session when cross-session cancel has no local state` (ghost session 문제)
  - v4.13.1 — `feat(team): Add cursor-agent as 4th tmux worker type` (2026-04)
  - v4.12.x — `autonomous` keyword false-positive autopilot 수정
- **우리 스킬에 적용 가능한 idea**:
  - **프리플라이트 표준화** — Phase 0 (env/tmux/permissions 체크) 를 스킬 workflow 공식 단계로 고정.
  - **에러 카탈로그** — "에러 이름 → 원인 → 고치는 법" 테이블 스킬 말미에 꼭 포함 (디버그 시간 단축).
  - **네이티브 vs 외부 CLI worker 분리** — 하네스 프로젝트는 `codex-cwd` 패턴을 이미 채택 → 향후 "native team" 과 "tmux-CLI team" 을 **별도 스킬**로 분리 고려 가능.

#### [3] zircote/claude-team-orchestration — 7 pattern 코드화
- **URL**: https://github.com/zircote/claude-team-orchestration
- **Stars**: 3 (신생) · **Last updated**: 2026-04-20T16:38:53Z
- **핵심** — 오케스트레이션 패턴 7종을 각각 SKILL 로 제공:
  1. **Parallel Specialists** — 여러 전문가 동시 검토 (코드 리뷰형)
  2. **Pipeline** — 순차 단계(research → plan → impl → test → review) + `blockedBy` 체인
  3. **Swarm** — 같은 작업 N개 병렬
  4. **Research + Implementation** — 탐색 후 구현 (phase gate)
  5. **Plan Approval** — 승인 게이트 (고위험 변경용)
  6. **Multi-File Refactoring** — fan-in 집계
  7. **RLM (Recursive Language Model)** — 컨텍스트 초과 파일 분석 (arXiv:2512.24601 참조)
- 스킬별로 **실제 JS 의사코드** 포함 — `TeamCreate / Task / TaskUpdate addBlockedBy / SendMessage` 호출이 어떻게 묶이는지 구체 예시.
- **우리 스킬에 적용 가능한 idea**:
  - **패턴 선택 가이드 테이블** — "Pattern | 언제 | 조정 비용 | 의존성" 을 스킬 초입에 배치.
  - **Pipeline 패턴**의 `TaskUpdate addBlockedBy` 사용 방식은 **주인님의 현재 agent-team-skill-redev 팀** 구조(task 1,2,3,4 의존)와 그대로 매칭 — 레퍼런스로 쓸 수 있음.
  - **RLM 패턴**은 **Graphify / 지식문서** 처럼 대형 파일을 다루는 워크플로에 적용 가능.

### 그 외 참고가치 (중요도순)

#### [4] Anthropic 공식 엔지니어링 블로그 — "How we built our multi-agent research system"
- **URL**: https://www.anthropic.com/engineering/multi-agent-research-system
- **Date**: 2025-06-13 · **Authors**: Jeremy Hadfield, Barry Zhang, Kenneth Lien, Florian Scholz, Jeremy Fox, Daniel Ford
- **핵심 교훈**:
  - orchestrator-worker 패턴이 single-agent 대비 내부 eval 에서 **+90.2%** 성능
  - "토큰 사용량이 research quality 분산의 80%" — **병렬 exploration 이 실제 이득의 원천**
  - 프롬프트는 **rigid rule 보다 heuristic** 심어주기: "간단한 쿼리는 1 agent (3–10 tool call), 복잡한 것은 10+ subagent" 같은 scaling rule 을 직접 명시
  - **"Think like your agents"** — 프롬프트를 시뮬레이션해서 실패 모드를 미리 찾기
  - eval 은 20 case 로 시작, LLM-as-judge + 사람 테스트 조합
  - agent 는 stateful → 에러 누적 → **resumable checkpoint** 필요
- **우리 스킬에 적용 가능한 idea**:
  - **scaling heuristic 명문화** — "단순: 1-2명 / 보통: 2-3명 / 복잡: 3-4명 / 매우복잡: 4-5명" 표 (wshobson 과 동일하게 수렴).
  - **프롬프트는 의도 중심** — "이 role 은 뭘 해야 한다" 가 아니라 "언제 몇 명, 어떤 구조로 일해야 하는지의 판단기준" 을 넣기.
  - **task 20개 세트로 스킬 검증** 아이디어.

#### [5] aws-samples/sample-claude-code-agent-team — 스펙 기반 개발팀
- **URL**: https://github.com/aws-samples/sample-claude-code-agent-team
- **Stars**: 6 · **Last updated**: 2026-04-17T06:19:50Z
- **구조**: `fullstack-agent` (lead, Opus) + `coding-agent` (Opus) + `devops-agent` (Sonnet) + `review-agent` (Opus) + `sa-agent` (Well-Architected 리뷰).
- **Spec-Driven Workflow** (`.claude/specs/<slug>/`):
  ```
  spec.md       (결정, 대안, 제약, 설계)
  design.md     (아키텍처, repo 구조, infra)
  tasks.md      (parallel 그룹별 task — 각 task = [coding]/[devops]/[sa] prefix + file 경로 + 인수 기준 + Run 명령)
  decisions.md  (언블록시 로그)
  ```
- **Build → Review 루프** — group 단위 작업 완료 후 review-agent 에 핸드오프, 리뷰 실패 시 fix task 추가 (최대 3 cycle).
- **모델 배분**: coding/review=Opus, devops/sa=Sonnet — `frontmatter` 로 agent 별 지정.
- **보안 스캔 단계 고정** — bandit/semgrep → safety → checkov 순서, Critical/High 는 merge 전 fix or document.
- **우리 스킬에 적용 가능한 idea**:
  - **spec-driven 단계** 를 하네스 프로젝트의 기존 `.dev-checklist.md` 워크플로와 통합 가능.
  - **model 배분 전략** — 역할별 Opus/Sonnet 구분 표준화 (reviewer=Opus 권장, devops=Sonnet).
  - **review cycle cap (3회)** — 무한루프 방지 가드레일.

#### [6] barkain/claude-code-workflow-orchestration
- **URL**: https://github.com/barkain/claude-code-workflow-orchestration
- **Stars**: 47 · **Last updated**: 2026-04-21T21:51:09Z
- **agents**: code-cleanup-optimizer, code-reviewer, codebase-context-analyzer, dependency-manager, devops-experience-architect, documentation-expert, task-completion-verifier, tech-lead-architect.
- **핵심** — agent 는 **native plan mode 통합** 기반 workflow 분해·병렬 실행·delegation.
- **idea**: task-completion-verifier 같은 **명시적 "verifier" 역할** — 우리 스킬에도 "완료 검증 전담" 역할을 preset 에 넣으면 /checklist 스킬과 결합 효과.

#### [7] hesreallyhim/awesome-claude-code — Teams 섹션
- **URL**: https://github.com/hesreallyhim/awesome-claude-code
- **Stars**: 40,264 · **Last updated**: 2026-04-22T11:28:47Z
- `Teams` 섹션 실사례:
  - **panaversity/claude-code-agent-teams-exercises** (22★, 2026-04-18) — 6 exercise + 2 capstone 학습 자료 (team creation, task coord, quality hooks, parallel review). 교재로 우수.
  - **revfactory/harness** (2,769★, 2026-04-22) — **주인님 프로젝트명과 동일** (revfactory 본인 레포?). "한국어 자원, 고품질 영문 출력 생성" 설명 + 6 architecture pattern (Pipeline / Fan-out-Fan-in / Expert Pool / Producer-Reviewer / Supervisor / Hierarchical Delegation) — **이미 L3 Meta-Factory 수준**. (확인 불가: 이 레포가 주인님 본인 것인지).
  - **mikeyobrien/ralph-orchestrator** — "Ralph Wiggum" 패턴 (prompt file 을 완료될 때까지 루프 돌리기). Anthropic Ralph plugin 공식 문서에서도 인용.
  - **SuperClaude-Org/SuperClaude_Framework** — persona + orchestration.
- Orchestrators 섹션: `Auto-Claude`, `claude-code-flow`, `claude-swarm`, `Ruflo`, `sudocode`, `the-startup`, `claude-hook-comms` (HCOM), `Omnara` 등 다양.

#### [8] anthropics/claude-code#32723 — 공식 이슈 (경고)
- **URL**: https://github.com/anthropics/claude-code/issues/32723
- **핵심 발견** — `TeamCreate`/`TeamDelete`/`SendMessage` 가 **standalone subagent 와 skill-forked context 에도 노출**되어 있음. 그러나 teammate 에게는 `Agent` (spawner) 가 없어서, subagent 가 `TeamCreate` 를 호출하면 **빈 team shell 만 디스크에 쓰고 실패** — 고아 `~/.claude/teams/<name>/config.json` 디렉토리 생성.
- **우리 스킬에 적용 가능한 idea**:
  - **스킬 호출 시점에 현재 컨텍스트가 subagent 인지 main session 인지 체크** — `Agent` 도구 존재 여부 확인 후 없으면 abort.
  - **`~/.claude/teams/` 고아 디렉토리 청소 가드** — 스킬 Phase 6 (cleanup) 에 포함.

#### [9] Shipyard 블로그 — 2026 multi-agent orchestration overview
- **URL**: https://shipyard.build/blog/claude-code-multi-agent/
- **Date**: 2026-03-18 · **Author**: Shipyard Team (개인 블로그가 아닌 회사 블로그, 2026-03 = 최근 6개월 내 ✓)
- **명시적 경고**: multi-agent workflow 는 "현재 95% 의 agent-assisted dev task 에는 맞지 않는다. expensive and experimental".
- 안티패턴: (a) context depletion, (b) git worktree 없이 branch 충돌, (c) vague prompting → hour 단위 compute 낭비, (d) 확장성 천장.
- **idea**: 스킬 설명에 **"언제 쓰지 말아야 하는가"** 를 명시적으로 넣기.

## 2. 팀 정의 포맷 — 수렴된 공통 패턴

3개 대형 구현(wshobson, oh-my-claudecode, aws-samples, zircote) 공통:

```
.claude/ (또는 plugin/<name>/)
├── agents/
│   ├── team-lead.md         # frontmatter: name, description, tools (optional), model, color
│   ├── team-reviewer.md     # 본문 = system prompt (capability, protocol, behavioral traits)
│   └── ...
├── commands/                # slash command 매핑 (team-spawn, team-status, ...)
│   └── team-spawn.md        # argument-hint + phase별 실행 스펙
└── skills/
    └── <pattern-skill>/
        └── SKILL.md         # frontmatter name/description + when-to-use + heuristics + troubleshooting + related skills
```

- **Agent frontmatter 표준** (`name`/`description`/`tools`/`model`/`color`) — Claude Code subagent 스펙과 일치.
- **SKILL.md 공통 구조** — "When to Use" → "Heuristics/Table" → "Examples" → "Troubleshooting" → "Related Skills". 우리 agent-team-manager v2 도 이 구조 차용 권장.
- **모델 지정 관습**:
  - Lead / Reviewer → Opus
  - Devops / Solution Architect → Sonnet
  - Implementer → Opus (aws-samples) 또는 Sonnet (wshobson default) — 비용·품질 트레이드오프

## 3. Teammate Spawn 패턴 — 병렬 vs 순차

- **완전 병렬** (Parallel Specialists / Swarm) — `Task()` 를 한 메시지 안에서 여러 번 호출, 각 teammate 는 독립 task. 리뷰·리서치용.
- **Pipeline 순차** — `TaskCreate` N개 생성 → `TaskUpdate(addBlockedBy=[prev])` 로 체인 → worker 들이 `TaskList` 폴링하며 unblocked 작업 클레임.
- **Research → Implementation 페이즈 게이트** — phase 1 팀 전원 종료 확인 후 phase 2 spawn.
- **Plan Approval Gate** (공식 문서 + wshobson skill) — `plan_mode_required=true` 로 spawn, teammate 가 `ExitPlanMode` 호출 시 lead 가 `plan_approval_response` 로 approve/reject. 고위험 변경용.

## 4. 흔한 안티패턴 / 실패 사례 (3개 이상 출처 교차 검증)

| # | 안티패턴 | 증상 | 해결책 | 출처 |
|---|---|---|---|---|
| A1 | **`broadcast` 남용** | 토큰 N배, 노이즈 | 직접 message 기본, broadcast 는 shared resource 변경시만 | wshobson team-communication-protocols, 공식 docs |
| A2 | **같은 파일 멀티 쓰기** | overwrite, merge 충돌 | file ownership 명시, 공유 파일은 lead 가 소유 | wshobson team-lead.md, 공식 docs "avoid file conflicts" |
| A3 | **UUID 로 teammate 지칭** | 읽기 어려움, 오류 | 항상 name 사용, UUID 금지 | wshobson team-lead.md, 공식 docs |
| A4 | **lead 가 teammate 대신 구현** | 병렬성 상실 | "Wait for your teammates to complete" 지시 | 공식 docs Best Practices, aws-samples |
| A5 | **Explore/Plan 에 구현 할당** | 읽기전용이라 write 실패 | subagent_type=general-purpose 또는 specialized | wshobson team-composition-patterns |
| A6 | **review dimension overlap** | 같은 이슈 중복 보고 | 차원 재정의 (correctness vs security vs perf) | wshobson multi-reviewer-patterns |
| A7 | **teammate 에서 TeamCreate 호출** | 빈 team shell 생성, Agent 도구 없음 | main/skill-fork 에서만 TeamCreate | issue#32723 |
| A8 | **/resume 후 lead 가 죽은 teammate 에게 메시지** | 에러 | teammate 재spawn 지시 | 공식 docs Limitations |
| A9 | **중첩 팀 시도** | teammate 는 TeamCreate 없음 | lead 만 팀 관리, 필요하면 sequential team | 공식 docs, issue#32723 |
| A10 | **routine task 에 team 사용** | 비용만 비쌈, 단일 세션 더 나음 | "95% 의 task 에는 쓰지 말것" | Shipyard 2026-03, 공식 docs |
| A11 | **size/complexity heuristic 없음** | 간단한 쿼리에 10+ subagent | 명시적 scaling rule 을 프롬프트에 넣기 | Anthropic engineering blog 2025-06 |
| A12 | **vague task prompt** | 시간 낭비, 재작업 | 완전한 context + 인수기준 + file 경로 | wshobson, aws-samples, Anthropic blog |
| A13 | **file locking race** | 한 task 를 여러 teammate 가 클레임 | 공식 task system 은 file lock 내장 (자동) | 공식 docs |
| A14 | **lead 가 조기 shutdown** | 미완성 work 남음 | "keep going until all tasks complete" 명시 | 공식 docs Troubleshooting |
| A15 | **orphan tmux session** | 누수 리소스 | `tmux ls` / `kill-session` 로 청소, 또는 `TeamDelete` 먼저 | 공식 docs + oh-my-claudecode Error Reference |

## 5. 스킬과 팀의 결합 방식

3가지 결합 모델 관찰됨:

1. **Plugin-as-team** (wshobson) — 플러그인 1개 = agents + commands + skills 한 세트. 설치하면 `/team-*` 커맨드 + `team-*` agent + 6개 heuristic skill 이 동시 제공.
2. **Runtime-split** (oh-my-claudecode) — `/team` (native API) 스킬과 `/omc-teams` (tmux CLI) 스킬을 명시적으로 분리, 상호 참조.
3. **Pattern-library** (zircote) — team 자체가 아닌 **orchestration pattern** 을 SKILL 로 만들어서, 사용자가 "Parallel Specialists 해줘" 처럼 호출하면 스킬이 TeamCreate/Task/SendMessage 호출을 대행.
4. **Meta-factory** (revfactory/harness) — 사용자가 도메인을 말하면 스킬이 team 구조 자체를 **생성**. L3 Meta-Factory 레이어로 자리매김.

> 주인님의 `agent-team-manager` 는 현재 (1)·(2) 성격이 혼재. 개편 방향으로는 **(2) runtime-split + (3) pattern-library** 결합이 적합 — native vs CLI worker 구분 명확화 + 패턴 테이블로 선택 가이드.

## 6. 우리 스킬에 바로 반영 가능한 체크리스트 (분석·설계 단계로 인계)

1. **Pre-flight Phase** — `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 체크, Claude Code v2.1.32+ 체크, `Agent` 도구 존재 체크(= subagent 가 아닌지).
2. **Preset 카탈로그** — review / debug / feature / fullstack / research / security / migration + 하네스 도메인 특화(docs-research / knowledge-graphify / harness-design).
3. **역할 정의 표준** — `agents/` 디렉토리에 name/description/tools/model 프론트매터 + role-specific system prompt.
4. **패턴 선택 가이드 테이블** — Parallel / Pipeline / Swarm / Research+Impl / Plan-Approval / Multi-File / RLM 7종.
5. **Anti-pattern 표** — 위 A1~A15 를 SKILL.md Troubleshooting 섹션에.
6. **Error Reference 표** — oh-my-claudecode 식 "에러 → 원인 → 해결" 테이블.
7. **Shutdown protocol** — `shutdown_request` → `shutdown_response` 응답 대기 → `TeamDelete` → orphan config 청소.
8. **Cleanup 가드** — `~/.claude/teams/` 의 활성 없는 디렉토리 검출 스크립트(선택).
9. **Model 배분** — lead/reviewer=Opus, devops/sa=Sonnet 을 default, 사용자 오버라이드 허용.
10. **"언제 쓰지 말것"** — 단일 세션이 더 나은 케이스(순차 task, same-file edit, routine) 명시.

## 7. 미확인 / 후속 조사 필요

- revfactory/harness 가 주인님 본인 레포인지 (2,769★, 매우 관련) — 확인 불가 태그.
- `mcp__claude_ai_*` 계열 Google Drive/Gmail 같은 MCP 툴이 team 내부 teammate 에 어떻게 전파되는지 (공식 docs 는 "skills/mcpServers frontmatter field 는 teammate 에 적용 안 됨, project/user settings 기반" 언급만) — 실제 실험 필요.
- Task tool 의 `isolation: "worktree"` 옵션 (aws-samples 언급) — 공식 docs 에는 명시 없음. 별도 확인 필요.
- `TeammateIdle` / `TaskCreated` / `TaskCompleted` 훅(공식 docs hooks 에 명시) 활용 예시 — 아직 공개 예제 희소.
- 한글 경로에서 Agent Teams config 생성 안정성 (주인님 하네스 프로젝트 기존 이슈와 연결).

---

**산출물**: 이 파일 (`02_community-patterns.md`)
**Task #2 상태**: completed
**다음**: team-lead 에게 완료 보고 → analyst 가 Gap 분석으로 이어받음 (Task #3).
