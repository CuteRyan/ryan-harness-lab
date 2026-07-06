# [부록] Agent Spawn Model 명시 규칙 — 위험·훅·검증·출처

> 글로벌 규칙 `~/.claude/rules/agent-spawn-model.md`의 근거 보관용 부록.
> 규칙 본문은 짧게(매 세션 로드), 위험·훅 메커니즘·검증 이력·출처는 여기 보존.
> 원본 작성: 2026-05-04 Day 19 turn 6 | 부록 분리: 2026-07-06 (하네스 다이어트)

---

## 위험 + 강제 훅 (원 규칙 §4, 활성 2026-05-04 turn 7 PASS)

**위험**: `model` 파라미터 누락 + settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 부재 환경에서 워커가 메인 model(Opus) 상속 → 작업당 비용 5배 + Anthropic 사용량 한도 빠른 소진.

**강제 훅 (활성)**: `~/.claude/hooks/pretooluse-agent-model-required.{sh,py}` (스테이징 ↔ 운영 SHA256 MATCH).
- settings.json `hooks.PreToolUse` 에 `{"matcher": "Task|Agent", "hooks": [...]}` 등록
- 검사 순위: (1) tool_name in ("Task","Agent") (2) `tool_input.model in {opus,sonnet,haiku}` 통과 (3) `subagent_type` frontmatter 예외 (4) 차단 = `permissionDecision: deny` JSON + stderr
- **차단 메커니즘**: Issue #26923 (CLOSED) + #40580 (OPEN) 의 "exit 2 가 서브에이전트 호출 무시" 알려진 버그 회피 = `permissionDecision: deny` JSON + exit 0 우회 (2026-05-04 turn 7 세계 1호 검증 PASS)
- 라이브 검증 (06 §11.3): 4 spawn 中 C(model 누락)=차단 PASS, A·B(명시)=통과, D(invalid)=SDK level 차단 (이중 보장)

**현 상태**: 강제 훅 등록 완료 + settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 (turn 7 Step 4 commit). fallback C+ 영구 적용 (메커니즘 3중 — 강제 훅 / env 제거 / 메인 재시작).

## 외부 리서치 (원 규칙 §5)

issue#32732 검증 (06 §9·§10) 기반. 외부 사례:
- Anthropic 공식 blog (Multi-Agent Research System, 2025) — Opus lead + Sonnet worker 조합 +90.2% 성능
- aws-samples/claude-code-cookbook — coding=Sonnet (review 만 Opus). 3 출처 동일 결론 (D-4 R-3 근거)

> [[research-mandatory]] 적용. 향후 본 규칙 갱신 시 외부 사실 인용 필수.

## 출처 (원 규칙 §6)

- **검증 보고서**: `docs/research/agent-office-masterplan/06_issue32732_experiment.md` §9 (turn 3 결정적 재현) + §10 (turn 6 PASS) + §11 (turn 7 강제 훅 PASS)
- **마스터플랜**: `docs/research/agent-office-masterplan/04_masterplan.md` §8.2 + §9.1
- **외부 출처**: [Issue #26923](https://github.com/anthropics/claude-code/issues/26923) + [Issue #40580](https://github.com/anthropics/claude-code/issues/40580) — exit 2 무시 버그 + permissionDecision 우회 가설
- **비전 SSOT**: `memory/agent-office-vision.md` D-4 (모델 배분 결정)
- **history**: `docs/history/2026-05-04.md`
