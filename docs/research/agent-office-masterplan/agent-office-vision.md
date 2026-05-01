---
title: Agent-office 비전 (마스터플랜 #010 4인 리서치 입력 자료)
type: research
status: active
created: 2026-05-01
updated: 2026-05-01
related_code: []
related_docs:
  - docs/research/agent-team-skill-redesign/04_redesign-spec.md
  - docs/research/agent-team-skill-redesign/02_community-patterns.md
  - skills/feedback/SKILL.md
---

# Agent-office 비전

> 본 문서는 Day 17 후속3·후속4 turn (2026-05-01) 의 주인님 ↔ 메인 Claude 토론으로 정리된 비전 SSOT.
> 마스터플랜 #010 4인 리서치 팀의 **입력 자료**. 4인 팀은 이 문서를 출발점으로 깊이 리서치 + 마스터플랜 작성.

---

## 1. 한 줄 요약

> **프로젝트마다 영속 PM 에이전트를 두고, PM 이 작업 분석 후 4가지 실행 방식 (Sub-agent / Agent Teams / 외부 CLI / 파이프라인) 중 동적으로 선택하여 워커를 호출. 작업 완료 후 /feedback 으로 객관 검수. 모든 결정은 주인님 컨펌이 최종.**

비유: **회사 + 컨베이어벨트**. 오너(주인님) 가 사장(메인 Claude) 에 지시 → 사장이 부장(PM) 과 토론 → 부장이 작업 성격에 맞는 일 시키는 방법 골라서 워커 호출 → 검수팀 거쳐 → 오너에게 최종 보고.

---

## 2. 5층 위계

```
[1층] 주인님 (오너 / 최종 결정권자)
   ↑ 컨펌 / 최종 검수
   │
[2층] 사장 (메인 Claude, Opus)              ← 코치 / 총괄
   ↕ 1:1 양방향 토론
[3층] 부장 (PM, Opus, Agent Teams 1인 팀)   ← 비판자 + 동적 선택자
   ↓ 합의 후 spawn
[4층] 워커들 (4갈래 동적 선택)
   ┌───────────────┬───────────────┬───────────────┬──────────────────┐
   ① 인턴          ② 회의실        ③ 외부 CLI      ④ 파이프라인
   (Sub-agent)     (Agent Teams)   (Codex/Gemini)  (zircote 7패턴)
   Sonnet          Sonnet          별도 모델       Sonnet
   ↓ 작업 완료
[5층] 검수 (/feedback)                       ← 호출·해석 = Opus / 검증 = 외부 CLI
   ↑ 결과 보고
[1층] 주인님 (최종 검수)
```

### 층별 책임

| 층 | 역할 | 모델 | 핵심 책임 |
|----|------|------|----------|
| 1 | 오너 (주인님) | — (사람) | 지시 / 컨펌 / 최종 검수 |
| 2 | 사장 (메인 Claude) | **Opus** | 주인님 의도 받음 → PM 과 토론 → 합의안 보고 |
| 3 | 부장 (PM) | **Opus** | 사장 결정에 **반박부터** + 워커 동적 선택 |
| 4-① | 인턴 (Sub-agent) | **Sonnet** | 단발 자료조사 / 탐색 |
| 4-② | 회의실 (Agent Teams 멀티) | **Sonnet** | 협업 작업 (병렬·순차) |
| 4-③ | 외부 CLI | Codex / Gemini | 다른 모델 시각 / 외부 검증 |
| 4-④ | 파이프라인 (zircote 7패턴) | **Sonnet** | 단계별 순차 (Pipeline / Swarm / Research+Impl / Plan-Approval / Multi-File / RLM / Parallel Specialists) |
| 5 | 검수 (/feedback) | 호출·해석 = Opus / 검증 = 외부 CLI | 객관 검증 (앵커링 회피) |

---

## 3. 워크플로

```
[1] 주인님 지시
    ↓
[2] 사장 + 부장 토론 (1:1 양방향)
    - 부장이 사장 제안에 1차로 반박
    - 동의는 반박 후 그래도 OK 일 때만
    - 부장이 4가지 워커 방식 중 추천
    ↓
[3] 합의안 도출 → 주인님께 보고
    ↓
[4] 주인님 컨펌
    ├─ 컨펌 OK → [5] 진행
    └─ 거부 → [2] 다시 토론
    ↓
[5] 워커 spawn (PM 이 ①②③④ 동적 선택)
    ↓
[6] 작업 완료
    ↓
[7] /feedback 검수 (단발 / 객관 / 외부 CLI 호출)
    ↓
[8] 주인님께 최종 결과 보고
```

> **주인님 컨펌 = 글로벌 CLAUDE.md "허락 받고 진행" + `/checklist` 승인 규칙과 일관**. Agent-office 도 같은 패턴.

---

## 4. 4가지 워커 — 동적 선택 기준

### ① 인턴 (Sub-agent) — 단발 / 격리 / 자료조사

- **언제 쓰나**: 단순 리서치 / 탐색 / Read-only 작업 / 컨텍스트 격리 필요
- **장점**: 메인 Claude 컨텍스트 보호, 빠름, 비용 ↓
- **단점**: 양방향 대화 X, 한 번 끝나면 사라짐
- **메커니즘**: `Agent` tool 직접 호출 (subagent_type=Explore/general-purpose)

### ② 회의실 (Agent Teams 멀티) — 협업

- **언제 쓰나**: 여러 명 협업 / 병렬 리뷰 / 의존 관계 있는 단계별 작업
- **장점**: SendMessage 양방향, 멀티 worker 협업, lead 가 조율
- **단점**: 셋업 비용 (TeamCreate + spawn + task), `/resume` 불가
- **메커니즘**: `TeamCreate` + `TaskCreate` + `Agent(team_name=...)` + `SendMessage`

### ③ 외부 CLI (Codex / Gemini) — 다른 시각

- **언제 쓰나**: 검증 / 다른 모델 시각 / Echo chamber 회피
- **장점**: 진짜 다른 모델 (Claude 가 아님) → 다양성
- **단점**: 인코딩 / 격리 디렉토리 / 5게이트 절차 (Day 7~14 시행착오)
- **메커니즘**: `/feedback` 헬퍼 라이브러리 (`run-codex.ps1` / `run-gemini.ps1` / `_encoding.ps1`) 활용

### ④ 파이프라인 (zircote 7패턴) — 단계별 순차

- **언제 쓰나**: 단계 의존성 + 명확한 fan-out/fan-in 구조
- **출처**: `zircote/claude-team-orchestration` (`02_community-patterns.md` §1#3, §5)
- **7가지 패턴**:
  1. **Parallel Specialists** — 여러 전문가 동시 검토
  2. **Pipeline** — 순차 단계 (research → plan → impl → test → review) + `addBlockedBy` 체인
  3. **Swarm** — 같은 작업 N개 병렬
  4. **Research + Implementation** — 탐색 후 구현 (phase gate)
  5. **Plan Approval** — 승인 게이트 (고위험 변경)
  6. **Multi-File Refactoring** — fan-in 집계
  7. **RLM (Recursive Language Model)** — 컨텍스트 초과 파일 분석
- **메커니즘**: ② Agent Teams + `TaskUpdate(addBlockedBy=...)` 체인 조합

---

## 5. 영속화 (확정안)

> **주인님 정리** (Day 17 후속4): "yaml 이 영속이 된다기보다는 매 세션마다 본인이 PM 롤이라는 것만 인지하는 수준일 거잖아. 히스토리는 필요하면 알아서 볼 테고 너가 보라고 할 수도 있고. 영속성 문제는 딱히 없다고 보는데."

### 정리

```
영속화 ≠ 세션 컨텍스트 유지
영속화 = 외부 자산 영속 (메인 Claude 와 동일 패턴)
```

- 메인 Claude 도 매 세션 새로 시작 → CLAUDE.md 읽고 "내 역할" 인지 → 필요 시 `docs/history/` / `memory/` 읽음
- PM 도 똑같음 → `pm.yaml` 읽고 "내 역할 = PM" 인지 → 필요 시 history / 결정 log 읽음 (사장이 보라고 하거나 본인이 알아서)

### 영속 자산 (프로젝트별)

| 자산 | 용도 |
|------|------|
| `CLAUDE.md` | 메인 Claude 가 프로젝트 파악 (기존) |
| `pm.yaml` (신규) | PM 역할 명세 (system prompt + heuristic 표 + 결정 권한) |
| `docs/history/` | 과거 결정·작업 log (필요 시 읽음) |
| `memory/` | 핵심 판단·포인터 (필요 시 읽음) |
| `HANDOFF.md` | 단일 세션 인계 (자동 소멸) |

→ Agent Teams 의 `/resume` 불가 한계는 **영속화 문제와 무관**. yaml + 외부 자산으로 해결.

---

## 6. 결정 D-1 ~ D-5 (확정)

### D-1. PM 메커니즘 = Agent Teams 1인 팀 + 비판자·선택자 두 역할

- 메커니즘: `TeamCreate` → 1인 팀 (members = [PM]) → 메인 Claude 가 lead → SendMessage 1:1 양방향
- system prompt 에 **두 역할 강제**:
  - ① **비판자 (devil's advocate)** — 사장 제안에 1차 반박부터. 동의는 그 후
  - ② **동적 선택자** — 작업 분석 후 ①②③④ 중 적합한 거 선택
- R3 (응답 안 함 / 알림 중복) 회피: 1:1 이므로 시스템 알림과 사람 지시 충돌 없음
- 영속화는 §5 정리대로 (yaml + 외부 자산)

### D-2. /feedback 통합 = 옵션 α (그대로 단발 유지) + 헬퍼 라이브러리 공유

- `/feedback` 은 Agent-office 가 호출만, 메커니즘 통합 X
- 사유: **단발성의 본질은 앵커링 회피** — 검증=객관성=fresh 인스턴스
- Agent-office 워커는 영속 (D-3) — 단발성/영속 운영 충돌 방지
- **하부 헬퍼 라이브러리화**: CLI 호출 (`run-codex.ps1`, `run-gemini.ps1`) / 격리 디렉토리 / 인코딩 헬퍼 (`_encoding.ps1`) — 두 스킬이 같은 라이브러리 사용

### D-3. Agent-office 워커 라이프사이클 = persistent (영속)

- preset YAML 에 `lifecycle: ephemeral | persistent` 필드
- **persistent**: 호출 간 컨텍스트 유지 (작업류 — PM, 개발자, 디자이너, 리서처 등)
- **ephemeral**: 매 호출 fresh (검증류 — `/feedback` 식)
- 본질 차이: 검증 = 객관성 (앵커링 방지) / 작업 = 누적 (이전 작업 기억)

### D-4. 모델 배분 정책

- **Opus**: 사장 (메인 Claude), PM (부장), /feedback 호출·해석
- **Sonnet**: ① 인턴, ② 회의실 멤버, ④ 파이프라인 워커
- **외부 모델 (Codex / Gemini)**: ③ 외부 CLI, /feedback 검증 워커
- **근거**: Anthropic 공식 블로그 "토큰 사용량이 quality 분산의 80%" + aws-samples + wshobson 모두 동일 결론
- **비용 효과**: Sonnet ≈ Opus 의 1/5 → 워커 80% 절감
- **구현**: `Agent(model="sonnet")` 명시 + agent frontmatter `model: sonnet`

### D-5. 최종 의사결정권자 = 주인님 (오너)

- 사장 + PM 토론 후 **합의안 → 주인님 컨펌 → 진행**
- 거부 시 다시 토론
- 글로벌 CLAUDE.md "허락 받고 진행" + `/checklist` 승인 규칙과 일관

---

## 7. 우려 사항 + 우선순위 (재정렬)

| # | 우려 | 우선순위 | 대응 |
|---|------|---------|------|
| 1 | **PM 의 동적 선택 판단력** — 잘못 고르면 비용 낭비 | 🔴 최우선 | heuristic 표 + 학습 자료 (4인 리서치 임무) |
| 2 | **2단계 호출 비용** — 가벼운 작업도 PM 거치면 비효율 | 🟡 | 언제 PM 거치고 안 거칠지 기준 정립 (4인 리서치 임무) |
| 3 | **Echo chamber** — 같은 Claude 끼리 yes-man | 🟡 | α 옵션 (system prompt 비판자 강제) + ③ 외부 CLI routinely 호출 |
| 4 | **공식 사례 부족** — "PM 1인 팀 + 동적 선택" 그대로 사례 0건 | 🟢 | 부품은 검증됨 (외부 9건). 통합 형태가 새로움 = 위험 인정 |
| ~~5~~ | ~~PM 영속화~~ | ✅ 해소 | 주인님 정리: yaml + 외부 자산 (메인 Claude 와 동일) |

---

## 8. 마스터플랜 #010 4인 리서치 임무

### 4인 리서치 팀이 깊이 다룰 점 (우선순위 순)

#### 🔴 최우선: PM 의 동적 선택 판단력 (우려 1번)

- PM 이 ①②③④ 중 어떤 걸 고를지 **heuristic 표** 작성
- 외부 사례에서 모델 배분·패턴 선택 기준 추출 (`02_community-patterns.md` §2, §3, §6 활용)
- 잘못된 선택 시 비용 낭비 시뮬레이션 + 가드레일 제안
- **산출물**: `04_masterplan.md` §PM 판단력 절

#### 🟡 다음: 2단계 호출 비용 vs 효과 (우려 2번)

- 언제 PM 거치고 언제 직접 워커 spawn 할지 기준
- 외부 사례에서 "small / medium / large task" 구분 기준 (Anthropic blog scaling heuristic 등)
- 비용 모델 (토큰·시간 추산)
- **산출물**: `04_masterplan.md` §언제 PM 거칠지 절

#### 🟡 그 다음: Echo chamber 회피 (우려 3번)

- α 옵션 (system prompt 비판자 강제) 의 효과 시뮬레이션
- ③ 외부 CLI 통합 빈도 권장 (routinely 호출 / 큰 결정마다 / 검증 시만)
- 다른 페르소나 / 모델 페어링 옵션
- **산출물**: `04_masterplan.md` §Echo chamber 회피 절

### 4인 팀 구성 (잠정 — 체크리스트 v2 에서 확정)

| # | 역할 | 담당 |
|---|------|------|
| 1 | architect-researcher | 공식 docs 깊이 (Agent Teams API / hooks / MCP / `/resume` 한계 / Task isolation) → `01_official-docs-deep.md` |
| 2 | external-pattern-researcher | 외부 사례 재리서치 (revfactory/harness Meta-factory / barkain verifier / oh-my-claudecode 2-runtime / Anthropic blog scaling) → `02_external-deep.md` |
| 3 | office-design-analyst | Gap 분석 (v2 + /feedback + 비전 3자 비교 + 우려 사항 분석) → `03_gap-analysis.md` |
| 4 | master-architect | 마스터플랜 + 마이그레이션 + 요약 → `04_masterplan.md` + `05_migration_plan.md` + `00_요약.md` |

### 4인 팀 입력 (이 문서)

- 본 VISION.md 전체
- 결정 D-1 ~ D-5 (§6)
- 우려 우선순위 (§7)
- 외부 사례 9건 (`02_community-patterns.md`)
- v2 스펙 (`agent-team-skill-redesign/04_redesign-spec.md`) — 마스터플랜의 1층 인프라로 위치 재조정 예정

---

## 9. v2 스펙 위치 재조정

- 기존: `04_redesign-spec.md` 가 agent-team-manager 스킬 v2 단독 스펙
- 신규: 마스터플랜 `05_migration_plan.md` 의 **Phase 1 인프라**로 재위치
- 사유: v2 스펙은 Agent-office 비전의 부분집합 — 처음부터 큰 집 설계도 그리고 1층부터 짓는 게 깔끔
- `.todo.md` #009 (v2 구현) 은 #010 (마스터플랜) 완료 후 위치 재조정 후 진행

---

## 10. 본 turn (Day 17 후속4) 시행착오 — 재발 방지

### 메인 Claude 의 잘못

1. **5-1 후속3 turn HANDOFF.md 에 4가지 동적 선택 명시 안 함** → 본 turn 메인 Claude 가 "4 teammate Agent Teams" 로 좁게 해석. 비전 1/4 만 dogfood.
2. **메모리 `agent-office-vision.md` 에 ④ 파이프라인 누락** (3가지만 적힘) — 주인님이 직접 짚어주심.
3. **5층 위계 / 모델 배분 / D-5 (오너 컨펌)** 모두 메모리·HANDOFF 양쪽에 안 적힘. 주인님이 매번 짚어주셔야 했음.
4. **PM 영속화 우려를 과대평가** — 주인님이 "yaml + 외부 자산" 으로 정리해주심.

### 재발 방지 약속

- **인계서·메모리에 "4가지 워커" 명시 의무** — 3가지 / 4 teammate 로 줄이지 말 것
- **메모리에 5층 위계 다이어그램** 보존 (텍스트로라도)
- **모델 배분 표** 메모리에 명시 (Opus / Sonnet / 외부 CLI 구분)
- **D-결정 표** 메모리 frontmatter 또는 본문 상단 고정
- **§10.5 주인님 반박 이력** 메모리·VISION 양쪽에 보존 — 메인 Claude 가 또 같은 우려 과대평가 방지

---

## 10.5. 주인님이 반박/정리하신 메인 Claude 의견 이력

> **목적**: 메인 Claude 가 제기한 우려·걱정 중 주인님이 직접 반박·정리해서 해소된 항목들. 다음 turn 의 메인 Claude 가 또 같은 우려를 과대평가하지 않도록 보존. 새 우려 제기 전 본 섹션 먼저 확인할 것.

### R-1. PM 영속화 우려 (해소)

- **메인 Claude 우려**: "🔴 PM 영속화 메커니즘이 미해결. Agent Teams 는 `/resume` 불가 = 다음 세션이 어제 PM 의 결정 history 를 어떻게 이어받나? 4인 리서치 #010 의 가장 큰 임무. 이거 못 풀면 영속 PM 골격 무너짐."
- **주인님 반박**: "yaml 이 영속이 된다기보다는 매 세션마다 본인이 PM 롤이라는 것만 인지하는 수준일 거잖아. 마찬가지로 히스토리나 이런 것들이 필요하면 알아서 볼 테고 너가 보라고 할 수도 있고. 영속성 문제는 딱히 없다고 보는데."
- **결과**: 영속화 ≠ 세션 컨텍스트 유지 / 영속화 = 외부 자산 영속 (메인 Claude 와 동일 패턴). §5 정리 채택. 우려 §7 에서 ✅ 해소.
- **다음 turn 메인 Claude 에게**: PM 영속화를 "기술적 난제" 로 다시 제기하지 말 것. 이미 외부 자산 패턴으로 정리됨.

### R-2. PM 별도 vs 메인 Claude 겸직 (옵션 검토 후 별도 채택)

- **메인 Claude 의견**: "PM 별도 두는 게 맞음. 제가 겸직하면 혼자 결정 = 견제 부재 = 앵커링."
- **주인님 정리**: "근데 어차피 너도 그렇고 yaml 이 있어도... 영속성 문제는 딱히 없다 + 한 명 더 있는 게 좋아서 PM 두는 거" — 즉 PM 별도 두기 채택.
- **옵션 α 채택**: PM = Claude (system prompt 비판자 강제). β (외부 CLI) / γ (Claude+외부 CLI 이중) 미채택.
- **다음 turn 메인 Claude 에게**: 메인 Claude 가 PM 겸직 제안하지 말 것. 별도 PM = 주인님 의도 = 견제 효과 핵심.

### R-3. 모델 배분 — Sonnet 으로 워커 가능한가? (확정)

- **메인 Claude 의 잠재 우려**: 워커도 Opus 써야 품질 보장 (구현은 명시적 우려는 아니었지만 기본 가정).
- **주인님 정리**: "결국 지시 모델은 너처럼 상위모델 쓰고 실제 수행하는 애들은 굳이 오퍼스 안 써도 쏘넷 써도 결과물에는 차이 없다는 연구 결과. 비판적 사고나 어떤 전략이나 PM 롤 같은 이거는 최상이 모델 쓰지만 나머지들은 그냥 소넷 써도 되잖아. 토큰값도 절약하고 너가 코치만 잘하면 되니까. 피드백 받거나 이런 거는 최고 모델 써야 하는데."
- **외부 근거**: Anthropic 블로그 "토큰 사용량이 quality 분산의 80%" + aws-samples (Coding/Review=Opus, Devops/SA=Sonnet) + wshobson (Lead/Reviewer=Opus, Implementer=Sonnet default) — 3개 출처 동일 결론.
- **결과**: D-4 모델 배분 확정. 워커 80% 비용 절감.
- **다음 turn 메인 Claude 에게**: "워커도 Opus 써야" 라고 비용 우려 무시하지 말 것. Sonnet 으로 충분.

### R-4. 4가지 동적 선택 — 3가지로 줄이지 말 것 (직접 누락 사례)

- **메인 Claude 누락**: 처음 비전 정리 시 ①Sub-agent / ②Agent Teams / ③외부 CLI **3가지** 만 명시. ④ 파이프라인 빠뜨림.
- **주인님 지적**: "그 다른 깃스타받은 것처럼 파이프라인 대로 일을 진행시킬지? 이거 그 리서치 내용 찾아보삼."
- **확인된 출처**: `02_community-patterns.md` §1#3 zircote/claude-team-orchestration — 7가지 orchestration 패턴 (Pipeline / Parallel Specialists / Swarm / Research+Impl / Plan-Approval / Multi-File / RLM).
- **결과**: ④ 파이프라인 정식 워커로 추가. §4 ④ 에 7패턴 명시.
- **다음 turn 메인 Claude 에게**: 워커 종류 항상 **4가지** 로 명시. 3가지로 줄이지 말 것.

### R-5. 주인님 = 오너 / 최종 컨펌 (직접 누락 사례)

- **메인 Claude 누락**: 처음 비전 정리 시 4층 위계만 그림 (사장/PM/워커/검수). 오너 층 빠뜨림.
- **주인님 지적**: "그리고 어쨌든 항상 PM 이랑 너랑 토론할 거고 결국에는 내 컨펌이 나야 하니까 그렇지?"
- **결과**: 5층 위계로 갱신. D-5 (최종 의사결정권자 = 주인님) 신규 추가. 글로벌 CLAUDE.md "허락 받고 진행" 과 일관.
- **다음 turn 메인 Claude 에게**: 비전 그릴 때 항상 오너 층 포함. 사장이 멋대로 결정하지 말 것.

### 본 섹션 운영 규칙

- **새 우려 제기 전 본 섹션 먼저 확인** — 같은 우려 반복 제기 = 재발
- **새 반박 발생 시 R-N 추가** — 항목 번호 누적 (지우지 말 것, 이력 보존)
- **메모리 `agent-office-vision.md` 에도 동일 보존** — VISION.md 와 1:1 일치 유지

---

## 11. 다음 단계 (체크리스트 v2 에서 처리)

1. **메모리 `agent-office-vision.md` 갱신** — 본 VISION.md 핵심 (5층 위계 + 4가지 워커 + 모델 배분 + D-1~D-5 + 우려 재정렬) 반영
2. **체크리스트 v1 폐기 + v2 재작성** — 본 turn 작업도 PM 컨셉 dogfood (4명 ①①①② + /feedback 마지막)
3. **Phase A 진입** — 4인 리서치 팀 빌딩 (TeamCreate + Task 5건 + Agent spawn + SendMessage)

---

**작성**: 2026-05-01 Day 17 후속4 turn 메인 Claude
**검토**: 주인님 (본 turn 진행 중 직접 정리·수정·확정)
**SSOT**: 본 문서 (마스터플랜 4인 리서치 입력)
