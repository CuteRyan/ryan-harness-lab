---
title: "agent-team-manager v2 재설계 스펙"
owner: architect
date: 2026-04-22
scope: task #4 of agent-team-skill-redev team
inputs:
  - C:/Users/rlgns/.claude/skills/agent-team-manager/SKILL.md (v1, 120 lines)
  - docs/research/agent-team-skill-redesign/01_official-docs.md
  - docs/research/agent-team-skill-redesign/02_community-patterns.md
  - docs/research/agent-team-skill-redesign/03_gap-analysis.md
benchmark: C:/Users/rlgns/.claude/skills/feedback/ (SKILL.md + 6 scripts)
note: 본 문서는 **명세**다. 실제 PowerShell 코드는 별건 구현 태스크에서 작성한다.
---

# agent-team-manager v2 재설계 스펙

## 0. Executive Summary

1. **구조 승격**: 프로즈 단일 md(120줄) → `SKILL.md` + `scripts/` 6개 + `reference/` 4개 + `presets/` 5개로 외부화 (feedback 스킬 공식).
2. **재현성 확보**: preflight/run/monitor/shutdown/validate 를 스크립트로 고정 — LLM 해석 경로 제거 (feedback 31회 백업 교훈 직접 적용).
3. **공식 프로토콜 명세화**: TeamCreate/TaskCreate/Agent/SendMessage 4-step 시퀀스를 Phase 로 고정. 단, **이 primitive 이름들은 공식 문서 부재, 런타임 실측 기반**임을 스킬 초입에 1회 경고.
4. **실측 4건(R1~R4) 전부 P0 으로 해결**: TaskUpdate activeForm 주기 강제 / -TimeoutMinutes 30 / 채널 분리 프로토콜 / blockedBy 체인 템플릿 내장.
5. **주인님 룰 충돌(U1) 해결안 — 옵션 C 권장**: 스킬 내부 Non-goals 섹션 + CLAUDE.md 수정 권고안 병행 (최종 판정은 주인님).

---

## 1. 새 디렉토리 구조

```
~/.claude/skills/agent-team-manager/
├── SKILL.md                                   # 엔트리 포인트 (< 500줄, LLM 이 항상 읽음)
├── scripts/
│   ├── preflight.ps1                          # 환경·버전·subagent 컨텍스트·tmux 체크
│   ├── resolve-preset.ps1                     # preset 로드 + depends_on → blockedBy 변환
│   ├── run-team.ps1                           # 진입점: preflight → 팀 프로비저닝 메타 출력
│   ├── monitor-team.ps1                       # 주기 상태 덤프 (사람이 읽는 표)
│   ├── validate-team.ps1                      # 고아 config / 좀비 task / 데드라인 검증
│   └── shutdown-team.ps1                      # 좀비 정리 + orphan team dir 청소
├── reference/
│   ├── patterns.md                            # 7 오케스트레이션 패턴 표
│   ├── anti-patterns.md                       # A1~A15 실패 모드 + Fix
│   ├── errors.md                              # Error → Cause → Fix 테이블
│   └── presets.md                             # preset 카탈로그 요약 (→ presets/*.md 포인터)
└── presets/
    ├── review.yaml                            # code review 팀 (Opus reviewer x3)
    ├── debug.yaml                             # bug hunting 팀
    ├── research.yaml                          # 일반 리서치 팀 (parallel researcher + analyst)
    ├── docs-research.yaml                     # 하네스 특화: 공식문서 + 커뮤니티 + analyst + architect (현 agent-team-skill-redev 구조 정형화)
    └── harness-design.yaml                    # 하네스 특화: rules 설계 전용
```

### 각 파일 책임 1줄 요약

| 파일 | 책임 |
|------|------|
| `SKILL.md` | 진입점·Phase 체계·스크립트 호출 순서. LLM 이 **해석**하는 유일한 md. |
| `scripts/preflight.ps1` | 런타임 전제조건 4종 검증 (env / version / subagent / tmux). abort 결정. |
| `scripts/resolve-preset.ps1` | YAML preset → 팀 프로비저닝 메타(JSON) 변환. `depends_on` → `blockedBy` 변환. |
| `scripts/run-team.ps1` | preflight + resolve-preset + 타임아웃 sentinel 파일 기록. Team/Task primitive 호출은 LLM이 수행 (스크립트는 tool을 호출하지 않음). |
| `scripts/monitor-team.ps1` | `~/.claude/tasks/<team>/` 디렉토리 주기 스캔 → 사람·LLM 둘 다 읽는 상태표 출력. |
| `scripts/validate-team.ps1` | feedback/validate-outputs.ps1 대응. 고아 디렉토리·미완료 task·데드라인 초과·중복 owner 감지 → JSON. |
| `scripts/shutdown-team.ps1` | 좀비 teammate 종료 신호 + orphan `~/.claude/teams/` 정리. |
| `reference/patterns.md` | 7 패턴 선택 가이드 — LLM 이 preset 이외 즉흥 설계 시 참조. |
| `reference/anti-patterns.md` | A1~A15 — Troubleshooting 시 on-demand 로드. |
| `reference/errors.md` | preflight/validate 실패 reason 코드별 해결법. |
| `reference/presets.md` | `presets/*.yaml` 의 요약 표 — LLM 이 preset 선택 시 1차 참조. |
| `presets/*.yaml` | team.md + members 를 하나의 선언형 파일로 통합. |

**Why 디렉토리 분리**:
- `scripts/` vs `reference/` vs `presets/` — 각각 **실행 / 판단 / 선언** 의 책임 분리. LLM 은 reference 를 "언제 읽을지" 를 SKILL.md 본문의 조건(= "패턴 선택 시" "에러 발생 시")에 의해 결정.
- 공식 skills best-practices: reference 는 depth 1, 100줄 초과 시 TOC — `reference/patterns.md` 는 이 룰 준수.

---

## 2. 스크립트 책임 분리 매트릭스 (LLM vs 스크립트)

feedback 공식: **결정론은 스크립트, 판단·종합은 LLM**. 본 스킬도 동일.

| 로직 | 담당 | Why |
|------|------|------|
| env/version/subagent/tmux 검사 | **스크립트** (preflight.ps1) | 논리식이 단순 명확, LLM 해석 시 매번 다르게 판정할 위험 |
| preset YAML 파싱 + depends_on→blockedBy 변환 | **스크립트** (resolve-preset.ps1) | 파싱은 LLM 으로 하면 타이포/누락 흔함. 스크립트 JSON 으로 LLM 에 전달 |
| 타임아웃 sentinel 파일 생성 | **스크립트** (run-team.ps1) | 기록 자체는 스크립트가 수행 (LLM 은 타임스탬프 계산 불안정) |
| **TeamCreate / TaskCreate / Agent spawn / SendMessage 호출** | **LLM** | Claude Code agent teams primitive 는 LLM 이 가진 tool — 스크립트가 호출 못 함 |
| teammate 역할 프롬프트 조립 | **LLM** | preset + 현재 태스크 맥락을 동적으로 합성. 프롬프트 엔지니어링은 LLM 본업 |
| task 의존성 체인 결정 (blockedBy 값) | **스크립트 1차 + LLM 2차** | preset 기준은 스크립트 자동 / 사용자 추가 요청은 LLM 판단 |
| 중간 진행 모니터링·상태 덤프 | **스크립트** (monitor-team.ps1) | 파일시스템 주기 읽기는 스크립트가 안정적. LLM 은 출력만 해석 |
| teammate 결과 종합·의사결정 | **LLM** | validate-team 판정 수용 후 LLM 이 종합 작성 (feedback Step 3 동일) |
| 고아 config / 데드라인 판정 | **스크립트** (validate-team.ps1) | 룰 기반 판정. feedback/validate-outputs.ps1 과 동일 철학 |
| 종합 보고서 작성 | **LLM** | feedback 과 동일 구조 |
| `/resume` 실패 복구 결정 | **LLM** | teammate 재spawn 필요 여부는 context 판단 |

### 경계선 원칙 (feedback 차용)

- **스크립트는 tool 을 호출하지 않는다.** PowerShell 안에서 `TeamCreate` 같은 claude-code tool 호출은 불가능. 스크립트는 **파일·프로세스·검증**만 담당.
- **LLM 은 스크립트 JSON stdout 을 그대로 수용한다.** validate-team.ps1 의 판정에 LLM 이 이의 제기 금지 (feedback 원칙 유지).

---

## 3. 명령별 플로우

### 3.1 `/agent-team run <preset|teamName>` — 팀 실행 (핵심 명령)

| Phase | 주체 | 동작 |
|-------|------|------|
| **Phase 0: Pre-flight** | SKILL.md → `scripts/preflight.ps1` 호출 (LLM) | 4체크. 실패 시 abort + `reference/errors.md` 의 해당 reason 안내 |
| **Phase 1: Preset 해석** | SKILL.md → `scripts/resolve-preset.ps1 -Preset <name>` | preset YAML 을 JSON 메타로 출력 (team_name, members[], task_graph[], timeout_minutes) |
| **Phase 2: TeamCreate** | **LLM** (tool 직접 호출) | resolve-preset 의 team_name, description 으로 호출. 실측 primitive — 실패 시 자연어 대체 경로 안내 |
| **Phase 3: TaskCreate + blockedBy 체인** | **LLM** | task_graph 순회, 각 task 를 TaskCreate 하고 이전 task 를 addBlockedBy 로 연결. phase gate 자동화. |
| **Phase 4: Agent spawn (teammate)** | **LLM** | members[] 순회, 각각 `Agent` tool 로 spawn. subagent_type 은 preset 에 선언된 것 사용 (기본 `general-purpose`). teammate 이름은 **예측 가능 — preset member.name 그대로** (UUID 금지). |
| **Phase 5: Sentinel 등록** | SKILL.md → `scripts/run-team.ps1 -SentinelInit -TimeoutMinutes 30` | `~/.claude/tasks/<team>/.sentinel.json` 에 start_time + deadline + members 기록 |
| **Phase 6: Monitor loop (선택)** | SKILL.md → `scripts/monitor-team.ps1 -Team <name>` 주기 호출 | N분마다 상태표 덤프. LLM 은 덤프 내용으로 팀 진행 판단. 좀비/데드라인 초과 시 개입. |
| **Phase 7: Validate + Synthesize** | SKILL.md → `scripts/validate-team.ps1 -Team <name>` → **LLM** | validate 판정 JSON 수용. valid 항목만 종합 보고서 작성. |
| **Phase 8: Shutdown** | SKILL.md → `scripts/shutdown-team.ps1 -Team <name>` | 좀비 정리. 주인님 승인 후에만 team dir 삭제 (feedback 의 `.dev-checklist.md` 삭제 금지 원칙 차용). |

**핵심 제약**:
- Phase 2·3·4 는 LLM 이 수행하는 유일한 자유도. SKILL.md 가 호출 순서·인자 포맷을 명세로 고정.
- Phase 0 에서 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS != 1` 또는 subagent 컨텍스트면 즉시 abort (Phase 1~ 진입 안 함).

### 3.2 `/agent-team create <name>` — 팀 정의 생성

- **대화형 제거 가능성**: v1 은 대화형 질문. v2 는 **preset 기반 파생**이 기본. 기존 preset 중 가장 유사한 것 복사 → 수정.
- Phase 1: `scripts/resolve-preset.ps1 -List` 로 preset 목록 출력, 사용자 선택.
- Phase 2: 선택된 preset YAML 을 `.claude/teams/<name>/team.yaml` 로 복사.
- Phase 3: LLM 이 사용자와 대화하며 필요한 필드(members 추가, prompt 수정) 변경.
- Phase 4: preset 검증: `scripts/resolve-preset.ps1 -ValidateOnly -Path <file>` 호출로 스키마 체크.

**Why**: v1 의 "매번 전체 구성 물어보기" 피로(U2) 제거. preset → 파생 방식이 실전에 더 빠름 (02 §6 #2).

### 3.3 `/agent-team list` — 팀 목록

- Phase 1: `.claude/teams/*/team.yaml` 글로브 + preset 디렉토리 스캔
- Phase 2: `scripts/validate-team.ps1 -Team <each>` 로 각 팀 건강 상태(OK / ORPHAN / STALE / ACTIVE) 표시
- **Why 확장**: v1 은 단순 ls. v2 는 건강 상태까지 — 고아 config 조기 감지 (실측 R6 대응)

---

## 4. 팀 정의 파일 포맷

### 4.1 preset/team 통합 YAML 포맷 (새 포맷)

**Why YAML 전환**: v1 은 markdown 프로즈. LLM 이 파싱해야 해서 해석 변동. YAML 은 스크립트가 직접 파싱 → resolve-preset.ps1 가 JSON 으로 변환 → LLM 은 JSON 만 수용.

```yaml
# 예: presets/docs-research.yaml
name: docs-research
description: 공식 문서 + 커뮤니티 리서치 → Gap 분석 → 설계안 4단계 파이프라인
version: 1

defaults:
  model: opus
  subagent_type: general-purpose
  timeout_minutes: 30

members:
  - name: docs-researcher
    role: "공식 문서만 읽고 팩트 리스트 작성"
    model: opus
    tools_allowlist: [Read, Write, WebFetch, Glob, Grep, TaskGet, TaskUpdate, SendMessage]
    prompt_file: members/docs-researcher.md    # (선택) 긴 프롬프트는 외부 파일
    initial_task: "1"

  - name: community-researcher
    role: "GitHub/커뮤니티 사례 조사"
    model: opus
    tools_allowlist: [Read, Write, WebFetch, WebSearch, TaskGet, TaskUpdate, SendMessage]
    initial_task: "2"

  - name: analyst
    role: "Gap 분석"
    model: opus
    tools_allowlist: [Read, Write, Glob, Grep, TaskGet, TaskUpdate, SendMessage]
    initial_task: "3"
    depends_on: ["1", "2"]

  - name: architect
    role: "최종 설계안"
    model: opus
    tools_allowlist: [Read, Write, Glob, TaskGet, TaskUpdate, SendMessage]
    initial_task: "4"
    depends_on: ["3"]

tasks:
  - id: "1"
    subject: "공식 문서 리서치"
    owner: docs-researcher
    output_path: "docs/research/{slug}/01_official-docs.md"
  - id: "2"
    subject: "커뮤니티 리서치"
    owner: community-researcher
    output_path: "docs/research/{slug}/02_community-patterns.md"
  - id: "3"
    subject: "Gap 분석"
    owner: analyst
    blocked_by: ["1", "2"]
    output_path: "docs/research/{slug}/03_gap-analysis.md"
  - id: "4"
    subject: "설계안"
    owner: architect
    blocked_by: ["3"]
    output_path: "docs/research/{slug}/04_redesign-spec.md"

protocols:
  instruction_prefix: true            # lead SendMessage 첫줄에 [INSTRUCTION]/[STATUS-REQUEST]/[CORRECTION]
  activeForm_update_minutes: 10       # teammate 는 10분마다 TaskUpdate activeForm
  broadcast_allowed: false            # 이 팀은 broadcast 금지 (A1 방지)

on_failure:
  retry_policy: "sync-retry-once"     # feedback 과 동일 철학
  abort_on: ["preflight_fail", "subagent_context"]

phase2_candidates:
  - review_cycle_cap: 3
  - plan_approval_gate: false
```

**Why 필드 구성**:
- `defaults` — 모든 member 에 적용, 개별 member 에서 override
- `members[].prompt_file` 선택 — 긴 system prompt 는 외부 .md 로. SKILL.md depth-1 룰(참조 깊이 1단)에 부합
- `tasks[].blocked_by` — 공식 TaskUpdate `addBlockedBy` 에 1:1 매핑. 스크립트가 자동 변환
- `protocols.activeForm_update_minutes` — 실측 R1 대응. SKILL.md 본문은 "preset 에 선언된 값 준수" 로 위임
- `phase2_candidates` — MVP 제외 항목 문서화 필드. 팀별로 "다음에 추가할 것" 관리

### 4.2 기존 v1 포맷 호환

- `.claude/teams/<name>/team.md` + `members/*.md` 구조는 `scripts/migrate-v1-to-v2.ps1` 에서 **1회** 변환 (본문 `## 역할` 섹션 → YAML `role:` 매핑).
- 마이그레이션 후 v1 파일은 `.v1.bak` 으로 보존 (주인님 승인 후 삭제).

---

## 5. 실행 프로토콜 — 4-step 명세 (공식 primitive 기반)

> ⚠️ **런타임 실측 기반 경고**: `TeamCreate`, `Agent(team_name=...)`, `TaskCreate`, `SendMessage` 는 공식 `code.claude.com/docs/` 레퍼런스에 parameter 스키마가 공개되지 않은 deferred tool 이다. 본 스펙은 2026-04-22 런타임 실측 기준으로 작성되었으며, Anthropic 이 API 를 변경하면 본 스킬도 개정 필요. 이 경고는 SKILL.md 본문에 1회 포함.

### Step 1: TeamCreate (LLM 1회 호출)

```
입력: team_name (preset.name 또는 user-supplied), description (preset.description)
출력: team_id (run-team.ps1 의 sentinel 에 기록)
```

**실패 처리**: tool 이 존재하지 않으면 (API 변경 시) → "tell Claude to create a team with <description>" 자연어 fallback (01 §1.2 공식 권장).

### Step 2: TaskCreate (LLM N회 호출, 각 task 당 1회)

```
입력: subject, description, owner (member.name), blocked_by[] (resolve-preset 이 계산)
호출 순서: blocked_by 가 빈 것부터 depth-first
```

**검증**: resolve-preset.ps1 가 DAG 사이클 검출. 사이클 있으면 Phase 1 에서 abort.

### Step 3: Agent spawn (LLM N회 호출, 각 member 당 1회)

```
입력: team_name, name (member.name), subagent_type (member.subagent_type|defaults),
      prompt (member.prompt_file 내용 + initial_task 정보 + 공통 프로토콜 문구)
```

**공통 프로토콜 문구** (모든 teammate 에게 동일 주입):
1. "taskId 클레임 → TaskUpdate status=in_progress, owner=<your-name>"
2. "10분 경과 시 TaskUpdate activeForm 갱신 (preset.protocols 준수)"
3. "완료 시 output_path 에 산출물 저장 → TaskUpdate completed → team-lead SendMessage"
4. "lead 메시지의 [INSTRUCTION]/[CORRECTION] prefix 식별 후 반응"
5. "teammate 가 skills/mcpServers 재사용 못 함 (01 §1.5). 필요시 main/project 에 이미 설치되어 있어야 함"
6. "nested team 금지 — 본 세션 내에서 TeamCreate 호출 금지"

### Step 4: SendMessage (LLM, 필요 시)

```
lead → teammate: [INSTRUCTION]/[STATUS-REQUEST]/[CORRECTION] prefix 필수
teammate → lead: 완료 보고 (산출물 경로 + task ID + 요약 1줄)
teammate ↔ teammate: 허용 (공식 §1.6) — 단, 핸드오프용만
broadcast(*): preset.protocols.broadcast_allowed=true 인 경우만
```

**실패 처리**: teammate 가 응답 없으면 `SendMessage` 자동 resume 시도 (공식 §1.6). 3회 실패 시 lead 가 teammate 종료 후 재spawn 판단.

---

## 6. 실패/검증 처리 (validate-team.ps1 설계)

feedback/validate-outputs.ps1 차용. **디스크 기반 판정**, LLM 해석 배제.

### 판정 대상

1. `~/.claude/teams/<team>/config.json` 존재 여부 (ORPHAN 검출)
2. `~/.claude/tasks/<team>/` 내 task 파일들의 일관성
   - owner 가 활성 teammate 인지
   - status 가 in_progress 인데 마지막 activeForm 갱신이 `protocols.activeForm_update_minutes * 3` 초과 (= STALE)
   - blocked_by 가 존재하지 않는 taskId 가리킴 (= BROKEN_GRAPH)
3. `.sentinel.json` 의 deadline 초과 여부 (= TIMEOUT)
4. output_path 존재 + 크기 > 0 여부 (완료 task 만)

### 출력 JSON

```json
{
  "summary": "3/4 valid, 1 stale",
  "team": "docs-research",
  "valid_count": 3,
  "total": 4,
  "issues": [
    {"task": "2", "status": "STALE", "owner": "community-researcher",
     "reason": "activeForm 30분 미갱신"}
  ],
  "orphans": [],
  "sentinel": {"deadline_exceeded": false, "minutes_remaining": 8}
}
```

### LLM 의 수용 규칙

- `valid_count = total` && 이슈 없음 → 종합 보고서 작성
- STALE 이슈 → lead 가 해당 teammate 에게 `[STATUS-REQUEST]` SendMessage
- BROKEN_GRAPH → Phase 1 preset 파싱 버그. 즉시 abort + reference/errors.md 참조
- TIMEOUT → shutdown-team.ps1 실행 후 주인님 보고

---

## 7. 템플릿 팀 예시 3개 (YAML 수준 초안)

### 7.1 `presets/review.yaml` — 병렬 전문가 리뷰

```yaml
name: review
description: 3 관점(보안/성능/정확성) 병렬 리뷰 + aggregator 가 종합
version: 1
defaults:
  model: opus
  subagent_type: general-purpose
  timeout_minutes: 20
members:
  - name: security-reviewer
    role: "보안 관점만 — OWASP Top 10, auth, injection"
    initial_task: "1"
    tools_allowlist: [Read, Grep, Glob, TaskGet, TaskUpdate, SendMessage]
  - name: perf-reviewer
    role: "성능 관점만 — N+1, 불필요 loop, 캐싱"
    initial_task: "2"
    tools_allowlist: [Read, Grep, Glob, TaskGet, TaskUpdate, SendMessage]
  - name: correctness-reviewer
    role: "로직 정확성 — edge case, 경계값, 예외 처리"
    initial_task: "3"
    tools_allowlist: [Read, Grep, Glob, TaskGet, TaskUpdate, SendMessage]
  - name: aggregator
    role: "3 리뷰 종합 + 우선순위 top3"
    initial_task: "4"
    depends_on: ["1", "2", "3"]
    tools_allowlist: [Read, Write, TaskGet, TaskUpdate, SendMessage]
tasks:
  - {id: "1", subject: "security review", owner: security-reviewer, output_path: "reports/review/{slug}/security.md"}
  - {id: "2", subject: "perf review", owner: perf-reviewer, output_path: "reports/review/{slug}/perf.md"}
  - {id: "3", subject: "correctness review", owner: correctness-reviewer, output_path: "reports/review/{slug}/correctness.md"}
  - {id: "4", subject: "aggregate", owner: aggregator, blocked_by: ["1", "2", "3"],
     output_path: "reports/review/{slug}/aggregate.md"}
protocols:
  broadcast_allowed: false
  activeForm_update_minutes: 10
```

**Why 이 구조**: 02 §1.[1] wshobson 의 multi-reviewer + §3 Parallel Specialists 패턴. dimension overlap(A6) 회피를 위해 역할 3 분리 명확.

### 7.2 `presets/docs-research.yaml` — 현재 팀 구조 정형화

(§4.1 예시 참조. 현재 agent-team-skill-redev 팀 구조 그대로를 YAML 로 고정)

### 7.3 `presets/harness-design.yaml` — 하네스 특화

```yaml
name: harness-design
description: 하네스 rules/skills 설계 — researcher + skill-auditor + architect 3단계
version: 1
defaults:
  model: opus
  timeout_minutes: 25
members:
  - name: researcher
    role: "공식 문서 + 기존 ~/.claude/rules/ 스캔"
    initial_task: "1"
    tools_allowlist: [Read, Glob, Grep, WebFetch, TaskGet, TaskUpdate, SendMessage]
  - name: skill-auditor
    role: "기존 스킬과의 충돌·중복 검출. /checklist, /feedback 등 연동 포인트 확인"
    initial_task: "2"
    depends_on: ["1"]
    tools_allowlist: [Read, Glob, Grep, TaskGet, TaskUpdate, SendMessage]
  - name: architect
    role: "최종 스펙 md — SKILL.md 초안 + scripts 명세"
    initial_task: "3"
    depends_on: ["2"]
    tools_allowlist: [Read, Write, Edit, Glob, TaskGet, TaskUpdate, SendMessage]
tasks:
  - {id: "1", subject: "research", owner: researcher,
     output_path: "docs/harness-design/{slug}/01_research.md"}
  - {id: "2", subject: "audit existing", owner: skill-auditor, blocked_by: ["1"],
     output_path: "docs/harness-design/{slug}/02_audit.md"}
  - {id: "3", subject: "design spec", owner: architect, blocked_by: ["2"],
     output_path: "docs/harness-design/{slug}/03_spec.md"}
protocols:
  broadcast_allowed: false
  activeForm_update_minutes: 10
  instruction_prefix: true
```

**Why**: 주인님이 하네스 관련 작업을 자주 함. 현재 팀 구조(researcher → analyst → architect) 를 공식 preset 로 승격하면 매번 이 팀 재구성할 필요 없음.

---

## 8. 마이그레이션 플랜 (v1 → v2)

### Step A: 리스크 파악 (변경 전)

- `~/.claude/skills/agent-team-manager/` 현재 파일 백업: `SKILL.md.v1.bak`
- 사용자가 이미 만든 팀: `.claude/teams/*/` 전 프로젝트 스캔 → 건수 파악
  - 2026-04-22 기준: **현재 팀 예시는 이 agent-team-skill-redev 1개만 존재** (실측 필요, v1 create 거의 미사용)
- 결론: 기존 팀 자산이 거의 없으므로 **breaking change 리스크 낮음**. v2 전면 교체 안전.

### Step B: 파일 배치 (v2 설치)

1. `SKILL.md` 교체 (v2 초안 — §11)
2. `scripts/preflight.ps1` 등 6개 스크립트 구현 (별건 구현 태스크)
3. `reference/patterns.md`, `anti-patterns.md`, `errors.md`, `presets.md` 작성 (기존 리서치 md 재활용)
4. `presets/*.yaml` 5개 작성

### Step C: 검증

1. `/agent-team list` — preset 5개 + 기존 팀이 모두 OK 상태로 보이는지
2. `/agent-team run docs-research` 로 이 **지금의 agent-team-skill-redev 구조**를 재현 — 4 teammate spawn + 4 task + 의존성 체인이 preset 로 1회 만에 복구되는지
3. `scripts/preflight.ps1` 의 4체크 각각을 일부러 실패시켜 abort 동작 확인

### Step D: v1 → v2 자동 변환 (기존 팀 있으면)

- `scripts/migrate-v1-to-v2.ps1 -TeamDir <path>` 제공 (별건 구현)
- team.md + members/*.md 를 team.yaml 로 변환
- 변환 실패 시 v1 보존, 로그 남김

### Step E: Global rules 연동 (주인님 승인 필요 — §9 참조)

- `~/.claude/CLAUDE.md` 의 "Agent Preferences" 섹션을 §9 옵션 C 에 따라 수정

### Step F: 관찰 기간 (2주)

- 주인님이 실제 사용 중 발견하는 이슈 `docs/history/` 에 기록
- 2주 후 P2 항목 중 어느 것을 v2.1 로 승격할지 회고

---

## 9. 의사결정 필요 항목 (주인님 승인 요함)

### 9.1 [최우선] U1 — "무조건 팀" 룰 vs Shipyard 경고 충돌

**배경**:
- 현재 `~/.claude/CLAUDE.md` : "설계·계획·분석·구현은 무조건 팀으로"
- Shipyard 2026-03 + 공식 docs limitations: "95% agent-assisted dev task 에 부적합. expensive and experimental"
- 실측: 지금 이 agent-team-skill-redev 자체는 팀 실행이 효용 큼. 하지만 단순 버그픽스·tiny edit 에 팀 쓰는 건 과투자

**옵션과 트레이드오프**:

| 옵션 | 내용 | 장점 | 단점 |
|------|------|------|------|
| **A** | 스킬 내부에서만 "언제 쓰지 말 것" 명시 + routine 예외 정의. CLAUDE.md 는 그대로 | CLAUDE.md 변경 없음 | 룰 충돌 지속. 스킬을 안 타면 여전히 "무조건 팀" 이 강제됨 |
| **B** | CLAUDE.md 수정 권고만, 스킬은 공식 패턴만 따름 | 글로벌 규칙 일관성 | 권고 반영 전까지 가이드 공백 |
| **C** | 둘 다 — 스킬에 Non-goals 섹션 + CLAUDE.md 수정안 제시 (예: "설계·계획·분석은 팀 권장, 단순 수정·3줄 이하 편집·routine 은 단일 세션") | 양쪽 보강. 실측 반영 | 주인님이 두 곳 검토 필요 |

**권장**: **C**. CLAUDE.md 의 "무조건 팀" 을 "다음 경우 팀 권장: 설계/계획/분석/구현. 예외: tiny edit (3줄/240자 이하), routine (단순 조회·이동), single-file refactor with 재현가능 테스트" 로 수정 제안. 스킬은 이 예외 기준을 Non-goals 섹션에 **동일 문구** 로 명시.

**결정 포인트**: 주인님이 A/B/C 중 선택 → architect 가 마이그레이션 Step E 에서 반영.

### 9.2 preset 5개 확정

- 제안: review / debug / research / docs-research / harness-design
- 대안: debug 제거하고 meta-review (리뷰어 팀 자체 리뷰) 추가?
- **결정 포인트**: 주인님의 실사용 빈도 체감 — 주로 만드는 팀은 뭐였는가?

### 9.3 preset YAML vs 기존 markdown

- 제안: YAML 전환 (파싱 안정성)
- 대안: markdown 유지 (기존 자산 호환, 학습 비용 0)
- **결정 포인트**: YAML 도입 허용 여부. 거부 시 `resolve-preset.ps1` 를 markdown 파서로 복잡화.

---

## 10. Phase 2 후보 (MVP 제외)

v2 MVP 에서는 다음 항목을 **명시적으로 제외**. 누락이 아닌 의도적 연기.

| ID | 항목 | 이유 | 승격 조건 |
|----|------|------|----------|
| Ph2-1 | Plan Approval Gate (`plan_approval_response`) 자동화 | 고위험 변경 전용. MVP 에서 사용 빈도 낮음 | 주인님이 deploy 스킬에 연동 요청 시 |
| Ph2-2 | Review cycle cap (3회 무한루프 방지) | preset 별 `cycles_max` 필드로 설정. MVP 는 수동 조율 | review preset 이 재귀 오작동 1회 관측 시 |
| Ph2-3 | Verifier 기본 preset 통합 | `/checklist` 스킬과 결합. 별도 설계 필요 | /checklist v2 완료 후 |
| Ph2-4 | Scaling heuristic 자동 적용 (단순:1-2명, 복잡:4-5명) | Anthropic blog 권장. preset 이 명시하므로 MVP 불필요 | preset 없이 즉흥 create 요청 증가 시 |
| Ph2-5 | `~/.claude/teams/` 글로벌 cleanup 유틸 (`scripts/cleanup-orphans.ps1`) | validate 가 감지만 하고 삭제는 수동 | 고아 디렉토리 5개 이상 누적 시 |
| Ph2-6 | bash 버전 병행 (리눅스 서버 배포용) | feedback Phase 2 와 동일. 하네스 프로젝트 최종 배포 타깃이 Linux | Linux 서버 운영 개시 시 |
| Ph2-7 | Pester 유닛 테스트 | 스크립트 6개 모두 단위 테스트 | 스크립트 2회 이상 regression 발생 시 |
| Ph2-8 | Monitor 자동화 (watchdog 데몬) | 현재는 on-demand 호출. 자동 루프는 Claude Code 밖 프로세스 필요 | 데드라인 초과 누락 3회 이상 시 |
| Ph2-9 | 재리뷰 시 이전 팀 실행 이력 첨부 | docs/history/ 통합 | history 스킬 v2 완료 후 |
| Ph2-10 | 팀 실행 비용·토큰 로깅 | token tracking API 필요 | Anthropic 이 teammate 별 token count 공개 시 |
| Ph2-11 | `argument-hint` / `arguments` frontmatter 재정비 | 6 명령 중 edit/show 재평가 필요 | v2 MVP 운영 2주 후 |
| Ph2-12 | 패턴 7 종 전부 preset 화 (Parallel/Pipeline/Swarm/R+I/Plan-Approval/Multi-File/RLM) | MVP 는 5 preset. 나머지는 reference 만 제공 | 사용 요청 발생 시 개별 추가 |

**Why 이 경계**: feedback 스킬의 MVP 범위(3 CLI 병렬 + validate + 종합) 수준을 유지. 가장 큰 실측 실패 모드 4건만 먼저 해결.

---

## 11. 최종 SKILL.md 초안 (실제 교체 가능한 수준)

아래 내용을 `~/.claude/skills/agent-team-manager/SKILL.md` 로 교체 (v1 은 `.v1.bak` 보존).

````markdown
---
name: agent-team-manager
description: Claude Code agent teams 를 프리셋·프로토콜·검증으로 운영하는 스킬. 설계/분석/리뷰/연구 팀 실행. Tiny edit·routine 에는 사용 금지.
when_to_use: |
  - "팀 실행해줘", "에이전트 팀", "agent team", "멀티 에이전트" 요청 시
  - 설계·분석·리뷰·리서치 같은 복잡 작업 (단일 세션 1시간 이상 예상)
  - 다관점 병렬 필요 시 (예: 보안 + 성능 + 정확성 리뷰)
argument-hint: "[run|create|list|show|delete] [preset|team-name]"
user-invocable: true
allowed-tools: Agent, TaskCreate, TaskUpdate, TaskGet, TaskList, SendMessage, Bash, Read, Write, Edit, Glob, Grep
---

# Agent Team Manager v2

Claude Code 의 experimental Agent Teams 기능을 **preset + 프로토콜 + 검증** 으로 운영.

## 중요 경고 (1회 명시)

- **런타임 실측 기반**: `TeamCreate`, `Agent(team_name=...)`, `TaskCreate`, `SendMessage` 는 공식 docs (`code.claude.com/docs/`) 에 parameter 스키마가 공개되지 않은 deferred tool 이다. Anthropic API 변경 시 본 스킬도 개정 필요. 자연어 fallback: "tell Claude to create a team with <description>".
- **teammate 제약** (공식): subagent 정의의 `skills`/`mcpServers` 는 teammate 에서 무시됨. tools/model 만 상속. teammate 는 nested team 생성 불가.
- **환경 요건**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, Claude Code v2.1.32+.

## Non-goals (이 스킬 쓰지 말 것)

- tiny edit (3줄 / 240자 이하)
- routine task (단순 조회·이동·1-file 수정)
- 재현 가능 테스트가 있는 single-file refactor
- teammate 가 자기 팀 생성 시도 (nested team 금지)
- 단일 관점만 필요한 리뷰 (oneshot 이 더 저렴)

## 명령어

### `/agent-team run <preset|teamName> [--timeout-minutes 30]`

팀 실행. 아래 Phase 0~8 순서 고정.

#### Phase 0. Pre-flight

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\preflight.ps1"
```

- JSON 반환: `{env_ok, version_ok, context_ok, tmux_ok, abort_reason?}`
- abort 시 `reference/errors.md` 의 해당 reason 안내

#### Phase 1. Preset 해석

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\resolve-preset.ps1" -Preset <name>
```

- JSON 반환: `{team_name, description, members[], tasks[], protocols, sentinel}`
- DAG 사이클 있으면 abort

#### Phase 2. TeamCreate (LLM tool 호출)

resolve-preset 의 `team_name`, `description` 으로 1회 호출.

#### Phase 3. TaskCreate + blockedBy 체인 (LLM)

tasks[] 순회. 각 task 를 TaskCreate 후 `blocked_by` 가 있으면 TaskUpdate addBlockedBy.

#### Phase 4. Agent spawn (LLM)

members[] 순회. 각 member 를 `Agent` tool 로 spawn.
- `name` = member.name (UUID 금지, 예측 가능해야)
- `subagent_type` = member.subagent_type (기본 general-purpose)
- `prompt` = member.prompt_file 내용 + 공통 프로토콜 문구 (아래)

**공통 프로토콜 문구** (모든 teammate 주입):
1. 배정된 taskId 클레임 → TaskUpdate status=in_progress, owner=<your-name>
2. `protocols.activeForm_update_minutes` 경과 시 TaskUpdate activeForm 갱신
3. 완료 시 output_path 에 산출물 저장 → TaskUpdate completed → lead SendMessage
4. lead 메시지의 `[INSTRUCTION]`/`[STATUS-REQUEST]`/`[CORRECTION]` prefix 식별 후 반응
5. skills/mcpServers 가정 금지. project/user settings 의존만 사용
6. nested team 금지 — TeamCreate 호출 불가

#### Phase 5. Sentinel 등록

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\run-team.ps1" -SentinelInit -Team <name> -TimeoutMinutes 30
```

- `~/.claude/tasks/<team>/.sentinel.json` 에 deadline 기록

#### Phase 6. Monitor (선택, 필요 시)

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\monitor-team.ps1" -Team <name>
```

- 사람이 읽는 상태표 + JSON 이슈 목록

#### Phase 7. Validate + Synthesize

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\validate-team.ps1" -Team <name>
```

- `valid_count = total` 이면 종합 보고서 작성
- 이슈 있으면 `reference/errors.md` 참조 후 개입

#### Phase 8. Shutdown

```powershell
& "$HOME\.claude\skills\agent-team-manager\scripts\shutdown-team.ps1" -Team <name>
```

- 주인님 승인 후에만 team dir 삭제

### `/agent-team create <name>`

preset 기반 파생. 대화형 질문 최소화.

1. `resolve-preset.ps1 -List` 로 선택지 제시
2. 선택한 preset 을 `.claude/teams/<name>/team.yaml` 로 복사
3. LLM 이 사용자와 필드 수정 대화
4. `resolve-preset.ps1 -ValidateOnly -Path <file>` 로 스키마 검증

### `/agent-team list`

`.claude/teams/*/team.yaml` + `~/.claude/skills/agent-team-manager/presets/*.yaml` 을 나열.
각 팀에 `validate-team.ps1` 결과(OK/STALE/ORPHAN/ACTIVE) 병기.

### `/agent-team show <name>`

team.yaml 을 읽어 표로 출력 (members, tasks, protocols).

### `/agent-team delete <name>`

확인 후 `.claude/teams/<name>/` + `~/.claude/teams/<name>/` + `~/.claude/tasks/<name>/` 동시 정리.
shutdown-team.ps1 을 먼저 호출.

## 패턴 선택 가이드

preset 이 없고 즉흥 설계 필요하면 `reference/patterns.md` 참조. 7 패턴:
Parallel Specialists / Pipeline / Swarm / Research+Implementation / Plan-Approval / Multi-File Refactoring / RLM.

## 안티패턴

`reference/anti-patterns.md` — A1~A15 실패 모드 + Fix. Troubleshooting 시 로드.

## 에러 참조

`reference/errors.md` — preflight/validate 실패 reason 코드 해설.

## Preset 카탈로그

`reference/presets.md` — review / debug / research / docs-research / harness-design 5종 요약.

## 스크립트 파일

- `scripts/preflight.ps1`
- `scripts/resolve-preset.ps1`
- `scripts/run-team.ps1`
- `scripts/monitor-team.ps1`
- `scripts/validate-team.ps1`
- `scripts/shutdown-team.ps1`

## Phase 2 후보 (MVP 제외)

`04_redesign-spec.md` §10 참조.
````

**Why SKILL.md 이 구조**:
- 500줄 이내 준수 (실측 약 180줄)
- 경고·Non-goals 를 본문 상단에 배치 → 모델 invoke 시 즉시 인지
- Phase 0~8 순서 고정 → "프로즈 활용한다" → "호출 명세" 로 전환
- 긴 내용(패턴 표·안티패턴·에러)은 reference/ 로 분리 (depth-1 룰)
- frontmatter `allowed-tools` 정정 (S8 해결 — Task*, SendMessage 포함)
- `description` 에 "Tiny edit·routine 에는 사용 금지" 1줄로 U1 대응 (frontmatter 항상 로드)

---

## 12. 반영 검증 체크리스트 (P0 11건 + 실측 4건)

| 항목 | 반영 위치 |
|------|----------|
| S5 scripts/ 외부화 | §1 디렉토리 구조, §2 책임 매트릭스, §11 SKILL.md 참조 |
| S8 allowed-tools 정정 | §11 SKILL.md frontmatter |
| P1 env 체크 | §3 Phase 0, §11 preflight.ps1 |
| P3 subagent 컨텍스트 체크 | §3 Phase 0, §11 preflight.ps1, §5 공통 프로토콜 #6 |
| O1 4-step 프로토콜 강제 | §5 전체, §11 SKILL.md Phase 2-4 |
| O5 nested team 금지 | §5 공통 프로토콜 #6, §11 SKILL.md Non-goals |
| R1 진행 상황 가시성 | §4.1 YAML `protocols.activeForm_update_minutes`, §3 Phase 6, §5 공통 프로토콜 #2 |
| R2 타임아웃 | §3 Phase 5 sentinel, §11 SKILL.md `--timeout-minutes`, §6 validate `sentinel` |
| R3 중복 알림 구분 | §4.1 `protocols.instruction_prefix`, §5 Step 4 prefix 규약, §5 공통 프로토콜 #4 |
| R4 핸드오프 자동화 | §4.1 `depends_on`/`blocked_by`, §3 Phase 3 체인 템플릿 |
| U1 "쓰지 말 것" | §9.1 옵션 C, §11 SKILL.md Non-goals, frontmatter description |
| U3 run Phase 체계 | §3.1 Phase 0~8, §11 SKILL.md |
| TeamCreate 공식 문서 부재 경고 | §5 서두, §11 SKILL.md 중요 경고 |
| 실측 #1 가시성 | R1 반영 동일 |
| 실측 #2 타임아웃 | R2 반영 동일 |
| 실측 #3 중복 알림 | R3 반영 동일 |
| 실측 #4 핸드오프 | R4 반영 동일 |

---

**작성자**: architect (agent-team-skill-redev team)
**다음**: team-lead 에게 보고 → 주인님 §9 의사결정 → 별건 구현 태스크 기안
