---
name: agent-team
description: 에이전트 팀 구성·실행·관리 (Phase 1 본격 운영 — PM·preset·hooks 全 구현 완료, ② 회의실 5 preset 즉시 호출 가능). 새 팀을 만들거나 기존 팀을 실행할 때 사용. "팀 만들어줘", "에이전트 팀 실행", "팀 목록", "리뷰 팀 돌려줘" 등의 요청에 반응.
trigger: /agent-team
argument-hint: "[create|run|list|show|edit|delete] [팀이름|--preset 이름] [추가 인자...]"
user-invocable: true
allowed-tools: Agent, TeamCreate, TaskCreate, SendMessage, TeamDelete, Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch
---

# Agent Team Manager (Phase 1 정식 운영)

## 0. 본 스킬의 위치

> **현 단계 (Phase 1)**: 정식 PM (`agents/pm.md`, Opus, turn 11 신설) + ② 회의실 5 preset (`presets/*.yaml`, Day 20 turn 1 신설) + 글로벌 강제 훅 (`hooks/pretooluse-agent-model-required.{sh,py}`, turn 7 신설, fallback C+ 영구 적용 turn 8 #019 PASS) **全 구현 완료**.
> **다음 단계 (Phase 2)**: `/agent-office` 통합 진입점 — 본 스킬 + 자동 분류 + UI 통합 + `validate-team.ps1`/`shutdown-team.ps1` 자동화. 본 스킬은 `/agent-office` 신설 후에도 그대로 호환.
> **마스터플랜 SSOT**: `docs/research/agent-office-masterplan/04_masterplan.md` (814줄+)
> **비전 SSOT**: `docs/research/agent-office-masterplan/agent-office-vision.md` (D-1~D-18 / R-1~R-12)

**본 스킬 호출 시 사장(메인 Claude) 의 의무**:
1. 작업 분석 → §2 heuristic 표로 4가지 워커 中 1~N개 선택, ② 회의실 시 §2.4 preset 카탈로그 (5종) 우선 매핑
2. §1 표준 4-step 으로 spawn — **글로벌 강제 훅 활성** (`Task|Agent` matcher, `model` 누락 시 차단, turn 7·8 라이브 검증 PASS)
3. §3 모델 배분 강제 (워커 = Sonnet, 강제 훅 + frontmatter + 명시 model 3중 보장)
4. PM 협의 가능 시 `agents/pm.md` (Opus) spawn → preset 추천 받음 → 사장이 spawn 대행 (R-2 보호막)
5. §4 작업 완료 후 `/feedback` 검수 의무
6. §5 가드레일 R-1~R-15 인지 (R-9 일반화 한계 + R-10 양식 일관 + R-11 team_size·members 정합 + R-12 dimension preset 컨텍스트 + R-13 §변경 이력 다중 entry + R-14 orphan 정리 + R-15 ps1 BOM 의무)

---

## 1. 표준 4-step (Agent Preferences 정합 + 강제 훅 활성)

> 글로벌 `~/.claude/CLAUDE.md` "Agent Preferences" 의 4-step 시퀀스를 본 스킬에서 강제. 단독 Agent 호출 / 즉석 spawn 금지. **글로벌 강제 훅 활성** = 4-step 우회 불가 (turn 7 #018 PASS + turn 8 #019 PASS).

```
1) TeamCreate            → 팀 생성 (글로벌 ~/.claude/teams/<팀이름>/ 자동 생성)
2) TaskCreate            → 태스크 정의 (필요 시 addBlockedBy 로 의존성 체인 — Pipeline)
3) Agent (team_name=)    → teammate spawn (model 명시 의무 — 강제 훅 차단, §3 참조)
4) SendMessage           → teammate 와 소통 / 결과 수신
```

**각 step 의 Why**:
- (1) **TeamCreate** — Agent Teams 메타 (`~/.claude/teams/<팀>/config.json` + `inboxes/`) 신설. 단독 Agent 호출은 금지 (글로벌 CLAUDE.md `⚠️ 금지` 항목)
- (2) **TaskCreate** — 작업 단위 정의 + 의존성. ④ 파이프라인 패턴 사용 시 `addBlockedBy` 로 순차 강제. preset YAML (§2.4) 의 `members[].blocked_by` 가 그대로 mapping
- (3) **Agent (team_name=)** — `subagent_type` 으로 역할 결정, **`model` 파라미터 명시 의무** (강제 훅 차단). PM=`opus` / 워커=`sonnet` / haiku 0건 (메모리 `feedback_no_haiku.md` 정합)
- (4) **SendMessage** — teammate 와 양방향 토론 (회의실) 또는 단방향 입력 (인턴/파이프라인). lead 미수신 방지 = 회신 의무 (turn 6 §6-1 교훈, turn 8 R-8 PASS)

### 1.1 글로벌 강제 훅 (PreToolUse `Task|Agent` matcher)

> 본 스킬을 통하지 않는 spawn 도 강제. 메인 Claude 의 모든 Agent 호출에 적용.

- 위치: `hooks/pretooluse-agent-model-required.{sh,py}` (스테이징↔운영 SHA256 MATCH `8559463C...3029` + `E4B0B37D...BEE4`, turn 7 #018 신설)
- 차단 조건: `tool_input.model` 부재 + `subagent_type` frontmatter 예외 (§3 의 pm/architect 등 frontmatter `model:` 명시 agent 만 면제)
- 차단 메커니즘: `permissionDecision: deny` JSON + exit 0 우회 ([Issue #26923](https://github.com/anthropics/claude-code/issues/26923) reporter 미검증 가설 = turn 7 세계 1호 검증 PASS)
- 라이브 검증 PASS: turn 7·8 4 spawn (A=opus / B=sonnet / C=차단 / D=haiku) 결정적 정합
- 출처: `06_issue32732_experiment.md §11~§12` + `04_masterplan.md §8.2 4·5차 실험 박스` + `~/.claude/rules/agent-spawn-model.md`

**저장 경로 (실제 도구 동작)**:
- 팀 메타: `~/.claude/teams/<팀이름>/` (글로벌, **프로젝트 로컬 아님** — v1 명세 버그 정정)
- 작업 메타: `~/.claude/tasks/<팀이름>/`
- sentinel: `~/.claude/tasks/<팀이름>/.sentinel.json` (deadline + members + cycle_count, `scripts/run-team.ps1 -SentinelInit` 자동 신설)
- 종료 후 정리: `scripts/shutdown-team.ps1 -Team <name>` (R-5 정합 archive 기본, `-Force` 즉시 삭제)

### 1.2 Phase 0~8 자동화 흐름 (scripts/ 6 헬퍼 호출)

> v2 spec `04_redesign-spec.md §3.1` 양식 차용 (본 비전 양식 SSOT 정합, D-23). LLM (메인 Claude) 가 본 흐름 따라 호출.

| Phase | 주체 | 동작 |
|-------|------|------|
| **0: Pre-flight** | LLM → `scripts/preflight.ps1 -SkipTmux` | 5 검사 (env 부재 + claude-code 버전 + 메인 컨텍스트 + PS 5.1+ + pyyaml). 실패 시 abort + `reference/errors.md` 의 reason 안내 |
| **1: Preset 해석** | LLM → `scripts/resolve-preset.ps1 -Preset <name>` | preset YAML → JSON 메타 (team_name_template + members + task_graph + protocol_steps + cap) |
| **2: TeamCreate** | **LLM** (tool 직접) | resolve-preset 의 team_name_template 으로 호출. **스크립트는 tool 호출 안 함** (v2 spec §2 경계선) |
| **3: TaskCreate + blockedBy** | **LLM** (tool 직접) | task_graph 순회, 각 task 를 TaskCreate + addBlockedBy = preset YAML `members[].blocked_by` 그대로 mapping |
| **4: Agent spawn** | **LLM** (tool 직접) | members 순회, `Agent({subagent_type: <name>, model: <model>, team_name: ...})`. 글로벌 강제 훅 통과 의무 (§1.1) |
| **5: Sentinel 등록** | LLM → `scripts/run-team.ps1 -Team <name> -SentinelInit -TimeoutMinutes 30 -Members ...` | `.sentinel.json` 신설 (start_time + deadline + members + cycle_count) |
| **6: Monitor loop** (선택) | LLM → `scripts/monitor-team.ps1 -Team <name>` 주기 | active/stale/zombie/orphan 상태 덤프. zombie/orphan 시 개입 |
| **7: Validate + Synthesize** | LLM → `scripts/validate-team.ps1 -Team <name>` → LLM 종합 | 5 검증 (orphan/deadline/cycle_cap/duplicate/zombie). valid 항목만 종합 보고서 작성 + `/feedback` 검수 (§4) |
| **8: Shutdown** | LLM → `scripts/shutdown-team.ps1 -Team <name>` | archive 기본 (R-5 정합). 사용자 컨펌 후 `-Force` 즉시 삭제 |

**핵심 제약**:
- Phase 2·3·4 = LLM 만 가능 (TeamCreate/TaskCreate/Agent spawn/SendMessage 는 Claude Code tool, 스크립트가 호출 못 함)
- 스크립트는 파일·프로세스·검증만 담당 (feedback 차용 경계선)
- 트러블슈팅: `reference/errors.md` (reason 코드별 해결법) + `reference/anti-patterns.md` (A1~A15 실패 모드)

---

## 2. 4가지 워커 동적 선택 (PM 추천 + 사장 spawn 대행)

> **R-4 가드**: 항상 **4가지** 워커. 3가지로 줄이지 말 것 (특히 ④ 파이프라인 누락 금지).
> **현 단계 (Phase 1)**: PM (`agents/pm.md`, Opus) 가 추천 + 사장이 spawn 대행. PM 협의 생략 시 사장이 §2 표 보고 직접 선택 (단순 작업 한정, R-2 보호막 약화).

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

### 2.4 ② 회의실 preset 카탈로그 (5종, Phase 1 정식)

> **1차 참조**: `reference/presets.md` (preset 요약 + 트리거 키워드 + 호출 흐름). LLM 이 본 §2.4 표 + reference 후 `presets/<name>.yaml` Read.
> Step B (Day 20 turn 1) 산출물 = `presets/*.yaml` 5건. Step A (turn 11) 의 정식 직책별 agent 12명 호출 박음. 마스터플랜 §2.4 ② 회의실 preset 표 1:1 정합 5/5 PASS (feature·security 2/7 보류 = 별도 turn #009-E).

| Preset | YAML | team_size | members (Step A 12 agent) | 단계 의존성 | 적합 작업 |
|--------|------|----------|--------------------------|------------|---------|
| **review** | `presets/review.yaml` | 3 | security-reviewer · performance-reviewer · correctness-reviewer | 병렬 | 코드 리뷰 (보안/성능/정확성 3차원) |
| **debug** | `presets/debug.yaml` | 3 | hypothesis-investigator → reproducer → solver | Pipeline | 버그 헌팅 (가설→재현→해결) |
| **research** | `presets/research.yaml` | 3 | docs-researcher ‖ community-researcher → analyst | Parallel + 종합 | 기술 조사 (공식docs/커뮤니티 → 종합) |
| **docs-research** | `presets/docs-research.yaml` | 4 | research 3 + architect ADR | 4단계 Pipeline | 하네스 리서치 (조사 → 종합 → ADR) |
| **harness-design** | `presets/harness-design.yaml` | 3 | docs-researcher → architect → auditor | Pipeline | 규칙·스킬 설계 (D-15 researcher 통합) |

**호출 방식**:

```
1. PM 협의 (선택, Opus)
   /agent-team run --pm-consult <작업 설명>
   → agents/pm.md spawn (model: opus)
   → PM 이 §2 heuristic + §2.4 preset 매핑 추천
   → 사용자 컨펌 (R-5)

2. preset 직접 호출
   /agent-team run --preset <이름> [추가 인자]
   → presets/<이름>.yaml Read
   → TeamCreate + members[].name 으로 spawn (model 명시 의무)
   → 단계 의존성 = blocked_by 그대로 mapping
   → SendMessage 로 단계 결과 전달
```

**preset 양식 출처**:
- 외부: [wshobson/agents](https://github.com/wshobson/agents) HEAD `ece811f23310a37ceb43496dbac0e244fe6845b6` (2026-05-02) `plugins/agent-teams/skills/team-composition-patterns/references/preset-teams.md`
- 본 비전 확장 4 항목: `pm_lead` · `protocol` (4-step) · `review_cycle_cap: 3` · `output_format_required` (4 요소: 결론·출처·추측 금지·자기비판)
- 출처 인용 cap 3: [aws-samples/sample-claude-code-agent-team](https://github.com/aws-samples/sample-claude-code-agent-team) HEAD `67840be315fad3ef252c06ccfe35d6ab9a2d43d6` `skills/spec-workflow/SKILL.md:65` "Max 3 review cycles per group, then escalate"

**보류 2 preset (별도 turn)**: feature (4명) · security (3명) — 마스터플랜 §2.4 표 中 5/7 PASS, 2/7 보류.

### 2.5 preset 자동 매핑 heuristic

| 사용자 요청 키워드 | 매핑 preset | 비고 |
|-----------------|-----------|------|
| "코드 리뷰" / "review" / "PR 검토" | review | full_review (3명) 또는 security_focused (2명) variations 선택 |
| "버그" / "debug" / "디버그" / "재현" | debug | hypotheses_n variations 시 가설 갯수 변동 |
| "조사" / "리서치" / "research" | research | 커뮤니티 자료 부족 시 docs_only variations |
| "하네스 리서치" / "ADR" / "설계 결정" | docs-research | ADR 단계 생략 시 research_only |
| "스킬 설계" / "훅 설계" / "규칙 설계" | harness-design | auditor 단계 분리 시 design_only |
| 매핑 모호 / 다관점 필요 | PM 협의 (`agents/pm.md`) | R-2 보호막 강화 |

---

## 3. 모델 배분 (D-4 강제, fallback C+ 영구 적용)

> **R-3 가드**: 3개 출처 일치 (Anthropic +90.2% / wshobson / aws-samples). 워커는 Sonnet 충분, Opus 는 lead·검증·종합에만. **Haiku 0건** (메모리 `feedback_no_haiku.md`).

| 역할 | 모델 | 강제 메커니즘 (3중 보장) |
|------|------|-----------------------|
| 메인 Claude (사장) | **Opus** | 본 세션 자체 |
| PM (3층 부장) | **Opus** | `agents/pm.md` frontmatter `model: opus` (turn 11 신설) |
| architect (docs-research·harness-design preset) | **Opus** | `agents/architect.md` frontmatter `model: opus` |
| 워커 ①②④ (나머지 9 슬롯) | **Sonnet** | (a) `agents/*.md` frontmatter `model: sonnet` (b) Agent spawn `model="sonnet"` 명시 (c) **글로벌 강제 훅** (PreToolUse `Task|Agent` matcher, §1.1) |
| ③ 외부 CLI / ⑤ /feedback 검증 | 외부 (Codex / Gemini / Claude Sub) | `/feedback` 스킬 내장 |
| ⑤ /feedback 결과 해석 (메인) | **Opus** | 본 세션 자체 |

### 3.1 fallback C+ 영구 적용 (issue#32732 종결)

> **issue#32732 종결** (turn 8 #019 PASS, 2026-05-04). env vs frontmatter vs 명시 model 우선순위 = "env 가 1순위, 명시 model 은 env unset 시 작동" 결정적 재현 → **fallback C+ 영구 적용** (메커니즘 3중 全 만족).

**3중 메커니즘**:
1. **env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거** — turn 7 commit (`hooks` 섹션과 분리, settings.json env 제거)
2. **메인 Claude Code 재시작** — 메인 프로세스 cache 갱신 의무 (turn 8 PowerShell `Get-ChildItem Env:CLAUDE_CODE_SUBAGENT_MODEL` 부재 라이브 검증)
3. **글로벌 강제 훅** (`hooks/pretooluse-agent-model-required.{sh,py}`, §1.1) — 모든 Agent spawn 에 model 명시 의무, 누락 시 `permissionDecision: deny` 차단

**라이브 검증 PASS** (turn 8 #019, 2026-05-04):
- A (`model="opus"`) → 자식 = `claude-opus-4-7` ✓
- B (`model="sonnet"`) → 자식 = `claude-sonnet-4-6` ✓
- C (model 누락) → **강제 훅 차단** PASS (`permissionDecision: deny` + exit 0 우회) ✓
- D (`model="haiku"`) → 자식 = `claude-haiku-4-5-20251001` ✓ (3종 valid model 모두 spawn 가능)

**부수 발견 R-7** (turn 8): 3종 valid model (`opus|sonnet|haiku`) 모두 spawn 가능 → 4단 비용 배분 가능성 (Phase 2 후속 검토). 단 본 비전 = Haiku 0건 정책 (`feedback_no_haiku.md` 100% 준수, R-10).

**출처**:
- `06_issue32732_experiment.md §10·§11·§12` (turn 6·7·8)
- `04_masterplan.md §8.2 3·4·5차 실험 박스` + `§9.1 model override 행`
- `~/.claude/rules/agent-spawn-model.md` (글로벌 강제 규칙, turn 6 신설)

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

### 4.3 6게이트 (5게이트 LLM + 외부 훅 1)

> **표기 정합** (Day 20 turn 6 #022 정정): 5게이트 = LLM 자체 검증, 게이트 6 = 외부 훅 자동 검수 = 합쳐서 **6게이트** 운영.

- **게이트 1** 라인 실측 (환각 차단)
- **게이트 2** 반박/유보 최소 1건 (sycophancy 방지)
- **게이트 3** 근거 강도 표시 (강/중/약, 약 ≥ 50% 시 ⚠️)
- **게이트 4** 통계 표 강제
- **게이트 5** 자기 비판 한 줄
- **게이트 6** 외부 훅 자동 검수 (`feedback-sycophancy-check.sh` PostToolUse, 7 카테고리)

상세: `~/.claude/skills/feedback/SKILL.md`

---

## 5. 가드레일 (R-1~R-15)

마스터플랜 §6 R-1~R-5 + 본 비전 누적 R-6~R-15 가드 운영:

| 가드 | 본 스킬에서의 적용 |
|------|-----------------|
| **R-1** 영속화 우려 | yaml + 외부 자산으로 해소. `~/.claude/teams/<팀>/config.json` + `agents/*.md` 12 + `presets/*.yaml` 5 + 산출물 파일이 외부 자산 |
| **R-2** PM 별도 두기 | **Phase 1 정식 PM** = `agents/pm.md` (Opus, turn 11 신설). 사장이 PM 협의 거쳐 결정 = 자기 확증 편향 1차 회피. `/feedback` 검수 = 2차 외부 보호막 |
| **R-3** Sonnet 워커 강제 | §3 모델 배분 + 강제 훅 3중 보장 |
| **R-4** 4가지 워커 명시 | §2 항상 ①②③④ 4가지 — 3가지로 줄이지 말 것 |
| **R-5** 오너 컨펌 | 합의안 / 큰 결정은 주인님 컨펌 필수. 사장이 멋대로 진행 금지 |
| **R-6** SendMessage 회신 의무 | spawn 텍스트 출력만으로는 lead 미수신 — 명시적 `SendMessage` 회신 필수 (turn 6 §6-1 교훈, turn 8 R-8 안정성 PASS) |
| **R-7** 3종 valid model spawn 가능 | `opus|sonnet|haiku` 모두 spawn 가능 검증 (turn 8 #019). 단 본 비전 = Haiku 0건 정책 |
| **R-8** SendMessage 회신 안정성 | turn 8 4 spawn 모두 회신 도착 = Phase 1 PM-워커 통신 신뢰 가능 |
| **R-9** 일반화 한계 정직 명시 | 외부 사례 적용 시 한계 명시 의무 (Anthropic +90.2% 일반화 한계 박스 사례, turn 10) — `agents/analyst.md` 전문 영역 4번 항목 |
| **R-10** 12 agent 양식 일관 | 핵심 행동 규칙 5 + 출력 형식 4 요소 + 면제 예외 = agent 12 全 동일 (turn 11). 어느 워커 spawn 되어도 출력 일관성 보장 |
| **R-11** team_size ≠ len(members) 가능 | preset variations (예: review.security_focused team_size=2). 검증 시 default variation 의 team_size 와 members 수 정합만 확인 (Day 20 turn 1) |
| **R-12** dimension = preset 컨텍스트 속성 | 동일 agent 가 다른 preset 에서 다른 dimension 명 (예: docs-researcher: "공식 문서" vs "조사"). 정합성 자동 검증 단위 = preset (Day 20 turn 1) |
| **R-13** §변경 이력 다중 entry 보존 | 체크리스트 grep 명세 작성 시 §변경 이력 entry M개 × 평균 단어/entry 사전 고려 의무. 단순 단어 카운트 명세 = 좁음 (Day 20 turn 2) |
| **R-14** orphan 팀 정기 정리 | `validate-team.ps1 -AllTeams` 부수 발견 (Day 20 turn 3 = 운영 71 orphan). `shutdown-team.ps1` 일괄 정리 별도 turn 권장 (#021) |
| **R-15** 한글 ps1 = UTF-8 BOM 의무 | PowerShell 5.1 한글 주석 ps1 = BOM 부재 시 CP949 fallback → here-string parse fail. `[UTF8Encoding]::new($true)` 의무. Python 호출 = `PYTHONIOENCODING=utf-8` 강제 (Day 20 turn 3) |

### 5.1 운영 가드레일 (마스터플랜 §9 인용)

| 가드레일 | 내용 |
|---------|------|
| 한 세션 1 team | Phase 1 정식 PM (`agents/pm.md`, Opus) 운영 가능, 단 PM 팀 cleanup 후 워커 팀 생성 (또는 워커 팀 단독) — PM 팀 + 워커 팀 동시 불가 |
| nested team 불가 | teammate 는 `Agent`/`TeamCreate` 도구 없음 (issue#32731). 추가 spawn 필요 시 lead 가 대행 |
| Ralph 자율 루프 제한 | `max_iterations: 5` + Plan-Approval gate 필수 (D-5 보호) |
| 고아 팀 청소 | `scripts/shutdown-team.ps1 -Team <name>` archive (Phase 1 신설 완료, Day 20 turn 3) 또는 `~/.claude/teams/.archived/` 수동 이동 |
| PM 팀 cleanup 실패 폴백 | 60초 timeout → 강제 archive (마스터플랜 §9.3) |
| spawn 범위 제한 | spawn prompt 에 "이 경로 외 탐색 금지" 명시 (issue#35513) |

### 5.2 Windows / OneDrive 주의

- 한글 경로 + Codex: `~/codex-cwd/<슬러그>/` 영문 workdir 표준 (글로벌 CLAUDE.md 정책)
- Agent Teams 메타 (`~/.claude/teams/`, `~/.claude/tasks/`) 는 영문 경로 = 안전
- in-process 모드 사용 (psmux split-pane = issue#42848 미해결)

---

## 6. 명령어

> v1 의 6개 명령어 보존 + Phase 1 = preset 옵션 추가. 모든 명령은 §1 4-step + §1.1 강제 훅 + §3 모델 배분 + §4 /feedback 검수를 강제.

### `/agent-team create [팀이름]`
새 에이전트 팀 구성. 사용자에게 목적·팀원 역할·지시사항을 묻고 §2 heuristic 표 + §2.4 preset 카탈로그 기반으로 추천.

**저장 위치**: 팀 메타는 `TeamCreate` 가 자동으로 `~/.claude/teams/<팀이름>/` 에 생성. 사용자가 별도로 `<프로젝트>/.claude/teams/` 에 저장하는 것 **아님** (v1 명세 버그 정정).

선택적 산출물 (사용자가 원할 때만):
- `<프로젝트>/docs/research/<주제>/team_brief.md` — 팀 목적·팀원 역할·실행 흐름 메모

### `/agent-team run [팀이름|--preset <이름>] [인자...]`

**모드 1 — 저장된 팀**: 팀 정의 (있다면) 로 §1 4-step 실행
**모드 2 — preset 직접 호출** (Phase 1 신설):

```
/agent-team run --preset review --target docs/research/.../auth.md
/agent-team run --preset debug --bug-description "로그인 후 세션 5분 단축"
/agent-team run --preset research --topic "Streaming SSE 표준 vs Anthropic SDK"
/agent-team run --preset docs-research --topic "agent-team-manager v2 ADR"
/agent-team run --preset harness-design --topic "글로벌 외부 리서치 의무 규칙"
```

**preset 모드 흐름** (§1.2 Phase 0~8 자동화 흐름 정합):
1. `scripts/preflight.ps1 -SkipTmux` → 5 검사 PASS (Phase 0)
2. `scripts/resolve-preset.ps1 -Preset <이름>` → JSON 메타 추출 (Phase 1)
3. `TeamCreate <이름>-팀-<timestamp>` (Phase 2, LLM 직접)
4. `TaskCreate` × N (Phase 3, blocked_by mapping)
5. 각 멤버 `Agent({subagent_type, model, team_name})` (Phase 4, 강제 훅 통과)
6. `scripts/run-team.ps1 -SentinelInit -TimeoutMinutes 30` (Phase 5)
7. `SendMessage` 로 `task_template` 전달 + lead 회신 의무 (R-6)
8. (선택) `scripts/monitor-team.ps1` 주기 호출 (Phase 6)
9. `scripts/validate-team.ps1` 검증 → cycle_cap 초과 시 PM 에스컬레이션 (Phase 7)
10. 결과 종합 + `/feedback` 검수 (§4)
11. `scripts/shutdown-team.ps1 -Team <name>` archive (Phase 8, R-5)

**모드 3 — PM 협의** (선택, R-2 강화):
```
/agent-team run --pm-consult <작업 설명>
```
→ `agents/pm.md` (Opus) spawn → preset 추천 받음 → 사용자 컨펌 → 모드 2 진입

### `/agent-team list`
`~/.claude/teams/` 디렉토리 스캔 → 활성 팀 목록 표시 + `presets/*.yaml` 5 카탈로그 표시 (이름·team_size·members) + archive 디렉토리 (`~/.claude/teams/.archived/`) 표시.

### `/agent-team show [팀이름|--preset <이름>]`
- 팀 모드: `~/.claude/teams/<팀이름>/config.json` Read + members 표시
- preset 모드 (Phase 1 신설): `presets/<이름>.yaml` 본문 + members focus_areas + variations 표시

### `/agent-team edit [팀이름]`
config.json 또는 사용자 메모 (`docs/research/.../team_brief.md`) 편집. **preset YAML 직접 편집 금지** — 스테이징 (`presets/<이름>.yaml`) 만 편집 후 운영 sync (D-11 정책, D-16 일관).

### `/agent-team delete [팀이름]`
**삭제 전 사용자 컨펌 필수** (R-5). `TeamDelete` 또는 `~/.claude/teams/.archived/` 로 archive.

---

## 7. 활용 자산 + 잔여 한계

### 7.1 Phase 1 구현 완료 자산 (즉시 호출 가능)

| 자산 | 위치 | 신설 turn | 호출 방식 |
|------|------|---------|---------|
| **PM 비판자 (3층 부장)** | `agents/pm.md` (Opus) + `~/.claude/agents/pm.md` 운영 sync | turn 11 (#009-A) | `/agent-team run --pm-consult <작업>` 또는 직접 spawn |
| **PM 외부 리서치 의무** | `agents/pm.md` 핵심 행동 규칙 5번 + 출력 형식 4 요소 | turn 9 (#014) | PM 추천 시 자동 적용 (글로벌 `rules/research-mandatory.md` superset) |
| **② 회의실 5 preset** | `presets/{review,debug,research,docs-research,harness-design}.yaml` + `~/.claude/presets/` 운영 sync | Day 20 turn 1 (#009-B) | `/agent-team run --preset <이름>` |
| **scripts/ 6 자동화 헬퍼** | `skills/agent-team-manager/scripts/{preflight,resolve-preset,run-team,monitor-team,validate-team,shutdown-team}.ps1` + 운영 sync | Day 20 turn 3 (#009-D-1) | §1.2 Phase 0~8 흐름 자동 호출 |
| **reference/ 4 사례 라이브러리** | `skills/agent-team-manager/reference/{patterns,anti-patterns,errors,presets}.md` + 운영 sync | Day 20 turn 4 (#009-D-2) | on-demand 로드 (LLM 이 패턴 선택·트러블슈팅·preset 선택 시 Read) |
| **글로벌 강제 훅** | `hooks/pretooluse-agent-model-required.{sh,py}` + settings.json `Task|Agent` matcher | turn 7 (#018) | `model` 누락 시 자동 차단 (`permissionDecision: deny`) |
| **fallback C+ 영구 적용** | env 영구 제거 + 메인 재시작 + 강제 훅 (3중 메커니즘) | turn 7·8 (#018·#019) | 자동 (settings.json 환경변수 분리) |
| **글로벌 강제 규칙** | `~/.claude/rules/agent-spawn-model.md` + Agent Preferences 5번째 규칙 | turn 6 (#015) | 모든 Agent spawn 에 적용 |

### 7.2 잔여 한계 (Phase 2 후 가능)

| 미구현 | 이유 | 진입 조건 |
|--------|------|---------|
| **feature·security 2 preset** | 마스터플랜 §2.4 표 中 2/7 보류 + 새 agent 7 (lead/frontend/backend/tester + SAST/DAST/compliance) 신설 선행 필요 | #009-E 별도 turn (추정 2 turn) |
| **운영 71 orphan 팀 정리** | Day 20 turn 3 R-14 부수 발견. `validate-team -AllTeams` 후 일괄 archive | #021 별도 turn (추정 30분) |
| **bypass_threshold 자동 적용** | 작업 복잡도 자동 분석 → 워커 자동 선택 | Phase 2 dogfood 후 |
| **`/agent-office` 통합 진입점** | 본 스킬 + 자동 분류 + UI 통합 | Phase 2 |
| **자동 검증 hooks 추가** | PostToolUse sycophancy + 강제 훅 외 추가 (예: preset 자동 매핑 검증) | Phase 2 |
| **Linux 서버 배포** | bash 버전 병행 (`pretooluse-agent-model-required.sh` 이미 신설, 나머지 헬퍼 별도) | Phase 3 |

---

## 8. 마이그레이션 안내 (`/agent-office` 신설 시)

본 스킬 = Phase 1 정식 운영. `/agent-office` (Phase 2) 신설 시 자연스럽게 흡수. 사용자 입장에서는:

```
[현재 Phase 1]                       [Phase 2 후]
/agent-team run --preset review  →  /agent-office "이 코드 리뷰해줘"
                                      ↓
                                    자동 분류 → review preset 매핑 (§2.5)
                                    PM 협의 (선택) → /agent-team run --preset
                                    ⑤ /feedback 검수
                                    주인님 보고
```

**호환성**:
- 본 스킬로 만든 팀 메타 (`~/.claude/teams/<팀>/`) + `presets/*.yaml` 5 + `agents/*.md` 12 는 `/agent-office` 도 그대로 읽음 (역방향 호환)
- 자연어 트리거 ("팀 만들어줘", "리뷰 팀 돌려줘") 는 Phase 2 후 `/agent-office` 가 우선 트리거 (본 스킬은 fallback)

상세 마이그레이션: 마스터플랜 `05_migration_plan.md` Phase 0~3.

---

## 변경 이력

- **2026-05-05 (v2.6, Day 20 turn 5 /feedback 반영)**: 3 CLI 외부 검수 (codex+gemini+claude_sub) 합집합 11건 → 환각 0 / 만장일치 1 + 부분 합의 1 + 단독 가치 3 = critical 6건 즉시 반영. (a) frontmatter `allowed-tools` = TeamCreate/TaskCreate/SendMessage/TeamDelete 4 도구 추가 (4-step 본문 명단 정합). (b) §0 의무 6번 R-1~R-12 → R-1~R-15. (c) §5 헤더 R-1~R-12 → R-1~R-15. (d) §5 본문 R-6~R-12 → R-6~R-15. (e) §5.1 "현재는 PM 없음" → Phase 1 정식 PM 운영 정합. (f) §5.1 "(Phase 1 후)" → Phase 1 신설 완료 표현. 반박 4건 (gemini exit 0 우회 = Issue #26923 의도 / 4-step 예외 = §2.1 heuristic 의도 / Phase 모순 = §7.1·§7.2 분리 의도 / SHA256 절단 = 히스토리 식별자 용도). 게이트 6 표기 모순 (5게이트 + 외부 훅) = #022 별도 turn 백로그. **자기비판** = v2.5 작성 시 frontmatter ↔ 본문 정합 grep 누락 (글로벌 더블 체크 §3 일관성 검증 빠뜨림). SHA256 (이전 v2.5) = `3D70CE05...A641`.
- **2026-05-05 (v2.5, Day 20 turn 4)**: scripts/ 6 + reference/ 4 호출 박기 (#009-D-2). §1.2 Phase 0~8 자동화 흐름 표 신설 (v2 spec §3.1 양식 차용 + 본 비전 양식 SSOT D-23). §2.4 `reference/presets.md` 1차 참조 박기. §5 가드레일 R-1~R-12 → R-1~R-15 확장 (R-13 §변경 이력 다중 entry 보존 + R-14 orphan 정리 + R-15 ps1 BOM 의무). §6 명령어 = scripts/ 6 호출 흐름 11단계 명시. §7.1 활용 자산 표 = scripts/ 6 + reference/ 4 행 추가 (6→8행). §7.2 잔여 한계 = scripts/ 6 + reference/ 4 행 제거, feature·security 2 preset (#009-E) + orphan 71 정리 (#021) 만 잔존. SHA256 (이전 v2) = `9FC078A6...AFFF`.
- **2026-05-05 (v2, Day 20 turn 2)**: PM·preset·hooks 보류 3건 흡수 (#009-C). v1.5 §7 한계 표 中 3 행 (PM 비판자 + PM 동적 선택 + preset YAML) 제거 → §7.1 활용 자산 표로 전환. §0 부트스트랩 표현 제거. §1.1 글로벌 강제 훅 박스 신설 (turn 7 #018 + turn 8 #019 라이브 검증 인용). §2.4 ② 회의실 5 preset 카탈로그 신설 (마스터플랜 §2.4 1:1 정합 5/5 PASS). §2.5 preset 자동 매핑 heuristic 신설. §3.1 박스 의미 전환 = 종전 경고 박스 → "fallback C+ 영구 적용" (turn 8 #019 PASS, issue#32732 종결). §5 가드레일 R-1~R-5 → R-1~R-12 확장 (turn 8 R-7·R-8 + turn 10 R-9 + turn 11 R-10 + Day 20 turn 1 R-11·R-12). §6 명령어 = preset 옵션 + PM 협의 모드 추가. SHA256 (이전 v1.5) = `ED0A9DD1...8F0C`.
- **2026-05-02 (v1.5, Day 18 후속)**: 마스터플랜 정합 재작성. v1 의 6가지 문제 해소 (저장 경로 / PM / 모델 배분 / 4가지 워커 / lifecycle / /feedback). 부트스트랩 가이드로 위치 확정. SHA256 (이전 v1) = `454F27ED...A8F5`.
- **2026-04-21 (v1)**: `/feedback` 스킬 구조 승격 패턴 모방, 단순 팀 관리 명령어 6개. → 마스터플랜 비전과 미정합.
