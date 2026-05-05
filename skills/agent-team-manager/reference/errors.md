# errors.md — preflight / validate / resolve-preset 실패 reason 코드별 해결법

> **Why on-demand 로드**: SKILL.md 가 항상 읽지 않음. LLM 이 스크립트 호출 후 fail/issue 발생 시 본 파일 Read.
> **출처**: `scripts/preflight.ps1` (Day 20 turn 3) + `scripts/validate-team.ps1` (Day 20 turn 3) + `scripts/resolve-preset.ps1` (Day 20 turn 3) 의 fail/issue type 全 列舉.

## 목차

1. [preflight.ps1 errors](#1-preflightps1-errors)
2. [validate-team.ps1 issues](#2-validate-teamps1-issues)
3. [resolve-preset.ps1 schema errors](#3-resolve-presetps1-schema-errors)
4. [common runtime errors](#4-common-runtime-errors)

---

## 1. preflight.ps1 errors

### `env_subagent_model_absent` = fail
**증상**: `CLAUDE_CODE_SUBAGENT_MODEL=<value>` 잔존
**원인**: settings.json env 영구 제거 누락 또는 메인 재시작 미수행
**해결**: settings.json `env` 섹션 제거 + 메인 Claude Code 재시작 → fallback C+ 메커니즘 3중 全 만족
**관련**: anti-patterns A3 / `06_issue32732_experiment.md §10·§11·§12` / turn 7 #018 + turn 8 #019

### `claude_code_version` = warn
**증상**: `claude --version` < 2.1.126 또는 출력 파싱 실패
**원인**: 강제 훅 `Task|Agent` matcher 작동 보장 안 됨 (Issue #26923 우회 패턴 미지원 가능)
**해결**: `claude --version` 확인 + 필요 시 업그레이드 (자동 update 또는 수동)
**관련**: turn 7 #018 + Issue #26923

### `main_claude_context` = fail
**증상**: 본 스크립트가 워커 (subagent) 컨텍스트에서 호출됨
**원인**: nested team 시도 (issue#32731 = teammate 가 `Agent`/`TeamCreate` 도구 없음)
**해결**: 메인 Claude (사장) 에서만 호출. 워커가 추가 spawn 필요 시 = lead 가 결과 회신 → 사장이 다음 단계 spawn 대행
**관련**: anti-patterns A7 + 마스터플랜 §9.1 nested team 가드

### `powershell_version` = fail
**증상**: PowerShell < 5.0
**원인**: 미지원 환경 (Win7 또는 PS 2.0)
**해결**: PowerShell 5.1 (Windows 10/11 기본) 또는 7+ 업그레이드

### `pyyaml_module` = fail
**증상**: `python -c "import yaml"` 실패
**원인**: pyyaml 미설치 (resolve-preset.ps1 의존성)
**해결**: `pip install pyyaml` 또는 `python -m pip install pyyaml`. Day 20 turn 1 검증 PASS = pyyaml 6.0.3.

### `tmux_available` = warn (Critical=false)
**증상**: tmux 미설치 (Windows 환경)
**원인**: Windows = tmux 부재 정상 (display_mode: tmux 사용 시 inline fallback)
**해결**: `-SkipTmux` 옵션 사용 (Windows 권장) 또는 WSL/Linux 환경에서 tmux 설치

---

## 2. validate-team.ps1 issues

### `orphan_no_sentinel`
**증상**: `~/.claude/teams/<name>/` 존재하나 `~/.claude/tasks/<name>/.sentinel.json` 부재
**원인**: 작업 종료 후 정리 누락 또는 중간 abort
**해결**: `shutdown-team.ps1 -Team <name>` 호출 (기본 archive). 일괄 정리 별도 turn 권장 (#021).
**관련**: anti-patterns A14 / R-14 (Day 20 turn 3 71개 발견)

### `team_meta_missing`
**증상**: `~/.claude/teams/<name>/` 디렉토리 부재
**원인**: 팀 이름 오타 또는 이미 archive 됨
**해결**: `validate-team.ps1 -AllTeams` 로 전체 列舉 → 정확한 팀 이름 확인. 또는 `~/.claude/teams/.archived/` 검색.

### `sentinel_parse_fail`
**증상**: `.sentinel.json` 파싱 실패
**원인**: JSON 손상 (수동 편집 또는 inscription 깨짐)
**해결**: `cat <sentinel>` 로 내용 확인 → 필요 시 `run-team.ps1 -SentinelInit` 재실행 (sentinel 재생성). 또는 archive.

### `deadline_exceeded`
**증상**: `sentinel.deadline < now` (deadline 초과)
**원인**: 작업 시간 추정 실패 또는 무한 대기
**해결**: `monitor-team.ps1 -Team <name>` 으로 진행 상태 확인 → (a) deadline 연장 (`run-team -SentinelInit -TimeoutMinutes <new>`) 또는 (b) `shutdown-team.ps1` archive.

### `cycle_cap_exceeded`
**증상**: `review_cycle_count > review_cycle_cap` (기본 3)
**원인**: 무한 review 루프 (PM 에스컬레이션 누락)
**해결**: PM (`agents/pm.md`) 협의 → (a) 산출물 재설계 또는 (b) 사장 에스컬레이션. preset YAML `escalation_after_cap` 필드 참조.
**관련**: anti-patterns A10 / aws-samples HEAD `67840be3` `skills/spec-workflow/SKILL.md:65`

### `duplicate_task_id`
**증상**: 동일 task id 의 owner 가 다중 존재
**원인**: spawn 시 task 중복 생성 (메인 Claude 의 TaskCreate 중복 호출)
**해결**: `~/.claude/tasks/<team>/*.json` 파일 列舉 → 중복 task 中 1개 보존, 나머지 archive. `shutdown-team.ps1` 후 새 팀으로 재시작 권장.

### `zombie_task`
**증상**: task `status != completed` + `deadline < now`
**원인**: 워커 abort 또는 SendMessage 회신 누락 (R-6)
**해결**: `monitor-team.ps1` 로 멤버 inbox/outbox 확인 → 회신 누락 워커 재 spawn 또는 archive.
**관련**: anti-patterns A7 / R-6 SendMessage 회신 의무

### `task_parse_fail`
**증상**: task json 파일 파싱 실패
**원인**: JSON 손상
**해결**: 손상 파일 archive + `validate-team -AllTeams` 재실행.

---

## 3. resolve-preset.ps1 schema errors

### `missing required key: <key>`
**증상**: preset YAML 에 필수 키 부재 (`name`/`description`/`members`/`task_template`/`protocol`/`review_cycle_cap`)
**원인**: preset 양식 위반 (Day 20 turn 1 D-17 본 비전 SSOT 위반)
**해결**: 기존 preset (예: `presets/review.yaml`) 양식 차용 → 누락 키 추가. `resolve-preset.ps1 -ValidateOnly -Path <file>` 재검증.

### `member '<name>' missing 'name'` 또는 `'model'`
**증상**: members 배열 中 1건 이상 필수 필드 부재
**원인**: YAML 들여쓰기 오류 또는 필드명 오타
**해결**: 기존 preset 양식 차용 → 모든 멤버에 `name` + `model` 명시.

### `member '<name>' model='<x>' not in [opus, sonnet, haiku]`
**증상**: invalid model 명
**원인**: 오타 또는 미지원 model (예: `gpt-4`)
**해결**: `opus | sonnet | haiku` 中 1개 선택. SDK enum 차단 (turn 7 D=invalid `gpt-5` 검증).

### `member '<name>' model=haiku violates feedback_no_haiku.md policy`
**증상**: 워커에 haiku 사용
**원인**: 메모리 `feedback_no_haiku.md` 정책 위반
**해결**: `opus` (PM·architect) 또는 `sonnet` (나머지) 로 변경. 사용자 명시 요청 시만 예외.
**관련**: anti-patterns A9

### `protocol.steps count != 4 (got <n>)`
**증상**: protocol 섹션 steps 가 4 아님
**원인**: 4-step 프로토콜 위반 (TeamCreate → TaskCreate → Agent spawn → SendMessage)
**해결**: 기존 preset 의 `protocol` 섹션 차용. 마스터플랜 §10.2 v2 P0 항목 (O1 4-step) 정합 의무.

### `review_cycle_cap != 3 (got <n>)`
**증상**: cap 가 3 아님
**원인**: aws-samples HEAD `67840be3` 정합 위반
**해결**: `review_cycle_cap: 3` 으로 변경 + `escalation_after_cap` 본문 인용.

### `task_template.output_format_required count != 4`
**증상**: output 4 요소 (결론·출처·추측 금지·자기비판) 부재
**원인**: pm-test (turn 9 #014) 강화 양식 정합 위반
**해결**: 4 요소 全 명시: ① 결론 (1~2줄) ② 출처 (URL+발행일+직접 인용) ③ 추측 표현 금지 (`아마`·`보통`·`일반적으로`) ④ 자기비판 1줄.

---

## 4. common runtime errors

### `YAML parse failed: <path>`
**증상**: pyyaml `yaml.safe_load` 실패
**원인**: YAML 문법 오류 (들여쓰기·따옴표·escape)
**해결**: `python -c "import yaml; yaml.safe_load(open('<path>'))"` 직접 실행 → 정확한 line:col 확인. 들여쓰기 = 2 space 일관 의무.

### `cp949 codec can't encode character '—'`
**증상**: Python stdout 인코딩 cp949 fallback 실패 (em-dash 등 유니코드)
**원인**: PowerShell 5.1 default = system code page (Korean Windows = CP949)
**해결**: `$env:PYTHONIOENCODING='utf-8'` + `sys.stdout = io.TextIOWrapper(buffer, encoding='utf-8')` 이중 보장. `resolve-preset.ps1` 패턴 차용.
**관련**: anti-patterns A15 / R-15

### `Unexpected token '}' in expression or statement`
**증상**: PowerShell 5.1 에서 한글 주석 ps1 parse 실패
**원인**: UTF-8 BOM 부재 → CP949 fallback → here-string 종결 (`"@`) 인식 실패
**해결**: 6 ps1 파일 全 UTF-8 BOM 추가 (Day 20 turn 3 정정 패턴):
```powershell
$utf8Bom = [System.Text.UTF8Encoding]::new($true)
$content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
[System.IO.File]::WriteAllText($path, $content, $utf8Bom)
```
**관련**: anti-patterns A15 / R-15

### `permissionDecision: deny` (Agent spawn)
**증상**: 글로벌 강제 훅 차단
**원인**: `model` 파라미터 부재 또는 non-frontmatter agent (`general-purpose`) 에 model 명시 누락
**해결**: spawn 시 `model: opus | sonnet` 명시. frontmatter `model:` 가진 agent (예: pm/architect) 만 예외.
**관련**: anti-patterns A1·A2 / turn 7 #018 + Issue #26923 우회 패턴
