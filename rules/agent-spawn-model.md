# Agent Spawn Model 강제 명시 규칙 (글로벌)

> 작성: 2026-05-04 Day 19 turn 6 | 강도: **글로벌 강제** (모든 작업·모든 프로젝트 적용)
> 근거: issue#32732 fallback C+ 최종 확정 검증 (06 §10 PASS)

---

## 핵심 원칙

**모든 Agent spawn 호출에 `model` 파라미터 명시 필수**. 누락 시 워커 디폴트 = 메인 model 상속 (= Opus) → D-4 비용 배분 (PM=Opus / 워커=Sonnet) 깨짐 + 비용 폭증 위험.

추측·암묵적 디폴트 의존 금지. PM=`model="opus"`, 워커=`model="sonnet"` 명시.

---

## 1. 의무 조건 (다음 중 1건이라도 해당 시 의무)

- `Agent` 도구 호출 (Claude Code 내장)
- `TeamCreate` 후 `Agent tool` 로 teammate spawn
- 자연어 trigger 로 자동 spawn 되는 모든 경로 (subagent_type 만 명시하고 model 생략 시도 금지)

## 2. 의무 형식

```
Agent({
  description: "...",
  subagent_type: "general-purpose",  // 또는 custom agent
  model: "sonnet",                   // ← 필수, 워커 = sonnet
  prompt: "...",
  team_name: "..."  // Agent Teams 사용 시
})
```

PM spawn 시:
```
Agent({
  ...,
  model: "opus",  // PM = opus
  ...
})
```

## 3. 예외

- **단순 스킬 호출** (Skill tool 직접 호출, Agent spawn 없음) — 본 규칙 무관
- **공식 agent 사용 시** — 해당 agent 의 frontmatter `model:` 가 명시되어 있으면 `model` 파라미터 생략 가능 (예: `pm-test` agent frontmatter `model: opus`). 단 frontmatter 미명시 agent (예: `general-purpose`) 는 본 규칙 적용.
- **검증 실험** — issue#32732 같은 model 우선순위 측정 실험은 의도적으로 `model` 생략 (디폴트 측정 목적) 가능. 단 실험 종료 후 즉시 정리.

## 4. 위험 + 강제 훅 (Phase 1 인프라)

**위험**: `model` 파라미터 누락 + settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 부재 환경에서 워커가 메인 model (Opus) 상속 → 작업당 비용 5배 + Anthropic 사용량 한도 빠른 소진.

**강제 훅 (Phase 1 신설 예정)**: `~/.claude/hooks/pretooluse-agent-model-required.sh` — Agent tool matcher 로 `model` 파라미터 검사 + 누락 시 차단 + 안내 메시지 (`.todo.md` #018 또는 #009 와 묶어서 진행).

**현 상태 (강제 훅 신설 전)**: 본 규칙은 권고 (자체 검증). settings.json env=sonnet 가 fallback (강제 훅 신설까지 보존) — 명시 누락 시 워커가 Sonnet 으로 자동 배치 (D-4 정합 보장). 단 env=sonnet 조건에서는 PM=Opus 명시도 무력화 (issue#32732 turn 3 결정적 재현) → **PM 운영은 강제 훅 신설 + env 영구 제거 후에만 가능**.

## 5. 외부 리서치 (선행)

본 규칙은 issue#32732 검증 (06 §9·§10) 기반. 외부 사례:
- Anthropic 공식 blog (Multi-Agent Research System, 2025) — Opus lead + Sonnet worker 조합 +90.2% 성능 (URL/조건 #012 보강 예정)
- aws-samples/claude-code-cookbook — coding=Sonnet (review 만 Opus). 3 출처 동일 결론 (D-4 R-3 근거)

> **외부 리서치 의무 규칙** (`~/.claude/rules/research-mandatory.md`) 적용. 향후 본 규칙 갱신 시 외부 사실 인용 필수.

## 6. 출처

- **검증 보고서**: `docs/research/agent-office-masterplan/06_issue32732_experiment.md` §9 (turn 3 결정적 재현) + §10 (turn 6 PASS)
- **마스터플랜**: `docs/research/agent-office-masterplan/04_masterplan.md` §8.2 (3차 실험 결과) + §9.1 (model override 행)
- **비전 SSOT**: `~/.claude/projects/.../memory/agent-office-vision.md` D-4 (모델 배분 결정)
- **history**: `docs/history/2026-05-04.md` (Day 19 turn 6 상세)
