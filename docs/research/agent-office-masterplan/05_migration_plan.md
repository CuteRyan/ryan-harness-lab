---
title: "Agent-office 마이그레이션 — Phase 0~3 단계별 구현 계획"
owner: master-architect (Agent Teams 1인 팀)
date: 2026-05-01
scope: Task 4 of agent-office-masterplan (#010)
parent_doc: 04_masterplan.md
input_docs:
  - 03_gap-analysis.md
  - agent-team-skill-redesign/04_redesign-spec.md
model: sonnet
type: research
status: active
created: 2026-05-01
updated: 2026-05-01
related_code: []
related_docs:
  - 04_masterplan.md
  - agent-office-vision.md
  - agent-team-skill-redesign/04_redesign-spec.md
---

# Agent-office 마이그레이션 — Phase 0~3

> 전제: 현재 인프라의 75% 이상 이미 설계됨 (/feedback=⑤검수 완성, v2 스펙=②④인프라 설계).
> 남은 핵심: **3층 PM 구체화** (pm.yaml + system prompt + 순차 시퀀스 표준화)
> v2 스펙 #009는 단독 구현 금지 — 마스터플랜 Phase 1 인프라로 위치 재조정.

---

## Phase 0. 마스터플랜 확정 + /feedback 검수 (본 turn)

### 목표

4인 리서치 팀 산출물(Task 1~4)을 종합한 마스터플랜을 확정하고, /feedback으로 독립 외부 검수를 수행한다.

### 완료 조건

- [x] `01_official-docs-deep.md` 완성 (Task 1)
- [x] `02_external-deep.md` 완성 (Task 2)
- [x] `03_gap-analysis.md` 완성 (Task 3)
- [x] `04_masterplan.md` 완성 (Task 4, 본 문서와 쌍)
- [ ] `05_migration_plan.md` 완성 (이 문서)
- [ ] `00_요약.md` 완성 (Task 5)
- [ ] /feedback 외부 검수 (04_masterplan.md 대상)
- [ ] 주인님 컨펌 후 Phase 1 진입 허가

### 부트스트랩 인정

본 Phase는 PM 인프라 없이 진행. 자기검증 부재 위험 → /feedback이 유일한 완화 수단.

---

## Phase 1. 인프라 구축 (v2 스펙 흡수)

### 목표

Agent-office 운영에 필요한 최소 인프라를 구축한다. v2 스펙 P0/P1 항목을 마스터플랜 구조로 흡수하여 구현한다.

### 1.1 pm.yaml 양식 + system prompt 표준

**설계 목표**: PM 역할 명세를 코드화. PM이 매 세션 읽고 역할을 인지.

```yaml
# pm.yaml 표준 포맷 (프로젝트 루트에 배치)
version: 1
role: PM
model: opus

# 역할 명세
identity:
  name: "PM (부장)"
  description: "비판자 + 동적 선택 추천자. 사장과 1:1 토론 후 워커 방식 추천."
  constraints:
    - "반박 우선 원칙: 사장 제안에 먼저 반박. 동의는 그 후."
    - "spawn 불가: 워커 직접 spawn 불가. lead(사장)에게 추천만."
    - "비용 인식: 워커 선택 시 예상 토큰 배수 명시."

# 동적 선택 heuristic 표 (v0 초안 — Phase 2에서 실측 보정 예정)
heuristic:
  bypass_threshold:
    max_tool_calls: 10          # 이하 → PM 게이트 생략, 사장이 ① 인턴 직접 호출
    single_file_with_test: true # 조건 충족 → 생략
  worker_selection:
    simple_query:              # tool call 3~10
      worker: "① 인턴 Sub-agent"
      parallel: false
      cost_level: "최저"
    small_parallel:            # tool call 10~15 each
      worker: "② 소규모 회의실 (2~3명)"
      parallel: true
      cost_level: "저~중"
    complex_parallel:          # tool call 20+
      worker: "② 대규모 회의실 (3~5명)"
      parallel: true
      cost_level: "중"
    external_validation:
      worker: "③ 외부 CLI (/feedback)"
      parallel: true
      cost_level: "저 (외부 비용)"
    sequential_stages:
      worker: "④ 파이프라인 Pipeline"
      parallel: false
      cost_level: "중~고"
    large_file_analysis:
      worker: "④ RLM"
      parallel: true
      cost_level: "고"
    high_risk_change:
      worker: "④ Plan-Approval"
      parallel: false
      cost_level: "중"
  escalation:
    review_cycle_cap: 3         # 리뷰 실패 3회 초과 → PM 에스컬레이션
    max_iterations: 5           # Ralph 패턴 차용 시 상한
    timeout_minutes: 30         # 워커 팀 기본 타임아웃

# 영속 자산 연결
memory:
  history_path: "docs/history/"
  memory_path: "memory/"
  handoff_path: "HANDOFF.md"
  # agent-memory 선택적 강화:
  # ~/.claude/agent-memory/<pm-name>/MEMORY.md (cross-session 누적)

# /feedback 연동
feedback:
  required_before_d5: true      # D-5 컨펌 직전 /feedback 필수
  required_on_worker_output: true  # 워커 산출물 최종 검수 필수
```

**구현 단계**:
1. `pm.yaml` 파일 생성 (프로젝트 루트, 또는 `.claude/pm.yaml`)
2. PM subagent 정의 파일 생성 (`~/.claude/agents/pm-agent.md`)
3. PM system prompt에 pm.yaml 읽기 지시 포함
4. Phase 1 검증: PM spawn 후 pm.yaml 내용 기반 역할 인지 확인

### 1.2 헬퍼 라이브러리 공유

**목표**: /feedback 스킬의 `scripts/`를 /agent-office와 공유하여 ③ 외부 CLI 호출 시 재사용.

**현재 /feedback scripts/ 목록**:
- `scripts/_encoding.ps1` — UTF-8 I/O 인코딩 고정 헬퍼
- `scripts/run-codex.ps1` — Codex 호출
- `scripts/run-gemini.ps1` — Gemini 호출
- `scripts/orchestrate.ps1` — 3 CLI 병렬 실행
- `scripts/validate-outputs.ps1` — Validation Gate
- `scripts/prepare-isolation.ps1` — 격리 디렉토리 생성

**공유 방식**:
```
공유 라이브러리 위치: ~/.claude/lib/agent-office/
├── cli/
│   ├── run-codex.ps1       # /feedback에서 복사 또는 symlink
│   ├── run-gemini.ps1
│   └── _encoding.ps1
└── team/
    ├── preflight.ps1       # v2 스펙 preflight.ps1
    ├── validate-team.ps1   # v2 스펙
    └── shutdown-team.ps1   # v2 스펙
```

또는 /feedback scripts/를 직접 참조 (`$HOME\.claude\skills\feedback\scripts\`). /feedback이 먼저 완성되어 있으므로 참조 방식이 더 실용적.

### 1.3 /agent-office 슬래시 커맨드 스킬 신설

**목표**: `~/.claude/skills/agent-office/SKILL.md` 신설. Agent-office 5층 위계 진입점.

**SKILL.md 구조** (초안):

```
~/.claude/skills/agent-office/
├── SKILL.md                    # 진입점
├── scripts/
│   ├── pm-spawn.ps1            # PM 팀 생성 + system prompt 주입
│   ├── pm-teardown.ps1         # PM 팀 cleanup + 합의안 기록
│   └── worker-dispatch.ps1     # 워커 타입별 spawn 진입점
├── reference/
│   ├── heuristic.md            # PM 동적 선택 표 (pm.yaml에서 읽어 출력)
│   └── anti-patterns.md        # 운영 실패 패턴
└── pm.yaml                     # (링크 또는 예시 — 실제는 프로젝트 루트)
```

**주요 명령어**:
- `/agent-office start` — PM 팀 생성 + 사장↔PM 토론 시작
- `/agent-office plan <작업>` — PM에게 작업 전달 + 워커 추천 요청
- `/agent-office dispatch` — PM 합의안 기반 워커 spawn
- `/agent-office review` — /feedback 외부 검수 호출
- `/agent-office teardown` — PM 팀 cleanup + 합의안 기록

### 1.4 PM 동적 선택 heuristic 표 코드화

pm.yaml의 `heuristic` 섹션을 PM system prompt에 직접 삽입. 매 세션 PM이 pm.yaml 읽고 heuristic 표 기반으로 워커 추천.

**구현**: `pm-spawn.ps1`이 pm.yaml 파싱 → PM spawn 시 system prompt에 heuristic 표 포함.

### 1.5 운영 가드레일 hooks

```json
// settings.json 추가 등록
{
  "hooks": {
    "TeammateIdle": [
      {
        "type": "command",
        "command": "$HOME\\.claude\\hooks\\pm-idle-check.sh"
      }
    ],
    "TaskCompleted": [
      {
        "type": "command",
        "command": "$HOME\\.claude\\hooks\\task-quality-gate.sh"
      }
    ]
  }
}
```

**pm-idle-check.sh 설계**:
```bash
#!/bin/bash
# TeammateIdle 훅: PM이 idle 상태 전환 직전 확인
# pm.yaml에서 persistent 설정이면 다음 태스크 확인
# exit 0: idle 허용 / exit 2: 계속 작업 지시
exit 0  # MVP: idle 허용 (Phase 2에서 강화)
```

**task-quality-gate.sh 설계**:
```bash
#!/bin/bash
# TaskCompleted 훅: 완료 전 기본 품질 체크
# exit 0: 완료 허용 / exit 2: 완료 차단
# MVP: output_path 파일 존재 여부만 확인
TASK_INPUT="$CLAUDE_TOOL_INPUT"
exit 0  # MVP: 차단 없이 트리거만
```

### Phase 1 검증 + 롤백

**검증 항목**:
- [ ] PM spawn (pm.yaml 기반) + 역할 인지 확인
- [ ] SendMessage 1:1 토론 (PM ↔ 사장)
- [ ] PM heuristic 추천 정확도 (§3 표와 일치 여부)
- [ ] PM cleanup + 워커 팀 생성 순차 시퀀스
- [ ] /feedback 연동 (워커 산출물 검수)

**롤백 트리거**:
- PM이 pm.yaml 읽지 못하는 경우 → pm.yaml 경로 수정
- 한 세션 1 team 한계 오류 → 순차 시퀀스 재확인
- issue#32732로 PM이 Sonnet으로 spawn 되는 경우 → fallback C+ 절차 실행 (settings.json env 영구 제거 + 메인 재시작 + 모든 spawn `model="opus"` 명시 + PreToolUse Agent matcher 강제 훅 = `~/.claude/rules/agent-spawn-model.md`). 2026-05-04 turn 6 PASS 검증 결과 (06 §10).

---

## Phase 2. 정식 PM 운영 dogfood

### 목표

Phase 1 인프라를 실제 작업에 적용하여 PM 운영을 검증한다.

### 2.1 PM 1인 팀 spawn (TeamCreate)

```
/agent-office start
→ pm-spawn.ps1 실행
→ PM(teammate, Opus) spawn
→ "pm.yaml 읽고 PM 역할 시작" 지시
```

### 2.2 사장 ↔ PM 토론 시뮬레이션

**토론 시나리오** (첫 dogfood용):
- 주인님 지시: "하네스 스킬 /checklist v2 개선 방안 검토해줘"
- 사장: "② 회의실 3명으로 병렬 검토 제안"
- PM 예상 반박: "3명이 과한가? tool call 추산이 10~15면 ② 소규모 2명으로 충분"
- 합의: 2명으로 축소 + 3번째는 /feedback으로 외부 검수

**토론 기록 형식**:
```
[사장] <제안>
[PM] <반박/동의 + 근거 + 예상 비용>
[합의안] <최종 결정>
[주인님 컨펌 대기]
```

### 2.3 워커 spawn (4갈래 중 적합)

합의안 확정 후:
```
PM 팀 teardown (pm-teardown.ps1)
  → 합의안을 pm.yaml 또는 HANDOFF.md에 기록
워커 팀 생성 (v2 스펙 Phase 0~8)
  → 해당 preset 선택 (harness-design 또는 review)
  → 각 워커 Sonnet으로 spawn
```

### 2.4 /feedback 검수

워커 산출물 완성 후:
```
/feedback <산출물 파일 경로>
→ orchestrate.ps1 실행 (Codex + Gemini + Claude Sub)
→ 5게이트 종합
→ 주인님에게 결과 보고
```

### 2.5 주인님 컨펌 (D-5)

검수 결과 보고 후 주인님 최종 컨펌. 거부 시 → 다시 토론.

### 2.6 한 세션 1 team 한계 우회 패턴

실제 운영에서 발생할 수 있는 케이스:
```
케이스 1: PM 토론 중 간단한 조회 필요
→ PM 팀 cleanup 없이 ① 인턴 직접 호출 가능
   (① 인턴 = Sub-agent, 팀 아님 → 팀 슬롯 미점유)

케이스 2: PM 합의 후 ② 회의실 필요
→ 순차 시퀀스: PM 팀 teardown → ② 회의실 팀 생성

케이스 3: ② 회의실 진행 중 검증 필요
→ 팀 내에서 /feedback 호출 (서브 클레임 가능)
   또는 특정 teammate가 직접 /feedback 스킬 invoke
```

### Phase 2 KPI

| 지표 | 목표 | 측정 방법 |
|------|------|---------|
| PM 비판자 역할 실효성 | 반박 최소 1건/토론 | 토론 기록 확인 |
| heuristic 표 정확도 | 추천 오류 < 30% | Phase 2 회고 |
| PM 오버헤드 비율 | 전체 비용의 5~20% | 토큰 비교 |
| Echo chamber 지수 | /feedback [반박] 최소 1건 | 종합 파일 확인 |
| 한 세션 1 team 한계 오류 | 0건 | 운영 로그 |

### heuristic 표 v0 → v1 보정

Phase 2에서 실측 데이터 수집:
- 작업별 실제 tool call 수 기록
- PM 추천 vs 실제 효율 비교
- bypass_threshold 수치 보정 (10이 너무 낮거나 높으면 조정)
- 2주 관찰 후 pm.yaml heuristic 업데이트

---

## Phase 3. 확장

### 3.1 다른 프로젝트 적용

현재 하네스 프로젝트(Harness-engineering)에서 검증 후 다른 프로젝트 확장.

**적용 순서**:
1. pm.yaml 해당 프로젝트 루트에 생성
2. CLAUDE.md에 "pm.yaml 참조" 지시 추가
3. /agent-office 스킬은 글로벌 (`~/.claude/skills/agent-office/`)이므로 즉시 사용 가능

### 3.2 preset 카탈로그 확장

wshobson 7종 + v2 5종 = 기본 카탈로그. Phase 2 실운영에서 자주 쓰는 패턴 추가.

추가 후보 (사용 빈도 확인 후):
- `agent-office.yaml` — PM 토론 전용 preset (1인 팀, D-1 표준)
- `feedback-loop.yaml` — /feedback 호출 + 검수 전담
- `writing.yaml` — 문서 작성 + 검토 팀

### 3.3 Anti-pattern 표 누적

Phase 2 실운영에서 발견된 실패 패턴을 `reference/anti-patterns.md`에 누적.

초안 항목 (외부 사례 + 본 마스터플랜 비판자 검토에서):

| Anti-pattern | 발생 조건 | 해결책 |
|-------------|---------|--------|
| PM이 사장과 동의만 반복 | α 옵션 system prompt 미주입 | pm.yaml 재확인 + PM 재spawn |
| 한 세션 1 team 오류 | PM 팀 cleanup 없이 워커 팀 생성 시도 | pm-teardown.ps1 먼저 실행 |
| ① 인턴을 ② 회의실로 과투자 | heuristic 표 미확인 | PM에게 bypass_threshold 확인 요청 |
| Ralph 자율 루프로 D-5 위반 | max_iterations 미설정 | pm.yaml escalation 설정 확인 |
| PM이 Sonnet으로 spawn 됨 | issue#32732 (env 가 frontmatter+명시 model 모두 덮음) | **fallback C+ 절차** (env 영구 제거 + spawn model 명시 + 강제 훅) — 2026-05-04 turn 6 PASS 검증, 글로벌 규칙 `agent-spawn-model.md` |
| /feedback 검수 생략 | 바쁠 때 건너뜀 | pm.yaml feedback.required_before_d5 강제 |

### 3.4 bash 버전 병행 (Linux 서버 배포)

/feedback Phase 2 후보와 동일. 하네스 최종 배포 타깃이 Linux (MEMORY.md 기록).

**필요 작업**:
- `scripts/` 내 PowerShell 스크립트의 bash 대응 버전 작성
- `preflight.sh`, `pm-spawn.sh` 등
- UTF-8 인코딩 처리 (CP949 이슈는 Linux 무관, Windows 전용)
- 배포 타깃 서버 환경 확인 후 진행

---

## 리스크·완화 표

| Phase | 리스크 | 심각도 | 완화 |
|-------|--------|--------|------|
| 0 | 부트스트랩 자기검증 부재 | 높음 | /feedback 검수 필수 |
| 0 | 마스터플랜 앵커링 편향 | 중간 | 비판자 검토 섹션 (§부록) |
| 1 | pm.yaml 역할 명세 미성숙 | 중간 | v0 명시 + Phase 2 보정 |
| 1 | issue#32732 PM Sonnet으로 spawn | ✅ 해소 (2026-05-04 turn 6) | fallback C+ 최종 확정 — env 영구 제거 (#018 강제 훅 후) + 모든 spawn `model` 명시 + 글로벌 규칙 `agent-spawn-model.md` |
| 1 | /feedback 헬퍼 경로 충돌 | 낮음 | 참조 방식 사용 (scripts/ 복사 불필요) |
| 2 | PM 비판자 역할 미실효 | 중간 | 토론 기록 모니터링 + PM 재spawn |
| 2 | 한 세션 1 team 오류 | 낮음 | pm-teardown.ps1 표준화 |
| 2 | heuristic 표 v0 불일치 | 중간 | 2주 관찰 + v1 보정 |
| 3 | 다른 프로젝트 pm.yaml 미동기화 | 낮음 | 프로젝트별 pm.yaml SSOT 원칙 |
| 3 | Linux 배포 시 PowerShell 의존성 | 중간 | bash 버전 병행 (Phase 3) |

---

## Phase 간 의존성

```
Phase 0 완료 조건:
  - 마스터플랜 확정
  - /feedback 검수 통과
  - 주인님 컨펌

Phase 1 선행 조건: Phase 0 완료
Phase 1 완료 조건:
  - pm.yaml 포맷 확정 + 샘플 작성
  - /agent-office 스킬 SKILL.md 신설
  - PM spawn + 토론 검증
  - 가드레일 hooks 등록

Phase 2 선행 조건: Phase 1 완료
Phase 2 완료 조건:
  - 실제 작업에 PM 운영 dogfood 1회 이상
  - heuristic 표 v0 → v1 실측 보정
  - KPI 달성 확인

Phase 3 선행 조건: Phase 2 완료 (일부는 병렬 가능)
```

---

**작성**: 2026-05-01 master-architect (Agent Teams 1인 팀, Sonnet)
**검토**: lead(메인 Claude)에게 Phase 1 상세 구현 우선순위 검토 요청
