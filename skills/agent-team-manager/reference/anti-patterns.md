# anti-patterns.md — A1~A15 실패 모드 + Fix

> **Why on-demand 로드**: SKILL.md 가 항상 읽지 않음. LLM 이 트러블슈팅 시 또는 가드레일 (§5) 위반 의심 시 본 파일 Read.
> **출처**: 본 비전 누적 R-1~R-15 + 메모리 + Day 19 turn 7~12 + Day 20 turn 1·2·3 학습 통합.
> **검출**: `preflight.ps1` (A1~A4) + `validate-team.ps1` (A14) + 글로벌 강제 훅 (A1·A2) 자동 검출. 나머지 = LLM (메인 Claude) 의 가드레일 §5 점검 의무.

## 목차

1. [A1: 단독 Agent 호출 (4-step 우회)](#a1)
2. [A2: 워커 model 누락](#a2)
3. [A3: env CLAUDE_CODE_SUBAGENT_MODEL 잔존](#a3)
4. [A4: 단순 조회에 ② 회의실 (15× 비용)](#a4)
5. [A5: 외부 검증에 ② 회의실 (Echo chamber)](#a5)
6. [A6: PM 협의 생략 (R-2 약화)](#a6)
7. [A7: SendMessage 회신 누락 (R-6)](#a7)
8. [A8: ④ 파이프라인 누락 (R-4)](#a8)
9. [A9: Haiku 워커 사용](#a9)
10. [A10: review_cycle_cap > 3 (무한 루프)](#a10)
11. [A11: preset YAML 직접 편집 (단방향 위반)](#a11)
12. [A12: 운영 디렉토리 수정 (스테이징 우회)](#a12)
13. [A13: 한글 경로 + Codex (codex-cwd 위반)](#a13)
14. [A14: 좀비 팀 방치 (orphan)](#a14)
15. [A15: 한글 ps1 + UTF-8 BOM 부재](#a15)

---

## A1
**증상**: 메인 Claude 가 `Agent({...})` 만 호출 (TeamCreate 없이 즉석 spawn)
**원인**: 4-step 프로토콜 우회 (글로벌 CLAUDE.md `⚠️ 금지` 항목)
**검출**: 글로벌 강제 훅 `pretooluse-agent-model-required.{sh,py}` 자동 차단 (turn 7 #018, `Task|Agent` matcher)
**Fix**: SKILL.md §1 4-step 순차 실행 (TeamCreate → TaskCreate → Agent spawn → SendMessage). 단순 작업 (≤ 10 tool call) 은 §2.1 heuristic 의 "직접 (4-step 생략)" 항목 적용.

## A2
**증상**: Agent spawn 시 `model` 파라미터 부재 → 차단 (`permissionDecision: deny`)
**원인**: 글로벌 강제 훅 (turn 7 #018) `Task|Agent` matcher 가 `tool_input.model` 부재 검사
**검출**: 강제 훅 자동 차단 + JSON deny 메시지 출력
**Fix**: 모든 spawn 에 `model: opus | sonnet` 명시 (`pm`/`architect`=opus, 나머지 워커=sonnet). frontmatter `model:` 명시된 agent 만 예외 (rules/agent-spawn-model.md §3).

## A3
**증상**: PowerShell `Get-ChildItem Env:CLAUDE_CODE_SUBAGENT_MODEL` 결과 변수 잔존
**원인**: settings.json env 영구 제거 누락 또는 메인 재시작 미수행 (fallback C+ 위반)
**검출**: `preflight.ps1` 의 `env_subagent_model_absent` 검사 fail
**Fix**: settings.json `env` 섹션에서 `CLAUDE_CODE_SUBAGENT_MODEL` 제거 + 메인 Claude Code 재시작. fallback C+ 메커니즘 3중 全 만족 의무 (turn 7 #018 + turn 8 #019).

## A4
**증상**: 3~5 tool call 단순 조회에 review preset (3명) 호출
**원인**: §2.1 heuristic 표 무시 (단순 조회는 ① 인턴 단독)
**검출**: 사후 토큰 비용 분석 (~15× 단일 인턴 대비, 마스터플랜 §3.2)
**Fix**: 작업 진입 전 SKILL.md §2.1 heuristic 표 확인 + bypass_threshold (Phase 2 자동화) 활용. 보수적 default = ① 인턴 단독.

## A5
**증상**: 워커 산출물 검증을 ② 회의실 다른 멤버에게 의뢰
**원인**: Echo chamber (같은 Claude 계열) — R-2 위반
**검출**: 사후 검수 패턴 분석 (외부 ③ CLI 호출 누락)
**Fix**: 워커 산출물 = `/feedback orchestrate` 호출 (Codex / Gemini / Claude Sub 병렬). 다른 모델 시각 = R-2 보호막.

## A6
**증상**: 사장 (메인 Claude) 이 PM 협의 없이 직접 워커 spawn
**원인**: PM `agents/pm.md` (turn 11 신설) 활용 누락 (R-2 약화)
**검출**: SKILL.md §6 의 `--pm-consult` 모드 미사용 패턴
**Fix**: 비전 R-1·R-2 정합 → PM 협의 → preset 추천 → 사장 spawn 대행. 단순 작업 (heuristic 표 명확) 시만 PM 협의 생략 가능.

## A7
**증상**: teammate spawn 후 lead (사장) 가 결과 미수신 → 다음 단계 진입 불가
**원인**: spawn 텍스트 출력만으로는 lead 미수신 (turn 6 §6-1 발견, turn 8 R-8 안정성 PASS 후 결정적)
**검출**: 사후 시간 추적 — spawn 후 timeout 도달
**Fix**: 모든 워커 prompt 마지막에 "결과를 SendMessage 로 lead 에게 회신" 명시. lead = `team_name` + `to=lead-name` 으로 수신.

## A8
**증상**: 4가지 워커 (①②③④) 中 ④ 파이프라인 누락 (3가지로 축소)
**원인**: R-4 가드 위반 (마스터플랜 §6 + SKILL.md §5)
**검출**: SKILL.md §2.2 4가지 워커 메커니즘 표 미인용
**Fix**: 항상 ① 인턴 + ② 회의실 + ③ 외부 CLI + ④ 파이프라인 4종 인지. zircote 7패턴 (`reference/patterns.md` §1·§4·§5·§6·§7) = ④ 파이프라인 하위.

## A9
**증상**: preset YAML `members[].model: haiku` 또는 spawn `model="haiku"` 사용
**원인**: 메모리 `feedback_no_haiku.md` 정책 위반 (사용자 명시 선호)
**검출**: `resolve-preset.ps1` 의 schema 검증 = `member '<name>' model=haiku violates feedback_no_haiku.md policy`
**Fix**: model 선택 = `opus` (PM·architect) 또는 `sonnet` (나머지). Haiku = 사용자 명시 요청 시만 예외 (글로벌 메모리 인용).

## A10
**증상**: review 사이클 4회+ 발생 (cap 3 초과)
**원인**: PM 에스컬레이션 누락 또는 무한 루프 (aws-samples HEAD `67840be3` 인용 cap 위반)
**검출**: `validate-team.ps1` 의 `cycle_cap_exceeded` issue
**Fix**: cycle 3회 도달 시 PM (`agents/pm.md`) 가 (a) 산출물 재설계 결정 또는 (b) 사장 에스컬레이션. preset YAML `escalation_after_cap` 필드 인용.

## A11
**증상**: `~/.claude/presets/<name>.yaml` 직접 편집 (운영 디렉토리)
**원인**: D-11/D-16/D-20 단방향 sync 정책 위반 (스테이징 only 편집 의무)
**검출**: `git status` 에 운영 변경 미반영 → 다음 sync 시 스테이징 덮어쓰기로 운영 변경 손실
**Fix**: 스테이징 (`presets/<name>.yaml`) 만 편집 → 운영 sync (Copy-Item -Force). SHA256 MATCH 검증. drift 발견 시 = 프로젝트 (스테이징) 가 정답 (글로벌 룰 정합).

## A12
**증상**: A11 의 일반화 = 운영 `~/.claude/{skills,agents,rules,presets,scripts}/` 직접 편집
**원인**: 스테이징/운영 분리 정책 (D-11/D-16/D-22) 위반
**검출**: 양측 SHA256 MISMATCH → 다음 sync 시 운영 변경 손실
**Fix**: 모든 자산 편집 = 스테이징 only (Harness-engineering/). 운영 = sync 결과만. 글로벌 `~/.claude/CLAUDE.md` Documentation 섹션 정합.

## A13
**증상**: Codex CLI 가 한글 경로 (예: `C:\Users\rlgns\OneDrive\문서\...`) 에서 CP949 깨짐 / 재귀 스캔 폭주
**원인**: Codex CLI 의 한글 경로 호환성 부재 (2026-04-19 실측 3종)
**검출**: Codex 호출 후 출력 mojibake 또는 timeout
**Fix**: 글로벌 CLAUDE.md 정합 = `~/codex-cwd/<슬러그>/` 영문 workdir 표준. `/feedback` 스킬 자동 적용. Gemini = 영향 없어 원본 경로 사용 가능.

## A14
**증상**: `~/.claude/teams/<name>/` 잔존하나 작업 종료 후 정리 안 됨
**원인**: shutdown-team.ps1 호출 누락 또는 중간 abort
**검출**: `validate-team.ps1 -AllTeams` 의 `orphan_no_sentinel` issue (Day 20 turn 3 R-14 = 71개 발견)
**Fix**: `shutdown-team.ps1 -Team <name>` 호출 (기본 archive). 일괄 정리 = `validate-team -AllTeams` → orphan 列舉 → `shutdown-team -Team <name>` × N (별도 turn 권장 = #021).

## A15
**증상**: PowerShell 5.1 에서 한글 주석 ps1 실행 시 `Unexpected token '}'` parse 에러
**원인**: UTF-8 BOM 부재 → CP949 fallback → here-string 종결 (`"@`) 인식 실패 (Day 20 turn 3 발견)
**검출**: `[Parser]::ParseFile($path)` 호출 후 `$errors.Count > 0`
**Fix**: 모든 한글 주석 ps1 = UTF-8 BOM 의무. 신설/편집 후 다음 명령:
```powershell
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
$content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
[System.IO.File]::WriteAllText($path, $content, $utf8Bom)
```
Python 호출 시 = `$env:PYTHONIOENCODING='utf-8'` + `sys.stdout = io.TextIOWrapper(buffer, encoding='utf-8')` 이중 보장.
