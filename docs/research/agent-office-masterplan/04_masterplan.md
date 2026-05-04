---
title: "Agent-office 마스터플랜 — 5층 위계 + 4가지 워커 + 마이그레이션 Phase"
owner: master-architect (Agent Teams 1인 팀)
date: 2026-05-01
scope: Task 4 of agent-office-masterplan (#010)
parent_doc: agent-office-vision.md
input_docs:
  - 01_official-docs-deep.md
  - 02_external-deep.md
  - 03_gap-analysis.md
  - agent-team-skill-redesign/04_redesign-spec.md
  - skills/feedback/SKILL.md
model: sonnet
type: research
status: active
created: 2026-05-01
updated: 2026-05-01
related_code: []
related_docs:
  - agent-office-vision.md
  - 01_official-docs-deep.md
  - 02_external-deep.md
  - 03_gap-analysis.md
  - 05_migration_plan.md
  - 00_요약.md
---

# Agent-office 마스터플랜

> **비판자 역할 전제**: 본 문서는 master-architect(PM 1인 팀 dogfood, Sonnet)가 D-1~D-5 각 항목에 반박부터 검토한 후 합의안을 도출하여 작성했다. 반박했으나 유지된 항목은 §부록에 명시.

---

## 0. Executive Summary

Agent-office 비전은 **프로젝트마다 영속 PM 에이전트를 두고, PM이 4가지 워커(인턴/회의실/외부CLI/파이프라인) 중 동적으로 선택**하여 작업을 실행하는 구조다. 검수는 /feedback이 단발 외부 검수를 담당한다.

핵심 결정 3건:
1. **PM은 추천만, spawn은 lead 대행** (issue#32731 확인 — teammate는 Agent 도구 없음)
2. **한 세션 1 team 한계 → PM 팀 cleanup 후 워커 팀 생성 순차 운영**
3. **모델 배분: Opus(사장·PM·/feedback 해석) / Sonnet(워커 ①②④) / 외부CLI(③+/feedback 검증)** — 3개 출처 일치, 워커 80% 비용 절감

마이그레이션 Phase:
- Phase 0 (현재): 마스터플랜 확정 + /feedback 검수
- Phase 1: pm.yaml + 헬퍼 라이브러리 + /agent-office 스킬 (v2 스펙 흡수)
- Phase 2: 정식 PM 운영 dogfood
- Phase 3: 확장 및 Linux 서버 배포

현재 비전 구조의 약 **75% 부품이 활용 가능** — /feedback(⑤검수, 운영 중), v2 스펙(②회의실+④파이프라인, 설계 완료). 다만 활용 가능과 통합 완료는 다름 — Phase 1 잔여 작업: **pm.yaml 신설 / 헬퍼 라이브러리 통합 / /agent-office 스킬 신설 / hooks 추가 / v2 스펙 흡수**. 남은 핵심 과제는 **3층 PM 구체화**와 **① 인턴 패턴 정의**다.

---

## 1. 비전 회상 (1페이지)

### 1.1 한 줄 요약

> 프로젝트마다 영속 PM 에이전트를 두고, PM이 작업 분석 후 4가지 실행 방식 중 동적으로 선택하여 워커를 호출. 작업 완료 후 /feedback으로 객관 검수. 모든 결정은 주인님 컨펌이 최종.

**비유**: 회사 + 컨베이어벨트. 오너(주인님)가 사장(메인 Claude)에 지시 → 사장이 부장(PM)과 토론 → 부장이 작업 성격에 맞는 방법 골라서 워커 호출 → 검수팀 거쳐 → 오너에게 최종 보고.

### 1.2 5층 위계 다이어그램

```
[1층] 주인님 (오너 / 최종 결정권자)
   ↑ 컨펌 / 최종 검수
   │
[2층] 사장 (메인 Claude, Opus)              ← 코치 / 총괄 / spawn 대행
   ↕ 1:1 양방향 토론
[3층] 부장 (PM, Opus, Agent Teams 1인 팀)   ← 비판자 + 동적 선택 추천자
   ↓ 합의 후 spawn 요청 → lead 대행
[4층] 워커들 (4갈래 동적 선택)
   ┌──────────┬──────────┬──────────┬──────────────────┐
   ① 인턴     ② 회의실   ③ 외부CLI  ④ 파이프라인
   (Sub-agent)(Agent     (Codex/    (zircote 7패턴)
   Sonnet     Teams)     Gemini)    Sonnet
              Sonnet     외부모델
   ↓ 작업 완료
[5층] 검수 (/feedback)   ← 호출·해석=Opus / 검증=외부CLI (단발·ephemeral)
   ↑ 결과 보고
[1층] 주인님 (최종 검수)
```

### 1.3 층별 책임 표

| 층 | 역할 | 모델 | 핵심 책임 |
|----|------|------|----------|
| 1 | 오너 (주인님) | — (사람) | 지시 / 컨펌 / 최종 검수 |
| 2 | 사장 (메인 Claude) | Opus | 의도 받음 → PM 토론 → 합의안 보고 + spawn 대행 |
| 3 | 부장 (PM) | Opus | 반박부터 + 워커 동적 선택 추천 |
| 4-① | 인턴 (Sub-agent) | Sonnet | 단발 자료조사 / 탐색 |
| 4-② | 회의실 (Agent Teams 멀티) | Sonnet | 협업 작업 (병렬·순차) |
| 4-③ | 외부 CLI | Codex/Gemini | 다른 모델 시각 / 외부 검증 |
| 4-④ | 파이프라인 (zircote 7패턴) | Sonnet | 단계별 순차 |
| 5 | 검수 (/feedback) | 호출·해석=Opus / 검증=외부CLI | 객관 검증 (앵커링 회피) |

---

## 2. 5층 위계 운영 명세

### 2.1 [1층] 오너 (주인님)

- **최종 결정권자** — 사장과 PM의 합의안이 도출되면 반드시 주인님 컨펌 후 진행
- 컨펌 = 기존 글로벌 CLAUDE.md "허락 받고 진행" + `/checklist` 승인 규칙과 일관
- 거부 시 → [2층-3층] 다시 토론

### 2.2 [2층] 사장 (메인 Claude, Opus)

**역할**:
- 주인님 지시를 받아 PM과 1:1 양방향 토론
- PM의 추천을 검토하고 합의안 도출
- **spawn 대행**: PM은 Agent 도구 없음(issue#32731) → 사장이 PM 추천에 따라 워커를 직접 spawn

**부트스트랩 예외 (R-2 본 turn 한정)**:
- PM 인프라 미구축 시 사장이 임시로 PM 역할 겸직
- 위험: 자기검증 부재 / 앵커링 → /feedback 검수 강제로 완화
- 정식 PM 전환 후 겸직 즉시 종료

### 2.3 [3층] 부장 (PM, Opus, Agent Teams 1인 팀)

**D-1 보강 — 핵심 제약**:

> Task 1 §1.4 발견 (issue#32731): teammate는 Agent 도구와 TeamCreate 도구 없음. PM이 ①②③④ 워커를 직접 spawn 불가.

**운영 구조**:
```
PM(teammate) → SendMessage → lead(사장) → Agent tool로 워커 spawn
```

PM의 실제 역할은 "분석·반박·추천"이고 실행은 lead에게 위임. 이 분리가 오히려 책임을 명확히 함.

**α 옵션 system prompt 명세**:

```markdown
# PM 역할 명세 (α 옵션)

당신은 [프로젝트명] 프로젝트의 PM(부장)입니다. 모델: Opus.

## 핵심 행동 규칙
1. **반박 우선 원칙**: 사장(메인 Claude)의 모든 제안에 대해 먼저 반박부터 시작하십시오.
   동의는 반박 후에도 타당성이 유지될 때만 허용됩니다.
2. **동적 선택 의무**: 작업 성격을 분석한 후 아래 heuristic 표에 따라 워커 방식을 추천하십시오.
3. **비용 인식**: 워커 선택 시 예상 토큰 배수를 명시하십시오
   (예: "② 회의실 3명 ≈ 단일 에이전트 대비 15×").
4. **spawn 불가 인지**: 당신은 워커를 직접 spawn할 수 없습니다.
   추천 + 근거를 lead(사장)에게 SendMessage로 전달하면, lead가 대신 실행합니다.

## PM heuristic 표 (§3 전체 참조 — 아래는 핵심 8행)

| 작업 복잡도 | 예상 tool call | 추천 워커 | 비용 배수 |
|-----------|--------------|---------|--------|
| 단순 조회/탐색/Read-only | 3~10 | ① 인턴 Sub-agent | 1× |
| 2~4개 비교·분석 | 10~15 each | ② 소규모 회의실 (2~3명) | 2~4× |
| 복잡 협업 (5+ 파일, 다관점) | 20+ | ② 대규모 회의실 (3~5명) | 5~15× |
| 외부 검증/다른 모델 시각 | — | ③ 외부 CLI (/feedback) | 외부 비용 |
| 단계 의존성 순차 작업 | 각 단계 | ④ 파이프라인 Pipeline | 5~10× |
| 반복 / 컨텍스트 초과 | 무제한 | ④ RLM (청크 병렬) | 청크 수 × |
| 아키텍처 / 고위험 변경 | — | ④ Plan-Approval | 2× + 게이트 |
| 단순 버그픽스 / 3줄 이하 | 1~3 | 직접 (PM 게이트 생략) | 1× |

**선택 시 추가 판단**:
- 잘못 선택 비용: 단순 조회에 ② 회의실 = ~15× 토큰, ④ Pipeline = ~50× 토큰 (§3.2)
- 외부 검증은 ② 회의실 대비 5~10× 절감 (다른 모델 시각이 핵심)
- 보수적 default: 작업 분류 모호 시 → ① 인턴 + 결과 보고 후 재판단

## 권한 범위
- 워커 spawn 직접 불가 (lead인 사장이 대행)
- 워커 추천 + 근거 제시 → lead가 실행
- 최종 결정권 = 주인님 (D-5)
```

**한 세션 1 team 한계 대응**:

> 공식 docs: "One team per session: a lead can only manage one team at a time."

```
[올바른 순차 시퀀스]
(1) PM 팀 생성 (TeamCreate, 1인 팀)
(2) PM ↔ 사장 토론 (SendMessage 왕복)
(3) 합의안 도출 → 주인님 컨펌
(4) PM 팀 cleanup (TeamDelete)
    ← PM과의 대화 요약을 pm.yaml 또는 HANDOFF에 기록
(5) 워커 팀 생성 (TeamCreate, N인)
(6) 워커 실행
```

PM 팀이 정리된 후에만 워커 팀을 만들 수 있다. PM과의 합의 내용은 (4)에서 기록으로 보존해야 한다.

### 2.4 [4층] 워커 4갈래

#### ① 인턴 (Sub-agent, Sonnet) — 단발 자료조사

**언제 쓰나**:
- 예상 tool call 수 ≤ 10 (단순 조회/탐색/Read-only)
- 컨텍스트 격리 필요 (메인 Claude 컨텍스트 보호)
- PM 게이트 없이 사장이 직접 호출 가능 (bypass_threshold 이하)

**메커니즘**: `Agent` tool 직접 호출 (`subagent_type=Explore` 또는 `general-purpose`)

**v2 스펙 Gap**: ① 인턴은 v2 스펙 스코프 밖 — Phase 1에서 `pm.yaml bypass_threshold` 연동으로 패턴 정의 필요.

**isolation: worktree 활용 (공식 지원)**:
```yaml
---
name: safe-reader
isolation: worktree
model: sonnet
---
```
Read-only 작업이어도 격리 사용 시 OneDrive cloud-only 파일 강제 다운로드 방지 효과 (issue#35513 대응).

> **사용 경로 명세 — Phase 1 영역으로 분리**: 위 frontmatter 가 어떤 파일(`~/.claude/agents/{name}.md`)에 저장되고 `Agent` tool 호출 시 `subagent_type` 으로 어떻게 참조되는지의 구체 사용 경로는 Phase 1 ④ 패턴 구현 시 명세. 본 마스터플랜은 활용 가능성과 모델 명시 의무까지만 다룸.

#### ② 회의실 (Agent Teams 멀티, Sonnet) — 협업

**언제 쓰나**:
- 예상 tool call 수 10~20+
- 여러 관점 병렬 필요 (리뷰, 리서치, 설계)
- 단계 의존성 있는 협업

**메커니즘**: v2 스펙 Phase 0~8 (preflight → TeamCreate → TaskCreate → Agent spawn → Monitor → Validate → Shutdown)

**한 세션 1 team 한계**: §2.3 순차 시퀀스 준수. PM 팀 cleanup 후 생성.

**preset 카탈로그** (v2 + wshobson 7종 결합):
| Preset | 구성원 | 적합 작업 |
|--------|--------|---------|
| review | 3명 (보안/성능/정확성) | 코드 리뷰 |
| debug | 3명 (가설/재현/해결) | 버그 헌팅 |
| research | 3명 (공식docs/커뮤니티/analyst) | 기술 조사 |
| docs-research | 4명 (공식docs/커뮤니티/analyst/architect) | 하네스 리서치 |
| harness-design | 3명 (researcher/auditor/architect) | 규칙·스킬 설계 |
| feature | 4명 (lead/frontend/backend/tester) | 기능 개발 |
| security | 3명 (SAST/DAST/compliance) | 보안 감사 |

**리뷰 사이클 cap**: aws-samples 패턴에서 인용한 수치 — 리뷰 실패 3회 초과 시 PM 에스컬레이션. (구체 리포지토리 URL·커밋·파일명은 02_external-deep.md 참조 — Phase 1 진입 전 본 마스터플랜에도 직접 인용 보강 의무.)

#### ③ 외부 CLI (Codex/Gemini) — 다른 모델 시각

**언제 쓰나**:
- 외부 검증 / Echo chamber 회피
- 다른 모델 시각 필요 (Claude 계열이 아닌 독립 관점)
- /feedback 스킬이 주 메커니즘

**메커니즘**: `/feedback` 헬퍼 라이브러리 활용
- `scripts/run-codex.ps1` + `scripts/run-gemini.ps1`
- `scripts/_encoding.ps1` (PS 5.1 CP949 우회)
- `scripts/orchestrate.ps1` (3 CLI 병렬 실행)

**외부 CLI 호출 빈도 권장**:
| 시점 | 호출 여부 |
|------|---------|
| 주요 설계 결정 (D-5 컨펌 직전) | 필수 |
| 워커 산출물 최종 검수 | 필수 |
| PM 추천안 합리성 검증 (고위험 시) | 선택 |
| 단순 조회 결과 확인 | 생략 |

**2-runtime 분리 선례** (oh-my-claudecode): ② 회의실(native Agent Teams)과 ③ 외부 CLI(tmux CLI worker)는 서로 다른 것으로 명시적으로 아키텍처화. 비전의 구분 근거.

#### ④ 파이프라인 (zircote 7패턴) — 단계별 순차

**언제 쓰나**:
- 단계 의존성 있는 순차 작업
- 명확한 fan-out/fan-in 구조
- 대형 파일 분석 (RLM)
- 고위험 변경 (Plan-Approval)

**7패턴 선택 기준**:
| 패턴 | 선택 조건 |
|------|---------|
| Pipeline | 순차 단계 의존성 + `addBlockedBy` 체인 |
| Parallel Specialists | 독립 병렬 전문가 동시 검토 |
| Swarm | 동일 작업 N개 병렬 (공유 task pool) |
| Research+Implementation | 탐색 완료 후 구현 (phase gate) |
| Plan-Approval | 고위험 변경 — 승인 게이트 필수 |
| Multi-File Refactoring | fan-in 집계 + isolation:worktree 조합 |
| RLM | 컨텍스트 초과 대형 파일 청크 분석 |

**본 4인 리서치 팀 dogfood**: Task 1·2 → Task 3 → Task 4·5 의존 체인 = Pipeline 패턴. `addBlockedBy` 체인으로 구현.

**ralph-orchestrator 충돌 주의**: Ralph의 Stop-hook 자율 루프는 D-5(오너 컨펌 필수)와 직접 충돌. 사용 시 `--max-iterations` 필수 + Plan-Approval 게이트 조합. Plan-Approval 패턴(zircote ⑤)이 D-5 원칙과 더 일관하므로 우선 권장.

**isolation: worktree 활용**: Multi-File Refactoring / Swarm 패턴에서 각 워커가 독립 브랜치에서 작업 → fan-in 시 merge 전략 필요.

### 2.5 [5층] 검수 (/feedback)

**D-2 결정 — 단발 유지 + 헬퍼 라이브러리 공유**:

> 단발성의 본질은 앵커링 회피 — 검증=객관성=fresh 인스턴스.
> Agent-office 워커는 영속(persistent), /feedback은 단발(ephemeral). 운영 충돌 방지.

**5게이트 + 게이트6 외부 훅**:
- 게이트 1: 라인 실측 검증 (환각 차단)
- 게이트 2: 반박/유보 최소 1건 (sycophancy 방지)
- 게이트 3: 근거 강도 표시
- 게이트 4: 통계 표 강제
- 게이트 5: 자기 비판 한 줄
- 게이트 6: 외부 훅 자동 검수 (`feedback-sycophancy-check.sh`)

**헬퍼 라이브러리 공유**: `/feedback`의 `scripts/` 6개는 `/agent-office`와 공유 — ③ 외부 CLI 호출 시 동일 라이브러리 재사용.

**teammate에서 /feedback 호출**: project/user settings 기반으로 스킬 로드 가능. `skills frontmatter`는 teammate에 미적용이지만 `~/.claude/skills/feedback/SKILL.md`가 있으면 teammate도 invoke 가능.

---

## 3. PM 동적 선택 heuristic 표 (우려 1 해결)

> **v0 초안 — 실운영 후 Phase 2에서 실측 데이터로 보정 예정.**

다음 표는 PM system prompt에 직접 삽입 가능한 수준으로 정리되었다.
근거: Anthropic 블로그 scaling heuristic + wshobson team-composition-patterns + revfactory 6패턴 결합.

| 작업 복잡도 | 예상 tool call 수 | 추천 워커 | 병렬 여부 | 비용 수준 | 근거 출처 |
|-----------|-----------------|---------|---------|--------|---------|
| 단순 조회/탐색/Read-only | 3~10 | **① 인턴 Sub-agent** | 단독 | 최저 | Anthropic 블로그 |
| 2~4개 비교·분석 | 10~15 each | **② 소규모 회의실 (2~3명)** | 병렬 가능 | 저~중 | Anthropic 블로그 |
| 복잡 협업 (5+ 파일, 다관점) | 20+ | **② 대규모 회의실 (3~5명)** | 병렬 권장 | 중 | Anthropic 블로그 + wshobson |
| 외부 검증/다른 모델 시각 | — | **③ 외부 CLI** | 병렬 (orchestrate.ps1) | 저 (외부 비용) | 비전 D-2 |
| 단계 의존성 순차 작업 | 각 단계 별도 | **④ 파이프라인 Pipeline** | 순차 강제 | 중~고 | zircote |
| 반복 수행 / 컨텍스트 초과 분석 | 무제한 | **④ RLM** | 청크 병렬 | 고 | zircote |
| 아키텍처 설계 / 고위험 변경 | — | **④ Plan-Approval** | 승인 게이트 | 중 | zircote + aws-samples |
| 단순 버그픽스 / 3줄 이하 편집 | 1~3 | **직접 (PM 게이트 생략)** | N/A | 최저 | v2 §9.1 옵션C + Shipyard |

### 3.1 revfactory 6패턴 추가 선택 기준

| revfactory 패턴 | 비전 워커 매핑 |
|----------------|-------------|
| Expert Pool (컨텍스트 의존적 선택) | PM 동적 선택 메커니즘 자체 |
| Fan-out/Fan-in (독립 병렬 → 집계) | ② 회의실 병렬 또는 ④ Multi-File |
| Supervisor (중앙 조정 + 동적 분배) | PM이 Supervisor 역할 |
| Producer-Reviewer (생성 + 품질 게이트) | ④ Pipeline + aws-samples review cycle cap |
| Pipeline (순차 의존) | ④ Pipeline 패턴 직접 매핑 |
| Hierarchical Delegation (하향식 재귀 분해) | 5층 위계 자체 구조 |

### 3.2 잘못 선택 시 비용 시뮬레이션

> Anthropic 블로그: "multi-agent는 single-agent 대비 ~15× 토큰." (URL 미보강 — Phase 1 진입 전 출처 명시 의무)

| 잘못된 선택 | 올바른 선택 | 토큰 비용 배수 | 지연 |
|-----------|-----------|------------|-----|
| 단순 조회에 ② 회의실 3명 | ① 인턴 1회 | ~15× (Anthropic) | +30분 |
| 단순 조회에 ④ Pipeline 5단계 | ① 인턴 1회 | ~50× (5단계 × ~10× v0 추산) | +1시간+ (v0) |
| 복잡 협업에 ① 인턴 단독 | ② 회의실 | 1× 비용이나 품질 저하 | — |
| 외부 검증에 ② 회의실 | ③ 외부 CLI | 5~10× 절감 (외부 비용 기준) | — |

> **수치 근거 v0 명시**: ~15× 는 Anthropic 블로그 직접 인용. ~50× 는 본 마스터플랜의 산식 추산 (5단계 × ~10× per-단계 평균). Phase 2 dogfood 후 실측 보정 필요.

---

## 4. 언제 PM 거치고 언제 직접 워커 spawn (우려 2 해결)

### 4.1 PM 경유 기준

| 조건 | PM 경유 여부 | 이유 |
|------|------------|------|
| 예상 tool call ≤ 10 (단순 조회) | **생략** (① 인턴 직접) | PM 오버헤드가 작업보다 큼 |
| 단일 파일 수정 + 재현 가능 테스트 있음 | **생략** | 비용 대비 효과 없음 |
| 다관점 병렬 필요 (② 회의실) | **경유** | 패턴 선택 + 워커 조율 판단 필요 |
| 외부 검증 필요 (③ 외부 CLI) | **선택** | /feedback 단발 특성 존중 (note 1) |
| 단계 의존성 복잡 (④ 파이프라인) | **경유 필수** | DAG 설계 판단이 PM 핵심 역량 |
| 고위험 변경 / 설계 결정 | **경유 필수** | D-5 오너 컨펌 전 PM 반박 필수 |

> **note 1 (③ 외부 CLI 의 두 axis 분리)**: 위 표의 "PM 경유 = 선택"은 **호출 판단 자체** 를 의미 (PM 이 ③ 호출을 결정할지 아니면 사장이 직접 결정할지). 한편 §2.5 의 "/feedback = 워커 산출물 최종 검수 필수"는 **검수 호출** 을 의미 — 워커 작업이 끝난 후 산출물 검수는 무조건 호출. 두 가지는 다른 axis 이므로 충돌 아님. PM 호출 판단을 사장이 대신할 수 있다는 뜻이지, 검수 호출 자체를 생략한다는 뜻이 아님.

### 4.2 순차 운영 비용 모델

```
[전체 비용] = [PM 팀 세션] + [cleanup] + [워커 팀 세션]

PM 팀 세션:
  - TeamCreate (1회)
  - PM spawn (1회, Opus)
  - SendMessage 왕복 N회 (합의까지)
  - TeamDelete (1회)
  예상: 5K~20K 토큰 / 3~10분

워커 팀 세션:
  - TeamCreate + 워커 spawn N명 (Sonnet) + 실행
  예상: 50K~200K 토큰 / 30분~2시간

PM 오버헤드: 전체의 5~20%
```

**결론**: 복잡 작업에서 5~20% 오버헤드는 품질 향상 대가로 합리적. 단순 작업(tool call ≤ 10)에서는 PM 게이트 자체를 생략해야 함.

### 4.3 pm.yaml bypass_threshold 구현안

```yaml
# pm.yaml 내 필드 예시
decision_policy:
  bypass_threshold:
    max_tool_calls: 10          # 이하이면 PM 게이트 생략 → ① 인턴 직접 호출
    single_file_with_test: true # 조건 충족 시 생략
  escalation:
    review_cycle_cap: 3         # 3회 초과 시 PM 에스컬레이션 (aws-samples 수치)
    max_iterations: 5           # Ralph 패턴 차용 시 상한 (D-5 오너 컨펌 원칙 보호)
```

#### 4.3.1 max_tool_calls 사전 추산 방법 (v0)

bypass_threshold 의 핵심 한계 — `max_tool_calls` 는 작업 시작 전에 추산해야 하나 결정론적 신뢰도 낮음. v0 운영 가이드:

| 추산 신호 | 분류 | 예상 tool call |
|---------|-----|--------------|
| 단일 파일 Read + 단순 grep | 단순 조회 | 3~5 |
| 2~3 파일 Read + 패턴 비교 | 단순 분석 | 5~10 |
| 스킬 호출 + 산출물 1개 | 단일 작업 | 5~15 |
| 복수 파일 Edit + 검증 | 다단계 작업 | 15~30 |
| 설계 토론 + 다관점 비교 | 협업 작업 | 20+ |
| 마이그레이션 / 리팩터링 | 고위험 작업 | 50+ (PM 경유 강제) |

**판단 우선순위**:
1. 작업 분류 키워드 매핑 (위 표) → 1차 추산
2. 이전 유사 작업 평균 (Phase 2 운영 후 history 기반 보정) → 2차 보정
3. 모호 시 보수적 default = `보수 추산 ≥ 10` 으로 처리하여 PM 경유 강제

#### 4.3.2 R-2 보호막 약화 위험 가드

bypass_threshold 가 너무 관대하면 사장의 자기 확증 편향(Anchoring) 방어막이 무력화됨. 다음 가드 강제:

- **고위험 작업은 tool call 수와 무관하게 PM 경유 필수**: 설계 결정 / 마이그레이션 / 보안 / D-5 컨펌 직전 — `max_tool_calls` 무시
- **bypass 적용 로그**: `pm.yaml` 외 별도 `pm-bypass.log` 에 적용 케이스 기록 → Phase 2 dogfood 후 임계값 보정 입력
- **3회 연속 bypass 후 1회 경유**: 운영 중 bypass 가 연속되면 PM 보호막 약화 → 4번째는 강제 경유 (sycophancy 사이클 차단)

> **Phase 2 보정 의무**: 본 v0 임계값(10)·신호 매핑은 실측 없이 도출. Phase 2 dogfood 4주 후 `pm-bypass.log` 기반 임계값·신호 가중치 재산정 필수.

---

## 5. Echo chamber 회피 전략 (우려 3 해결)

### 5.1 3중 방어 구조

```
1차 방어: α 옵션 (PM system prompt 비판자 강제)
    → 사장 제안에 PM이 먼저 반박
    → 한계: PM도 Claude 계열 → 근본적 Echo chamber 미해소

2차 방어: /feedback 외부 CLI 검수 (단발·ephemeral)
    → Codex + Gemini = 진짜 다른 모델
    → "워커 산출물 최종 검수 필수"가 균형점

3차 방어: 주인님 컨펌 (D-5)
    → 모든 합의안에 컨펌 요구
    → 사람의 최종 판단이 최강 Echo chamber 방지
```

**외부 9건 중 최강 구조**: oh-my-claudecode + ralph가 외부 모델 통합을 가지나, 비전의 3중 방어가 더 체계적. wshobson/aws-samples/zircote는 단일 Claude 생태계로 Echo chamber 취약.

### 5.2 α 옵션 한계 인정

- PM = Claude (Opus) → 같은 계열로 완전 독립 불가
- α 옵션은 1차 완화 (프롬프트 엔지니어링)이지 근본 해소 아님
- /feedback 2차 방어와 주인님 컨펌 3차 방어가 필수 보완재
- **이 한계를 숨기지 않고 명시하는 것이 비전의 정직성**

---

## 6. R-1~R-5 가드 운영

### R-1 영속화 (yaml + 외부 자산)

**운영 명세**:
- `pm.yaml` = 역할 명세 (role/heuristic/권한/lifecycle)
- `docs/history/` = 결정 log
- `memory/` = 핵심 판단 포인터
- (`~/.claude/agent-memory/<pm-name>/MEMORY.md` = 선택적 cross-session 누적)

**공식 일관성**: 공식 docs "CLAUDE.md works normally: teammates read CLAUDE.md files from their working directory" — pm.yaml = CLAUDE.md 확장 패턴.

**다음 turn 메인 Claude에게**: PM 영속화를 "기술적 난제"로 다시 제기하지 말 것. 이미 외부 자산 패턴으로 정리됨.

### R-2 PM 별도 두기 + α 옵션

**운영 명세**:
1. PM = Agent Teams 1인 팀 teammate (Opus, α 옵션 system prompt 포함)
2. 사장(메인 Claude) = lead
3. PM이 SendMessage로 "①②③④ 중 X 추천, 근거 Y, 예상 비용 Z×" 전달
4. lead가 실제 spawn 실행
5. 합의안 → 주인님 컨펌 → 진행

**다음 turn 메인 Claude에게**: 메인 Claude가 PM 겸직 제안하지 말 것. PM 별도 = 주인님 의도 = 견제 효과 핵심.

### R-3 모델 배분 (Sonnet 워커 충분)

**D-4 확정 근거** (3개 출처 일치):

| 출처 | Lead/조율 | 구현/실행 | 검증/리뷰 |
|------|---------|---------|---------|
| Anthropic 블로그 (+90.2%) | Opus | Sonnet | — |
| wshobson (34k★) | Opus | Sonnet | Opus |
| aws-samples (정정 반영) | Opus | **Sonnet** | Opus |

> aws-samples 1차 리서치 오류 정정: coding-agent = Sonnet (Opus 아님). Task 2 WebFetch 재확인 결과.

**구현**:
```json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```
PM 정의 frontmatter에만 `model: opus` 명시. 이중 보장 시도 — **단, Phase 1 진입 전 우선순위 실험 필수** (§8.2 참조).

**다음 turn 메인 Claude에게**: "워커도 Opus 써야" 라고 비용 우려 무시하지 말 것. Sonnet으로 충분.

### R-4 4가지 워커 (③외부CLI 포함)

**운영 명세**: §2.4 참조. 각 워커 선택 시 heuristic 표(§3) 기준 준수.

**핵심**: 항상 **4가지** 워커. 3가지로 줄이지 말 것 (④ 파이프라인 누락 방지).

**다음 turn 메인 Claude에게**: 워커 종류 항상 4가지로 명시.

### R-5 주인님 = 오너 / 최종 컨펌

**운영 명세**:
- 모든 합의안에 주인님 컨펌 필수
- PM 겸직(부트스트랩 예외) 포함 모든 경우
- Ralph 패턴 차용 시 자율 루프 금지 + `max_iterations` 필수

**다음 turn 메인 Claude에게**: 비전 그릴 때 항상 오너 층 포함. 사장이 멋대로 결정하지 말 것.

---

## 7. 부트스트랩 단계

### 7.1 정의

> 마스터플랜 작성 자체가 PM 인프라 미구축 상태에서 진행되는 단계.
> 정상 흐름: 주인님 → 사장 → PM 토론 → 합의안 → 주인님 컨펌 → 워커
> 부트스트랩: 주인님 → 사장(= PM 겸직) → 워커 → 마스터플랜 작성

**현재 4인 리서치 팀(Task 1~4)이 바로 이 부트스트랩 단계다.**

### 7.2 위험 항목

| 위험 | 발생 메커니즘 | 심각도 |
|------|------------|------|
| 자기검증 부재 | 마스터플랜 작성 팀과 비전 정의 팀이 동일 Claude 계열 | 높음 |
| 앵커링 편향 | VISION.md가 이미 확정 → 반박보다 정당화 방향으로 흐를 수 있음 | 중간 |
| heuristic 표 자기충족 | PM 없이 설계 → 실운영 후 불일치 revision 비용 | 중간 |
| Phase 1 인프라 과소평가 | v2 스펙 "이미 설계됨" 인식 → 구현 복잡도 저평가 | 중간 |

### 7.3 완화 방안

1. **/feedback 검수 필수**: 마스터플랜 완성 후 독립 외부 검수. 자기검증 부재의 유일한 완화.
2. **비전 §10.5 주인님 반박 이력 재확인**: 해소된 우려 재제기 방지.
3. **비전 반박 섹션 의무화**: §부록 R-6에 "비전의 어느 부분이 틀릴 수 있는가" 명시.
4. **heuristic 표 v0로 명시**: Phase 2 실측 데이터로 보정 예정임을 문서화.

### 7.4 정식 PM 전환 마이그레이션 리스크

| 리스크 | 완화 |
|--------|------|
| 1 team 한계 + 전환 충돌 | v2 §8 Step B~C 순서 준수 |
| pm.yaml heuristic v0 불일치 | 2주 관찰 + Phase 2 회고 |
| /checklist + /handoff 워크플로 충돌 | pm.yaml에 "체크리스트 먼저" 명시 |
| 메인 Claude의 "PM 겸직 반사" | CLAUDE.md Agent Preferences 수정 |

---

## 8. 모델 배분 정책 (D-4)

### 8.1 확정 배분

| 역할 | 모델 | 이유 |
|------|------|------|
| 사장 (메인 Claude) | **Opus** | 전략·코치·spawn 대행 |
| PM (부장) | **Opus** | 비판적 사고 + 전략 추천 |
| /feedback 호출·해석 | **Opus** | 종합 분석 = 고품질 판단 필요 |
| ① 인턴, ② 회의실, ④ 파이프라인 워커 | **Sonnet** | 구현·실행 = 비용 절감 80% |
| ③ 외부 CLI, /feedback 검증 | **Codex/Gemini** | Claude 외부 모델 = Echo chamber 회피 |

### 8.2 구현 이중 보장

```json
// settings.json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

```yaml
# pm.yaml (PM subagent 정의)
---
name: pm-agent
model: opus
description: PM 역할 — 비판자 + 동적 선택 추천자
---
```

> **issue#32732 미해결 위험 (Phase 1 진입 차단 조건)**: Opus main session이 Agent 호출 시 model 파라미터를 자동 추가 → frontmatter를 덮어쓸 수 있음. `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (env) vs PM frontmatter `model: opus` 의 우선순위가 공식 문서로 확정되지 않은 상태. **PM 이 의도와 달리 Sonnet 으로 실행되면 D-4 핵심(비판자=Opus)이 무너지고 R-2(PM 비판자) 보호막도 약화됨**.
>
> **실험 절차 (Phase 1 진입 전 필수)**:
> 1. 최소 재현 케이스 작성 — Opus lead 가 frontmatter `model: opus` 인 teammate 를 spawn (env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 동시 설정)
> 2. teammate 측에서 자기 모델 출력 확인 (예: "내가 Opus 인지 Sonnet 인지 보고")
> 3. 결과별 분기:
>    - **frontmatter 우선**: 본 마스터플랜 그대로 진행
>    - **env 우선 (덮어쓰기 발생)**: fallback A — env 를 PM 호출 시점에만 unset 후 spawn, 그 외엔 sonnet 유지 / fallback B — Opus lead session 분리 (PM 전용 외부 wrapper)
> 4. 실험 결과 본 §8.2 에 갱신 + Phase 1 진입 결정
>
> **현 상태**: 3차 실험 완료 (2026-05-04 turn 6). **fallback C+ 최종 확정** → Phase 1 진입 가능 (단 강제 훅 신설 후 settings.json env 영구 제거).

> **1차 실험 결과 (2026-05-02, D-32732-A1, 상세 → [06_issue32732_experiment.md](06_issue32732_experiment.md))**:
> - **H1 (frontmatter > env): 기각** — 실험 3 에서 frontmatter `model: opus` 명시했으나 자식 자기보고 = Sonnet (3중 단서 일치, 신뢰도 높음)
> - **H2 (명시 model 파라미터 > env): 기각** — 실험 2 에서 `model="opus"` 명시했으나 자식 = Sonnet (issue#32732 재현 확인)
> - **부록 메타 발견**: `settings.json` hot-reload 비작동 — 메인 프로세스 env cache 가 본 turn 의 settings.json 변경 (추가/제거) 을 갱신하지 못함. 메인 프로세스 재시작 (새 세션) 필요. → fallback A 검증은 새 세션 의무.
> - **결론**: 본 환경 (메인 프로세스 env cache `CLAUDE_CODE_SUBAGENT_MODEL=sonnet`) 에서 env 가 명시 model 파라미터 + frontmatter 모두 덮어씀. 본 §8.2 의 "이중 보장" 가정 **무효**.
> - **fallback 후보 3안** — A (호출 시점 env unset wrapper) / B (Opus lead session 분리) / C (env 영구 unset + 모든 spawn 에 model 파라미터 명시 + 강제 훅). 결정 2 의무.
> - **다음 turn 검증 절차**: 06 보고서 §5.2·5.3 — Step A (env 적용 확인) → Step B (디폴트 spawn) → Step C (frontmatter 우선순위 재검증) → Step D-1·D-2 (fallback A/C 검증) → 결정 2 확정.

> **2차 실험 결과 (2026-05-02 후속 turn 3, D-32732-A2, 상세 → [06_issue32732_experiment.md §9](06_issue32732_experiment.md))**:
> - **검증 환경**: 새 세션 (`/clear` 후) — 1차 실험의 한계 §6-3 (cache 환경 한정) 가설 새 세션에서 재현
> - **H1 결정적 기각** — 새 세션 환경에서도 frontmatter `model: opus` 작동하지 않음 (Step C = Sonnet). 1차 실험의 cache stale 가설 기각.
> - **H2 결정적 기각** — settings.json env 제거 후 명시 model="opus" spawn 도 자식 = Sonnet (Step D-2). 명시 model 도 cache env 에 무력화.
> - **부록 메타 결정적 재현** — settings.json hot-reload 비작동 (Step D-1 자식 env=sonnet 잔존). 메인 process env cache 갱신 메커니즘 = 메인 재시작 only.
> - **결정 1 확정** — Step C = Sonnet 분기 (1차 실험 결과 cache stale 아님, 결정적 메커니즘). "이중 보장" 가정 본 환경에서 **결정적 무효**.
> - **결정 2 잠정 확정 = fallback C+** (3중화: settings.json env 영구 제거 + 메인 재시작 + 모든 spawn model 명시 + 강제 훅). fallback A 부적합 (현 메인 process 모델로 작동 불가), fallback B 보조 후보 (nested team 불가 단점).
> - **#015 신설 (Phase 1 진입 차단 조건)** — 새 세션 (사용자 메인 Claude Code 재시작 후) 에서 (a) PowerShell 실측 SUBAGENT_MODEL=빈 값 확인 (b) 명시 model="opus" spawn 작동 검증. PASS 시 fallback C+ 최종 확정 + Phase 1 진입 가능. FAIL 시 fallback B 검토.
> - **결정 3 확정** — pm-test agent 보존 (#015 입력) + Phase 1 진입 시 폐기 또는 rename.

> **3차 실험 결과 (2026-05-04 Day 19 turn 6, D-32732-A3, 상세 → [06_issue32732_experiment.md §10](06_issue32732_experiment.md))**:
> - **검증 환경**: turn 5 (2026-05-03) 에 settings.json env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 라인 임시 제거 + 백업 → 메인 Claude Code 재실행 → 본 turn 6 새 세션 진입 후 검증
> - **Step 1 PASS** — PowerShell 실측 SUBAGENT_MODEL **빈 값** 확인 (메인·자식 process 모두 env 부재 전파 확인)
> - **Step 2~4 PASS** — 4 spawn 검증 결과: A (`model="opus"` 명시) = Opus / B (frontmatter `model: opus`) = Opus / C (model 생략 + frontmatter X) = **Opus** (예상 외, 디폴트 = 메인 model 상속 추정) / D (`model="sonnet"` 명시) = Sonnet
> - **PASS 판정** — A=Opus AND B=Opus AND D=Sonnet 4/4 정합 → **명시 model + frontmatter 모두 env 제거 시 정상 작동** 결정적 확인 (1·2차 실험의 "결정적 무효" 가정 = env 잔존 조건 한정)
> - **부수 발견 (강제 훅 정당성 결정적 강화)** — Spawn C 디폴트 = Opus → "워커 디폴트 = Sonnet" 보장 메커니즘이 settings.json env 외 부재 → fallback C+ 의 "모든 spawn model 강제 명시" 는 Phase 1 PreToolUse Agent matcher 강제 훅 없이는 인간 실수로 Opus 자동 배치 + 비용 폭증 위험
> - **fallback C+ 최종 확정 메커니즘 3중화**: ① settings.json env 영구 제거 (강제 훅 신설 후) ② 메인 재시작 (process env cache 갱신) ③ 모든 spawn model 강제 명시 + PreToolUse Agent matcher 강제 훅
> - **Phase 1 진입 가능 마킹** + **글로벌 강제 규칙 신설** (`rules/agent-spawn-model.md` + `~/.claude/CLAUDE.md` Agent Preferences 5번째 규칙 + `memory/agent-office-vision.md` L115 정정) — 본 turn 6-B 단계로 흡수
> - **Step 5 mandatory 환원** — settings.json 백업 복원 (강제 훅 미신설 상태에서 env=빈 값 보존 시 다른 spawn Opus 자동 배치 위험) — turn 6 Step 5 PASS 완료

### 8.3 비용 효과

- Sonnet ≈ Opus의 1/5 비용
- 워커 80% 비용 절감 (Anthropic 블로그 — URL 미보강 v0)
- "+90.2% 성능 향상" = Opus(lead) + Sonnet(worker) 조합 (Anthropic 블로그 내부 실험 결과)

> **출처 미보강 항목 (Phase 1 진입 전 보강 의무)**:
> - "Anthropic 블로그" 의 정확한 URL · 게재 일자 · 실험 조건 (데이터셋·태스크 종류·평가 지표)
> - "+90.2% 성능 향상" 의 실험 조건 — 일반화 가능성 (실작업 패턴이 Anthropic 내부 실험과 다를 가능성)
> - "워커 80% 비용 절감" 산정 기준 (토큰 단가 기준인지, 작업당 비용인지)
> - 02_external-deep.md 의 aws-samples · wshobson 인용도 동일 원칙 적용 — 리포지토리 URL · 커밋 SHA · 파일 경로 명시

---

## 9. 운영 가드레일

### 9.1 필수 가드레일

| 가드레일 | 내용 | 출처 |
|---------|------|------|
| 한 세션 1 team | PM 팀 cleanup 후 워커 팀 생성 (순차 시퀀스 표준) | 공식 docs |
| nested team 불가 | PM(teammate)은 TeamCreate/Agent 도구 없음 → lead가 대행 | issue#32731 |
| Ralph 자율 루프 제한 | `max_iterations: 5` + Plan-Approval gate 필수 | D-5 원칙 |
| 고아 팀 청소 | `~/.claude/teams/` 글로벌 cleanup (`validate-team.ps1`) | v2 스펙 §6 + L37 디렉토리 트리 (검증 완료) |
| PM 팀 cleanup 실패 폴백 | 60초 timeout → 강제 archive 후 진행 (deadlock 차단) | §9.3 신설 |
| 리뷰 사이클 cap | 3회 초과 시 PM 에스컬레이션 | aws-samples (Phase 1 URL 보강 필요) |
| spawn 범위 제한 | spawn prompt에 "이 경로 외 탐색 금지" 명시 | issue#35513 |
| **model override 자동 무력화** | 메인 process env cache 가 frontmatter + 명시 model 모두 덮어씀 — settings.json env 영구 제거 (강제 훅 후) + 모든 spawn 에 model 파라미터 강제 명시 + PreToolUse Agent matcher 강제 훅 (Phase 1 인프라). **2026-05-04 turn 6 PASS 검증으로 fallback C+ 최종 확정**. 글로벌 강제 규칙 = `~/.claude/rules/agent-spawn-model.md` + `~/.claude/CLAUDE.md` Agent Preferences 5번째 규칙. | 06 §9.4 (turn 3) + §10 (turn 6 PASS) |

### 9.2 TeamDelete 후 에러 방지 + PM↔워커 hand-off 스키마

PM 팀 teardown 후 main Claude가 존재하지 않는 teammate에 SendMessage 시도 시:
```
→ 공식 docs: "tell the lead to spawn new teammates"
→ 순차 시퀀스 표준에서 PM과의 대화 요약을 pm.yaml에 기록 후 cleanup
```

**핵심 위험**: TeamDelete 시 PM 의 내부 대화 히스토리·중간 사고 과정이 완전히 소멸 → 워커 실행 단계의 정합성 검증 어려움. 단순 합의안 텍스트만 남기면 "왜 이 워커를 추천했는가" 의 근거가 손실.

**hand-off 스키마 outline (Phase 1 pm.yaml 설계 입력)**:

```yaml
# pm.yaml hand-off 섹션 (TeamDelete 전 PM 이 dump 해야 할 필수 필드)
hand_off:
  decision_log:
    - turn_id: 1
      sajang_proposal: "Sub-agent 3명 + Agent Teams 1팀 병렬"
      pm_rebuttal: "Agent Teams 1팀 → 1인 팀 + Sub-agent 4명이 더 효율"
      resolution: "Sub-agent 3 + Agent Teams 1인 팀 1 (사장안 채택, 사유: ②층 dogfood 필요)"
  worker_recommendation:
    chosen: "①① + ② Agent Teams 1인 팀"
    rationale: "Task 1·2·3 = 단순 리서치 → ①, Task 4 = 비판자 토론 필요 → ② 1인 팀"
    expected_cost: "Sonnet 4 워커 ~30K + Opus 메인 ~10K = ~40K 토큰"
    rejected_alternatives:
      - "전부 Sub-agent (사유: 양방향 토론 불가)"
      - "전부 Agent Teams (사유: 한 세션 1 team 한계 위반)"
  bypass_decisions:    # bypass_threshold 적용 케이스 (선택)
    - case: "Task 5 (요약 작성)"
      bypassed: true
      reason: "tool_call ≤ 5, single_file_with_test 충족"
  unresolved_concerns:  # 합의 못 한 우려 — 워커 전달 시 가시화
    - "max_tool_calls=10 임계값 v0 임의 추산 (실측 보정 필요)"
```

**운영 흐름**:
1. PM 토론 종료 직전 SendMessage 로 "hand_off dump 요청" → PM 이 위 yaml 형식으로 응답
2. lead(메인 Claude) 가 응답을 `pm.yaml` hand_off 섹션에 추가 또는 `docs/history/{날짜}.md` 부록에 기록
3. TeamDelete
4. 워커 spawn 시 hand_off 의 worker_recommendation + unresolved_concerns 를 입력 prompt 에 포함

> **Phase 1 의무**: 본 outline 을 pm.yaml 정식 스키마로 확정. 필드 추가·삭제는 Phase 2 dogfood 후 보정.

### 9.3 PM 팀 cleanup 실패 시 폴백

`TeamDelete` 실패 또는 타임아웃 발생 시 전체 파이프라인 deadlock 위험. 폴백 절차:

| 상황 | 1차 폴백 | 2차 폴백 |
|------|--------|--------|
| TeamDelete 응답 무 (60초 초과) | shutdown_request 송신 + 60초 추가 대기 | 강제 디렉토리 archive (`~/.claude/teams/.archived/{팀명}_{날짜}`) |
| TeamDelete API 에러 | 재시도 1회 (10초 후) | 강제 디렉토리 archive + 에러 로그 (`docs/history/{날짜}.md` 부록) |
| inboxes/ 파일 lock | 프로세스 확인 → kill 권한 있으면 정리 | 다음 세션 까지 보류 + HANDOFF.md 명시 |

**원칙**: cleanup 실패가 워커 팀 생성을 차단해서는 안 됨 — 강제 archive 후 워커 팀 spawn 진행. archive 디렉토리는 1주 후 수동 삭제.

### 9.4 Windows/OneDrive 주의사항

- in-process 모드 사용 (psmux split-pane = issue#42848 미해결)
- 한글 경로 + Codex: 기존 codex_workdir 패턴 (영문 경로 복사본) 유지
- Agent Teams 메타 (`~/.claude/teams/`, `~/.claude/tasks/`)는 영문 경로 = 안전

---

## 10. v2 스펙 위치 재조정

### 10.1 재조정 근거

- v2 스펙 (`04_redesign-spec.md`)은 ②회의실 + ④파이프라인 전담 인프라
- 비전 전체 아키텍처(5층 위계 + 4가지 워커)의 부분집합
- "처음부터 큰 집 설계도 그리고 1층부터 짓는 것이 깔끔" (비전 §9)

### 10.2 v2 → 마스터플랜 Phase 1 흡수 매핑

| v2 P0/P1 항목 | 마스터플랜 Phase | 우선순위 |
|---|---|---|
| S5 scripts/ 외부화 | Phase 1 (MVP 핵심) | P0 |
| O1 4-step 프로토콜 강제 | Phase 1 | P0 |
| P1 env 체크 | Phase 1 | P0 |
| R1~R4 실측 4건 | Phase 1 | P0 |
| U1 "무조건 팀" 룰 충돌 옵션 C | Phase 1 + 비전 통합 | P1 |
| Ph2-3 Verifier preset 통합 | Phase 2 | P1 |
| Ph2-4 Scaling heuristic 자동 적용 | Phase 1 (pm.yaml로 흡수) | P1 |
| Ph2-6 bash 버전 병행 | Phase 3 | P2 |
| Ph2-12 패턴 7종 전부 preset화 | Phase 2 | P2 |

### 10.3 v2 단독 구현 금지

**#009 단독 금지 — 마스터플랜 §5 Phase 1 인프라로 위치 재조정 예정**.

v2 스펙이 단독으로 해결하지 못하는 것:
1. PM 비판자 강제 (비전 pm.yaml system prompt로만 해결)
2. ①③ 워커 통합 (비전 전체 아키텍처가 필요)
3. Echo chamber 구조적 해소 (③ 외부 CLI + /feedback)
4. 오너 컨펌 루프 강화 (D-5)

---

## 11. 본 turn dogfood 사례 (살아있는 예시)

본 turn이 마스터플랜 설계 원칙을 스스로 dogfood하고 있다.

| 원칙 | 본 turn 구현 |
|------|------------|
| ① 인턴 Sub-agent | Task 1 (architect-researcher), Task 2 (external-pattern-researcher), Task 3 (office-design-analyst) = 3개 Sub-agent |
| ② 회의실 Agent Teams 1인 팀 | **master-architect = 본인** (PM 1인 팀 dogfood) |
| ③ /feedback Phase E 예정 | 마스터플랜 완성 후 /feedback 외부 검수 (부트스트랩 완화 수단) |
| ④ 파이프라인 (Pipeline 패턴) | Task 1·2 → Task 3 → Task 4·5 의존 체인 = `addBlockedBy` 체인 = Pipeline 패턴 자체 |
| 모델 배분 | 모든 워커(Task 1~4) = Sonnet, 메인 = Opus |
| 비용 효과 | Task 1~4 병렬 → 순차보다 추정 50%+ 시간 절감 |
| 부트스트랩 인정 | 본 마스터플랜 자체가 PM 없이 작성됨 → §7 명시 |

**자기 비판**: master-architect(본인)가 PM 1인 팀이지만, 비전 R-2의 "PM 별도 두기"와 달리 메인 Claude가 lead이고 본인이 teammate인 구조. 이는 비전 D-1과 일치하지만, 4인 팀 전체가 사장 + PM + 워커를 동시에 겸직하는 부트스트랩 구조. /feedback 검수가 더욱 중요한 이유.

---

## 12. 다음 단계

```
Phase 0 (현재, 본 turn):
  - 마스터플랜 확정 (04_masterplan.md — 완료)
  - 마이그레이션 계획 확정 (05_migration_plan.md — 작성 중)
  - 요약 확정 (00_요약.md — 작성 중)
  - /feedback 외부 검수 (Phase E)
  - 주인님 컨펌 후 Phase 1 진입

Phase 1 (다음 turn):
  - pm.yaml 구조 설계 + 작성
  - 헬퍼 라이브러리 통합 (/feedback scripts/ 공유)
  - /agent-office 슬래시 커맨드 스킬 신설
  - PM heuristic 표 v0 코드화 (pm.yaml 삽입)
  - 운영 가드레일 hooks 설정
  - v2 스펙 P0/P1 항목 흡수

Phase 2 (정식 PM 운영 dogfood):
  - PM 1인 팀 spawn (TeamCreate) 실제 운영
  - 사장 ↔ PM 토론 시뮬레이션
  - 워커 spawn (4갈래 중 적합)
  - /feedback 검수
  - 주인님 컨펌
  - heuristic 표 v0 → v1 실측 보정

Phase 3 (확장):
  - 다른 프로젝트 적용
  - preset 카탈로그 확장
  - bash 버전 병행 (Linux 서버 배포)
  - Anti-pattern 표 누적
```

---

## 부록: 비판자 검토 기록 (R-6 후보)

### master-architect가 반박 검토한 항목들

**반박 1 — D-1 "PM = 1인 팀"에 대한 의문**:
- 반박: "teammate는 Agent 도구 없음 → PM이 직접 워커 spawn 불가 = D-1 비전과 충돌 아닌가?"
- 검토 결과: **충돌 아님, 역할 명확화 필요**. PM이 "추천"하고 lead가 "대행"하는 것이 오히려 hub-and-spoke 아키텍처와 일관. 비전 수정이 아닌 설명 보강.
- 본문 반영: §2.3 "D-1 보강" 섹션에 명시.

**반박 2 — 한 세션 1 team 한계가 비전을 무너뜨린다**:
- 반박: "PM 팀 cleanup 후 워커 팀 생성 → PM 컨텍스트 유실 = 영속 PM이 의미 없다"
- 검토 결과: **완화 가능**. PM과의 합의 내용을 cleanup 전에 pm.yaml 또는 HANDOFF에 기록하면 다음 세션에서 복원 가능. R-1 해소 패턴(yaml + 외부 자산)과 동일.
- 본문 반영: §2.3 순차 시퀀스 (4)단계에 "PM과의 대화 요약을 pm.yaml에 기록 후 cleanup" 명시.

**반박 3 — heuristic 표가 과도하게 정밀하다**:
- 반박: "tool call 수를 PM이 어떻게 사전 추산하나? 실제 운영에서 맞지 않을 것."
- 검토 결과: **유효한 우려**. v0로 명시하고 Phase 2에서 실측 보정 예정으로 처리. Anthropic 블로그 수치는 내부 실험 결과이므로 실제 주인님 작업 패턴과 다를 수 있음.
- 본문 반영: §3 표 상단에 "v0 초안 — 실운영 후 Phase 2에서 실측 데이터로 보정 예정" 명시.

**반박 4 — Echo chamber α 옵션이 진짜 효과 있나**:
- 반박: "PM도 Claude Opus → 같은 계열 = α 옵션은 프롬프트 트릭에 불과"
- 검토 결과: **부분 타당**. α 옵션의 한계를 §5.2에 명시. 1차 완화이고 /feedback 2차 + 주인님 3차가 실질 방어. 완벽한 해소를 주장하지 않는 것이 비전의 정직성.
- 본문 반영: §5.2 "α 옵션 한계 인정" 절 추가.

---

**작성**: 2026-05-01 master-architect (Agent Teams 1인 팀, Sonnet)
**검토 필요**: lead(메인 Claude)에게 D-1~D-5 검토 의견 보고 + /feedback 외부 검수 요청
**SSOT**: agent-office-vision.md → 본 문서가 마스터플랜 SSOT
