---
title: "Gap 분석 — 현재 agent-team-manager SKILL.md vs 리서치 결과"
owner: analyst
date: 2026-04-22
scope: task #3 of agent-team-skill-redev team
inputs:
  - C:/Users/rlgns/.claude/skills/agent-team-manager/SKILL.md (120 lines, 현재 v1)
  - docs/research/agent-team-skill-redesign/01_official-docs.md
  - docs/research/agent-team-skill-redesign/02_community-patterns.md
benchmark: C:/Users/rlgns/.claude/skills/feedback/SKILL.md (+ scripts/ 6종)
---

# Gap 분석 — 현재 `agent-team-manager` vs 공식/커뮤니티/실측

> 목적: 재설계 입력으로 쓸 **항목별 격차표 + 우선순위표 + 실측 4건**. 장황 금지.
> Gap 크기: **치명 / 높음 / 중간 / 낮음**. 우선순위: **P0 / P1 / P2**.
> 각 gap 에 Why 필수 (CLAUDE.md 규칙).

---

## 0. 현재 스킬 요약 (120 lines, 모두 프로즈)

- 6 명령: `create`, `run`, `list`, `show`, `edit`, `delete` (모두 프로즈 지시)
- 팀 정의 포맷: `.claude/teams/<팀이름>/team.md` + `members/member-N.md`
- **스크립트 0개.** 모든 로직이 LLM 해석 의존
- **Pre-flight 체크 없음** (env, 버전, subagent 컨텍스트 체크)
- **Preset 카탈로그 없음**
- **에러 카탈로그 없음**
- **패턴 가이드 없음**
- **taskId·owner·status 프로토콜 언급 없음**
- **"언제 쓰지 말 것" 없음** (Shipyard 경고 미반영)
- **중간 보고·타임아웃·shutdown 프로토콜 전무**

---

## 1. Gap 표 (항목 × 현재 × 기준 × 갭 × Why)

### 1.1 구조·준수 계층 (Skills 공식 스펙)

| # | 항목 | 현재 상태 | 기준 (공식/커뮤니티) | 갭 크기 | Why |
|---|------|-----------|---------------------|---------|------|
| S1 | frontmatter — `when_to_use` | 없음 | 공식 권장 (01 §4.2) — skill listing 에 들어감 | **높음** | "언제 자동 invoke 되는지" 가 description 1줄에만 의존 → 모호한 trigger 로 오발 invoke 위험 |
| S2 | frontmatter — `argument-hint` | `"[create|run|list|delete] ..."` 있음 (하지만 edit/show 빠짐) | 6 명령 반영 필요 | 중간 | autocomplete 이 실제 명령셋과 어긋남 — 사용자 혼선 |
| S3 | frontmatter — `arguments` (positional) | 없음 | 공식 지원 (01 §4.2) | 낮음 | 6 명령 모두 인자 수·이름 상이 → subcommand 체계엔 `arguments` 보다 파서가 적합. 낮음 유지 |
| S4 | SKILL.md 줄수 | 120 lines | 공식 권장 500 이내 + reference 1단계 분리 (01 §4.4, §4.9) | 낮음 | 현재 너무 짧은 게 문제 — 확장 여지 풍부. 단, 확장 시 500 초과 방지 가드 필요 |
| S5 | scripts/ 분리 | **0개** | 벤치마크(feedback): 6 스크립트로 로직 외부화 | **치명** | 실행 로직이 LLM 해석에 의존 → 재현성 zero, 타임아웃·retry 없음 (feedback 이 31회 백업 끝에 얻은 교훈 그대로 복습 중) |
| S6 | reference 파일 (패턴·에러 카탈로그 등) | 없음 | 01 §4.4 (reference/ 분리 권장), 02 §2 (SKILL 공통 구조) | 높음 | SKILL.md 본문에 모든 판단 규칙을 때려넣으면 500 초과. 지금부터 reference 체계 설계 필요 |
| S7 | `disable-model-invocation` 정책 | 명시 없음 (default=false) | 파괴적 명령(delete) 은 고려 필요 | 낮음 | `delete` 가 모델 자동 invoke 되면 위험. sub-command 단위로는 frontmatter 제어 불가 → 스크립트 단에서 guard |
| S8 | `allowed-tools` 정확성 | `Agent, Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch` | 팀 오케스트레이션이면 `TaskCreate/TaskUpdate/TaskGet/TaskList/SendMessage` 필수 (01 §1.7) | **치명** | 실제 팀 운영에 쓰이는 핵심 tool 이 allow-list 에 없음 → skill active 중 approval prompt 폭탄 or 호출 실패 |

### 1.2 사전조건·환경 (Pre-flight)

| # | 항목 | 현재 상태 | 기준 | 갭 크기 | Why |
|---|------|-----------|------|---------|------|
| P1 | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 체크 | 없음 | 01 §1.1 필수. 02 §1.[1] wshobson/oh-my-claudecode 공통 권장 | **치명** | env 미설정 상태에서 run 실행하면 SendMessage/TaskCreate 등이 조용히 실패 or 숨어있다가 터짐 |
| P2 | Claude Code v2.1.32+ 버전 체크 | 없음 | 01 §1.1 필수 | 높음 | 낮은 버전에서는 기능 자체가 없음 — 디버깅 낭비 |
| P3 | 현재 컨텍스트가 subagent 인지 체크 | 없음 | 02 §1.[8] issue#32723 — teammate 가 TeamCreate 호출하면 고아 config 생성 | **치명** | 중첩 팀 시도 시 `~/.claude/teams/<name>/` 빈 디렉토리가 누적됨. 자동 invoke 로 일어나면 치명적 누수 |
| P4 | tmux/teammateMode 체크 (split panes 환경 시) | 없음 | 01 §1.9. 02 §1.[2] oh-my-claudecode Phase 0 표준화 | 중간 | VS Code/Windows Terminal 에서 split panes 지정하면 실패 — 주인님은 Windows 환경이라 실질 중요 |

### 1.3 팀 오케스트레이션 프로토콜

| # | 항목 | 현재 상태 | 기준 | 갭 크기 | Why |
|---|------|-----------|------|---------|------|
| O1 | TeamCreate → TaskCreate → Agent(team_name) → SendMessage 시퀀스 강제 | "Agent Teams 기능을 활용한다" 1줄 | 글로벌 CLAUDE.md 의무, 02 §3 (Parallel/Pipeline/Gate 패턴별 구체 호출) | **치명** | 사용자 규칙이 실제 skill 로 내려와야 하는데 프로즈 "활용한다"만 있음 — LLM 이 매번 해석. 01 §6 에서도 "TeamCreate 가 공식 문서에 없다" 사실 자체를 스킬이 밝혀야 |
| O2 | Task blockedBy/blocks 의존성 명시 | 없음 | 01 §1.7, 02 §3 Pipeline 패턴 | 높음 | Pipeline 패턴의 핵심인데 skill 에 한 줄도 없음 → LLM 이 의존성 없이 병렬 spawn 하기 쉬움 |
| O3 | teammate 이름 규약 (UUID 금지, 예측 가능한 name) | 없음 | 01 §1.6, 02 §4 A3 | 높음 | 지금 이 세션도 이미 `analyst`, `docs-researcher`, `community-researcher` 같은 이름 규약 쓰는 중. skill 이 강제 안 하면 다른 팀에서 UUID 로 돌아감 |
| O4 | broadcast 사용 가이드 (`*` 남용 방지) | 없음 | 01 §1.6, 02 §4 A1 | 중간 | "Use sparingly, costs scale with team size" — skill 에 명시 필요 |
| O5 | nested team 금지 경고 | 없음 | 01 §1.10, 02 §4 A7/A9, issue#32723 | **치명** | 현재 skill 은 "팀원 spawn" 만 얘기. teammate 가 skill 재호출 시 TeamCreate 시도 가능성 차단 필요 |
| O6 | skill/mcpServers 가 teammate 에서 무시됨 경고 | 없음 | 01 §1.5 Note 원문 인용 | 높음 | teammate 에게 skill 이 있을 거라 가정하고 설계하면 조용히 실패 — 사용자 함정 |
| O7 | 패턴 선택 가이드 (Parallel/Pipeline/Swarm/Research+Impl/Plan-Approval/Multi-File/RLM) | 없음 | 02 §1.[3] zircote 7패턴, 02 §6 | 높음 | 선택 기준 없이 만들면 매번 즉흥 설계 — feedback 스킬이 "하나의 시나리오만 정의"로 안정성 얻은 것과 정반대 |
| O8 | Plan Approval Gate 프로토콜 | 없음 | 02 §3 + 공식 `plan_approval_response` | 중간 | 고위험 변경엔 필요하나 MVP 범위에선 P2 |
| O9 | Model 배분 (lead/reviewer=Opus, devops=Sonnet) | 없음 | 02 §2 수렴 관습, §6 체크리스트 #9 | 낮음 | 주인님은 Opus 라이선스. Opus 고정이 실제 practical. 문서화만 필요 |
| O10 | Preset 팀 카탈로그 | 없음 | 02 §1.[1] wshobson 7 preset, §6 체크리스트 #2 | 높음 | 매번 `create` 할 때마다 전체 구성을 물어보는 건 피로. 하네스 프로젝트 특화 preset (docs-research / harness-design / knowledge-graphify) 이 효용 큼 |
| O11 | Verifier/Reviewer 역할 기본 제공 | 없음 | 02 §1.[6] barkain task-completion-verifier, §1.[5] aws-samples review-agent | 중간 | /checklist 스킬과 연동 효과 |
| O12 | Review cycle cap (무한 루프 방지) | 없음 | 02 §1.[5] aws-samples 3 cycle cap | 중간 | review → fix → review 무한 회피 |
| O13 | Scaling heuristic (단순:1-2 / 보통:2-3 / 복잡:3-4 / 매우복잡:4-5) | 없음 | Anthropic eng blog 2025-06 (02 §1.[4]) | 중간 | LLM 이 N=10 팀 spawn 하는 사고 예방 |

### 1.4 신뢰성·관측 가능성 (실측 4건 대응)

| # | 항목 | 현재 상태 | 기준 | 갭 크기 | Why |
|---|------|-----------|------|---------|------|
| R1 | **진행 상황 가시성 (중간 보고)** | 없음 | 벤치마크 feedback: JSON stdout, status 파일. 공식 TaskUpdate `activeForm` 필드 | **치명** | 실측 2026-04-22 agent-team-skill-redev 세션 — 팀원이 뭐 하는지 얼마나 남았는지 0% 관찰 가능. feedback 은 각 CLI 결과 파일로 실시간 확인 가능했음. 이 skill 은 같은 원리(주기적 TaskUpdate activeForm + 산출물 파일) 강제 필요 |
| R2 | **타임아웃 메커니즘** | 없음 | 벤치마크 feedback: `-TimeoutSeconds 300` 기본 + `orchestrate.ps1` 내부 enforcement | **치명** | 실측 2026-04-22 — 웹 서칭 루프/hang 방지 장치 전무. /feedback 은 300초 timeout + 1회 retry 로 hang 예방. 동일 패턴 필수 |
| R3 | **중복 알림/시스템 artifact 구분** | 없음 (프로토콜 없음) | — (공식·커뮤니티 명시 기준 없음, 실측 기반 신규 요구) | 높음 | 실측 2026-04-22 — 중복 재할당 시스템 메시지와 team-lead 의 진짜 지시가 구분 불가. skill 차원에서 "lead 의 지시는 반드시 SendMessage 로만, task 재할당은 TaskUpdate owner 로만" 프로토콜 고정 필요 |
| R4 | **병렬→순차 핸드오프 자동화** | 없음 (수동 조율) | 02 §1.[3] Pipeline `TaskUpdate addBlockedBy`, 02 §3 "phase gate" | **치명** | 실측 2026-04-22 — team-lead 가 매번 직접 re-spawn. blockedBy 체인 + "Phase N 전원 완료 시 자동 unblock" 를 공식 Task 시스템이 지원(01 §1.7) 하는데 skill 이 그걸 쓰지 않음 |
| R5 | shutdown 프로토콜 | 없음 | 01 §1.10 (shutdown 느림), 02 §6 체크리스트 #7 | 높음 | /resume 불가 + 1 team/session → 종료 절차 없으면 좀비 team 누적 |
| R6 | 고아 `~/.claude/teams/<name>/` 청소 가드 | 없음 | 02 §1.[8] issue#32723 | 중간 | Pre-flight 에서 orphan 감지 or 설치 시 검사 |
| R7 | 에러 카탈로그 (Error → Cause → Fix) | 없음 | 02 §1.[2] oh-my-claudecode Error Reference | 높음 | 벤치마크 feedback 의 Validation Gate 와 유사한 "판정 자동화" 효과 |
| R8 | 안티패턴 목록 (A1~A15) | 없음 | 02 §4 | 중간 | Troubleshooting 섹션에 reference 로 분리 가능 |

### 1.5 사용 범위·"언제 쓰지 말 것"

| # | 항목 | 현재 상태 | 기준 | 갭 크기 | Why |
|---|------|-----------|------|---------|------|
| U1 | "언제 쓰지 말 것" 명시 | 없음 | Shipyard 2026-03 "95% task 에 부적합", 02 §6 #10 | **치명** | 사용자 CLAUDE.md 가 "설계·계획·분석·구현은 무조건 팀" 으로 강제 중 — 공식 경고와 충돌. skill 이 명시적으로 반박/완화 기준 제공해야 (ex: "tiny edit, routine task 는 예외") |
| U2 | 6 명령 필요성 재평가 | create/run/list/show/edit/delete 모두 포함 | 실사용 시 edit/show 거의 안 쓰임 (수동 파일 수정이 더 쉬움) | 중간 | `show` = `cat team.md` 과 동일, `edit` = `Edit` tool 호출과 동일. 중복 기능 삭감 여지 |
| U3 | `run` 의 실제 수행 계약 | 프로즈 6줄 ("저장된 팀을 불러와서 실행") | 프리플라이트→TeamCreate→TaskCreate 체인→spawn→monitor→shutdown 까지 명확한 Phase 체계 필요 (벤치마크 feedback 4 Step) | **치명** | `run` 은 이 skill 의 심장. 프로즈 6줄로는 재현성 zero |

---

## 2. 우선순위표 (P0/P1/P2) — 재설계 반영 순서

### P0 (당장 — architect 가 반드시 반영)

| ID | 항목 | 재설계 반영 형태 (제안) |
|----|------|----------------------|
| S5 | scripts/ 외부화 | `scripts/preflight.ps1`, `scripts/run-team.ps1`, `scripts/shutdown.ps1`, `scripts/validate-team.ps1` 최소 4개 |
| S8 | allowed-tools 정정 | `TaskCreate, TaskUpdate, TaskGet, TaskList, SendMessage, Agent, Read, Write, Edit, Bash, Glob, Grep` |
| P1 | env 체크 (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) | preflight.ps1 내 고정, 미설정 시 abort + 안내 |
| P3 | subagent 컨텍스트 체크 | preflight.ps1 에서 `Agent` tool 존재 여부 체크 (없으면 abort) |
| O1 | 4-step 프로토콜 강제 | SKILL.md 본문에 "Step 1-4" 고정, 각 step 이 호출할 tool 명시 |
| O5 | nested team 금지 | preflight 와 본문 경고 양쪽 |
| R1 | 진행 상황 가시성 | TaskUpdate `activeForm` + 산출물 파일 경로 기록 강제 (주기 명시: 10분마다 or phase 전환 시) |
| R2 | 타임아웃 | run-team.ps1 의 `-TimeoutMinutes` 파라미터, 기본 30분 (feedback 5분 패턴 차용) |
| R4 | 핸드오프 자동화 | TaskCreate 시 `blockedBy` 체인 템플릿 제공, phase gate 자동 unblock 설명 |
| U1 | "쓰지 말 것" 명시 | frontmatter `description` 에 "tiny edit/routine 제외" 포함 + 본문 Non-goals 섹션 |
| U3 | `run` Phase 체계 | 벤치마크 feedback Step 1-4 구조 차용 — 프로즈 6줄 → 구체 Step 4개 |

### P1 (중요 — v2 에서 포함, 허용되면 P0 로 승격)

| ID | 항목 | 재설계 반영 형태 (제안) |
|----|------|----------------------|
| S1 | `when_to_use` frontmatter | trigger phrase 3-5개 명시 |
| S6 | reference 파일 분리 | `reference/patterns.md`, `reference/anti-patterns.md`, `reference/errors.md`, `reference/presets.md` |
| P2 | Claude Code 버전 체크 | preflight 에 `claude --version` 파싱 |
| O2 | blockedBy/blocks 명시 | reference/patterns.md 의 Pipeline 섹션 + Step 2 스크립트 출력 예시 |
| O3 | teammate name 규약 | SKILL.md 본문 "예측 가능한 name 할당" 1문단 |
| O6 | skill/mcp teammate 전파 안 됨 경고 | SKILL.md 본문 경고 박스 |
| O7 | 패턴 선택 가이드 | reference/patterns.md — 7패턴 표 (zircote 기반) |
| O10 | Preset 카탈로그 | `presets/` 디렉토리 — review, debug, research, docs-research, harness-design 5종 (MVP) |
| R3 | 중복 알림 구분 프로토콜 | 본문 "lead 지시는 SendMessage, 재할당은 TaskUpdate owner" 1문단 |
| R5 | shutdown 프로토콜 | `scripts/shutdown.ps1` + 본문 Phase 명시 |
| R7 | 에러 카탈로그 | reference/errors.md (oh-my-claudecode 차용) |

### P2 (나중에 — v3+ 고려)

| ID | 항목 | 이유 |
|----|------|------|
| S2 | argument-hint 완성 | 6 명령 재평가 후 (U2) |
| S3 | `arguments` positional | 현 sub-command 체계엔 부적합 — 재평가 |
| S7 | `disable-model-invocation` 세분화 | delete 만 따로 뽑아내야 하는데 skill 단위 제약 |
| O4 | broadcast 가이드 | 안티패턴에 포함되면 충분 |
| O8 | Plan Approval Gate | MVP 범위 밖, 고위험 변경 전용 |
| O9 | Model 배분 | 문서화만 필요 |
| O11 | Verifier 기본 제공 | /checklist 통합 후 |
| O12 | Review cycle cap | preset 별 설정 |
| O13 | Scaling heuristic | 본문 1표 |
| R6 | 고아 config 청소 | 별도 유틸 스크립트 |
| R8 | 안티패턴 목록 (A1~A15) | reference/anti-patterns.md |
| U2 | 6 명령 재평가 | edit/show 삭제 후보 |

---

## 3. 실측 4건 섹션 (2026-04-22 agent-team-skill-redev 세션)

주인님이 현재 팀(docs-researcher + community-researcher + analyst + architect) 실행 중 **직접 관찰**한 현재 스킬의 실제 실패 모드. 공식·커뮤니티 문서에는 없는 1차 관찰 데이터이므로 출처를 "실측 2026-04-22 agent-team-skill-redev 세션" 으로 명시.

### 실측 #1 — 진행 상황 가시성 zero (R1, **치명 / P0**)

- **현상**: 팀원이 뭐 하는지, 얼마나 남았는지 보이지 않음. 중간 보고 프로토콜 없음.
- **왜 발생**: SKILL.md 에 "활성 teammate 는 주기적으로 TaskUpdate 로 진행을 보고해야 한다" 같은 강제 항목이 없음. team-lead 가 teammate 에게 SendMessage 로 "현황 보고해라" 를 매번 수동 보내야 함.
- **재설계 처방**:
  1. SKILL.md 본문에 "Phase 전환 시 + 10분 경과 시 TaskUpdate activeForm 갱신 필수" 명시.
  2. preset 의 member md 에 "진행 보고 프로토콜" 고정 문구 삽입.
  3. `scripts/monitor-team.ps1` 으로 `~/.claude/tasks/<team>/` 디렉토리를 주기적으로 덤프하여 사람이 읽기 쉬운 상태표 출력(선택).
- **벤치마크**: /feedback 은 `docs/feedback/` 아래 각 CLI 결과 파일로 실시간 진행 확인 가능 — 같은 철학(파일 = 관측점) 채택 필요.

### 실측 #2 — 타임아웃 없음 (R2, **치명 / P0**)

- **현상**: 웹 서칭 루프·hang 방지 메커니즘 전무. teammate 가 조용히 멈춰도 감지 못함.
- **왜 발생**: run 프로세스가 프로즈 6줄로만 정의 → 타임아웃 개념 자체가 skill 에 없음.
- **재설계 처방**:
  1. `scripts/run-team.ps1 -TimeoutMinutes <N>` 도입 (기본 30분, 벤치마크 feedback 5분 원리 확대).
  2. teammate 별 개별 타임아웃: 각 task 에 `metadata.timeoutMinutes` 필드 권장 (TaskUpdate 로 설정).
  3. 타임아웃 초과 시 team-lead 에게 TeammateIdle hook 신호 → SendMessage 로 개입 요청.
- **벤치마크**: feedback `-TimeoutSeconds 300` + `orchestrate.ps1` 내부 enforcement (Wait-Job with timeout).

### 실측 #3 — 중복 알림 스팸 (R3, 높음 / P1)

- **현상**: 시스템 artifact(중복 재할당 notification) 와 진짜 team-lead 지시가 구분 불가. teammate 는 두 종류를 같은 inbox 에서 받음.
- **왜 발생**: SendMessage 는 모두 `<teammate-message>` 태그로 오며, "이게 사람(lead)이 쓴 건가 시스템이 자동 재전송한 건가" 알 방법이 없음.
- **재설계 처방**:
  1. SKILL.md 본문에 "lead 지시는 SendMessage, task 재할당은 TaskUpdate owner" 로 **채널 분리**.
  2. lead 에게 강제: SendMessage body 첫 줄에 `[INSTRUCTION]`, `[STATUS-REQUEST]`, `[CORRECTION]` 같은 prefix 태깅 규약.
  3. teammate side: 같은 taskId 에 대해 중복 재할당 받을 때는 최신 것만 반영, 이전 것 무시 로직을 member.md system prompt 에 명시.
- **공식 기준 없음**: 이는 실측 기반 신규 요구. 우선순위 높음이지만 P1 로 (프로토콜 설계만, 스크립트 강제 어려움).

### 실측 #4 — 핸드오프 수동 조율 (R4, **치명 / P0**)

- **현상**: 병렬→순차 전환(phase gate) 을 팀 리드가 매번 직접 spawn 해야 함. 자동 unblock 활용 못함.
- **왜 발생**: 현재 skill 이 `blockedBy`/`blocks` 의 의존성 체인을 한 문장도 설명하지 않음. 공식 Task 시스템은 "완료 시 의존 task 자동 unblock" 을 지원(01 §1.7)하는데 skill 사용자가 모름.
- **재설계 처방**:
  1. SKILL.md 본문에 Pipeline 패턴 예시 (research1 + research2 → analyst → architect) 템플릿 고정 (= 지금 이 agent-team-skill-redev 팀 구조 그대로).
  2. reference/patterns.md 의 Pipeline 섹션에 `TaskCreate` + `TaskUpdate addBlockedBy` 예시 JS/PS 의사코드.
  3. `scripts/run-team.ps1` 이 preset 로드 후 자동으로 blockedBy 체인 생성 (preset 의 members 에 `depends_on` 필드로 선언).
- **벤치마크**: zircote Pipeline skill — 이미 코드화됨.

---

## 4. 요약 — 재설계 시 architect 가 놓치면 안 되는 것

1. **scripts/ 외부화가 최우선** (S5). 프로즈 skill 은 31회 백업 공식을 답습한다. feedback 성공 공식을 그대로 차용.
2. **Pre-flight 4개** (env / version / subagent / tmux) 를 **스크립트 1개** (`preflight.ps1`) 로 묶어 Step 1 에 고정. 실패 시 abort.
3. **실측 4건은 치명 3 + 높음 1**. 모두 v2 MVP 에 포함해야 함.
4. **"쓰지 말 것" 명시 (U1)** 와 **4-step 프로토콜 강제 (O1, U3)** 는 skill 의 정체성. 프로즈에서 Phase 체계로 전환.
5. **Preset 5종** (review / debug / research / docs-research / harness-design) 으로 create 명령의 "매번 전체 구성 물어보기" 피로 제거.
6. **TeamCreate 는 공식 primitive 아님** — skill 이 이 사실을 밝히고, 자연어 요청 fallback 도 설명 (사용자가 tool 이름 바뀔 때 대비).
7. **teammate 에서 skills/mcp 무시, nested team 금지** — v2 본문 경고 박스 2개 필수.

---

## 5. 부록 — 벤치마크(/feedback) 에서 가져올 3가지 패턴

| 벤치마크 항목 | /feedback 에서 | agent-team-manager v2 에 이식 |
|--------------|--------------|-----------------------------|
| 격리 디렉토리 패턴 | `prepare-isolation.ps1` + `$HOME/codex-cwd` 슬러그 | 팀 실행마다 `~/.claude/tasks/<team>-<slug>/` 격리 (공식 경로에 맞춤) |
| 스크립트 1회 호출로 통합 | `orchestrate.ps1` 1회 = 병렬 실행 + 타임아웃 + 재시도 | `run-team.ps1` 1회 = preflight + TeamCreate + task spawn + monitor + shutdown |
| Validation Gate 자동화 | `validate-outputs.ps1` — 디스크 기반 판정, LLM 해석 배제 | `validate-team.ps1` — 고아 config 검출, task 상태 일관성, deadline 초과 감지 |

---

**작성자**: analyst
**다음**: architect 가 이 Gap 분석을 기반으로 `04_v2-design.md` 작성. P0 11건 + P1 11건 을 SKILL.md + scripts/ + reference/ 구조로 설계.
