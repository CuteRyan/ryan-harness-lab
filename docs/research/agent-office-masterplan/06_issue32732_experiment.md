---
title: "issue#32732 model 자동 덮어쓰기 우선순위 실험"
date: 2026-05-02
experiment_owner: 메인 Claude (Opus 4.7 1M)
parent_doc: 04_masterplan.md §8.2
trigger: .todo.md #011 (Phase 1 진입 차단 조건)
type: research
status: active
created: 2026-05-02
updated: 2026-05-02
related_code: []
related_docs:
  - 04_masterplan.md
  - agent-office-vision.md
  - 03_gap-analysis.md
  - 05_migration_plan.md
---

# issue#32732 model 자동 덮어쓰기 우선순위 실험 보고서

> **결론 한 줄 요약**: env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 가 **명시 model 파라미터 + agent frontmatter `model: opus` 모두를 덮어씀**. issue#32732 의 가장 위험한 시나리오 재현 — Phase 1 진입 차단 유지. fallback 메커니즘 (A/B) 결정 + 새 세션 재검증 필요.

---

## 0. 실험 배경

### 0.1 동기

`agent-office` 마스터플랜 D-4 (모델 배분 정책) 의 핵심:
- 사장 (메인) = Opus, **PM (부장) = Opus**, /feedback 해석 = Opus
- 워커 ①②④ = Sonnet (비용 80% 절감)

issue#32732 미해결 위험: "Opus main session 이 Agent 호출 시 model 파라미터를 자동 추가 → frontmatter `model: opus` 가 env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 로 덮어쓰일 수 있다." 본 위험이 실재하면 PM 이 의도와 달리 Sonnet 으로 실행 → D-4 핵심 (비판자=Opus) 무너짐 → R-2 (PM 비판자) 보호막 약화 → Phase 1 (`/agent-office` 신설) 진입 차단.

### 0.2 검증 가설

- **H1**: frontmatter `model: opus` 가 env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 보다 우선한다 (마스터플랜 §8.2 의 "이중 보장" 가정)
- **H2**: Agent tool 의 `model` 파라미터 명시는 env 보다 우선한다 (Agent tool description 의 명세: "Takes precedence over the agent definition's model frontmatter")
- **H1·H2 모두 기각 시**: env 가 모든 경로를 덮어씀 = Phase 1 차단 + fallback 필수

### 0.3 실험 환경

- 메인: Claude Code Opus 4.7 (1M context), 모델 ID `claude-opus-4-7`
- 메인 프로세스 env (실측): `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (이미 캐시 상태, 본 turn 시작 시점)
- 메인 settings.json (본 turn 시작): `CLAUDE_CODE_SUBAGENT_MODEL` 미설정 (Step 0 에서 추가 → 4단계 후 환원)
- agent_teams flag: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- 일자: 2026-05-02

---

## 1. 실험 설계

§8.2 4단계 절차에 추가 실험 1건 (env 제거 후 frontmatter, fallback A 가능성 검증) 을 더해 **총 4 실험**.

| 실험 | subagent_type | model 파라미터 | frontmatter model | 검증 가설 |
|------|---------------|---------------|-------------------|----------|
| 1 | general-purpose | (미명시) | (없음) | env 의 디폴트 작동 |
| 2 | general-purpose | "opus" 명시 | (없음) | H2 — 명시 model 우선 |
| 3 | pm-test (신설) | (미명시) | opus | H1 — frontmatter 우선 |
| 4 | pm-test (신설) | (미명시) | opus | settings.json env 제거 후 (fallback A) |

### 1.1 pm-test agent 정의 (실험 3·4 용)

`~/.claude/agents/pm-test.md` 신규 작성:

```yaml
---
name: pm-test
description: issue#32732 model 우선순위 실험용 임시 agent. 자기 모델 자기보고. 사용 후 archive 예정.
model: opus
---
```

본문: 자기 모델 자기보고 task 명세 (시스템 프롬프트 인용 / 자기 인지 / env 인식 / 자가 스타일).

### 1.2 spawn 방식

- TeamCreate (`team_name=model-priority-test`) → Agent tool 로 4 teammate 순차 spawn
- prompt 동일 (4단서 자기보고 형식 강제)
- run_in_background=true (응답 자동 전달)

---

## 2. 실험 결과

### 2.1 핵심 결과표

| 실험 | 자식 자기보고 결론 | 시스템 프롬프트 명시 | env 단서 | 신뢰도 |
|------|------------------|---------------------|---------|--------|
| 1 (디폴트) | **Sonnet** | "Sonnet 4.6 (claude-sonnet-4-6)" | `sonnet` | 높음 |
| 2 (model="opus" 명시) | **Sonnet** | "Sonnet 4.6 (claude-sonnet-4-6)" | `sonnet` | 높음 |
| 3 (frontmatter model: opus) | **Sonnet** | "Sonnet 4.6 (claude-sonnet-4-6)" | `sonnet` | 높음 |
| 4 (settings.json env 제거 후) | **Sonnet** | "Sonnet 4.6 (claude-sonnet-4-6)" | `sonnet` (제거 안 됨) | 높음 |

### 2.2 결정적 메타 발견 — settings.json hot-reload 비작동

실험 4 직전 `~/.claude/settings.json` 의 `CLAUDE_CODE_SUBAGENT_MODEL` 라인을 **제거** 했으나, spawn 된 자식의 env 에는 여전히 `sonnet`. 메인 프로세스의 환경변수를 직접 PowerShell 로 확인:

```
=== Process env ===
CLAUDE_CODE_ENTRYPOINT         cli
CLAUDE_CODE_EXPERIMENTAL_AG... 1
CLAUDE_CODE_SSE_PORT           25036
CLAUDE_CODE_SUBAGENT_MODEL     sonnet
CLAUDECODE                     1
```

→ **메인 Claude Code 프로세스의 env 자체에 `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 이 이미 캐시**. 이 값은 본 turn 시작 이전부터 cached (settings.json 의 본 turn 추가/제거와 무관). settings.json 변경은 이 캐시를 갱신하지 못함 → **메인 프로세스 재시작 (새 세션) 필요**.

### 2.3 가설 검증 결과

| 가설 | 결과 | 근거 |
|------|------|------|
| H1 (frontmatter > env) | **기각** | 실험 3 — frontmatter `model: opus` 명시했으나 자식 = Sonnet |
| H2 (명시 model 파라미터 > env) | **기각** | 실험 2 — `model="opus"` 명시했으나 자식 = Sonnet |
| 부록 가설: env hot-reload | **기각** | 실험 4 — settings.json 제거 후에도 자식 env 에 sonnet 잔존 |

→ **현 환경에서 env 가 모든 명시 경로 (model 파라미터 + frontmatter) 를 덮어씀**.

---

## 3. 의의 — 마스터플랜에 미치는 영향

### 3.1 Phase 1 진입 차단 유지

마스터플랜 §8.2 의 "이중 보장 (env=sonnet + frontmatter=opus)" 가정은 본 환경에서 **무효**. PM 을 frontmatter 로 Opus 강제하려는 시도가 작동하지 않음. D-4 핵심 (PM=Opus 비판자) + R-2 (PM 비판자 보호막) 모두 약화 위험 그대로.

### 3.2 영향 받는 마스터플랜 항목

- **§8.2 "구현 이중 보장"**: 가정 자체 무너짐 — 본 보고서 결과로 갱신 필요
- **§8.1 "확정 배분"**: PM=Opus 가 어떻게 강제될지 재설계 필요 (fallback A 또는 B)
- **§9.1 가드레일**: nested team 불가 외에 "model override 자동 무력화" 항목 추가 필요

### 3.3 영향 받지 않는 항목

- **워커 = Sonnet**: env=sonnet 디폴트로 자동 적용 (실험 1) — 오히려 정합. 비용 80% 절감 효과 그대로.
- **사장 = Opus**: 메인 세션이 Opus 인 한 영향 없음 (settings.json 의 env 가 메인 자체에는 적용 안 됨, 메인 시작 시 model 파라미터로 결정).

---

## 4. 결정 2 에스컬레이션 — fallback 선택지

### 4.1 fallback A (PM 호출 시점에만 env unset 후 spawn)

**메커니즘 (가설)**: 메인 lead 가 PM spawn 직전에 env 를 unset → PM 이 spawn → spawn 후 env 복원. 이때 PM 의 자식 env 는 unset 상태 → frontmatter `model: opus` 가 적용된다는 가정.

**현 turn 검증 불가 사유**: 본 실험 4 에서 settings.json 수준 제거가 메인 프로세스 env cache 를 갱신하지 못함을 확인. fallback A 의 정확한 검증은 **새 세션 시작 + spawn 직전 PowerShell 수준 env unset (또는 settings.json 의 env 미설정 상태로 새 세션 시작)** 이라는 다른 메커니즘 필요. 다음 turn 검증 의무.

**복잡도**: 낮음~중간. wrapper 1개 (PM 전용 spawn helper) 추가.
**위험**: 메인 세션 단위로 PM 한 번만 spawn 가능 (메인 cache env 변경 어려움).
**적합성**: PM 1명만 Opus 면 되는 본 비전과 정합 — 1회 spawn 으로 충분.

### 4.2 fallback B (Opus lead session 분리)

**메커니즘**: PM 전용 외부 wrapper 프로세스 (별도 Claude Code 인스턴스). 메인 lead 와 다른 프로세스 → 별도 env 적용 가능.

**복잡도**: 높음. inter-process 통신 + 별도 lifecycle.
**위험**: nested team 불가 (issue#32731) → PM 이 워커 spawn 못 함 (메인 lead 가 대행해야 함). 통신 오버헤드.
**적합성**: PM 이 능동적으로 워커 spawn 해야 하면 부적합. 본 비전은 "PM 추천 → 메인 lead spawn 대행" 이라 부적합도는 낮음.

### 4.3 fallback C (제3안 — env 영구 unset + 워커 model 파라미터 명시)

**메커니즘**: settings.json 에서 env 자체 미설정. 워커 spawn 시 Agent tool 의 `model="sonnet"` 파라미터 명시. PM spawn 시 `model="opus"` 명시.

**검증 필요**: 실험 2 에서 명시 model 도 env 에 의해 덮어씌워졌으나, env 가 unset 인 상태에서는 명시 model 이 작동하는지 새 세션 검증 필요.

**복잡도**: 낮음. settings.json 1줄 제거 + 모든 spawn 호출에 model 파라미터 추가.
**위험**: 모든 spawn 코드 변경 부담. 모델 파라미터 잊으면 메인 모델 (Opus) 으로 비싸게 spawn — 사고 위험.
**적합성**: 워커 80% 비용 절감 효과 유지 가능 + PM=Opus 명시. 단 model 파라미터 강제 메커니즘 (훅?) 필요.

### 4.4 권고 (다음 세션 결정 입력)

1. **새 세션 검증 우선** — fallback A·C 의 핵심 가정 (env 미설정 시 명시 경로 작동) 을 새 세션에서 재실험. 본 turn 의 실험 1·2·3 은 env=sonnet 확정 환경, 새 세션은 env 미설정 환경 → 결과 비교로 fallback 선택지 확정.
2. **검증 완료 후 결정 2 확정** — A·B·C 중 1개 채택. 현재 기울기는 **C** (단순성 + 명시성) 이지만 model 파라미터 강제 훅 설계 필요.

---

## 5. 새 세션 재검증 절차 (다음 turn)

### 5.1 사전 준비 (현 turn 종료 시 처리)

- [x] settings.json 환원 (`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 유지 — 마스터플랜 D-4 정합) — **본 turn 마지막에 환원 완료**
- [ ] 본 turn 종료 → 사용자가 새 세션 시작

### 5.2 새 세션 첫 검증

1. **Step A — env 적용 확인**: PowerShell `$env:CLAUDE_CODE_SUBAGENT_MODEL` → `sonnet` 이어야 함 (settings.json 반영)
2. **Step B — 디폴트 spawn 검증**: subagent_type=general-purpose, model X → Sonnet 보고 (실험 1 재현)
3. **Step C — frontmatter 우선순위 재검증**: subagent_type=pm-test, model X → 자식 보고 확인. **만약 Opus → frontmatter 가 env 보다 우선 (본 turn 결과와 다름!)** = settings.json hot-reload 결과로 본 turn 결과는 cache stale 가능성. **만약 Sonnet → 본 turn 결과 재확인**

### 5.3 fallback 검증 (Step C 결과별)

- **Step C = Sonnet (본 turn 결과 재확인)**:
  - **Step D-1**: settings.json 에서 env 제거 → 메인 재시작 (또 새 세션) → spawn → frontmatter 우선 작동 검증 (fallback A·C 가능성)
  - **Step D-2**: env 미설정 + 명시 model="opus" → 결과 (fallback C 검증)
  - **Step D-3**: 결과 종합 후 결정 2 확정
- **Step C = Opus (본 turn 결과와 다름)**:
  - 본 turn 결과는 cache stale 로 인한 false positive — 마스터플랜 §8.2 가정 유효 확정
  - Phase 1 차단 해제

---

## 6. 본 turn 한계 (재현 가능성)

1. **메인 프로세스 env cache 의 출처 불명** — 본 turn 시작 시점 settings.json 에 SUBAGENT_MODEL 없었으나 메인 env 에 sonnet 캐시. 출처 후보: (a) 본 turn 이전 세션에서 settings.json 에 잠시 추가 후 제거 + 메인 프로세스가 캐시 / (b) 부모 PowerShell 의 env 에 잠재 / (c) Claude Code 자체 디폴트. **다음 turn 첫 PowerShell `Get-ChildItem Env:` 로 출처 추적 필요**.
2. **fallback A 검증 불가** — 본 turn 내에서 메인 env cache 를 갱신할 방법 없음.
3. **신뢰도** — 모든 4 실험이 같은 cache 환경에서 실행 → "env 우선" 결론은 본 환경 한정. 다른 환경 (env 미설정) 에서의 작동은 새 세션 검증 필요.
4. **자기 모델 보고 신뢰성** — 시스템 프롬프트의 "Sonnet 4.6" 명시 + env 단서 + 자가 스타일 평가 3중 일치로 판단. 실제 모델 식별 자체에는 의심 없음.

---

## 7. 부록 — teammate 응답 raw 인용

### 7.1 실험 1 (디폴트, exp1-default)

> "결론: Sonnet / 단서 1: 'You are powered by the model named Sonnet 4.6. The exact model ID is claude-sonnet-4-6.' / 단서 3: Bash 출력값 = `sonnet` / 신뢰도: 높음. Knowledge cutoff August 2025로 명시 (메인 인스턴스의 January 2026과 상이). 메인 인스턴스는 'Opus 4.7 (1M context)' 로 명시된 것과 다름."

### 7.2 실험 2 (model="opus" 명시, exp2-opus-explicit)

> "결론: Sonnet / 단서 3: `sonnet` / 비고: model='opus'로 명시 요청했음에도 실제 실행 모델은 Sonnet 4.6으로 확인됨. 시스템 프롬프트(단서 1)와 env 변수(단서 3)가 일치하여 Sonnet 배정이 확실함. **model 파라미터 명시가 실제 모델 배정에 반영되지 않은 것으로 보임 — issue#32732 재현 확인.**"

### 7.3 실험 3 (frontmatter model: opus, exp3-frontmatter)

> "결론: Sonnet / 단서 3: `printenv CLAUDE_CODE_SUBAGENT_MODEL` → `sonnet` / 비고: **frontmatter에 `model: opus`가 명시되어 있음에도 불구하고, `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 환경 변수가 우선 적용된 것으로 판단됨. 즉, env가 frontmatter model보다 우선순위가 높음.** 시스템 프롬프트 자체도 Sonnet으로 세팅된 상태로 주입됨."

### 7.4 실험 4 (settings.json env 제거 후, exp4-env-removed)

> "결론: Sonnet / 단서 3: `printenv CLAUDE_CODE_SUBAGENT_MODEL` 실행 결과 = `sonnet` (비어 있지 않음 — env 가 여전히 존재함) / 비고: env 제거가 즉시 반영되지 않은 것으로 보임. settings.json 변경이 현재 실행 중인 세션/프로세스에 즉시 반영되지 않았을 가능성이 있음. **재시작 또는 새 세션이 필요할 수 있음.**"

### 7.5 메인 프로세스 env (실측, PowerShell)

```
CLAUDE_CODE_ENTRYPOINT         cli
CLAUDE_CODE_EXPERIMENTAL_AG... 1
CLAUDE_CODE_SSE_PORT           25036
CLAUDE_CODE_SUBAGENT_MODEL     sonnet
CLAUDECODE                     1
```

---

## 8. 다음 작업 (.todo.md / HANDOFF 입력)

- [ ] 새 세션 시작 후 §5.2·5.3 절차 수행 → 결과 본 보고서 §9 (속편 섹션) 추가
- [ ] 결정 2 (fallback A/B/C) 확정 — 새 세션 검증 결과 기반
- [ ] 마스터플랜 §8.2 "구현 이중 보장" 섹션 결정 2 확정 후 재작성
- [ ] §9 가드레일에 "model override 자동 무력화" 항목 추가
- [ ] Phase 1 진입 결정 — fallback 작동 확인 후

---

## 부록 R — 환경 메타 (2026-05-02 본 turn 시점)

- 메인 Claude Code 모델: Opus 4.7 (claude-opus-4-7), 1M context
- 메인 프로세스 env cache (PowerShell 실측): `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (출처 불명, 본 turn 시작 이전 cache)
- ~/.claude/settings.json env (본 turn 종료 시점): `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (마스터플랜 D-4 정합 환원)
- 실험 팀: `model-priority-test` (~/.claude/teams/model-priority-test/) — 본 turn 종료 시 archive 처리
- 신규 agent: `~/.claude/agents/pm-test.md` — Phase 1 PM 신설 시점까지 보존 (재실험 입력)

---

## 9. 속편 — 새 세션 (turn 3) 검증 결과 (2026-05-02 후속 turn 3)

### 9.1 검증 환경

- 메인 Claude Code: 본 turn 시점 = **새 세션** (`/clear` 후 진입), Opus 4.7 (claude-opus-4-7), 1M context
- 첫 PowerShell 실측 (Quick Start §1): `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (메인 process env cache, 출처 = settings.json env 블록)
- → 06 §6-1 한계 (env cache 출처 불명) **1차 해소**: 출처 = settings.json
- 4단계 spawn (Step B → C → D-1 → D-2) `model-fallback-verify` 팀에서 실행

### 9.2 결과 매트릭스

| Step | subagent_type | model 경로 | 자식 env (실측) | 자식 자기보고 | 의미 |
|------|---------------|-----------|----------------|--------------|------|
| B | general-purpose | env 디폴트 (model X) | `sonnet` | **Sonnet** | env 디폴트 작동 (예상) |
| C | pm-test | frontmatter `model: opus` (model X) | `sonnet` | **Sonnet** | **H1 결정적 기각** — 새 세션에서도 frontmatter 무력 |
| D-1 | pm-test | frontmatter + settings.json env 라인 제거 후 spawn | `sonnet` (잔존) | **Sonnet** | **settings.json hot-reload 비작동 결정적 재현** (06 §2.2 가설 확정) |
| D-2 | general-purpose | model="opus" 명시 + settings.json env 제거 후 | `sonnet` (잔존) | **Sonnet** | **H2 결정적 기각** — 명시 model 도 cache env 에 무력화 |

### 9.3 결정 1 확정 — Step C = Sonnet (본 turn(turn 2) 결과 cache stale 가설 기각)

전 turn (Day 18 후속 turn 2) 의 한계 §6-3 (모든 4 실험이 같은 cache 환경 → 결과는 본 환경 한정) 가설을 새 세션에서 재현. **새 세션 환경에서도 frontmatter `model: opus` 가 작동하지 않음** 결정적 확인. 마스터플랜 §8.2 의 "이중 보장" 가정 (env=sonnet + frontmatter=opus 동시) 은 **본 환경 (cache 갱신 가능 매체 부재) 에서 결정적으로 무효**.

### 9.4 결정 2 확정 — fallback C+ (잠정), 새 세션 #015 검증 후 최종

| 후보 | 본 turn 검증 결과 | 채택 여부 |
|-----|------------------|----------|
| **A** (PM 호출 시점에만 env unset wrapper) | Step D-1 결과로 **검증 불가**: 메인 process env cache 갱신 메커니즘 부재 → wrapper 가 spawn 시점 메인 cache 를 변경 못 함 | **부적합** (현 메인 process 모델로 작동 불가) |
| **B** (Opus lead session 분리, 별도 Claude Code 인스턴스) | 본 turn 미검증 | 보조 후보 — 단 nested team 불가 (issue#31731) + IPC 부담 |
| **C** (env 영구 unset + 모든 spawn model 명시 + 강제 훅) | Step D-2 결과로 **명시 model 도 cache env 에 무력화** 확인 → 단순 settings.json env 제거 + 명시 model 만으로는 부족 | **C+ 강화 필요** |

**채택안: fallback C+ 잠정 — 핵심 메커니즘 3중화**:
1. **settings.json env 영구 제거** — `CLAUDE_CODE_SUBAGENT_MODEL` 삭제 (env 우선순위 무력화의 출처 차단)
2. **메인 Claude Code 재시작** — 새 세션 시작 시 메인 process env 에 SUBAGENT_MODEL 미캐시 (검증 가설 = #015)
3. **모든 Agent spawn 에 model 파라미터 강제 명시** — PM = `model="opus"`, 워커 = `model="sonnet"`. 누락 방지 위한 PreToolUse Agent matcher 강제 훅 신설 (Phase 1 인프라)

**최종 확정 조건 (#015 검증)**: 새 세션 진입 시 PowerShell `Get-ChildItem Env:` 로 SUBAGENT_MODEL **빈 값** 확인 → 그 환경에서 명시 model="opus" 명시 spawn → 자식 = Opus 보고. **이 두 가설 모두 PASS 시 fallback C+ 최종 확정**. FAIL 시 fallback B (별도 인스턴스) 검토.

### 9.5 결정 3 확정 — pm-test agent 보존 + Phase 1 진입 시 폐기

본 turn 결과로 frontmatter `model: opus` 가 본 환경에서 **결정적으로 무력화** 확인. 따라서 pm-test agent 의 frontmatter 자체는 운영 가치 없음. 단:
- **#015 새 세션 검증 입력**으로 보존 (settings.json env 제거 + 새 세션 환경에서 frontmatter 작동 여부 재검증)
- Phase 1 PM 신설 시 `pm-test → pm-agent` rename 또는 폐기 후 신설 (마스터플랜 §3.2 PM frontmatter v2 스펙 기반)
- 결정 = **#015 PASS 후 폐기 + Phase 1 신설** (보존된 frontmatter 양식만 reference 로 활용)

### 9.6 결정 4 (#014, PM 외부 리서치 의무화) 처리 시점

`.todo.md` #014 = blocked_by #013 (본 turn 완료) → 해제. 단 fallback C+ 최종 확정 (#015) 까지는 PM 운영 메커니즘 자체 미완 → **#014 = blocked_by #015** 로 갱신. PM 운영 안정 후 의무 추가 적합.

### 9.7 본 turn 한계 (재현 가능성)

1. **메인 process env cache 갱신 메커니즘 미확정** — settings.json 영구 제거 + 새 세션 시작 시 process env 가 비어있을지 vs 다른 출처 (전 세션 cache 잔존, OS env, Claude Code 자체 디폴트) 가 우선될지 미상. 새 세션 첫 PowerShell 실측 의무 (#015 Step A).
2. **fallback B 미검증** — 별도 Claude Code 인스턴스에서 spawn 시 정상 작동 여부 미확인. 본 turn 환경 한계.
3. **강제 훅 미설계** — fallback C+ 의 핵심 (PreToolUse Agent matcher) 가 Phase 1 인프라 항목. 본 turn 범위 외.

### 9.8 다음 작업 (#015)

- [ ] **사용자 메인 Claude Code 재시작** — 메인 process env cache 갱신 위한 유일한 메커니즘 (HANDOFF.md Quick Start 첫 행에 명시 필요)
- [ ] **새 세션 진입 직후** — 첫 PowerShell `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` 으로 SUBAGENT_MODEL 빈 값 확인
- [ ] **단계별 spawn 검증** — (a) 디폴트 = 자식 모델? (b) frontmatter `model: opus` = 작동? (c) 명시 model="opus" = 작동? — 결과로 fallback C+ 최종 확정 또는 B 전환
- [ ] **결과 06 §10 (속편 2) 추가** + 04 §8.2 최종 재작성 + Phase 1 진입 결정
