# presets.md — preset 카탈로그 요약 (presets/*.yaml 포인터)

> **Why on-demand 로드**: SKILL.md 가 항상 읽지 않음. LLM 이 preset 선택 시 1차 참조. 본 파일 후 `presets/<name>.yaml` 본문 Read.
> **출처**: Day 20 turn 1 (#009-B) 신설 자산 + 마스터플랜 §2.4 ② 회의실 preset 표 1:1 정합 5/5 PASS.
> **자동 매핑**: SKILL.md §2.5 키워드 매핑 표 + `resolve-preset.ps1 -List` 출력.

## 5 preset 요약 표

| Preset | YAML | team_size | members | 단계 의존성 | 트리거 키워드 |
|--------|------|----------|---------|------------|------------|
| **review** | `presets/review.yaml` | 3 | security-reviewer · performance-reviewer · correctness-reviewer | 병렬 | 코드 리뷰 / review / PR 검토 |
| **debug** | `presets/debug.yaml` | 3 | hypothesis-investigator → reproducer → solver | Pipeline | 버그 / debug / 디버그 / 재현 |
| **research** | `presets/research.yaml` | 3 | docs-researcher ‖ community-researcher → analyst | Parallel + 종합 | 조사 / 리서치 / research |
| **docs-research** | `presets/docs-research.yaml` | 4 | research 3 + architect | 4단계 Pipeline | 하네스 리서치 / ADR / 설계 결정 |
| **harness-design** | `presets/harness-design.yaml` | 3 | docs-researcher [D-15 통합] → architect → auditor | Pipeline | 스킬 설계 / 훅 설계 / 규칙 설계 |

## 각 preset 상세

### review (3, 병렬)
- **역할**: 코드 리뷰 — 보안·성능·정확성 3차원 병렬 검토
- **모델**: 全 sonnet (lead = pm 별도, opus)
- **task_template**: subject = `[명사형 - 리뷰 대상 + 차원]`, output 4 요소 (결론·출처[CVE/OWASP]·추측 금지·자기비판)
- **variations**:
  - `full_review` (3명 全, 기본)
  - `security_focused` (security + correctness 2명, 성능 영향 적은 영역)

### debug (3, Pipeline)
- **역할**: 버그 헌팅 — 가설 → 최소 재현 → 해결
- **모델**: 全 sonnet
- **단계**: hypothesis-investigator (1) → reproducer (2, blocked_by hypothesis) → solver (3, blocked_by reproducer)
- **task_template**: subject = `[명사형 - 버그 증상]`, output 4 요소 (결론·출처[file:line/commit]·추측 금지·자기비판)
- **variations**:
  - `default` (3 단계 직선)
  - `hypotheses_n` (가설 N개 병렬, zircote Parallel Specialists 변형)

### research (3, Parallel + 종합)
- **역할**: 기술 조사 — 공식 docs + 커뮤니티 병렬 후 analyst 종합
- **모델**: 全 sonnet
- **단계**: docs-researcher (1) ‖ community-researcher (1, 병렬) → analyst (2, blocked_by 둘 다)
- **task_template**: subject = `[명사형 - 조사 주제]`, output 4 요소 (결론·출처[직접 인용]·추측 금지·자기비판[일반화 한계 명시 R-9])
- **variations**:
  - `default` (3명, 기본)
  - `docs_only` (커뮤니티 자료 부족 시 2명)

### docs-research (4, 4단계 Pipeline)
- **역할**: 하네스 도메인 리서치 — research 3 + architect ADR
- **모델**: docs/community/analyst = sonnet, **architect = opus** (설계 결정 = Opus 영역)
- **단계**: docs ‖ community → analyst → architect (blocked_by analyst)
- **task_template**: subject = `[명사형 - 리서치 + 설계 주제]`, output 4 요소 + ADR 회귀 위험
- **variations**:
  - `default` (4명, 기본)
  - `research_only` (ADR 단계 생략 시 research preset 다운그레이드)

### harness-design (3, Pipeline)
- **역할**: 하네스 규칙·스킬 설계 — researcher (조사) → architect (설계) → auditor (검증)
- **모델**: docs-researcher · auditor = sonnet, **architect = opus**
- **단계**: docs-researcher (1, **D-15 researcher 통합**) → architect (2) → auditor (3)
- **task_template**: subject = `[명사형 - 하네스 설계 주제]`, output 4 요소 + audit false positive
- **variations**:
  - `default` (3명, 기본)
  - `design_only` (auditor 별도 turn 분리 시 2명)

## 보류 2 preset (#009-E)

다음 2 preset = 마스터플랜 §2.4 표 中 5/7 PASS, 2/7 보류. 별도 turn 신설 (#009-E).
- **feature** (4, lead/frontend/backend/tester) — 새 agent 4 신설 선행 필요 (Step A 12 agent 에 없음)
- **security** (3, SAST/DAST/compliance) — 새 agent 3 신설 선행 필요

추정 = 2 turn (agent 7 신설 + preset 2 신설 + SKILL.md §2.4 표 갱신).

## 4 요소 출력 형식 (모든 preset 공통)

모든 preset 의 `task_template.output_format_required` = 4 요소 의무 (turn 9 #014 + turn 11 R-10 + Day 20 turn 1 검증):
1. **결론** (1~2줄): 단계별 결과 요약 + Severity 또는 confidence
2. **출처**: URL + 발행일 + 직접 인용 1~2줄 (CVE/OWASP/공식 docs/HEAD SHA/file:line)
3. **추측 표현 금지**: `아마`·`보통`·`일반적으로` 사용 금지, 출처 없는 단언 금지
4. **자기비판 1줄**: false positive 가능성 또는 일반화 한계 명시 (R-9 정합)

## 호출 흐름 (`/agent-team run --preset <name>`)

```
1. preflight.ps1 -SkipTmux       → 5 검사 PASS
2. resolve-preset.ps1 -Preset <name>  → JSON 메타 (members + task_graph + protocol)
3. TeamCreate (LLM 직접)         → ~/.claude/teams/<name>-<slug>-<timestamp>/
4. TaskCreate × N (LLM 직접)     → task_graph.blocked_by 그대로 mapping
5. Agent spawn × N (LLM 직접)    → members[].name + model (강제 훅 통과)
6. run-team.ps1 -SentinelInit    → ~/.claude/tasks/<team>/.sentinel.json
7. (작업 진행, monitor-team 주기 호출)
8. SendMessage (lead ↔ 멤버)     → R-6 회신 의무
9. validate-team.ps1 -Team <name>  → 5 검증 (orphan/deadline/cycle_cap/duplicate/zombie)
10. (LLM 종합 보고서 작성, /feedback 검수 권장)
11. shutdown-team.ps1 -Team <name>  → archive (R-5 정합, 사용자 컨펌)
```

## 출처

- 마스터플랜 `04_masterplan.md §2.4` (② 회의실 preset 표) + `§9.1` (review cycle cap 출처)
- v2 spec `04_redesign-spec.md §1` (디렉토리 구조) — 단독 구현 금지된 spec 의 명세 부분만 차용
- wshobson/agents HEAD `ece811f23310a37ceb43496dbac0e244fe6845b6` (preset-teams.md 양식 차용)
- aws-samples/sample-claude-code-agent-team HEAD `67840be315fad3ef252c06ccfe35d6ab9a2d43d6` (review cycle cap 3)
- Day 20 turn 1 (#009-B) 산출물 + Day 20 turn 3 (#009-D-1) 호출 자동화
