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

## 4. 위험 + 강제 훅 (활성, 2026-05-04 turn 7 PASS)

**위험**: `model` 파라미터 누락 + settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 부재 환경에서 워커가 메인 model (Opus) 상속 → 작업당 비용 5배 + Anthropic 사용량 한도 빠른 소진.

**강제 훅 (활성)**: `~/.claude/hooks/pretooluse-agent-model-required.{sh,py}` (스테이징 ↔ 운영 SHA256 MATCH).
- settings.json `hooks.PreToolUse` 에 `{"matcher": "Task|Agent", "hooks": [...]}` 등록
- 검사 순위: (1) tool_name in ("Task","Agent") (2) `tool_input.model in {opus,sonnet,haiku}` 통과 (3) `subagent_type` frontmatter 예외 (§3) (4) 차단 = `permissionDecision: deny` JSON + stderr
- **차단 메커니즘**: Issue #26923 (CLOSED) + #40580 (OPEN) 의 "exit 2 가 서브에이전트 호출 무시" 알려진 버그 회피 = `permissionDecision: deny` JSON + exit 0 우회 (Issue #26923 reporter 본인 미검증 가설 = **2026-05-04 turn 7 세계 1호 검증 PASS**)
- 라이브 검증 결과 (06 §11.3): 4 spawn 중 C (model 누락) = 차단 PASS, A·B (명시) = 통과, D (invalid) = SDK level 차단 (이중 보장)

**현 상태 (활성)**: 강제 훅 등록 완료 + settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 (turn 7 Step 4 commit). fallback C+ 영구 적용 진입 (메커니즘 3중 — 강제 훅 / env 제거 / 메인 재시작). **최종 효과 검증 = 다음 세션 (turn 8) env 부재 환경 라이브 재검증 후 마킹**.

## 5. 외부 리서치 (선행)

본 규칙은 issue#32732 검증 (06 §9·§10) 기반. 외부 사례:
- Anthropic 공식 blog (Multi-Agent Research System, 2025) — Opus lead + Sonnet worker 조합 +90.2% 성능 (URL/조건 #012 보강 예정)
- aws-samples/claude-code-cookbook — coding=Sonnet (review 만 Opus). 3 출처 동일 결론 (D-4 R-3 근거)

> **외부 리서치 의무 규칙** (`~/.claude/rules/research-mandatory.md`) 적용. 향후 본 규칙 갱신 시 외부 사실 인용 필수.

## 6. 출처

- **검증 보고서**: `docs/research/agent-office-masterplan/06_issue32732_experiment.md` §9 (turn 3 결정적 재현) + §10 (turn 6 PASS) + **§11 (turn 7 강제 훅 PASS)**
- **마스터플랜**: `docs/research/agent-office-masterplan/04_masterplan.md` §8.2 (1·2·3·4차 실험 결과) + §9.1 (model override 행)
- **외부 출처 (turn 7)**: [Issue #26923](https://github.com/anthropics/claude-code/issues/26923) + [Issue #40580](https://github.com/anthropics/claude-code/issues/40580) — exit 2 무시 버그 + permissionDecision 우회 가설
- **비전 SSOT**: `~/.claude/projects/.../memory/agent-office-vision.md` D-4 (모델 배분 결정)
- **history**: `docs/history/2026-05-04.md` (Day 19 turn 6 상세)
