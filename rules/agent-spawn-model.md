# Agent Spawn Model 명시 (글로벌)

**핵심**: 모든 Agent spawn 호출에 `model` 파라미터 **명시 필수**. 누락 시 워커가 메인 model(Opus) 상속 → 비용 배분(PM=Opus / 워커=Sonnet) 깨짐 + 비용 폭증. 추측·암묵 디폴트 의존 금지.

## 의무 조건
- `Agent` 도구 호출 (Claude Code 내장)
- teammate spawn (Agent Teams)
- 자연어 trigger 자동 spawn 포함 (`subagent_type`만 쓰고 `model` 생략 금지)

## 형식
- 워커: `model: "sonnet"`
- PM: `model: "opus"`

## 예외
- 스킬 직접 호출 (Agent spawn 없음) — 무관
- 공식 agent frontmatter에 `model:` 명시돼 있으면 (예: `pm` = opus) 파라미터 생략 가능. frontmatter 미명시 agent(예: `general-purpose`)는 명시 필수
- model 우선순위 측정 실험 — 의도적 생략 가능 (종료 후 즉시 정리)

## 강제 훅 (활성)
`pretooluse-agent-model-required.{sh,py}` 가 `Task|Agent` 호출 시 `model` 누락을 `permissionDecision: deny`로 차단. settings.json에 등록됨.

---
> 위험 상세 · 훅 메커니즘(issue#26923/40580) · 라이브 검증 이력 · 외부 출처 → `Harness-engineering/docs/rules-appendix/agent-spawn-model.md`
