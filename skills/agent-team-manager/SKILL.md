---
name: agent-team
description: 에이전트 팀 구성·실행·관리 (마스터플랜 부트스트랩 단계용 중간 가이드). 새 팀을 만들거나 기존 팀을 실행할 때 사용. "팀 만들어줘", "에이전트 팀 실행", "팀 목록" 등의 요청에 반응.
trigger: /agent-team
argument-hint: "[create|run|list|show|edit|delete] [팀이름] [추가 인자...]"
user-invocable: true
allowed-tools: Agent, Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch
---

# Agent Team Manager (부트스트랩 단계 가이드)

## 0. 본 스킬의 위치

> **최종 목표**: `/agent-office` (Phase 1·2 후 신설). 5층 위계 + 4가지 워커 + PM(부장) 비판자 + 동적 선택 + ⑤ /feedback 검수의 통합 진입점.
> **본 스킬**: 그 사이 부트스트랩 단계용 **중간 가이드**. PM 인프라 (`pm.yaml`·α 옵션 system prompt·자동 hooks) 미구축 상태에서 사장(메인 Claude) 이 직접 4가지 워커를 운영.
> **마스터플랜 SSOT**: `docs/research/agent-office-masterplan/04_masterplan.md` (814줄, 본 turn Phase F 까지 안정화)
> **비전 SSOT**: `docs/research/agent-office-masterplan/agent-office-vision.md` (D-1~D-5 / R-1~R-5)

**본 스킬 호출 시 사장(메인 Claude) 의 의무**:
1. 작업 분석 → §2 heuristic 표로 4가지 워커 중 1~N개 선택
2. §1 표준 4-step 으로 spawn
3. §3 모델 배분 강제 (워커 = Sonnet)
4. §4 작업 완료 후 `/feedback` 검수 의무
5. §5 가드레일 R-1~R-5 모두 인지

---

## 1. 표준 4-step (Agent Preferences 정합)

> 글로벌 `~/.claude/CLAUDE.md` "Agent Preferences" 의 4-step 시퀀스를 본 스킬에서 강제. 단독 Agent 호출 / 즉석 spawn 금지.

```
1) TeamCreate            → 팀 생성 (글로벌 ~/.claude/teams/<팀이름>/ 자동 생성)
2) TaskCreate            → 태스크 정의 (필요 시 addBlockedBy 로 의존성 체인)
3) Agent (team_name=)    → teammate spawn (model: sonnet 강제 — §3 참조)
4) SendMessage           → teammate 와 소통 / 결과 수신
```

**각 step 의 Why**:
- (1) **TeamCreate** — Agent Teams 메타 (`~/.claude/teams/<팀>/config.json` + `inboxes/`) 신설. 단독 Agent 호출은 금지 (글로벌 CLAUDE.md `⚠️ 금지` 항목)
- (2) **TaskCreate** — 작업 단위 정의 + 의존성. ④ 파이프라인 패턴 사용 시 `addBlockedBy` 로 순차 강제
- (3) **Agent (team_name=)** — `subagent_type` 으로 역할 결정, **`model: sonnet`** frontmatter 또는 env 로 모델 강제 (§3)
- (4) **SendMessage** — teammate 와 양방향 토론 (회의실) 또는 단방향 입력 (인턴/파이프라인)

**저장 경로 (실제 도구 동작)**:
- 팀 메타: `~/.claude/teams/<팀이름>/` (글로벌, **프로젝트 로컬 아님** — v1 명세 버그 정정)
- 작업 메타: `~/.claude/tasks/<팀이름>/`
- 종료 후 정리: `validate-team.ps1` 또는 수동 archive (마스터플랜 §9.3 폴백 참조)

---

## 2. 4가지 워커 동적 선택 (PM 없이 사장이 직접)

> **R-4 가드**: 항상 **4가지** 워커. 3가지로 줄이지 말 것 (특히 ④ 파이프라인 누락 금지). 본 turn (5-1 후속4) 직접 누락 사례 있었음.
> **부트스트랩 단계 한정**: PM 미구현이라 사장이 직접 선택. Phase 1 후 `/agent-office` 신설 시 PM 이 추천 + 사장이 spawn 대행 구조로 전환.

### 2.1 heuristic 표 (마스터플랜 §3 인용 — 8행)

| 작업 복잡도 | 예상 tool call 수 | 추천 워커 | 병렬 여부 | 비용 수준 |
|-----------|-----------------|---------|---------|--------|
| 단순 조회/탐색/Read-only | 3~10 | **① 인턴 Sub-agent** | 단독 | 최저 |
| 2~4개 비교·분석 | 10~15 each | **② 소규모 회의실 (2~3명)** | 병렬 가능 | 저~중 |
| 복잡 협업 (5+ 파일, 다관점) | 20+ | **② 대규모 회의실 (3~5명)** | 병렬 권장 | 중 |
| 외부 검증/다른 모델 시각 | — | **③ 외부 CLI** | 병렬 (orchestrate.ps1) | 저 (외부 비용) |
| 단계 의존성 순차 작업 | 각 단계 별도 | **④ 파이프라인 Pipeline** | 순차 강제 | 중~고 |
| 반복 수행 / 컨텍스트 초과 분석 | 무제한 | **④ RLM** | 청크 병렬 | 고 |
| 아키텍처 설계 / 고위험 변경 | — | **④ Plan-Approval** | 승인 게이트 | 중 |
| 단순 버그픽스 / 3줄 이하 편집 | 1~3 | **직접 (4-step 생략)** | N/A | 최저 |

**보수적 default**: 작업 분류 모호 시 → ① 인턴 단독 + 결과 보고 후 재판단.

### 2.2 4가지 워커 메커니즘

- **① 인턴 (Sub-agent)** — `Agent` tool 직접 호출, `subagent_type: Explore | general-purpose`, **단발**·격리 컨텍스트, OneDrive 이슈#35513 회피용 `isolation: worktree` frontmatter 권장
- **② 회의실 (Agent Teams 멀티)** — TeamCreate + 다수 spawn + SendMessage 양방향 토론, **persistent**, 다관점 병렬 / 양방향 토론에 적합
- **③ 외부 CLI** — `/feedback` 스킬 통해 Codex / Gemini / Claude Sub 병렬 호출. **다른 모델 시각** 이 핵심 — Echo chamber 회피 (R-2 보호막)
- **④ 파이프라인 (zircote 7패턴)** — TaskCreate + `addBlockedBy` 체인. Pipeline / Parallel Specialists / Swarm / Research+Implementation / Plan-Approval / Multi-File Refactoring / RLM 7가지

### 2.3 잘못 선택 시 비용 (마스터플랜 §3.2)

| 잘못된 선택 | 올바른 선택 | 토큰 비용 배수 |
|-----------|-----------|------------|
| 단순 조회에 ② 회의실 3명 | ① 인턴 1회 | ~15× (Anthropic) |
| 단순 조회에 ④ Pipeline 5단계 | ① 인턴 1회 | ~50× (v0 추산) |
| 복잡 협업에 ① 인턴 단독 | ② 회의실 | 1× 비용이나 품질 저하 |
| 외부 검증에 ② 회의실 | ③ 외부 CLI | 5~10× 절감 |

---

## 3. 모델 배분 (D-4 강제)

> **R-3 가드**: 3개 출처 일치 (Anthropic +90.2% / wshobson / aws-samples). 워커는 Sonnet 충분, Opus 는 lead·검증·종합에만.

| 역할 | 모델 | 강제 메커니즘 |
|------|------|--------------|
| 메인 Claude (사장) | **Opus** | 본 세션 자체 |
| 워커 ①②④ | **Sonnet** | env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` + frontmatter `model: sonnet` 이중 보장 |
| ③ 외부 CLI / ⑤ /feedback 검증 | 외부 (Codex / Gemini / Claude Sub) | `/feedback` 스킬 내장 |
| ⑤ /feedback 결과 해석 (메인) | **Opus** | 본 세션 자체 |

### 3.1 issue#32732 미해결 경고

> **Phase 1 진입 차단 조건 (`.todo.md` #011)**: Opus main session 이 Agent 호출 시 model 파라미터를 자동 추가 → frontmatter 를 덮어쓸 수 있음. env vs frontmatter 우선순위가 공식 문서로 확정되지 않은 상태. **PM 이 의도와 달리 Sonnet 으로 실행될 위험** (PM 구현 시).
>
> 본 부트스트랩 단계는 PM 없이 사장이 직접 워커 spawn 하므로, 워커 = Sonnet 만 보장하면 됨. 그러나 ② 회의실 lead-teammate 가 추가 teammate 를 spawn 할 때 같은 위험 발생 가능 → spawn 시 frontmatter `model: sonnet` 명시 + env 동시 설정 권장.

---

## 4. ⑤ /feedback 검수 (작업 완료 후 의무)

> **D-2 / R-2 보호막**: 워커 산출물은 **무조건** 외부 검수. 사장이 같은 Claude 계열로 검수하면 Echo chamber 미해소.

### 4.1 호출 시점
- 워커 1명 이상의 작업 산출물이 생성된 직후 (커밋 전)
- 설계 결정 / 마스터플랜 / 큰 문서 변경 시
- 본 turn Phase E 사례 — `04_masterplan.md` 검수 → 15건 지적 → 11건 반영

### 4.2 호출 방법

```
/feedback <대상 파일 절대경로>
```

또는 직접:

```powershell
& "$HOME\.claude\skills\feedback\scripts\orchestrate.ps1" -SourceFile "<경로>" -TimeoutSeconds 600
```

### 4.3 5게이트 + 외부 훅
- **게이트 1** 라인 실측 (환각 차단)
- **게이트 2** 반박/유보 최소 1건 (sycophancy 방지)
- **게이트 3** 근거 강도 표시 (강/중/약, 약 ≥ 50% 시 ⚠️)
- **게이트 4** 통계 표 강제
- **게이트 5** 자기 비판 한 줄
- **게이트 6** 외부 훅 자동 검수 (`feedback-sycophancy-check.sh` PostToolUse, 7 카테고리)

상세: `~/.claude/skills/feedback/SKILL.md`

---

## 5. 가드레일 (R-1~R-5)

마스터플랜 §6 R-1~R-5 가드 운영:

| 가드 | 본 스킬에서의 적용 |
|------|-----------------|
| **R-1** 영속화 우려 | yaml + 외부 자산으로 해소. 본 부트스트랩 단계는 `~/.claude/teams/<팀>/config.json` + 산출물 파일이 외부 자산 |
| **R-2** PM 별도 두기 | 본 부트스트랩은 사장 겸직 (예외). Phase 1 후 정식 PM 전환. **사장이 같은 Claude 계열이라 자기 확증 편향 위험** → §4 /feedback 검수가 유일한 보호막 |
| **R-3** Sonnet 워커 강제 | §3 모델 배분 적용 |
| **R-4** 4가지 워커 명시 | §2 항상 ①②③④ 4가지 — 3가지로 줄이지 말 것 |
| **R-5** 오너 컨펌 | 합의안 / 큰 결정은 주인님 컨펌 필수. 사장이 멋대로 진행 금지 |

### 5.1 운영 가드레일 (마스터플랜 §9 인용)

| 가드레일 | 내용 |
|---------|------|
| 한 세션 1 team | PM 팀 cleanup 후 워커 팀 생성 (현재는 PM 없음 — 워커 팀만) |
| nested team 불가 | teammate 는 `Agent`/`TeamCreate` 도구 없음 (issue#32731). 추가 spawn 필요 시 lead 가 대행 |
| Ralph 자율 루프 제한 | `max_iterations: 5` + Plan-Approval gate 필수 (D-5 보호) |
| 고아 팀 청소 | `~/.claude/teams/.archived/` 로 archive 또는 `validate-team.ps1` (Phase 1 후) |
| PM 팀 cleanup 실패 폴백 | 60초 timeout → 강제 archive (마스터플랜 §9.3) |
| spawn 범위 제한 | spawn prompt 에 "이 경로 외 탐색 금지" 명시 (issue#35513) |

### 5.2 Windows / OneDrive 주의

- 한글 경로 + Codex: `~/codex-cwd/<슬러그>/` 영문 workdir 표준 (글로벌 CLAUDE.md 정책)
- Agent Teams 메타 (`~/.claude/teams/`, `~/.claude/tasks/`) 는 영문 경로 = 안전
- in-process 모드 사용 (psmux split-pane = issue#42848 미해결)

---

## 6. 명령어

> v1 의 6개 명령어 보존. 단 모든 명령은 §1 4-step + §3 모델 배분 + §4 /feedback 검수를 강제.

### `/agent-team create [팀이름]`
새 에이전트 팀 구성. 사용자에게 목적·팀원 역할·지시사항을 묻고 §2 heuristic 표 기반으로 추천.

**저장 위치**: 팀 메타는 `TeamCreate` 가 자동으로 `~/.claude/teams/<팀이름>/` 에 생성. 사용자가 별도로 `<프로젝트>/.claude/teams/` 에 저장하는 것 **아님** (v1 명세 버그 정정).

선택적 산출물 (사용자가 원할 때만):
- `<프로젝트>/docs/research/<주제>/team_brief.md` — 팀 목적·팀원 역할·실행 흐름 메모

### `/agent-team run [팀이름] [인자...]`
저장된 팀 정의 (있다면) 또는 즉석 spawn 으로 §1 4-step 실행. 결과 종합 후 §4 /feedback 검수 호출.

### `/agent-team list`
`~/.claude/teams/` 디렉토리 스캔 → 활성 팀 목록 표시. archive 디렉토리 (`~/.claude/teams/.archived/`) 도 별도 표시.

### `/agent-team show [팀이름]`
`~/.claude/teams/<팀이름>/config.json` Read + members 표시.

### `/agent-team edit [팀이름]`
config.json 또는 사용자 메모 (`docs/research/.../team_brief.md`) 편집.

### `/agent-team delete [팀이름]`
**삭제 전 사용자 컨펌 필수** (R-5). `TeamDelete` 또는 `~/.claude/teams/.archived/` 로 archive.

---

## 7. 한계 (Phase 1 후 가능)

본 부트스트랩 단계에서는 다음을 제공하지 않음. `/agent-office` 신설 시 가능:

| 미구현 | 이유 | 진입 조건 |
|--------|------|---------|
| **PM 비판자 (3층 부장)** | pm.yaml 미작성 / α 옵션 system prompt 미정의 | `.todo.md` #011 issue#32732 실험 + Phase 1 진입 |
| **PM 동적 선택 자동화** | PM 부재 → 사장이 §2 표 보고 직접 선택 중 | Phase 1 |
| **preset YAML (5종)** | review / debug / research / docs-research / harness-design | Phase 1 (v2 스펙 §1 흡수) |
| **자동 검증 hooks** | PostToolUse 자동 sycophancy 외 추가 검사 | Phase 1 |
| **validate-team.ps1 / shutdown-team.ps1** | 고아 정리 자동화 (마스터플랜 §9.1 가드레일 출처) | Phase 1 (v2 스펙 §1 위치 확정) |
| **bypass_threshold 자동 적용** | 작업 복잡도 자동 분석 → 워커 자동 선택 | Phase 2 dogfood 후 |
| **Linux 서버 배포** | bash 버전 병행 | Phase 3 |

---

## 8. 마이그레이션 안내 (`/agent-office` 신설 시)

본 스킬은 `/agent-office` 신설 시 자연스럽게 흡수. 사용자 입장에서는:

```
[현재 부트스트랩]                    [Phase 1 후]
/agent-team create  → 팀 구성   →  /agent-office "이 작업 분석해줘"
                                     ↓
                                   PM 1인 팀 spawn
                                   사장 ↔ PM 토론
                                   PM 추천 → 사장 spawn 대행
                                   ⑤ /feedback 검수
                                   주인님 보고
```

**호환성**:
- 본 스킬로 만든 팀 메타 (`~/.claude/teams/<팀>/`) 는 `/agent-office` 도 그대로 읽음
- 자연어 트리거 ("팀 만들어줘") 는 Phase 1 후 `/agent-office` 가 우선 트리거 (본 스킬은 fallback)

상세 마이그레이션: 마스터플랜 `05_migration_plan.md` Phase 0~3.

---

## 변경 이력

- **2026-05-02 (v1.5, 본 turn)**: 마스터플랜 정합 재작성. v1 의 6가지 문제 해소 (저장 경로 / PM / 모델 배분 / 4가지 워커 / lifecycle / /feedback). 부트스트랩 가이드로 위치 확정. SHA256 (이전 v1) = `454F27ED...A8F5`.
- **2026-04-21 (v1)**: `/feedback` 스킬 구조 승격 패턴 모방, 단순 팀 관리 명령어 6개. → 마스터플랜 비전과 미정합.
