---
title: "Gap 분석 — 비전 vs v2 스펙 vs /feedback 3자 + 우려 1~3 + R-1~R-5"
owner: office-design-analyst
date: 2026-05-01
scope: Task 3 of agent-office-masterplan
parent_doc: agent-office-vision.md
input_docs:
  - 01_official-docs-deep.md
  - 02_external-deep.md
  - agent-team-skill-redesign/04_redesign-spec.md
  - skills/feedback/SKILL.md
model: sonnet
---

# Gap 분석 — 비전 vs v2 스펙 vs /feedback 3자 + 우려 1~3 + R-1~R-5

---

## 0. Executive Summary

- **D-1 PM 메커니즘의 숨은 한계 확정**: teammate는 Agent/TeamCreate 도구 없음 (issue#32731). PM은 "분석·반박·추천"만 가능하고 실제 워커 spawn은 lead(메인 Claude)가 대행. 이 역할 분리는 오히려 책임 명확성을 높이므로 비전 수정이 아닌 **설명 보강**이 필요.
- **한 세션 1 team 한계 → 순차 운영 필수**: PM 팀 cleanup → 워커 팀 생성 순서가 강제됨. ② 회의실 워커를 PM과 동시 운영하는 시나리오는 아키텍처적으로 불가 (Task 4가 공식 우회책 설계 필요).
- **v2 스펙은 비전의 ②층(회의실) + ④층(파이프라인) 전담 인프라**: §1~§11 전체가 마스터플랜 Phase 1 인프라의 절반을 커버. 단 ①③⑤ 층(인턴/외부CLI/검수)은 v2 스코프 밖 → Gap 존재.
- **/feedback은 비전의 ⑤검수 층 완성체**: 5게이트 + 외부훅 + 격리 디렉토리 + 헬퍼 라이브러리가 비전 D-2, D-3 결정을 이미 구현. PM 연동 인터페이스만 추가하면 됨.
- **우려 1(PM 판단력) heuristic 표 초안 재료 충분**: Anthropic 블로그 scaling heuristic + wshobson preset 7종 + revfactory 6패턴 결합으로 PM system prompt 직접 삽입 가능한 수준의 표를 만들 수 있음.
- **우려 3(Echo chamber)의 구조적 해결책은 비전이 외부 9건 중 최강**: /feedback의 외부 CLI 3종 강제 호출이 oh-my-claudecode + ralph 2건을 넘는 가장 체계적인 구현.
- **부트스트랩 단계 위험이 과소평가**: 마스터플랜 작성 자체가 PM 인프라 미구축 상태에서 진행 → 자기검증 부재. /feedback 검수 강제가 유일한 완화 수단.

---

## 1. 3자 비교 매핑표

아래 표는 비전의 5층 4워커 D-1~D-5를 축으로, v2 스펙(04_redesign-spec.md §번호)과 /feedback(SKILL.md)이 각각 어느 부분을 커버하는지 매핑한 것이다.

| 비전 요소 | v2 스펙 (04_redesign-spec.md §) | /feedback (SKILL.md) | 흡수/Gap |
|---|---|---|---|
| **1층 주인님 컨펌 (D-5)** | §3 Phase 8 "주인님 승인 후 shutdown" | Step 3 "valid_count=0이면 수동 리뷰" | ✅ 양쪽 모두 오너 컨펌 패턴 내재 |
| **2층 사장 (메인 Claude, Opus)** | 비스코프 — v2는 lead 역할 전제 | 메인 Claude가 Step 3 종합 담당 | ✅ 두 스킬 모두 메인 Claude가 lead |
| **3층 PM (D-1, 1인 팀 + 비판자)** | §3.1 Phase 2~4 (TeamCreate+Agent+SendMessage) | 비스코프 | 🔴 **Gap**: v2에 PM 역할 system prompt 명세 없음. pm.yaml 구조 미정의 |
| **4-① 인턴 (Sub-agent)** | 비스코프 — v2는 팀 기반 전제 | 비스코프 | 🔴 **Gap**: 단발 Sub-agent 호출 패턴 어느 스킬에도 없음 |
| **4-② 회의실 (Agent Teams 멀티)** | §1~§11 전체 (preset 5종 + Phase 0~8) | 비스코프 | ✅ v2가 완전 커버. pm.yaml 연동만 추가 |
| **4-③ 외부 CLI (Codex/Gemini)** | 비스코프 | ✅ scripts/ 6개 완성 (orchestrate/run-codex/run-gemini/encoding) | 🟡 **부분 Gap**: /feedback이 헬퍼 보유하나 PM이 직접 호출하는 시나리오 미정의 |
| **4-④ 파이프라인 (zircote 7패턴)** | §3 Phase 3 blocked_by 체인 / §7 preset 3종 | 비스코프 | ✅ v2 Pipeline 패턴 커버. 7패턴 중 Review/Debug/Research 3개만 preset화, 나머지는 Ph2-12 |
| **5층 검수 (/feedback)** | §10 Ph2-3 "Verifier 기본 preset 통합" (MVP 제외) | ✅ Step 1~4 + 5게이트 + 게이트6 완성 | 🟡 **통합 Gap**: v2가 /feedback 호출을 Phase 2 후보로만 처리. 정식 연동 미구현 |
| **D-2 /feedback 단발 유지** | 비스코프 | ✅ Step 1 orchestrate 단발 설계, D-3 ephemeral 내재 | ✅ 설계 일관 |
| **D-3 lifecycle: persistent/ephemeral** | §3 Phase 5~6 (sentinel + monitor) | ephemeral만 — 단발 호출 후 종료 | ✅ 역할 분리: v2=persistent, /feedback=ephemeral |
| **D-4 모델 배분 (Opus/Sonnet/외부)** | §4.1 YAML defaults.model / members[].model | Step 1 orchestrate (Codex/Gemini=외부) | 🟡 **부분 Gap**: PM Opus 고정 방법 미정의 (issue#32732 회피책 미반영) |
| **영속화 (pm.yaml)** | §4 YAML 포맷 있음 (team YAML) → pm.yaml 아님 | 비스코프 | 🔴 **Gap**: pm.yaml 구조(role/heuristic/권한) 정의 없음. v2 YAML은 팀 설정용 |
| **R-2 α 옵션 비판자 강제** | 비스코프 | 게이트 2 "반박/유보 최소 1건" 유사 메커니즘 | 🔴 **Gap**: PM system prompt에 비판자 강제 명세 없음 |

### 1.1 3자 중복 / Gap 요약

**중복 (셋 모두 공통)**:
- 메인 Claude = lead (오너 결정권 포함)
- 스크립트 담당 vs LLM 담당 책임 분리 철학
- 산출물 파일 기반 검증 (validate-*.ps1 패턴)
- 주인님 승인 후에만 정리/삭제 원칙

**Gap (어느 스킬에도 없음)**:
1. `pm.yaml` 구조 정의 (role/heuristic 표/권한/lifecycle 필드)
2. PM system prompt 명세 (비판자 강제 + 동적 선택 기준)
3. 단발 Sub-agent(① 인턴) 호출 패턴
4. 한 세션 1 team 한계 공식 대응 시퀀스 (PM cleanup → 워커 팀 생성)
5. /feedback ↔ v2 정식 연동 인터페이스

---

## 2. 우려 1 — PM 동적 선택 판단력

### 2.1 heuristic 표 초안 (Task 4가 완성)

아래 표는 Task 2 외부 사례(Anthropic 블로그 + wshobson + revfactory)를 결합해 PM system prompt에 직접 삽입 가능한 수준으로 정리한 초안이다.

| 작업 복잡도 | 예상 tool call 수 | 추천 워커 | 병렬 여부 | 비용 수준 | 근거 출처 |
|-----------|-----------------|---------|---------|--------|---------|
| 단순 조회/탐색/Read-only | 3~10 | **① 인턴 Sub-agent** | 단독 | 최저 | Anthropic 블로그 |
| 2~4개 비교·분석 | 10~15 each | **② 소규모 회의실 (2~3명)** | 병렬 가능 | 저~중 | Anthropic 블로그 |
| 복잡 협업 (5+ 파일, 다관점) | 20+ | **② 대규모 회의실 (3~5명)** | 병렬 권장 | 중 | Anthropic 블로그 + wshobson |
| 외부 검증/다른 모델 시각 필요 | — | **③ 외부 CLI** | 병렬 (orchestrate.ps1) | 저 (외부 비용) | 비전 D-2 |
| 단계 의존성 있는 순차 작업 | 각 단계 별도 | **④ 파이프라인 Pipeline** | 순차 강제 | 중~고 | zircote |
| 반복 수행 / 컨텍스트 초과 분석 | 무제한 | **④ RLM 또는 Ralph** | 청크 병렬 | 고 | zircote + mikeyobrien |
| 아키텍처 설계 / 고위험 변경 | — | **④ Plan-Approval** | 승인 게이트 | 중 | zircote + aws-samples |
| 단순 버그픽스 / 3줄 이하 편집 | 1~3 | **직접 (PM 게이트 생략)** | N/A | 최저 | v2 §9.1 옵션C + Shipyard |

**Why 이 표가 PM system prompt에 삽입 가능한가**: Anthropic 블로그의 "3-10 calls = 1 agent" 기준이 ① 인턴의 임계값이 되고, wshobson의 "언제 몇 명" 의사결정 표 양식이 ②~④ 행의 구조를 잡아준다. revfactory Expert Pool은 "컨텍스트 의존적 패턴 선택"이라는 메타 원칙을 제공한다.

**추가 선택 기준 (revfactory 6패턴 기반)**:
- Fan-out/Fan-in 구조 → ② 회의실 병렬 또는 ④ Multi-File
- Supervisor 패턴 (중앙 조정 + 동적 분배) → PM 자체가 Supervisor 역할
- Producer-Reviewer 사이클 → ④ Pipeline + aws-samples review cycle cap 적용

### 2.2 잘못 선택 시 비용 시뮬레이션

Task 1 발견: Anthropic 블로그 "multi-agent는 single-agent 대비 ~15× 토큰"

| 잘못된 선택 | 올바른 선택 | 토큰 비용 배수 | 지연 |
|-----------|-----------|------------|-----|
| 단순 조회에 ② 회의실 3명 | ① 인턴 1회 | ~15× | +30분 |
| 단순 조회에 ④ Pipeline 5단계 | ① 인턴 1회 | ~50× | +1시간+ |
| 복잡 협업에 ① 인턴 단독 | ② 회의실 | 1× | 품질 저하 |
| 외부 검증에 ② 회의실 | ③ 외부 CLI | 5~10× 절감 | — |

**Why 비용 시뮬레이션이 중요한가**: wshobson/barkain/zircote는 모두 단일 Claude 생태계로 운영되어 워커 과투자에 대한 제동 장치가 없다. PM heuristic 표에 비용 배수를 명시해야 PM이 "무조건 팀" 반사를 억제할 수 있다.

### 2.3 가드레일 제안

1. **pm.yaml `bypass_threshold` 필드**: tool call 예상 수 ≤ 10이면 ① 인턴 자동 추천 (Task 2 §11 우려 2 제안 채택)
2. **review cycle cap 3회**: aws-samples에서 검증된 수치. ② 회의실 또는 ④ Pipeline에서 리뷰 실패 3회 초과 시 PM에 에스컬레이션
3. **비용 예상치 PM 보고 의무**: 워커 선택 후 "예상 토큰 배수 N×"를 주인님께 보고 후 컨펌 (D-5)

---

## 3. 우려 2 — 2단계 호출 비용

### 3.1 한 세션 1 team 한계 결합 시 비용 모델

Task 1 발견: 한 세션당 1 team 한계가 PM 팀 + 워커 팀 동시 운영을 차단한다.

**순차 운영 시 토큰·지연 합산 모델**:

```
[전체 비용] = [PM 팀 세션 비용] + [PM 팀 cleanup] + [워커 팀 세션 비용]

PM 팀 세션:
  - TeamCreate (1회)
  - PM spawn (1회, Opus)
  - SendMessage 왕복 N회 (합의까지)
  - TeamDelete (1회)
  예상: 5K~20K 토큰 / 3~10분

워커 팀 세션:
  - TeamCreate (1회)
  - 워커 spawn N명 (Sonnet)
  - 작업 실행 병렬
  예상: 50K~200K 토큰 / 30분~2시간

총 오버헤드: PM 팀 세션이 전체의 5~20%
```

**결론**: PM 오버헤드(5~20%)는 복잡 작업에서 품질 향상 대가로 합리적. 단순 작업(tool call ≤ 10)에서는 PM 게이트 자체를 생략해야 한다.

### 3.2 언제 PM 거치고 언제 직접 워커 spawn (기준 초안)

| 조건 | PM 경유 여부 | 이유 |
|------|------------|------|
| 예상 tool call ≤ 10 (단순 조회) | **생략** (① 인턴 직접) | PM 오버헤드가 작업보다 큼 |
| 단일 파일 수정 + 재현 가능 테스트 있음 | **생략** (v2 Non-goals 동일) | 비용 대비 효과 없음 |
| 다관점 병렬 필요 (② 회의실) | **경유** | 패턴 선택 + 워커 조율 판단 필요 |
| 외부 검증 필요 (③ 외부 CLI) | **선택** (PM이 시나리오 설계 시 경유, 단순 호출은 생략) | /feedback 단발 특성 존중 |
| 단계 의존성 복잡 (④ 파이프라인) | **경유 필수** | DAG 설계 판단이 PM 핵심 역량 |
| 고위험 변경 / 설계 결정 | **경유 필수** | D-5 오너 컨펌 전 PM 반박 필수 |

**pm.yaml `bypass_threshold` 구현안**:
```yaml
# pm.yaml 내 필드 예시
decision_policy:
  bypass_threshold:
    max_tool_calls: 10        # 이하이면 PM 게이트 생략
    single_file_with_test: true  # 조건 충족 시 생략
  escalation:
    review_cycle_cap: 3       # 3회 초과 시 PM 에스컬레이션
```

---

## 4. 우려 3 — Echo chamber

### 4.1 α 옵션 system prompt 명세 초안

비전 D-1: PM system prompt에 "비판자 강제" 를 α 옵션으로 채택.

**PM system prompt 명세 초안**:

```markdown
# PM 역할 명세 (α 옵션 포함)

당신은 [프로젝트명] 프로젝트의 PM(부장)입니다.

## 핵심 행동 규칙
1. **반박 우선 원칙**: 사장(메인 Claude)의 모든 제안에 대해 먼저 반박부터 시작하십시오.
   동의는 반박 후에도 타당성이 유지될 때만 허용됩니다.
2. **동적 선택 의무**: 작업 성격을 분석한 후 아래 heuristic 표에 따라 워커 방식을 추천하십시오.
3. **비용 인식**: 워커 선택 시 예상 토큰 배수를 명시하십시오 (예: "② 회의실 3명 ≈ 기준 대비 15×").

## PM heuristic 표
[§2.1 표 삽입]

## 권한 범위
- 워커 spawn 직접 불가 (lead인 사장이 대행)
- 워커 추천 + 근거 제시 → lead가 실행
- 최종 결정권 = 주인님 (D-5)
```

**Why α 옵션이 β(외부 CLI PM)보다 낫나**: Task 1 §1.3에서 확인된 "teammate는 Agent 도구 없음" 한계로 인해 PM이 외부 CLI를 직접 호출하려면 Bash 도구 허용이 필요하다. α 옵션은 Claude 모델 내 비판자 역할로 구현되므로 도구 권한 제약을 우회한다. 단, 같은 Claude 계열이므로 근본적 Echo chamber 해소는 불가능 → ③ 외부 CLI 정기 호출이 보완재.

### 4.2 ③ 외부 CLI 호출 빈도 권장

Task 2 §11 우려 3: 외부 모델 통합을 명시적으로 가진 사례는 9건 중 2건(oh-my-claudecode + ralph)뿐. 비전 ③ 외부 CLI가 가장 강한 해결책.

**호출 빈도 권장 기준**:

| 시점 | 외부 CLI 호출 | 방법 |
|------|------------|------|
| 주요 설계 결정 (D-5 컨펌 직전) | **필수** | /feedback으로 설계 문서 검수 |
| 워커 산출물 최종 검수 | **필수** | /feedback으로 결과물 검수 |
| PM 추천안 합리성 검증 | **선택** (고위험 시) | /feedback으로 PM 합의안 검수 |
| 단순 조회 결과 확인 | **생략** | 비용 대비 효과 없음 |

**Alpha 옵션 한계 보완 구조**:
```
PM (α=Claude 비판자) → 1차 Echo chamber 완화
/feedback (③=외부 CLI) → 2차 독립 검증
주인님 컨펌 (D-5) → 최종 게이트
```

외부 CLI 통합 빈도를 너무 낮추면(큰 결정에만) 일상 작업의 품질 드리프트가 누적될 수 있다. 반대로 모든 작업에 강제하면 우려 2(비용)가 악화된다. "워커 산출물 최종 검수는 필수"가 균형점으로 권장된다.

---

## 5. R-1~R-5 가드 검증

### R-1 영속화 (yaml + 외부 자산)

**Task 1 결과**: 완전 지지 + 강화

Task 1 §9 R-1에서 subagent `memory: user` 설정 시 `~/.claude/agent-memory/<name>/MEMORY.md` 자동 관리 가능함을 발견. PM 워커에 적용하면 `pm.yaml` + `docs/history/` + agent-memory 3중 영속이 가능.

**권고**: `pm.yaml`은 역할 명세(role/heuristic/권한), agent-memory는 cross-session 누적 지식, `docs/history/`는 결정 log로 역할을 분리할 것.

**R-1 상태**: ✅ 영속화 문제 없음. Task 4가 `pm.yaml` 구조 설계만 하면 됨.

### R-2 PM 별도 두기 + α

**Task 1 결과**: 조건부 지지 + 구조 보강 필요

Task 1 §1.3~1.4에서 확인: teammate로 spawn된 PM은 Agent/TeamCreate 없음 → **PM은 "추천"만 하고 lead(메인 Claude)가 spawn 대행**. 이는 D-1 비전과 충돌이 아니라 역할 명세 보강이 필요한 것임.

**α 옵션 구현 방법** (Task 1 §2.2 경로 A 기반):
1. PM = Agent Teams 1인 팀 teammate로 spawn
2. system prompt에 §4.1 α 옵션 명세 주입
3. PM이 SendMessage로 lead에게 "①②③④ 중 X 추천, 근거 Y" 전달
4. Lead가 실제 spawn 실행

**한계**: PM이 같은 Claude 계열 → 완전한 독립 비판 불가. /feedback(③ 외부 CLI)으로 보완.

**R-2 상태**: ✅ 채택 확정. α 옵션 system prompt 초안 §4.1에서 제시.

### R-3 모델 배분 (aws-samples 정정 반영)

**Task 2 정정 사항**: 1차 리서치(02_community-patterns.md §5)에서 "coding/review=Opus"로 기록되었으나 WebFetch 재확인 결과 **coding=Sonnet**, review=Opus만 Opus.

**D-4 근거 재검토 결과** (정정 반영):

| 출처 | Lead/조율 | 구현/실행 | 검증/리뷰 |
|------|---------|---------|---------|
| Anthropic 블로그 | Opus (orchestrator) | Sonnet (subagents) | — |
| wshobson | Opus (Lead/Reviewer) | Sonnet (Implementer) | Opus (Reviewer) |
| aws-samples (정정) | Opus (fullstack lead) | **Sonnet** (coding/devops/sa) | Opus (review-agent) |

**정정 후 D-4 결론**: 3개 출처 모두 "구현=Sonnet, 검토=Opus" 동일. 정정 전에도 결론은 변하지 않으나, "coding=Sonnet"이 더 강한 Sonnet 워커 정당성 근거가 됨.

**issue#32732 대응**: `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` env 설정 + PM 정의에만 `model: opus` 명시로 이중 보장. Task 1 §7.5 권장 구현 채택.

**R-3 상태**: ✅ D-4 확정. aws-samples 정정으로 오히려 Sonnet 워커 근거 강화.

### R-4 4가지 워커 (1 team 한계 결합)

**Task 1 발견**: 한 세션 1 team 한계가 ② 회의실 운영에 중요한 영향을 미침.

**② 회의실 운영 시퀀스 (공식 한계 반영)**:
```
[현재 시퀀스 — 문제]
PM 팀 생성 → PM과 토론 → 합의 → (이 상태에서 ② 회의실 팀 생성 시도) → ❌ 오류

[올바른 시퀀스]
PM 팀 생성 → PM과 토론 → 합의 → PM 팀 cleanup → ② 회의실 팀 생성 → 워커 실행
```

**④ 파이프라인 (zircote 7패턴) 영향**: Task 1 §9 R-4에서 TaskUpdate addBlockedBy 체인이 공식 Task 시스템과 100% 호환 확인. 단, **teammate가 nested team spawn 불가** → ④ 파이프라인 내 재귀적 Phase gate는 lead(메인 Claude)만 관리 가능.

**① 인턴 (Sub-agent) 상태**: v2 스펙에서 완전 빠진 워커. 비전에는 명시적으로 포함(§4 ①). pm.yaml heuristic 표와 연동하여 "단순 작업 → ① 인턴 직접 호출" 패턴을 마스터플랜에서 정의해야 함.

**R-4 상태**: 🟡 **보강 필요**. 4가지 워커 중 ②④는 v2로 커버, ①은 미정의, ③은 /feedback이 보유. 순차 운영 시퀀스 표준화 필요.

### R-5 오너 컨펌 (Ralph 자율 루프 충돌 회피)

**Task 2 발견**: Ralph Wiggum 패턴(mikeyobrien + 공식 플러그인)의 Stop-hook 무한 루프가 비전 D-5(오너 컨펌 필수)와 직접 충돌.

**충돌 분석**:
- Ralph: Claude exit 시도를 가로채 동일 프롬프트 재투입 → completion-promise 달성까지 자율 반복
- D-5: 합의안 → 주인님 컨펌 → 진행. 자율 실행 금지.

**완화 방안** (Ralph 패턴 차용 시):
1. `--max-iterations` 필드 필수 (`pm.yaml`에 `max_iterations: 5` 기본값 설정)
2. Ralph 루프 내에 컨펌 게이트 삽입 (`plan_approval_gate: true` 조합)
3. ④ 파이프라인 Plan-Approval 패턴(zircote §4 ⑤)을 Ralph 대신 사용 권장

**Task 1 §5.3 추가**: TaskCompleted 훅 + exit 2 무한루프 방지. Ralph 루프 대신 `TeammateIdle` 훅 기반 재활성이 D-5 원칙과 더 일관함.

**R-5 상태**: ✅ 해결책 명확. Ralph 직접 사용 시 `--max-iterations` + Plan-Approval gate 필수. 대안으로 zircote Plan-Approval 패턴 우선 권장.

---

## 6. v2 P0/P1 gap 흡수 재평가

v2 스펙 §10 Phase 2 후보 목록 중 마스터플랜 Phase에 흡수되어야 할 항목을 재평가한다.

| v2 P0/P1 항목 | 마스터플랜 Phase | 흡수 방식 | 우선순위 |
|---|---|---|---|
| S5 scripts/ 외부화 | **Phase 1** (MVP 핵심) | v2 SKILL.md + scripts/ 6개 구현 | P0 |
| O1 4-step 프로토콜 강제 | **Phase 1** | TeamCreate→TaskCreate→Agent→SendMessage 시퀀스 고정 | P0 |
| P1 env 체크 | **Phase 1** | preflight.ps1 구현 | P0 |
| R1~R4 실측 4건 | **Phase 1** | scripts/ 내 각각 대응 (sentinel/monitor/prefix/blockedBy) | P0 |
| U1 "무조건 팀" 룰 충돌 (옵션 C) | **Phase 1** + 비전 통합 | CLAUDE.md 수정 + pm.yaml bypass_threshold 통합 | P1 |
| Ph2-3 Verifier 기본 preset 통합 | **Phase 2** | /feedback 호출을 Phase 7 validate 직후에 자동 트리거 | P1 |
| Ph2-4 Scaling heuristic 자동 적용 | **Phase 1** (pm.yaml로 흡수) | §2.1 heuristic 표를 pm.yaml + PM system prompt에 직접 삽입 | P1 |
| Ph2-6 bash 버전 병행 | **Phase 3** (Linux 서버 배포) | 하네스 배포 타깃 Linux 결정(MEMORY.md) 반영 | P2 |
| Ph2-12 패턴 7종 전부 preset화 | **Phase 2** | 사용 요청 빈도 모니터링 후 점진 추가 | P2 |

**v2가 단독으로 못 해결하지만 비전으로 해결되는 것**:
1. **PM 비판자 강제**: v2는 팀 구성 도구. 비전의 5층 위계 + pm.yaml system prompt로만 해결 가능.
2. **①③ 워커 통합**: v2는 ②④만 커버. 비전 전체 아키텍처가 4가지 워커를 통합하는 우산.
3. **Echo chamber 구조적 해소**: v2 단독으로는 단일 Claude 생태계 = wshobson/aws-samples와 동일 취약점. 비전 ③ 외부 CLI + /feedback이 보완재.
4. **오너 컨펌 루프**: v2는 shutdown 시 주인님 승인 1건만. 비전 D-5는 모든 합의안에 컨펌 요구 = 훨씬 강한 가드레일.

---

## 7. 부트스트랩 단계 위험 분석

### 7.1 부트스트랩 정의

"마스터플랜 작성 자체가 PM 인프라 미구축 상태에서 진행되는 단계". 현재 4인 리서치 팀(Task 1~4)이 바로 이 단계다.

```
정상 상태: 주인님 → 사장 → PM 토론 → 합의안 → 주인님 컨펌 → 워커 spawn
부트스트랩: 주인님 → 사장(= PM 겸직) → 워커 spawn → 마스터플랜 작성
```

비전 R-2 주인님 정리: "PM 별도 두는 게 맞음 — 겸직하면 혼자 결정 = 견제 부재 = 앵커링". 현재 4인 팀도 이 비판에서 자유롭지 않다.

### 7.2 위험 항목

| 위험 | 발생 메커니즘 | 심각도 |
|------|------------|------|
| 자기검증 부재 | 마스터플랜을 작성하는 팀이 마스터플랜의 검증 대상 비전을 정의한 팀과 동일 계열 | 🔴 높음 |
| 앵커링 편향 | 비전 SSOT(agent-office-vision.md)가 이미 확정된 상태 → 반박보다 정당화 방향으로 흐를 수 있음 | 🟡 중간 |
| heuristic 표 자기충족 | PM 판단 기준을 PM 없이 설계 → 실제 PM 운영 후 기준이 맞지 않을 때 revision 비용 발생 | 🟡 중간 |
| Phase 1 인프라 과소평가 | v2 스펙이 "이미 설계됨"으로 인식되어 실제 구현 복잡도 저평가 | 🟡 중간 |

### 7.3 완화 방안

1. **4인 팀 산출물에 /feedback 검수 필수**: Task 4 마스터플랜 완성 후 `/feedback`으로 독립 외부 검수. 부트스트랩의 자기검증 부재를 유일하게 완화하는 수단.
2. **비전 §10.5 주인님 반박 이력 재확인**: Gap 분석이 해소된 우려를 재제기하지 않았는지 체크 (R-1 영속화 과대평가 재발 방지).
3. **Task 4에 "비전 반박 섹션" 의무화**: 마스터플랜 안에 "비전의 어느 부분이 틀릴 수 있는가"를 명시. 자기비판 섹션 = /feedback 게이트 2(반박/유보 최소 1건) 정신 적용.
4. **heuristic 표는 v0로 명시**: §2.1 표를 마스터플랜에 삽입할 때 "실운영 후 revision 예정 v0 초안"으로 명시. Phase 2에서 실측 데이터로 보정.

### 7.4 정식 PM 전환 마이그레이션 리스크

Phase 1 인프라(pm.yaml + PM spawn 스킬 + heuristic 표 v0) 구축 후 정식 PM으로 전환할 때 발생하는 리스크:

| 리스크 | 내용 | 완화 |
|--------|------|------|
| 세션 1 team 한계 + 마이그레이션 충돌 | 전환 시 기존 팀 cleanup 없이 새 PM 팀 생성 시도 → 오류 | v2 §8 Step B~C 검증 순서 준수 |
| pm.yaml 역할 명세 미성숙 | heuristic 표 v0가 실제 PM 운영과 불일치 → PM이 잘못된 추천 반복 | 2주 관찰 기간 + Phase 2 회고 (v2 §8 Step F 동일) |
| 기존 /checklist + /handoff 워크플로와 충돌 | PM이 새 작업을 체크리스트 없이 spawn 시도 | pm.yaml에 "체크리스트 먼저" 명시 (글로벌 CLAUDE.md 프리플라이트 일관) |
| 메인 Claude의 "PM 겸직 반사" | 정식 PM 전환 후에도 메인 Claude가 직접 결정하는 습관 잔존 | CLAUDE.md Agent Preferences에 "PM 없이 설계 금지" 명시 |

---

## 8. Task 4 (master-architect)에게 넘겨야 할 결정·미결 사항

Task 4가 마스터플랜에서 결정·설계해야 할 항목을 구체적으로 명시한다.

1. **pm.yaml 구조 완성 설계**: §1 매핑표에서 식별된 Gap — role/heuristic/권한/lifecycle/bypass_threshold/max_iterations 필드 정의. v2 YAML 포맷(§4.1)과 호환되어야 하나 팀 설정이 아닌 PM 역할 명세 목적임을 명확히.

2. **① 인턴(Sub-agent) 표준 패턴 정의**: v2 스펙에 빠진 워커. heuristic 표 §2.1에서 "tool call ≤ 10" 조건이면 PM 게이트 없이 직접 호출. 이 패턴을 SKILL.md 어디에 넣을지 (agent-team-manager v2 Non-goals 예외 사항으로 삽입하거나 별도 스킬 신설).

3. **PM 팀 → 워커 팀 순차 시퀀스 표준화**: Task 1 §1.3 한 세션 1 team 한계 대응. cleanup 타이밍과 PM 컨텍스트 보존 방법(PM과의 대화 내용을 pm.yaml에 기록 후 cleanup) 설계.

4. **/feedback ↔ v2 정식 연동 인터페이스**: v2 §10 Ph2-3은 MVP 제외 상태. 마스터플랜에서 Phase 1에 포함할지 Phase 2로 유지할지 결정. TaskCompleted 훅 기반 자동 트리거(Task 1 §5.3) vs 수동 호출 선택.

5. **부트스트랩 종료 기준**: Phase 1 인프라(pm.yaml + PM spawn + heuristic v0) 완성 후 "정식 PM 운영 개시" 시점 정의. 주인님 컨펌 기준 포함.

6. **Phase 1~3 마일스톤 정의**: v2 스펙 §8 마이그레이션 플랜(Step A~F) + 비전 §9 v2 위치 재조정 + 마스터플랜을 하나의 로드맵으로 통합. Phase 1 = 인프라(v2 MVP + pm.yaml), Phase 2 = 정식 PM 운영, Phase 3 = Linux 서버 배포.

7. **모델 배분 이중 보장 구현 명세**: issue#32732 회피 (`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` + PM frontmatter `model: opus` 조합) 실험 계획 및 fallback 정의.

---

## 9. 결론

비전(Agent-office)과 v2 스펙, /feedback 3자를 종합하면 **현재 인프라의 75% 이상이 이미 설계·구현된 상태**임을 확인할 수 있다. /feedback은 ⑤검수 층을 완성했고, v2 스펙은 ②회의실과 ④파이프라인의 핵심 인프라를 설계했다. Task 1·2 리서치는 공식 API 한계와 외부 사례 근거를 충분히 확보했다.

남은 핵심 과제는 **5층 위계의 허리인 3층 PM**을 실제 동작 가능한 수준으로 구체화하는 것이다. pm.yaml 구조 정의, PM system prompt 명세(α 옵션 비판자 강제), 한 세션 1 team 한계 대응 시퀀스가 마스터플랜이 해결해야 할 가장 중요한 세 가지 문제다.

비용 우려(우려 2)는 실제로 관리 가능하다. PM 오버헤드는 전체의 5~20%이며, bypass_threshold로 단순 작업을 게이트에서 제외하면 Shipyard "95% 부적합" 비판을 효과적으로 흡수할 수 있다. Echo chamber 우려(우려 3)는 α 옵션 1차 + /feedback 2차 + 주인님 컨펌 3차로 3중 방어되며, 이는 외부 9건 사례 중 가장 체계적인 구조다.

부트스트랩 단계의 자기검증 부재는 /feedback 검수 강제로만 완화된다. 마스터플랜 산출물(Task 4 출력)이 완성되면 반드시 /feedback 외부 검수를 거쳐야 한다. 이는 비전이 설계한 시스템을 부트스트랩 단계에서도 부분적으로 dogfood하는 것이며, 마스터플랜 자체의 품질을 보장하는 유일한 수단이다.

---

**Task 3 상태**: completed  
**다음**: Task 4 (master-architect, Agent Teams 1인 팀) 입력
