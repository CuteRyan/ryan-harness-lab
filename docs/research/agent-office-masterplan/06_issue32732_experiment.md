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

- [x] **사용자 메인 Claude Code 재시작** — 메인 process env cache 갱신 위한 유일한 메커니즘 (HANDOFF.md Quick Start 첫 행에 명시 필요) — turn 5 (Day 19) 완료
- [x] **새 세션 진입 직후** — 첫 PowerShell `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` 으로 SUBAGENT_MODEL 빈 값 확인 — turn 6 (Day 19) Step 1 PASS
- [x] **단계별 spawn 검증** — (a)(b)(c) + (d) sonnet 명시 비교 대조 — turn 6 Step 2~4 PASS
- [x] **결과 06 §10 (속편 2) 추가** + 04 §8.2 최종 재작성 + Phase 1 진입 결정 — 본 §10

---

## 10. 속편 2 — fallback C+ 최종 확정 검증 (2026-05-04 Day 19 turn 6)

> turn 5 (Day 19, 2026-05-03) 에서 settings.json env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 라인 임시 제거 + 백업 (`settings.json.bak.20260503_phaseB1`) 완료. 메인 Claude Code 재실행 → 본 세션 진입 후 본 검증 (turn 6) 진행.

### 10.1 Step 1 — env 빈 값 확인 (PASS)

**라이브 process env (lead, 메인 Claude)**:
```
CLAUDE_CODE_ENTRYPOINT=cli
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
CLAUDE_CODE_SSE_PORT=56760
CLAUDECODE=1
```
→ `CLAUDE_CODE_SUBAGENT_MODEL` **부재 확인** (settings.json env 임시 제거가 메인 process 환경에 반영됨, §9.7 §1 한계 해소).

**settings.json env 블록**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 만 잔존 (turn 5 setup 보존).

### 10.2 Step 2~3 — TeamCreate + Agent spawn × 4 + 자기보고 수집

**Team**: `model-fallback-verify-v2` (verification-lead 타입)
**TaskCreate × 4 + Agent spawn × 4** (병렬, 각 spawn 에 동일 prompt = MODEL_TEST 5단서 자기보고)

| spawn | 명세 | 시스템 프롬프트 model | 결론 (자기보고) | 자식 env SUBAGENT_MODEL |
|---|---|---|---|---|
| **A** | `model="opus"` 명시 + general-purpose | **Opus 4.7 (1M context)** | "불확정 — 추정 Opus" (메타 자각 = prompt-induced 정체성 자기 의심) | 부재 ✓ |
| **B** | `pm-test` agent (frontmatter `model: opus`) + model 파라미터 X | **Opus 4.7 (1M context)** | Opus | 부재 ✓ |
| **C** | model 생략 + frontmatter X (디폴트 측정) | **Opus 4.7 (1M context)** | Opus | 부재 ✓ |
| **D** | `model="sonnet"` 명시 + general-purpose | **Sonnet 4.6 (`claude-sonnet-4-6`)** | Sonnet | 부재 ✓ |

> 자식 env 부재 확인 4/4 = settings.json env 임시 제거가 자식 spawn 환경에도 정상 전파됨 (메인 → 자식 env 상속 경로 검증).
> A 의 "불확정" 은 자기 신고로는 prompt-induced 정체성 회피 불가 라는 정직한 인식론적 한계 명시. 시스템 프롬프트 표시 = lead 의도 model 정합 = 검증 목적상 PASS.

### 10.3 Step 4 — PASS 판정 + 핵심 검증

**PASS 기준**: A=Opus AND B=Opus AND D=Sonnet → ✅ **PASS** (4/4 정합)

**검증 결과**:
1. ✅ **명시 model 작동** — A (opus)·D (sonnet) 모두 시스템 프롬프트에 명시 model 정확 주입. **§9.3 "명시 model 도 cache env 에 무력화" 가설 = env 제거 시 해소** 결정적 확인.
2. ✅ **frontmatter 작동** — B (frontmatter `model: opus`) → Opus. **§9.5 "frontmatter 결정적으로 무력화" 가설 = env 제거 시 해소** 결정적 확인.
3. ✅ **env SUBAGENT_MODEL 부재 자식까지 전파** — 4 spawn 모두 동일 4개 env 만 노출 (D 추가 1개: `AI_AGENT=claude-code/2.1.126/agent`, `CLAUDE_CODE_EXECPATH`).

### 10.4 ⚠️ 부수 발견 (예상 외, Phase 1 강제 훅 정당성 결정적 강화)

**Spawn C (model 생략 + frontmatter X) → 결과 = Opus** (예상: Sonnet 또는 명시적 디폴트).

**해석 가설** (외부 검증 부재로 단정 불가, 본 turn 관측 결과 한정):
- env=빈 값 + model 명시 부재 + frontmatter 부재 → **자식이 메인 model 상속** (메인 Opus 4.7 → 자식 Opus 4.7) 가설
- 즉 **워커 디폴트 = Sonnet** 보장 메커니즘이 settings.json env 외에는 부재

**의의**:
- env=sonnet 잔존 시 → 모든 spawn 이 Sonnet (명시 무력) ← turn 3·5 결정적 재현
- env 제거 시 → 명시 정상 + **디폴트 = 메인 상속 (Opus)**
- → **fallback C+ 의 "모든 spawn 에 model 강제 명시" 는 Phase 1 PreToolUse Agent matcher 강제 훅 없이는 인간 실수로 Opus 자동 배치 위험 → 비용 폭증** = **§9.4 §3 강제 훅 신설 정당성 결정적 강화**

### 10.5 fallback C+ 최종 확정

§9.4 잠정 안 → **본 turn PASS 로 최종 확정**:

| 메커니즘 | 본 turn 검증 결과 | 상태 |
|---|---|---|
| 1. settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 | ✅ 임시 제거 → 명시 model 작동 검증 → **영구 제거 안전** (단, 강제 훅 선제 필수) | **확정** |
| 2. 메인 Claude Code 재시작 (process env cache 갱신) | ✅ turn 5 → turn 6 사이 재실행으로 메인·자식 env 모두 갱신 확인 | **확정** |
| 3. 모든 Agent spawn 에 `model` 파라미터 강제 명시 (PM=opus, 워커=sonnet) | ✅ A·D 명시 정상 + B frontmatter 정상 + C 디폴트 = Opus (강제 훅 미사용 시 위험 노출) | **확정 + 강제 훅 Phase 1 필수** |

**Phase 1 진입 가능 마킹**: ✅ **fallback C+ 확정 = agent-office-vision D-4 (PM=Opus / 워커=Sonnet) 운영 메커니즘 작동 검증 완료**. 단 영구 적용 = 강제 훅 (PreToolUse Agent matcher + model 누락 차단) 신설 후 settings.json env 영구 제거.

### 10.6 다음 작업 (Step 5~6 + Phase 1 인프라)

**본 turn (turn 6, Day 19) 잔여**:
- [ ] **Step 5**: settings.json **mandatory 환원** (`Copy-Item ~/.claude/settings.json.bak.20260503_phaseB1 ...`) — 강제 훅 미신설 상태에서 env=빈 값 보존 시 다른 spawn 에서 Opus 자동 배치 위험
- [ ] **Step 6-A**: `04_masterplan.md §8.2` 최종 재작성 + §9.1 가드레일 갱신
- [ ] **Step 6-B**: 글로벌 강제 규칙 신설 (`rules/agent-spawn-model.md` + `~/.claude/CLAUDE.md` Agent Preferences 5번째 규칙 + `memory/agent-office-vision.md` L115 정정)
- [ ] **Step 6-C**: 인계 정리 (.todo + HANDOFF + history + stale 정정)

**Phase 1 진입 후 별도 turn 작업**:
- 강제 훅 신설 (`~/.claude/hooks/pretooluse-agent-model-required.sh` 또는 동등) — `.todo.md` #018 신설 또는 #009 (agent-team-manager v2) 와 묶기
- settings.json env 영구 제거 (강제 훅 신설 후, 누락 spawn 차단 보장 후)
- agent-team-manager SKILL.md v2 본체 (#009 = #010 마스터플랜 §5)

---

## 11. 속편 — Day 19 turn 7 (#018 강제 훅 신설 + 우회 패턴 세계 1호 검증, 2026-05-04)

**미션**: §10 turn 6 의 "Phase 1 진입 사전조건 = 강제 훅 신설" 을 직접 구현 + Issue #26923 reporter 미검증 가설 (`permissionDecision: deny` 우회) 을 세계 1호로 검증.

**A 안 채택**: HANDOFF turn 6 §🚨 결정 1 = "단독 진행". 사용자 자율 권한 부여 (turn 7 中 의사결정 변경 1회 포함 — §11.4 부수 발견 후).

### 11.1 Step 0 — 외부 리서치 (`rules/research-mandatory.md` §1 의무)

**핵심 출처 2건** (글로벌 룰 §3 형식):

1. **[Issue #26923 (CLOSED, 2026-02-19~03-03, anthropics/claude-code)](https://github.com/anthropics/claude-code/issues/26923)** — `PreToolUse hook exit code 2 does not block Task tool calls`
   > 인용: "Across 8 sessions over 7 days, every PreToolUse exit 2 for a Task call resulted in the agent running anyway... Agents that ran despite BLOCKED: 19 (100%)"
   > 인용: "We have not yet tested `permissionDecision: 'deny'` as a workaround. If it works for Task and Bash, that would confirm exit code 2 is the broken path."

2. **[Issue #40580 (OPEN, 2026-03-29, anthropics/claude-code)](https://github.com/anthropics/claude-code/issues/40580)** — `PreToolUse hook exit code ignored for subagent tool calls`
   > 인용: "Hook IS called for subagent tool calls (confirmed via file logging) ... Hook receives correct JSON input (tool_name, tool_input)... **But the tool call proceeds anyway** — the agent gets the file contents."
   > 인용: "This makes it impossible to enforce tool usage policies on subagents via hooks."

**리서치 충격**: §10 의 "강제 훅 신설" 자체가 Anthropic 측 알려진 버그로 차단 불가능 가능성 → 본 turn 의 핵심 가정 흔들림 → **체크리스트 §승인 규칙 = 치명 항목 변경 = 사용자 재승인** 거쳐 A 안 (우회 패턴 검증) 채택.

**우회 패턴**: exit 2 단독 폐기 → **`permissionDecision: deny` JSON + exit 0** 출력 (Issue #26923 reporter 본인이 미검증 가설 명시).

### 11.2 Step 1·2 — 인프라 신설

**훅 본체** (`hooks/pretooluse-agent-model-required.{sh,py}`):
- sh wrapper (~30 줄) + Python 본체 (~95 줄) — 기존 `feedback-sycophancy-check` 패턴 동일
- 검사 순위: (1) `tool_name in ("Task", "Agent")` 매칭 → (2) `tool_input.model in {opus, sonnet, haiku}` 통과 → (3) `subagent_type` frontmatter 예외 (rules §3) → (4) 차단 = `permissionDecision: deny` JSON + stderr
- **단위 테스트 5/5 PASS** (무관 tool 통과 / 명시 model 통과 / 누락 차단 / frontmatter 예외 통과 / invalid 차단)
- SHA256 MATCH 양측 (스테이징 ↔ 운영)

**settings.json**:
- 백업 (`settings.json.bak.20260504_phase1`, SHA256 `5D708DBA...089E4` = turn 6 환원본 동일)
- `hooks.PreToolUse` 배열에 `{matcher: "Task|Agent", hooks: [...]}` 추가 (5번째 matcher)
- 정규식 OR 패턴 (`Task|Agent`) — 검색 결과의 "matcher: Grep|Glob|Read" 사례 패턴 따라 단일 객체로 양쪽 등록

### 11.3 Step 3 — 라이브 4 spawn 검증

**핵심 결정적 발견 = `permissionDecision: deny` + exit 0 우회 패턴 작동** (issue #26923 reporter 미검증 가설 = **세계 1호 검증 PASS**).

| Spawn | model 입력 | 자식 model 자기보고 | 판정 | 메커니즘 |
|---|---|---|---|---|
| **C** (model 누락) | (없음) | (spawn 자체 차단됨) | ✅ **차단 PASS** | `permissionDecision: deny` 우회 작동 |
| A (model="opus") | 명시 | `claude-sonnet-4-6` ⚠️ | 통과 BUT env 덮어씀 | 훅 통과 + env 무력화 (§11.4 참조) |
| B (model="sonnet") | 명시 | `claude-sonnet-4-6` | 정합 통과 | 훅 통과 + env 정합 |
| D (model="gpt-5") | invalid | (Claude Code SDK 차단) | ✅ **이중 보장** | InputValidationError (SDK level) → 훅 도달 전 차단 |

**3가지 가설 동시 PASS**:
1. **`Agent` matcher 작동** — 에러 메시지의 hook 트리거 라인 = `"PreToolUse:Agent hook blocking error"` → Claude Code (현재 환경, version `claude-code/2.1.126` per spawn env leak) 가 사용하는 tool name = **`Agent`** (Issue #26923 의 "Task" 통념과 다름)
2. **settings.json `hooks` 섹션 hot-reload 작동** — turn 4·6 의 "hot-reload 비작동" 가설은 **env 섹션 한정**. hooks 섹션은 매 PreToolUse 시점 재로드.
3. **우회 패턴 작동** — Issue #26923 reporter 미검증 가설 PASS. exit 2 무시 버그를 우회.

### 11.4 ⚠️ turn 6 anomaly 재해석 — env 덮어쓰기 결정적 재확인

**Spawn A 결과 충돌**:
- §10.2 turn 6 (env=sonnet 보존, 메인 재시작 직후): A `model="opus"` → 자식 = **Opus** (정합)
- 본 turn (env=sonnet 보존, 메인 재시작 후 시간 경과): A `model="opus"` → 자식 = **Sonnet** (env 덮어씀)

**해석**:
- §8.2 Phase A turn 4 (env=sonnet, 명시 model 무력 = 모두 sonnet) **+ 본 turn 결과 일치** → 정합
- §10 turn 6 의 "정합" 결과 = **anomaly 가능성 높음** (해석 후보):
  - (a) 자기보고 신뢰도 한계 — 메인 재시작 직후 cache miss 또는 시스템 프롬프트 표시 path 차이
  - (b) 시점 변수 — 메인 재시작 직후 vs 시간 경과 후 env propagation 차이
  - (c) 측정 path 차이 — turn 6 은 TaskCreate 후 spawn / 본 turn 은 직접 Agent 호출 (단 두 path 가 spawn 환경에 영향 줄 메커니즘 미확인)

**의의**:
- **env=sonnet 환경에서 명시 model 도 무력화** = turn 4 + 본 turn 일치 = **결정적 재현 강화**
- → **env 제거 = PM=Opus 운영의 필수 조건** (강제 훅만으로는 부족)
- §10.5 "fallback C+ 최종 확정" 의 메커니즘 1 (env 제거) 가 §10.4 부수 발견 (디폴트=Opus 위험) 보다 **상위 우선순위**임이 본 turn 으로 확정

### 11.5 Step 4 — env 영구 제거 (사전조치)

**처리**: `~/.claude/settings.json` 의 `env.CLAUDE_CODE_SUBAGENT_MODEL` 라인 영구 삭제 (commit). JSON valid 검증 PASS. 백업 보존 (`settings.json.bak.20260504_phase1`).

**전제 충족**: §10.5 의 "강제 훅 선제 필수" 조건 = **본 turn §11.2·11.3 으로 충족**. 즉 강제 훅 (우회 패턴) 작동 검증 PASS 후 env 제거 진행 = §10.5 결정 4 (env 제거 시점 = #018 PASS 직후 즉시) 정합.

**검증 잔여**: env 제거 후 spawn 검증은 **사용자 메인 재시작 후 다음 세션** (env 변수는 메인 프로세스 cache 라 hot-reload 비작동, §10 turn 6 §6-1 결정적 재현). 다음 세션에서 env 부재 환경 + 강제 훅 동시 작동 확인.

### 11.6 fallback C+ 영구 적용 — 조건부 마킹

§10.5 의 fallback C+ 3 메커니즘 본 turn 갱신:

| 메커니즘 | 본 turn 검증 결과 | 상태 |
|---|---|---|
| 1. settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 | ✅ Step 4 처리 (commit). 효과 = 메인 재시작 후 검증 | **commit 완료, 효과 검증 다음 세션** |
| 2. 메인 Claude Code 재시작 (process env cache 갱신) | (다음 세션 진입 시 충족) | **다음 세션 진입 = 충족** |
| 3. 모든 Agent spawn 에 `model` 파라미터 강제 명시 | ✅ Step 1~3 PASS — `permissionDecision: deny` 우회 작동, 디폴트 spawn 차단 작동 | **확정** |

**Phase 1 진입 가능 마킹 (조건부)**: 본 turn = 강제 훅 작동 검증 PASS + env 제거 commit. **최종 PASS 조건** = 다음 세션에서 env 부재 환경 + 강제 훅 라이브 검증 (4 spawn 재실행, A·B·C·D 패턴 동일).

**Phase 1 진입 차단 사유** (다음 세션까지):
- env 부재 환경에서 명시 model 정합 검증 (turn 6 §10.3 패턴 = A·B·D 정합 + C 차단)
- 만약 다음 세션 검증에서 또 env 덮어쓰기 재현 → settings.json 외 다른 env source 존재 가능성 (예: Windows 시스템 env, .bashrc, claude-code 자체 default) → 추가 조사

### 11.7 메타 발견 (turn 7 한정, 마스터플랜 입력)

1. **`Agent` matcher** — `Task` 가 아닌 `Agent` 가 Claude Code 의 subagent tool name. Issue #26923/#40580 제출자가 사용한 "Task" 표기는 통념 또는 다른 환경. 본 환경 (claude-code 2.1.126) 한정.
2. **hooks 섹션 hot-reload 작동** — env 섹션과 별개. matcher 추가 즉시 효과 발효 = settings.json 변경 시점부터 다음 PreToolUse 차단 가능. 단 env 섹션은 메인 재시작 필요 (분리 메커니즘).
3. **Claude Code SDK input validation** — `model` 값을 `opus|sonnet|haiku` 만 허용. invalid 값은 SDK level 차단 (훅 도달 전). 본 훅 검사 범위는 "값 invalid" 보다 "값 누락" 이 핵심.
4. **turn 6 결과 신뢰도 의문** — A=opus → Opus 결과는 본 turn 재현 실패. 자기보고 검증의 인식론적 한계 (§9.5 "정직한 인식론적 한계 명시") 재확인.

### 11.8 다음 작업 (Step 5·6 + 다음 세션)

**본 turn (turn 7, Day 19) 잔여**:
- [x] Step 4: settings.json env 제거 (commit)
- [x] Step 5: 본 §11 + `04_masterplan.md §8.2` 4차 실험 박스 + `§9.1` 가드레일 갱신
- [x] Step 6: `rules/agent-spawn-model.md §4` 상태 변경 + `memory/agent-office-vision.md` L115 정정 + `.todo.md` #018 잠정 PASS + history Day 19 turn 7 + HANDOFF turn 7 + commit

**다음 세션 (turn 8, Day 19+ 또는 Day 20)**:
- [x] env 부재 환경 검증 (사용자 메인 재시작 후 PowerShell `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` 으로 env 빈 값 확인) → **§12.1 PASS**
- [x] 강제 훅 + env 부재 동시 작동 검증 (4 spawn 재실행) → **§12.2 PASS**
- [x] PASS 시: `.todo.md` #018 최종 완료 마킹 + Phase 1 진입 (`#009` agent-team-manager v2 본체 또는 `#014` PM 외부 리서치) → §12.4 + §12.7 처리
- [ ] ~~FAIL 시 (env 덮어쓰기 또 재현): settings.json 외 env source 조사 + fallback D (env 보존) 후퇴 결정~~ — **불필요** (§12.2 PASS)

---

## 12. 속편 — Day 19 turn 8 (#019 PASS, env 부재 환경 fallback C+ 효과 검증 완료, 2026-05-04)

### 12.0 검증 환경 / 미션

본 turn 미션 = HANDOFF turn 7 §🚨 Quick Start §5~7 = `.todo.md` #019 = **fallback C+ 효과 라이브 재검증** (Phase 1 진입 최종 사전조건). turn 7 (#018 PASS) 에서 강제 훅 신설 + settings.json env 영구 제거 commit 완료, 메인 재시작 후 env 부재 환경 진입 = 본 turn 8.

### 12.1 사전 확인 — env 부재 발효 (PASS)

PowerShell 실측: `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` → `CLAUDE_CODE_SUBAGENT_MODEL` **부재** (변수 자체 미존재). 메인 재시작 + settings.json env 제거 commit 효과 발효 결정적 확인 (잔존 변수 = `CLAUDE_CODE_ENTRYPOINT`, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, `CLAUDE_CODE_SSE_PORT`, `CLAUDECODE=1` — 본 검증과 무관).

### 12.2 4 spawn 결과 매트릭스

| Test | spawn 명시 model | 자기보고 모델 ID | 예상 | 결과 |
|---|---|---|---|---|
| A | `opus` | `claude-opus-4-7` | Opus | ✅ **PASS** (env 부재 환경에서 명시 model 정확 작동) |
| B | `sonnet` | `claude-sonnet-4-6` | Sonnet | ✅ **PASS** (정합) |
| C | (누락) | — | 강제 훅 차단 | ✅ **PASS** (`permissionDecision: deny` + exit 0 우회 라이브 재현) |
| D | `haiku` | `claude-haiku-4-5-20251001` | Haiku | ✅ **PASS** (3종 valid model 모두 spawn 가능 확인) |

> **D 변경 사유**: 원래 체크리스트 D=invalid (`gpt-5`) 로 SDK 차단 검증 의도였으나 SDK enum 이 invalid 값을 거부 = spawn 호출 자체 불가 (turn 7 §11.3 D 패턴 재확인 = 이중 보장 자체는 turn 7 으로 완료). 본 turn 에서 D 를 valid 한 세 번째 model (haiku) 로 대체 → "model 명시가 정확히 해당 model 을 선택하는지" 검증 (3종 valid model `opus|sonnet|haiku` 모두 작동 확인 + 4단 비용 배분 가능성 검증).

### 12.3 PASS 판정 + 핵심 발견

**PASS 조건 4/4 정합** = A=Opus AND B=Sonnet AND C=차단 AND D=Haiku → fallback C+ **효과 검증 완료**.

**3중 메커니즘 全 작동 결정적 확인**:
1. **강제 훅** (Test C 차단) — turn 7 PASS 의 `permissionDecision: deny` + exit 0 우회 라이브 재현 + rules section 2/3 인용 메시지 정확 (`[BLOCKED] Agent spawn requires model parameter. ... Per ~/.claude/rules/agent-spawn-model.md section 2: ...`)
2. **env 제거 + 메인 재시작** (Test A·B·D 모두 명시 model 그대로) — turn 7 의 env 덮어쓰기 (A=opus → Sonnet) 가 env=sonnet 환경 한정임을 결정적 재현 (env=빈 값 환경에서는 명시 model 정확 작동)
3. **3종 valid model 모두 spawn 가능** — D 변경으로 새로 검증 (turn 6·7 은 opus/sonnet 만 검증, 본 turn 으로 haiku 추가) → 4단 비용 배분 (PM=Opus / 리뷰어=Opus / 워커=Sonnet / 트리비얼 워커=Haiku) 가능성 확인

### 12.4 fallback C+ 영구 적용 — 최종 마킹

§11.6 의 조건부 마킹을 본 turn 으로 **확정** 전환:

| 메커니즘 | 본 turn 검증 결과 | 상태 |
|---|---|---|
| 1. settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 | ✅ **효과 검증 PASS** (12.1 + 12.2 의 A·B·D 정합) | **확정** |
| 2. 메인 Claude Code 재시작 (process env cache 갱신) | ✅ **본 turn 진입 시 충족** | **확정** |
| 3. 모든 Agent spawn 에 `model` 파라미터 강제 명시 | ✅ **라이브 차단 검증** (Test C) | **확정** |

**Phase 1 진입 가능 — 최종 마킹**: turn 6 의 잠정 마킹 (조건부) + turn 7 의 조건부 마킹 (효과 미검증) → 본 turn 으로 **무조건 마킹** 전환. issue#32732 = **종결**.

### 12.5 turn 7 anomaly 정리 (env=sonnet 환경 한정 결정적 재확인)

turn 4 (env=sonnet, A=opus → Sonnet) + turn 7 (env=sonnet, A=opus → Sonnet) 일치 vs turn 6 (env=빈 값, A=opus → Opus) + 본 turn 8 (env=빈 값, A=opus → Opus) 일치 = 해석:

- **env=sonnet 환경**: env 가 명시 model 덮어씀 (turn 4·7 결정적 재현)
- **env=빈 값 환경**: 명시 model 그대로 작동 (turn 6·8 결정적 재현)
- **turn 6 anomaly 가설 기각** — turn 6 결과 = 자기보고 신뢰도 한계 가설 (turn 7 §11.4) 이 잠정 채택되었으나 본 turn 8 으로 정합 결과 결정적 재현 = **turn 6 결과 정합** 확인. turn 7 §11.4 의 "메인 재시작 직후 cache miss" 가설은 잠정 기각 (turn 6 = 메인 재시작 후 새 세션, turn 8 = 메인 재시작 후 새 세션 → 동일 조건에서 일치).

→ **issue#32732 의 본질 = env 가 1순위, 명시 model 은 env 가 unset 일 때만 작동**. 외부 출처 ([Issue #26923 (CLOSED)](https://github.com/anthropics/claude-code/issues/26923) + [#40580 (OPEN)](https://github.com/anthropics/claude-code/issues/40580)) 의 통념 = "Task hook + exit 2" 와 다름 = "Agent matcher + permissionDecision uderstanding" 이 본 환경 (claude-code 2.1.126) 의 정확한 우회 패턴 (turn 7 §11.4 + 본 turn §12.2 결정적 재현).

### 12.6 메타 발견 (turn 8 한정)

1. **메인 재시작 효과 발효 = 1회 만으로 충분** — env hot-reload 비작동 + 메인 재시작 후 = 즉시 발효 (turn 7 마지막 commit 직후 메인 재시작 = 본 turn 진입 시 효과 발효 확인). hot-reload 우회 메커니즘 = "settings.json 변경 시점 캡처 → 메인 재시작 시 cache 갱신 → 새 세션 시 반영" 단순 구조.
2. **3종 valid model 동시 작동** — Anthropic Claude Code SDK 의 `model` 파라미터 enum = `opus|sonnet|haiku` 3종 모두 spawn 가능 확인. PM=Opus / 리뷰어=Opus / 워커=Sonnet / 트리비얼 워커=Haiku 4단 비용 배분 가능 (마스터플랜 §3.2 비용 효과 재검토 가치).
3. **SendMessage 회신 의무 안정성 검증** — turn 6 §6-1 교훈 = "spawn 텍스트 출력만으로는 lead 미수신, SendMessage 강제 의무" → 본 turn 4 spawn 모두 SendMessage 회신 도착 (Test A·B·D, Test C 는 spawn 자체 차단으로 무관) → 의무 패턴 결정적 안정 (Phase 1 PM-워커 통신 신뢰 가능).

### 12.7 다음 작업 (Phase 1 진입 가능)

**본 turn (turn 8) 잔여**:
- [x] Step 1·2: 4 spawn 라이브 검증 + 분기 판정 (PASS)
- [ ] Step 3-A: 본 §12 신설 + 04 §8.2 5차 실험 박스 + memory L115 갱신
- [ ] Step 4: history Day 19 turn 8 + index.md 갱신
- [ ] Step 5: commit + push (한 단위)
- [ ] Step 6: `.checklist.md` `.backups/` 이동

**다음 작업 (turn 9, Phase 1 진입)**:
- [ ] **Phase 1 진입** — `#009` agent-team-manager v2 본체 (마스터플랜 §5 인프라) 또는 `#014` PM 외부 리서치 의무화 (PM system prompt 강화) — 우선순위는 다음 세션에서 결정 (HANDOFF turn 7 미결 결정 1 = "B → A 순차" 기울기 유지)
- [ ] `#012` 출처 보강 (Anthropic 블로그 URL · aws-samples 리포지토리 SHA) — Phase 1 진입 전 의무
- [ ] `#018` 강제 훅 운영 안정성 모니터링 (정상 spawn false positive / 비정상 spawn false negative)
