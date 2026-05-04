---
title: "외부 사례 9건 깊이 재리서치 — Agent-office 비전과의 매칭 평가"
owner: external-pattern-researcher
date: 2026-05-01
scope: Task 2 of agent-office-masterplan
parent_doc: agent-office-vision.md
model: sonnet
---

# 외부 사례 9건 깊이 재리서치 — Agent-office 비전과의 매칭 평가

## 0. Executive Summary

- **revfactory/harness** 가 비전과 가장 높은 매칭: L3 Meta-Factory 패턴이 PM 의 동적 선택 메커니즘과 직접 대응하며, 6 아키텍처 패턴은 ② 회의실 + ④ 파이프라인의 세부 선택 기준표로 즉시 차용 가능.
- **Anthropic 공식 블로그**는 D-4 모델 배분의 직접 수치 근거를 제공: 토큰 사용량이 quality 분산의 **80%** + orchestrator(Opus)-worker(Sonnet) 조합에서 **+90.2%** 성능 향상.
- **전체 매칭 사례는 0건** (예상대로). 9건 모두 비전의 부품(워커 선택 / 모델 배분 / 검수 / 파이프라인 패턴 중 일부)에 해당하며, "PM 1인 팀 + 4가지 워커 동적 선택 + 5층 위계" 통합 구조는 어디에도 없음.
- **wshobson/agents** 의 7 preset 카탈로그 + **aws-samples** 의 spec-driven review cycle cap(3회) 은 비전의 ② 회의실 preset + 무한루프 방지 가드레일로 직접 흡수 가능.
- **Ralph Wiggum 패턴**(mikeyobrien + 공식 플러그인)은 ④ 파이프라인의 RLM 변형과 다르며, Stop-hook 루프는 비전의 ④-⑦ RLM 패턴보다 덜 정교하지만 단순 반복 작업에서 실용적.
- **우려 1(PM 판단력)**에 가장 많은 외부 근거 있음: revfactory 6패턴 선택 기준 + Anthropic 블로그 scaling heuristic + wshobson 팀 크기 표가 heuristic 표 초안 재료로 충분.
- **우려 3(Echo chamber)** 에 대해 oh-my-claudecode 의 2-runtime 분리(tmux CLI worker = 진짜 외부 모델) 가 ③ 외부 CLI 설계의 직접 선례.

---

## 1. revfactory/harness — Meta-factory L3

> **URL**: https://github.com/revfactory/harness  
> **Stars**: 2,769 (2026-04-22 기준) → WebFetch 재확인: 수치 미업데이트 (동일 수준 유지)  
> **Last updated**: 2026-04-22

### 핵심 구조

Harness 는 "사용자가 도메인 설명 → 에이전트 팀 구조 자동 생성"하는 **L3 Meta-Factory** 레이어 플러그인. 인접 프로젝트인 Archon(Runtime-Configuration Factory), meta-harness(Codex port)와 다르게, Harness 는 에이전트 팀 **구조 자체**를 설계한다. 영어, 한국어, 일본어 인터페이스 지원.

### 6 아키텍처 패턴 (깊이 분석)

| # | 패턴 | 핵심 메커니즘 | 비전 매핑 |
|---|------|-------------|---------|
| 1 | **Pipeline** | 순차 의존 단계 (A → B → C) | ④ 파이프라인 Pipeline 하위 패턴 |
| 2 | **Fan-out/Fan-in** | 독립 병렬 작업 → 집계 | ④ Multi-File Refactoring / ② 회의실 병렬 |
| 3 | **Expert Pool** | 컨텍스트 의존적 에이전트 선택 | **PM 동적 선택 직접 대응** (우려 1 입력) |
| 4 | **Producer-Reviewer** | 생성 + 품질 게이트 | aws-samples Build→Review 루프와 동일 |
| 5 | **Supervisor** | 중앙 조정자 + 동적 분배 | ③ 부장(PM) 역할의 워커 할당 방식 |
| 6 | **Hierarchical Delegation** | 하향식 재귀적 태스크 분해 | 5층 위계 자체 구조와 이론적 동일 |

### Meta-Factory L3 메커니즘

> "사용자가 도메인 설명 → 팀 구조 자동 생성" 흐름:
> 1. 도메인 입력 수신
> 2. 해당 도메인에 적합한 아키텍처 패턴 선택 (6가지 중)
> 3. 에이전트 정의 파일(`.md` + frontmatter) + 스킬 파일 자동 생성
> 4. **Harness Evolution Mechanism**: 실사용 결과 δ를 피드백 루프로 흡수 → 같은 도메인 반복 요청 시 품질 향상

측정 결과 (author-measured, n=15, third-party 미검증):
- 평균 품질: 49.5 → 79.3 (구조화 사전 설정 효과)
- 태스크 완료율: 100%
- 출력 분산: 32% 감소

### 주인님 레포 가능성

`revfactory` 는 GitHub 사용자명. 주인님의 GitHub ID(`rlgnsday`)와 불일치. **본인 레포가 아닌 것으로 판단**. "한국어 자원, 고품질 영문 출력 생성" 설명과 한국어 인터페이스 지원은 한국 개발자 작품임을 시사하나, 주인님과의 직접 연결은 확인 불가.

### 비전 매칭 평가

- **부분 매칭**:
  - Expert Pool 패턴 → **PM 의 ①②③④ 동적 선택 메커니즘**의 외부 선례 (우려 1 heuristic 표 직접 입력)
  - Supervisor 패턴 → 부장(PM)이 워커를 중앙에서 동적 배분하는 구조
  - Hierarchical Delegation → 5층 위계 자체
  - Harness Evolution Mechanism → 비전 §7 우려 1의 "학습 자료" 로드맵에 해당
- **전체 매칭**: 없음. revfactory 는 팀 구조 자동 **생성**에 특화. 비전의 "작업마다 워커 방식 동적 선택" 과는 추상 수준 다름.
- **상충**: 없음. 보완 관계.

---

## 2. barkain/claude-code-workflow-orchestration — task-completion-verifier

> **URL**: https://github.com/barkain/claude-code-workflow-orchestration  
> **Stars**: 53 (WebFetch 2026-04-26 v2.1.0 기준 업데이트)  
> **Last updated**: 2026-04-26

### 핵심 구조

**Stage 0 (Planning)**: native plan mode 로 태스크 분해 → 의존성 분석 → 전문 에이전트 keyword 매칭 배분.  
**Stage 1 (Execution)**: Subagent 모드(격리 병렬 Agent 인스턴스) vs Team 모드(Native Agent Teams + SendMessage) 중 선택.

특이점: 차단(hard block)이 아닌 **적응형 넛지(silent → hint → warning → strong reminder)** 로 위임을 유도. 위반 카운터는 매 사용자 메시지마다 리셋.

### task-completion-verifier 메커니즘

8개 전문 에이전트 중 하나: "Validation, testing, quality assurance" 전담. 실행 단계 완료 후 검증 단계에서 호출. 구체적으로:
- 태스크 완료 조건 명시적 확인
- 테스트/린팅 통과 여부 체크
- wave 단위 완료 후 review-agent 에 핸드오프 전 최종 게이트

### /feedback (단발 검수) 와의 비교

| 측면 | barkain verifier | 비전 /feedback |
|------|----------------|--------------|
| 생명주기 | 워크플로 내 지속 상주 (persistent) | 단발 호출 (ephemeral) |
| 목적 | 태스크 완료 조건 확인 | 앵커링 회피 + 객관 검증 |
| 호출 시점 | wave 완료 후 자동 | 주인님 또는 PM 이 판단해 수동 |
| 모델 | 지정 미확인 | 호출·해석=Opus / 검증=외부 CLI |
| 독립성 | 같은 Claude 세션 내 | 외부 CLI (진짜 다른 모델) |

핵심 차이: barkain verifier 는 동일 세션 내 "완료 게이트"이고, /feedback 은 앵커링 방지를 위한 **완전 독립** 검증. 비전 D-2 결정의 근거("단발성의 본질은 앵커링 회피")를 반증하지 않고 오히려 뒷받침.

### 비전 매칭 평가

- **부분 매칭**: Stage 0 planning (→ PM 의 사전 분석) + Stage 1 Subagent vs Team 이분 선택 (→ ① 인턴 vs ② 회의실 선택 기준과 동형)
- **상충**: verifier 의 persistent 상주 방식 vs /feedback 의 ephemeral 단발. 비전 D-3 결정(검증류=ephemeral)과 직접 충돌 → 그러나 이는 비전이 의도적으로 선택한 차이점.

---

## 3. Yeachan-Heo/oh-my-claudecode — 2-runtime CHANGELOG 최신

> **URL**: https://github.com/Yeachan-Heo/oh-my-claudecode  
> **Stars**: 32,200 (WebFetch 확인, 1차 리서치 30,667 대비 증가)  
> **Latest**: v4.13.5 (2026-04-28)

### v4.13.x 최신 변경사항 (실측)

| 버전 | 변경 | 비전 관련성 |
|------|------|-----------|
| v4.13.5 | ghost session 최종 정리 (abnormal shutdown 후 cleanup 보장) | 비전 워커 라이프사이클 D-3 의 termination 설계 참고 |
| v4.13.4 | `omc team` 으로 legacy `/omc-teams` 라우팅 | ③ 외부 CLI 호출 인터페이스 설계 참고 |
| v4.13.3 | autopilot false-positive 패치 (Ralph mode 루프 종료 강화) | ④ RLM 패턴 무한루프 방지 가드레일 참고 |
| v4.13.1 | **cursor-agent 를 4번째 tmux worker 로 추가** (codex/gemini/claude 에 이어) | ③ 외부 CLI 확장 선례 |
| v4.13.2 | ghost session fix: cross-session cancel 시 local state 없는 경우 Ralph session 정리 | D-3 persistent 워커의 비정상 종료 처리 |

### /team vs /omc-teams 2-runtime 분리 모델

```
/team        = native Claude Code in-session workflow (canonical)
omc team     = terminal-spawned tmux CLI workers (codex/gemini/claude/cursor-agent panes)
/omc-teams   = legacy compatibility skill (→ omc team 으로 라우팅)
```

이 분리가 비전의 **② 회의실 (native Agent Teams) vs ③ 외부 CLI (Codex/Gemini)** 구분의 직접 선례. oh-my-claudecode 는 "둘은 다른 것"임을 명시적으로 아키텍처화한 유일한 대형 사례.

### Error Reference 테이블 (비전 가드레일 차용 후보)

| 에러 | 원인 | 해결책 | 비전 적용 |
|------|------|--------|---------|
| `not inside tmux` | tmux 세션 외부에서 omc team 호출 | tmux 환경 체크 Phase 0 | ③ 외부 CLI 프리플라이트 |
| `cmux surface detected` | cmux 환경 충돌 | 표준 tmux 사용 | 환경 검증 |
| `Unsupported agent type` | 지원하지 않는 worker 지정 | worker 목록 확인 | ① ② ③ ④ 타입 검증 |
| `Team <name> is not running` | 팀 존재하지 않는 상태에서 메시지 | TeamCreate 먼저 | ② 회의실 lifecycle |
| `status: failed` | 워커 실패 | 로그 확인 후 재spawn | D-3 persistent 오류 복구 |

### 비전 매칭 평가

- **부분 매칭**:
  - 2-runtime 분리 → **② 회의실 vs ③ 외부 CLI 아키텍처 분리의 가장 직접적인 선례**
  - Error Reference 테이블 → 비전 운영 가드레일에 직접 차용 가능
  - cursor-agent 4번째 worker 추가 이력 → ③ 외부 CLI 확장 경로 참고 (Cursor 추가 가능성)
- **상충**: swarm keyword 완전 제거 → 비전 ④ Swarm 패턴 사용 시 oh-my-claudecode 와의 통합 불가. 그러나 비전은 oh-my-claudecode 를 직접 사용하지 않으므로 실질 충돌 없음.

---

## 4. zircote/claude-team-orchestration — 7 패턴 SKILL

> **URL**: https://github.com/zircote/claude-team-orchestration  
> **Stars**: 3 (신생)  
> **Last updated**: 2026-02-11 (v1.2.1, WebFetch 확인)

> **중요**: 이 레포는 비전 §4 ④ 파이프라인의 **직접 출처**. 7패턴 코드화 방식 깊이 분석.

### 7 패턴 — SKILL 구현 방식

각 패턴이 `swarm:` namespace 하위 독립 SKILL 로 제공됨. 메커니즘 상세:

| 패턴 | SKILL 호출 흐름 | 비전 ④ 매핑 |
|------|--------------|-----------|
| **Parallel Specialists** | TeamCreate → N명 동시 spawn → 각자 독립 분석 | ④-①  Parallel Specialists |
| **Pipeline** | TaskCreate N개 → `TaskUpdate(addBlockedBy=[prev])` 체인 → 폴링으로 unblocked 클레임 | ④-② Pipeline |
| **Swarm** | 공유 task pool → 워커 자율 클레임 | ④-③ Swarm |
| **Research + Implementation** | Phase 1 종료 확인 → Phase 2 spawn (phase gate) | ④-④ Research+Impl |
| **Plan Approval** | `plan_mode_required=true` spawn → `ExitPlanMode` → lead 가 approve/reject | ④-⑤ Plan-Approval |
| **Multi-File Refactoring** | fan-in 집계 + RLM chunking 조합 | ④-⑥ Multi-File |
| **RLM** | arXiv:2512.24601 참조, 대형 파일 청크 분할 분석 | ④-⑦ RLM |

### TaskUpdate addBlockedBy 실제 사용 패턴

```javascript
// Pipeline 패턴 예시 (zircote SKILL 의사코드)
const t1 = TaskCreate({ title: "Research" });
const t2 = TaskCreate({ title: "Plan" });
const t3 = TaskCreate({ title: "Implement" });
const t4 = TaskCreate({ title: "Review" });

// 의존 체인 설정
TaskUpdate(t2.id, { addBlockedBy: [t1.id] });
TaskUpdate(t3.id, { addBlockedBy: [t2.id] });
TaskUpdate(t4.id, { addBlockedBy: [t3.id] });
// → worker 들이 TaskList 폴링, unblocked 상태인 태스크만 클레임
```

**본 4인 리서치 팀의 Task 의존 구조**(Task 1,2 → Task 3 → Task 4,5)가 이 패턴과 그대로 매칭. 즉, 4인 팀 자체가 Pipeline 패턴 dogfood.

### 9개 모듈식 SKILL (swarm: namespace)

`Orchestrating` / `Team Management` / `Task System` / `Messaging` / `Agent Types` / `Spawn Backends` / `Error Handling` / `RLM Pattern` / `JSONL Log Analyzer`

Spawn Backends 가 tmux / iTerm2 / in-process 3종을 지원해 oh-my-claudecode 의 2-runtime 분리와 보완 관계.

### 비전 매칭 평가

- **부분 매칭**:
  - **7패턴 전체 → 비전 ④ 파이프라인의 하위 선택 메뉴** (가장 직접적인 출처)
  - Pipeline + addBlockedBy → 비전 ④-② 의 구체 구현 방법
  - Plan Approval Gate → 비전 D-5 (주인님 컨펌) 의 기술적 구현체 후보
- **상충**: 없음. 비전이 이 레포를 ④ 출처로 명시 채택.
- **주의**: v1.2.1 이후 (2026-02-11) 업데이트 없음. 실험적 API 변경 시 패턴 코드 깨질 수 있음 → 실 구현 전 API 호환 재확인 필요.

---

## 5. Anthropic 공식 엔지니어링 블로그

> **URL**: https://www.anthropic.com/engineering/multi-agent-research-system  
> **Date**: 2025-06-13 (authors: Jeremy Hadfield 외 5명)

### 핵심 수치 (직접 인용)

**토큰 사용량 = quality 분산의 80%**
> "Three factors explained 95% of performance variance in BrowseComp evaluation: token usage (80%), tool calls and model choice (remaining 15%)."

→ 비전 D-4 모델 배분의 **직접 수치 근거**: 모델 선택보다 토큰 양(=워커 수·병렬성)이 더 중요. Sonnet 워커 다수 운용이 Opus 소수보다 효과적.

**orchestrator-worker +90.2% 성능 향상**
> "90.2% improvement over single-agent Claude Opus 4 when using Claude Opus 4 as lead agent with Claude Sonnet 4 subagents"

→ D-4 에서 Opus(PM/사장) + Sonnet(워커) 조합의 **직접 실험 근거**.

**Sonnet 업그레이드 > 토큰 2배**
> "upgrading to Claude Sonnet 4 is a larger performance gain than doubling the token budget on Claude Sonnet 3.7"

→ 모델 세대 업그레이드가 예산 투입보다 효과적. 워커를 최신 Sonnet 으로 유지할 근거.

### Scaling Heuristic (PM 판단력 직접 입력)

| 복잡도 | 에이전트 수 | tool call 수 | 비전 워커 매핑 |
|--------|----------|------------|-------------|
| Simple fact-finding | 1 agent | 3-10 calls | ① 인턴 Sub-agent |
| Direct comparisons | 2-4 subagents | 10-15 calls each | ② 회의실 소규모 |
| Complex research | 10+ subagents | 분산 | ② 회의실 대규모 / ④ Parallel |

→ **우려 1(PM 동적 선택 판단력)의 heuristic 표 초안 재료**. PM system prompt 에 위 기준 직접 삽입 가능.

### "Think Like Your Agents" 원칙

> 프롬프트를 Console 에서 시뮬레이션 → 실패 모드 사전 발견 → 반복 최적화.

→ 비전 PM system prompt 작성 시 적용 원칙: PM 이 각 워커를 어떻게 "경험하는지" 시뮬레이션해서 지시 문구 최적화.

### Resumable Checkpoint

> "Agents require resumable checkpoints — the system stores research plans in memory before context limits (200,000 tokens) to prevent state loss."

→ 비전 §5 영속화와 연결: 외부 자산(memory/, docs/history/)에 계획 저장 = Anthropic 공식 권장 패턴과 일치.

### 비전 매칭 평가

- **부분 매칭**:
  - 토큰 80% 수치 → D-4 모델 배분의 수치 근거 (가장 강력한 외부 근거)
  - +90.2% → Opus(상위)+Sonnet(워커) 조합 근거
  - Scaling heuristic 표 → 우려 1 heuristic 표 초안
  - Resumable checkpoint = 외부 자산 영속 → §5 영속화 정당성
- **상충**: 없음.

---

## 6. wshobson/agents — 34k★ 플러그인

> **URL**: https://github.com/wshobson/agents  
> **HEAD SHA**: `ece811f23310a37ceb43496dbac0e244fe6845b6` (default branch=main, 2026-05-02 — 2026-05-04 turn 10 #012 보강)  
> **Stars**: 34,600 (WebFetch 확인, 1차 리서치 34,082 대비 증가)  
> **7 preset 카탈로그 정확한 위치**: `plugins/agent-teams/skills/team-composition-patterns/references/preset-teams.md` (Review/Debug/Feature/Fullstack/Research/Security/Migration 7 헤더 직접 확인)  
> **team-composition-patterns 양식 위치**: `plugins/agent-teams/skills/team-composition-patterns/SKILL.md`  
> **agent 총 수**: 184 specialized AI agents (`docs/agents.md` 첫 줄, ② 회의실 preset 갯수와 의미 다름)

### 7 preset 팀 상세

| Preset | 구성원 수 | 주요 역할 | 비전 ② 회의실 매핑 |
|--------|---------|---------|-----------------|
| review | 3명 | code reviewer × 3 (다른 차원) | 병렬 검토 preset |
| debug | 3명 | hypothesis / reproducer / solver | 단계별 debug preset |
| feature | 4명 | lead + frontend + backend + tester | 기능 개발 preset |
| fullstack | 4명 | lead + frontend + backend + devops | 풀스택 preset |
| research | 3명 | 리서치 전문가 병렬 | ② 회의실 리서치 preset |
| security | 3명 | SAST + DAST + compliance | 보안 감사 preset |
| migration | 4명 | analyzer + implementer + tester + reviewer | 마이그레이션 preset |

→ **비전 ② 회의실의 preset 카탈로그 7종을 그대로 차용 가능**. 하네스 도메인 특화 preset(docs-research / harness-design) 추가만 필요.

### 6 skill (heuristic 표 양식)

1. **team-composition-patterns** — "언제 몇 명?" 의사결정 표
2. **team-communication-protocols** — broadcast vs direct message 기준
3. **task-coordination-strategies** — 병렬/순차 선택 기준
4. **multi-reviewer-patterns** — 리뷰 차원 분리 기준
5. **parallel-debugging** — 병렬 디버그 패턴
6. **parallel-feature-development** — 병렬 기능 개발 패턴

→ **team-composition-patterns** 가 우려 1(PM 판단력) heuristic 표의 양식 참고. "언제 몇 명, 어떤 구조" 표 형식 직접 차용.

### 모델 배분 (D-4 직접 출처)

> Lead/Reviewer = Opus (복잡한 분석·의사결정)  
> Implementer = Sonnet (개발·실행 태스크)

1차 리서치에서 "D-4 근거 출처" 로 기록된 내용 재확인. Anthropic 블로그 + aws-samples + wshobson 3개 출처 모두 동일 결론 = D-4 채택의 충분한 외부 근거.

### 비전 매칭 평가

- **부분 매칭**:
  - 7 preset → ② 회의실 preset 카탈로그 직접 차용 (7종 + 하네스 특화 추가)
  - team-composition-patterns → 우려 1 heuristic 표 양식
  - 모델 배분 표 → D-4 근거 3 중 하나
- **상충**: 없음.

---

## 7. aws-samples/sample-claude-code-agent-team

> **URL**: https://github.com/aws-samples/sample-claude-code-agent-team  
> **HEAD SHA**: `67840be315fad3ef252c06ccfe35d6ab9a2d43d6` (default branch=main, 2026-04-29 — 2026-05-04 turn 10 #012 보강)  
> **Stars**: 10 (WebFetch 확인, 1차 리서치 6 대비 증가)  
> **review cycle cap 정확한 위치**: `skills/spec-workflow/SKILL.md:65` 직접 인용 = "**Safeguards**: Max 3 review cycles per group, then escalate. Log decisions in `decisions.md`. Same blocker twice -> escalate to user."  
> **모델 배분 frontmatter 직접 확인** (`agents/*.md` 5건): `coding-agent.md=sonnet` / `devops-agent.md=sonnet` / `fullstack-agent.md=opus` (lead) / `review-agent.md=opus` / `sa-agent.md=sonnet`  
> **중요**: "NOT approved for production use" 공식 면책 명시

### Spec-Driven Workflow 구조

```
.claude/specs/<slug>/
├── spec.md       → 설계 결정, 대안, 제약
├── design.md     → 아키텍처, 레포 구조, 인프라
├── tasks.md      → 병렬 그룹별 태스크 (각 = [coding]/[devops]/[sa] prefix)
├── review.md     → 품질 발견사항
└── decisions.md  → 언블록 로그
```

→ **비전 ④ 파이프라인 (Pipeline 패턴) 의 spec-file 변형**. 비전 §5 영속 자산 중 `pm.yaml` 의 구조 참고로도 활용 가능 (spec.md 양식 = pm.yaml 의 태스크 섹션 초안).

### 팀 구성 + 모델 배분 (WebFetch 재확인)

| 역할 | 모델 | 기능 |
|------|------|------|
| fullstack-agent (lead) | **Opus** | 계획 + 조율 |
| coding-agent | **Sonnet** | 기능 구현 + 테스트 ← 1차 리서치와 다름! |
| devops-agent | **Sonnet** | 인프라 + CI/CD |
| review-agent | **Opus** | 품질 + 보안 검증 |
| sa-agent | **Sonnet** | AWS 아키텍처 리뷰 (on-demand) |

> 1차 리서치(02_community-patterns.md §5)에서 "coding/review=Opus" 로 기록했으나, WebFetch 재확인 결과 coding-agent 는 **Sonnet**. review-agent 만 Opus. **정정 필요**: D-4 근거 출처로서 "coding=Opus" 부분은 오류. coding=Sonnet 이 실제.

### Build → Review 루프 + Review Cycle Cap

```
fullstack(plan+research) → coding+devops(병렬) → review → fullstack(다음 그룹 or fix)
```
리뷰 실패 시 fix task 추가 → **최대 3 cycle** 후 강제 종료.

→ **비전 무한루프 방지 가드레일**의 직접 참고. ② 회의실 또는 ④ 파이프라인에서 "review 3회 초과 시 PM 에 에스컬레이션" 규칙 도입 가능.

### 비전 매칭 평가

- **부분 매칭**:
  - spec-driven → ④ 파이프라인 Pipeline 변형 / pm.yaml 구조 참고
  - review cycle cap(3회) → **무한루프 방지 가드레일** (비전에 없는 구체적 수치 제공)
  - 모델 배분 재확인 → D-4 근거 (coding=Sonnet 로 정정)
- **상충**: "NOT approved for production use" 면책 → aws-samples 자체를 비전에 직접 사용하면 안 됨. 패턴만 참고.

---

## 8. mikeyobrien/ralph-orchestrator — Ralph Wiggum 패턴

> **URL**: https://github.com/mikeyobrien/ralph-orchestrator  
> **Stars**: 2,800 (WebFetch 확인)  
> **Latest**: v2.9.2 (2026-04-10)  
> **공식 Anthropic 플러그인**: `anthropics/claude-code/plugins/ralph-wiggum/` 에도 포함

### Ralph Wiggum 패턴 메커니즘

**핵심**: Stop hook 이 Claude 의 exit 시도를 가로채 동일 프롬프트를 재투입 → 완료 조건 달성까지 루프.

```bash
# 공식 플러그인 사용 패턴
/ralph-loop "Your task description" --completion-promise "DONE" --max-iterations 50

# 루프 흐름:
# 1. Claude 작업
# 2. exit 시도
# 3. Stop hook 차단
# 4. 동일 프롬프트 재투입
# 5. 반복 → completion-promise 텍스트 출력 시 종료
```

**mikeyobrien 강화판 추가 기능**:
- **Hat System**: 전문 페르소나(hat)들이 이벤트 기반으로 조율
- **Backpressure Gates**: 테스트/린팅/타입체크 통과 전 downstream 차단
- **Persistent Memory**: 태스크 트래킹 + 이전 iteration 컨텍스트 보존
- **Multi-backend**: Claude Code / Kiro / Gemini CLI / Codex / Amp / Copilot CLI / OpenCode 7종

### zircote RLM 패턴과의 비교

| 측면 | Ralph Wiggum | zircote RLM |
|------|-------------|-----------|
| 루프 목적 | 태스크 완료까지 자율 반복 | 컨텍스트 초과 대형 파일 청크 분석 |
| 상태 유지 | 파일 시스템 + git history | 청크별 분석 결과 집계 |
| 종료 조건 | completion-promise 텍스트 | 모든 청크 처리 완료 |
| 메커니즘 | Stop hook (session 내부) | TaskUpdate + pipeline 체인 |
| 적용 대상 | 반복 수행 단일 태스크 | 대형 파일/디렉토리 분석 |

→ **둘은 다른 패턴**. Ralph 는 "같은 프롬프트를 완료까지" 이고, RLM 은 "청크 분할 병렬 분석". 비전 ④ 파이프라인에서 둘을 구분해서 사용해야 함.

### 비전 매칭 평가

- **부분 매칭**:
  - Hat System → 비전의 "PM + 사장 역할 분리" 의 역할 페르소나 개념과 유사
  - Backpressure Gates → ④ 파이프라인의 품질 게이트 (aws-samples review cycle cap 과 보완)
  - Multi-backend → ③ 외부 CLI 확장 시 Gemini CLI / Codex 이외 백엔드 참고
- **전체 매칭**: 없음. Ralph 는 단일 루프 에이전트. 비전은 PM 중개 멀티 워커 구조.
- **상충**: Ralph 의 "자율 루프" 접근 vs 비전의 "주인님 컨펌 필수 (D-5)" 직접 충돌. Ralph 에서 무한 자율 실행은 비전의 오너 컨펌 원칙에 위배. 사용 시 `--max-iterations` + 컨펌 게이트 필수.

---

## 9. panaversity/claude-code-agent-teams-exercises

> **URL**: https://github.com/panaversity/claude-code-agent-teams-exercises  
> **Stars**: 25 (WebFetch 확인, 1차 리서치 22 대비 소폭 증가)  
> **Last updated**: 2026-02-11 (v1.2.1, zircote 와 동일 날짜 — 같은 생태계 동반 업데이트 가능성)

### 8 exercise + 3 capstone 구조

**Module 1-4** (각 2개 = Type A 실습 + Type B 설계):
- Module 1: 팀 생성 기초 (TeamCreate / Agent spawn)
- Module 2: 태스크 조율 (Pipeline dependencies / workflow sequencing)
- Module 3: 커뮤니케이션 프로토콜 (inter-agent messaging / debate structures)
- Module 4: 품질 게이트 (review cycles / approval workflows + parallel processing)

**Module 5**: 3개 capstone (난이도 상승 비즈니스 시나리오)

### Anti-pattern 교육 내용 (implied)

루브릭 기준: "team coordination" 이 핵심 측정 항목 → 조율 실패가 주요 학습 대상. Type B (설계 → API 비용 없이) 는 패턴 선택 실수를 저비용으로 연습하는 훈련 구조.

주요 anti-pattern 커버 예상:
- 비효율적 에이전트 의존 체인 → §4 A10 (routine task 에 팀 사용)
- 빈약한 커뮤니케이션 흐름 → §4 A1 (broadcast 남용)
- 부족한 품질 검토 체크포인트 → §4 A6 (review dimension overlap)

### 비전 매칭 평가

- **부분 매칭**:
  - 7 anti-pattern 교육 커리큘럼 → **비전 §6 Anti-pattern 표 보강 재료**. Module 3 debate structures 는 비전 PM 의 "반박부터" 원칙 훈련과 직접 연결.
  - Type B (설계 연습) → 비전 마스터플랜 §8 검증 방법 (API 비용 절감 검증 패턴)
- **상충**: 없음. 순수 학습 자료.

---

## 10. 매칭 종합표

| 사례 | 부분 매칭 (비전 흡수 가능 부품) | 전체 매칭 | 상충 |
|------|-------------------------------|---------|------|
| revfactory/harness | Expert Pool → PM 동적 선택 / Supervisor → PM 워커 배분 / Hierarchical Delegation → 5층 위계 / 6패턴 → ④ 하위 메뉴 보강 | X | 없음 |
| barkain/verifier | Stage 0 planning → PM 사전 분석 / Subagent vs Team 이분 → ① vs ② 선택 기준 | X | verifier persistent vs /feedback ephemeral (의도적 설계 차이) |
| oh-my-claudecode | **② vs ③ 2-runtime 분리의 직접 선례** / Error Reference 표 / cursor-agent 확장 선례 | X | swarm 제거 (비전 ④-③ Swarm 과 용어 충돌, 실질 충돌 없음) |
| zircote | **④ 파이프라인 7패턴 전체 직접 출처** / addBlockedBy chain / Plan Approval = D-5 기술 구현 후보 | X | 없음 (비전이 명시 채택) |
| Anthropic 블로그 | **토큰 80% + +90.2% = D-4 수치 근거** / scaling heuristic = 우려 1 표 초안 / checkpoint = §5 영속화 정당성 | X | 없음 |
| wshobson/agents | **7 preset → ② 회의실 카탈로그** / team-composition-patterns 양식 / D-4 모델 배분 근거 3 중 하나 | X | 없음 |
| aws-samples | spec-driven → ④ Pipeline 변형 / **review cycle cap 3회** = 무한루프 가드레일 수치 / 모델 배분 재확인 | X | "NOT for production" 면책 (패턴만 차용) |
| ralph-orchestrator | Hat System → 역할 페르소나 / Backpressure Gates → 품질 게이트 / Multi-backend → ③ 확장 참고 | X | **Ralph 자율 루프 vs D-5 오너 컨펌** (사용 시 max-iterations 필수) |
| panaversity exercises | Anti-pattern 교육 커리큘럼 → §6 Anti-pattern 표 보강 / Type B 설계 연습 → 검증 방법 | X | 없음 |

---

## 11. 우려 1~3 입력 (Task 3 Gap 분석용)

### 우려 1 (PM 동적 선택 판단력) — 외부 heuristic 근거 수집 완료

외부 사례에서 명시적 선택 기준표를 가진 곳:

| 출처 | heuristic 내용 | 신뢰도 |
|------|--------------|--------|
| **Anthropic 블로그** | Simple: 1 agent 3-10 calls / Direct comparison: 2-4 agents 10-15 calls / Complex: 10+ agents | ★★★★★ (공식 내부 실험) |
| **wshobson** `team-composition-patterns` | "언제 몇 명?" 의사결정 표 양식 | ★★★★ (34k★ 실사용 검증) |
| **revfactory** Expert Pool + 6패턴 | 컨텍스트 의존적 패턴 선택 메커니즘 | ★★★ (author-measured n=15) |
| **aws-samples** | coding/review/devops/sa 역할별 모델 배분 | ★★★ (공식 AWS 샘플) |

**PM heuristic 표 초안 (4인 팀 제안)**:

| 작업 복잡도 | 예상 tool call | 추천 워커 | 근거 출처 |
|-----------|-------------|---------|---------|
| 단순 조회/탐색 | 3-10 | ① 인턴 (Sub-agent) | Anthropic 블로그 |
| 2-4개 비교/분석 | 10-15 each | ② 소규모 회의실 (2-3명) | Anthropic 블로그 |
| 복잡 협업 (5+ 파일) | 20+ | ② 대규모 회의실 (3-5명) | Anthropic 블로그 + wshobson |
| 검증/다른 시각 | — | ③ 외부 CLI | 비전 D-2 결정 |
| 순차 의존 단계 | 각 단계 별도 | ④ 파이프라인 Pipeline | zircote |
| 반복 대형 작업 | 무제한 | ④ RLM / Ralph | zircote / mikeyobrien |

### 우려 2 (2단계 호출 비용) — 외부 비용 모델

| 출처 | 비용 관련 언급 | 비전 적용 |
|------|-------------|---------|
| Anthropic 블로그 | "multi-agent 는 single-agent 대비 ~15× 토큰" | PM 거칠지 여부의 임계값 |
| Shipyard 블로그 | "95% 의 task 에는 맞지 않는다" | 우려 2 의 "언제 PM 안 거칠지" 기준 |
| barkain | 적응형 넛지 (차단 X → 비용 유연) | PM 게이트 vs 직접 호출 혼용 모델 참고 |

**제안**: Anthropic "3-10 tool call" 이하 태스크는 PM 게이트 생략하고 ① 인턴 직접 호출. 이상이면 PM 경유. 이를 `pm.yaml` 의 `bypass_threshold` 필드로 구현 가능.

### 우려 3 (Echo chamber) — 외부 모델 통합 빈도

| 출처 | 외부 모델 통합 빈도·방식 | 비전 적용 |
|------|---------------------|---------|
| oh-my-claudecode | tmux CLI worker 로 codex/gemini/claude/cursor 4종 | ③ 외부 CLI 설계의 직접 선례 |
| ralph-orchestrator | 7개 백엔드 지원 (Gemini CLI, Codex 포함) | ③ 외부 CLI 확장 경로 |
| wshobson | Lead/Reviewer=Opus, 단일 모델 생태계 | Echo chamber 위험 (wshobson 은 해결 안 됨) |
| barkain | 동일 Claude 세션 내 verifier → Echo chamber 해결 미흡 | 비전 /feedback 의 차별점 명확화 |

**결론**: 외부 모델 통합을 명시적으로 가진 사례는 oh-my-claudecode 와 ralph-orchestrator 2건. wshobson/aws-samples/zircote 는 단일 Claude 생태계로 Echo chamber 취약. **비전 ③ 외부 CLI 의 존재 이유는 9건 중 2건만 해결한 문제**로, 비전이 더 강한 해결책 보유.

---

## 12. 미확인 / 후속 조사 필요

1. **revfactory/harness 의 한국어 자원 → 영문 출력 메커니즘 구체 사항** — README 에서 "Korean, English, Japanese interfaces" 지원 확인했으나, 내부 프롬프트 구조까지 확인 못함. 주인님 레포 여부는 rlgnsday ≠ revfactory 로 부정.

2. **zircote `addBlockedBy` 구체 구문** — 의사코드만 WebFetch 에서 확인. 실제 API 파라미터 이름(`addBlockedBy` vs `blocked_by`) 공식 문서 재확인 필요.

3. **aws-samples coding-agent 모델 정정 출처** — ~~WebFetch 결과 coding=Sonnet 확인했으나 1차 리서치(02_community-patterns.md §5)에 "coding/review=Opus" 로 기록. 공식 레포 frontmatter 직접 확인으로 최종 결론 내야 함.~~ ✅ **2026-05-04 turn 10 #012 보강 PASS**: 공식 레포 (HEAD `67840be3`) `agents/coding-agent.md` frontmatter `model: sonnet` 직접 확인 → `coding=sonnet` 결정적 확정 (review=opus, fullstack=opus 도 동시 확인). §7 헤더 보강에 반영.

4. **ralph-orchestrator Hat System 과 비전 PM 역할 통합 가능성** — 현재 "부분 매칭" 으로 처리했으나, Hat System 의 이벤트 기반 조율이 PM ↔ 사장 SendMessage 루프와 구조적으로 유사. 깊이 비교 가능.

5. **panaversity 의 capstone 3개 구체 내용** — 8 exercise + **3 capstone** 확인 (1차 리서치에서 "2 capstone" 으로 기록된 것과 불일치). 상위 capstone 이 비전 마스터플랜 검증에 활용 가능한지 확인 필요.

6. **oh-my-claudecode v4.13.5 Error Reference 전체 표** — WebFetch 에서 일부만 확인. 공식 웹사이트(yeachan-heo.github.io/oh-my-claudecode-website)에서 전체 테이블 확인 가능할 것으로 예상.

---

**Task 2 상태**: completed  
**다음**: Task 3 (gap-analysis) 입력으로 활용  
**작성**: 2026-05-01 external-pattern-researcher (Sonnet)  
**검토 필요**: ~~§7 aws-samples 모델 배분 정정 (coding=Sonnet) → Task 3 gap-analysis 에서 D-4 근거 재검토 시 반영 요망~~ ✅ **2026-05-04 turn 10 #012 PASS**: aws-samples HEAD `67840be3` frontmatter 직접 확인으로 결정적 확정 (§7 헤더 + §11.3 의 #3 항목 보강 완료, 04_masterplan §8.3.5 표 반영)
