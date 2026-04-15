---
title: Codex 하네스 리팩터링 작업 기록
type: audit
status: final
created: 2026-04-15
related_code:
  - ../.gitignore
  - ../settings/settings.json
  - ../settings/settings.template.json
  - ../hooks/_harness_common.sh
  - ../hooks/run-hook.ps1
  - ../hooks/dev-checklist-guard.sh
  - ../hooks/doc-checklist-guard.sh
  - ../hooks/doc-protection.sh
  - ../hooks/post-edit-verify.sh
  - ../hooks/pre-commit-guard.sh
  - ../hooks/code-doc-sync.sh
  - ../hooks/doc-template-guard.sh
  - ../hooks/wiki-index-guard.sh
  - ../hooks/graphify-reminder.sh
  - ../skills/project-history/SKILL.md
related_docs:
  - harness_refactor_plan.md
  - project_harness_architecture.md
  - HISTORY.md
  - log.md
---

# Codex 하네스 리팩터링 작업 기록

작성일: 2026-04-15

작업 주체: Codex

작업 대상:
- 로컬 하네스 저장소: `C:\Users\rlgns\OneDrive\문서\하네스`
- Claude Code 전역 설정: `C:\Users\rlgns\.claude`

## 1. 작업 배경

오늘 작업은 기존 하네스에 대한 냉정한 진단에서 시작했다.

핵심 문제는 다음이었다.

- 훅 수는 많지만 실제 강제력은 얕았다.
- 체크리스트 훅은 파일 존재만 확인하고 내용 품질은 보지 않았다.
- 규칙은 엄격하지만 훅은 느슨해서 에이전트가 최소 저항 경로를 택할 수 있었다.
- `settings.json`의 Bash/Python/PowerShell 권한이 너무 넓어 훅 우회가 쉬웠다.
- 문서 작업에서 `.dev-checklist.md`와 `.doc-checklist.md`가 동시에 요구되는 데드락이 있었다.
- 잡음성 훅이 작업 중 계속 경고를 내며 원래 작업 흐름을 방해했다.
- PostToolUse 검증이 없어 수정 후 깨진 파일을 바로 잡지 못했다.
- Windows 환경에서 `bash`가 PATH에 없으면 Claude Code 훅이 실행되지 않을 수 있었다.

작업 원칙은 다음 한 줄로 정리했다.

> 훅은 적게, 깊게. 규칙은 적게, 강제로.

## 2. 전체 결과 요약

오늘 적용한 결과는 다음과 같다.

- 위험한 권한을 줄였다.
- 잡음성 훅을 기본 배선에서 제거했다.
- pre-commit 훅을 통합했다.
- 코드 체크리스트와 문서 체크리스트의 책임을 분리했다.
- 체크리스트 품질 검증과 승인 마커를 실제 훅에서 강제했다.
- `.harness.yml`의 `features.*` 값을 실제 훅 동작에 연결했다.
- tiny edit 면제 정책을 추가했다.
- PostToolUse 검증을 추가했다.
- 문서 보호 훅을 하나로 병합했다.
- Python/PowerShell 기반 문서 쓰기 우회 경로를 더 많이 차단했다.
- 스킬 frontmatter를 통일했다.
- Windows에서 `bash` PATH에 의존하지 않도록 `run-hook.ps1`을 추가했다.
- 모든 변경을 전역 `~/.claude`에 동기화했다.
- 주요 훅에 PowerShell 기반 스모크 테스트를 추가했다.

## 3. P0 작업 기록

### 3.1 settings 권한 축소

수정 대상:
- `settings/settings.json`
- `settings/settings.template.json`
- `C:\Users\rlgns\.claude\settings.json`

적용 내용:
- `skipDangerousModePermissionPrompt` 제거
- 광범위 Bash 권한 제거
- Python 직접 실행 허용 제거
- PowerShell 직접 실행 허용 제거
- 일회성 base64 파일 생성 허용 제거
- 추적 가능한 `settings/settings.template.json` 추가

의도:
- 훅이 강화되어도 권한 설정에서 우회되면 의미가 없으므로, 권한 표면을 먼저 줄였다.

남긴 정책:
- `WebFetch`
- `WebSearch`
- 제한된 읽기성 Git 명령
- `rg`, `ls`, `find`, `wc`
- `pip show`
- `tasklist`

### 3.2 잡음 훅 기본 배선 제거

settings의 Edit matcher에서 제거한 훅:
- `venv-guard.sh`
- `graphify-reminder.sh`
- `code-doc-sync.sh`

의도:
- 작업 중 해결할 성격이 아닌 경고를 매 Edit마다 출력하지 않도록 했다.
- graphify, venv, code-doc 상태는 작업 중 경고가 아니라 audit 성격으로 다루는 방향으로 이동했다.

### 3.3 docs 체크리스트 데드락 제거

수정 대상:
- `hooks/dev-checklist-guard.sh`
- `hooks/doc-checklist-guard.sh`

기존 문제:
- 문서 파일 수정 시 `.dev-checklist.md`와 `.doc-checklist.md`가 모두 요구될 수 있었다.

변경 후:
- 코드 파일은 `.dev-checklist.md` 담당
- 문서 파일은 `.doc-checklist.md` 담당
- `docs/`, `rules/`, `.md`, `.rst`, `.txt` 등은 dev guard에서 제외

### 3.4 pre-commit 훅 병합

삭제한 훅:
- `hooks/pre-commit-test.sh`
- `hooks/lint-guard.sh`

추가한 훅:
- `hooks/pre-commit-guard.sh`

역할:
- `git commit` 감지
- staged Python 파일이 있으면 `ruff check`
- `tests/`가 있고 Python이 있으면 `pytest`
- `ruff`나 `pytest`가 없으면 차단하지 않고 통과

의도:
- 같은 Bash matcher에서 여러 훅이 같은 stdin을 반복 파싱하지 않도록 했다.
- commit 전 검증 순서를 한 파일에서 명확히 관리하도록 했다.

### 3.5 공식 훅 회피 전략 제거

수정 대상:
- `skills/project-history/SKILL.md`

변경 내용:
- 훅 우회를 정상 절차처럼 안내하던 문장을 제거했다.
- 필요한 경우 정책화된 예외로 처리하도록 방향을 바꿨다.

## 4. P1 작업 기록

### 4.1 체크리스트 품질 검증

수정 대상:
- `hooks/_harness_common.sh`
- `hooks/dev-checklist-guard.sh`
- `hooks/doc-checklist-guard.sh`

추가한 공통 함수:
- `harness_has_heading`
- `harness_checklist_has_approval`
- `harness_checklist_item_count`
- `harness_checklist_has_trivial_item`
- `harness_validate_checklist`

개발 체크리스트 필수 섹션:
- `## 구현 항목` 또는 `## 작업 항목`
- `## 수정 대상 파일`
- `## 검증 항목`
- `## 더블 체크`

영문 호환 섹션:
- `## Tasks`
- `## Implementation`
- `## Changed Files`
- `## Target Files`
- `## Files`
- `## Verification`
- `## Double Check`

문서 체크리스트 필수 섹션:
- `## 작업 범위` 또는 `## 작업 내용`
- `## 연관 문서`
- `## 교차 검증`
- `## 더블 체크`

문서 체크리스트 영문 호환 섹션:
- `## Scope`
- `## Work Scope`
- `## Content`
- `## Related Docs`
- `## Related Documents`
- `## Cross Check`
- `## Cross Verification`
- `## Double Check`

차단 조건:
- 승인 마커 없음
- 필수 섹션 없음
- 체크박스 항목 3개 미만
- `구현`, `확인`, `수정`, `fix`, `check` 같은 한 단어 항목만 있는 경우

승인 마커로 인정하는 형식:
- `status: approved`
- `approved: true`
- `- [x] 승인`
- `- [x] approved`

### 4.2 Windows 인코딩 대응

테스트 과정에서 PowerShell 5가 BOM 없는 `.ps1`의 한글 리터럴을 ANSI로 해석할 수 있음을 확인했다.

대응:
- 체크리스트 섹션은 한글과 영문을 모두 허용했다.
- 테스트 fixture는 ASCII 중심으로 작성했다.
- 한글 문서 자체는 유지하되, 테스트 안정성은 OS 로케일에 덜 의존하게 했다.

### 4.3 feature 파싱 추가

수정 대상:
- `hooks/_harness_common.sh`
- `hooks/wiki-index-guard.sh`
- `hooks/doc-template-guard.sh`
- `hooks/code-doc-sync.sh`
- `hooks/graphify-reminder.sh`

추가한 함수:
- `harness_feature_value`
- `harness_feature_enabled`

지원 형식:

```yaml
harness: true
features:
  wiki: true
  doc_templates: true
  code_doc_sync: true
  graphify: true
```

또는:

```yaml
features.wiki: true
```

기본 정책:
- optional feature 기본값은 `false`
- 명시적으로 true인 기능만 켜짐

feature 연결:
- `features.wiki` -> `wiki-index-guard.sh`
- `features.doc_templates` -> `doc-template-guard.sh`
- `features.code_doc_sync` -> `code-doc-sync.sh`
- `features.graphify` -> `graphify-reminder.sh`

### 4.4 느린 훅 로그 추가

수정 대상:
- `hooks/_harness_common.sh`
- 주요 훅들

추가한 함수:
- `harness_timer_start`
- `harness_timer_stop`

정책:
- 500ms 이상 걸린 훅은 `.claude/harness-audit.log`에 `slow` 로그 기록
- `PROJECT_ROOT`가 확인된 경우에만 로그 기록

의도:
- 느린 훅을 감으로 판단하지 않고 실제 로그로 판단하도록 했다.

### 4.5 스킬 frontmatter 통일

수정 대상:
- `skills/agent-team-manager/SKILL.md`
- `skills/daily-report/SKILL.md`
- `skills/graphify/SKILL.md`
- `skills/memory-manager/SKILL.md`
- `skills/portfolio/SKILL.md`
- `skills/project-history/SKILL.md`
- `skills/project-structure/SKILL.md`
- `skills/research-knowledge/SKILL.md`

통일한 필드:
- `name`
- `description`
- `trigger`
- `user-invocable`

정리 내용:
- `user_invocable` 제거
- frontmatter가 없던 스킬에 frontmatter 추가
- 호출형 스킬에 `argument-hint`, `allowed-tools` 보강

## 5. P2 작업 기록

### 5.1 tiny edit 면제

수정 대상:
- `hooks/_harness_common.sh`
- `hooks/dev-checklist-guard.sh`
- `hooks/doc-checklist-guard.sh`

추가한 함수:
- `harness_value_line_count`
- `harness_tiny_edit_allowed`

면제 조건:
- tool이 `Edit`
- `old_string`이 3줄 이하
- `new_string`이 3줄 이하
- `old_string`이 240자 이하
- `new_string`이 240자 이하

면제하지 않는 작업:
- `Write`
- Bash
- 삭제
- 배포
- 3줄 초과 수정
- 240자 초과 수정

로그:
- tiny edit으로 통과한 경우 `tiny-exempt` audit 로그 기록

의도:
- 오탈자와 작은 주석 수정까지 6단계 체크리스트를 요구하지 않도록 했다.

### 5.2 PostToolUse 최소 검증

추가한 훅:
- `hooks/post-edit-verify.sh`

settings 연결:
- `PostToolUse` `Edit`
- `PostToolUse` `Write`

초기 검증 항목:
- Python 파일 `py_compile`
- Markdown 상대 로컬 링크 존재 여부
- 병합 충돌 마커

### 5.3 PostToolUse 검증 확장

추가 검증:
- frontmatter가 있으면 필수 필드 확인
- `features.doc_templates: true`인 신규 docs 문서는 PostToolUse에서도 frontmatter 존재 확인
- `.dev-checklist.md`의 완료된 `Changed Files` 항목이 실제 파일을 가리키는지 확인
- `.doc-checklist.md`의 완료된 `Related Docs` 항목이 실제 파일을 가리키는지 확인

frontmatter 필수 필드:
- `title`
- `type`
- `status`
- `created`

검증 범위 조정:
- 모든 체크박스를 무작정 파일 경로로 보지 않았다.
- 파일 경로가 있어야 하는 섹션만 검사했다.
- dev 체크리스트는 `Changed Files`, `Target Files`, `Files` 계열 섹션만 검사했다.
- doc 체크리스트는 `Related Docs`, `Related Documents` 계열 섹션만 검사했다.

의도:
- 체크박스만 완료 처리했는데 실제 파일이 없거나, frontmatter가 깨진 문서를 다음 작업까지 방치하지 않도록 했다.

### 5.4 code-doc-sync 무음화

수정 대상:
- `hooks/code-doc-sync.sh`

기존 동작:
- `features.code_doc_sync: true`인데 `docs/.harness-index.json`이 없으면 사용자 경고 출력

변경 후:
- 인덱스가 없으면 사용자 출력 없이 통과
- audit 로그에는 `skip` 기록
- 인덱스가 있을 때만 관련 문서/코드 리마인더 출력

의도:
- 준비되지 않은 프로젝트에서는 완전 무음
- 준비된 프로젝트에서만 유용한 리마인더 제공

### 5.5 문서 보호 훅 병합

삭제한 훅:
- `hooks/block-write-docs.sh`
- `hooks/bash-doc-guard.sh`

추가한 훅:
- `hooks/doc-protection.sh`

보호 범위:
- 기존 문서/설정 파일에 대한 `Write` 덮어쓰기 차단
- Bash `sed -i` 차단
- Bash `perl -i` 차단
- Bash `>`, `>>` 차단
- Bash `tee` 차단
- PowerShell `Set-Content`, `Add-Content`, `Out-File` 차단
- Python/Node 계열 쓰기 API 차단
- `mv`, `cp` 기반 문서/설정 파일 덮어쓰기 가능성 차단

예외:
- `.backups` 관련 작업
- `git ...` 명령
- 신규 문서 `Write`
- 코드 파일 `Write`

의도:
- 같은 목적의 훅을 하나로 줄였다.
- 기존 Bash 보호 훅이 잡지 못하던 Python/PowerShell 우회 경로를 보강했다.

## 6. Windows 훅 실행 경로 안정화

### 6.1 발견한 문제

전역 `settings.json`은 훅 command를 다음처럼 호출하고 있었다.

```text
bash ~/.claude/hooks/some-hook.sh
```

그러나 현재 PowerShell 환경에서 `bash`는 PATH에 없었다.

확인 결과:
- `C:\Program Files\Git\bin\bash.exe`는 존재
- `Get-Command bash`는 실패

즉, 훅 파일과 settings가 모두 있어도 Claude Code 실행 환경에서 `bash`를 찾지 못하면 하네스가 실행되지 않을 수 있었다.

### 6.2 적용한 해결책

추가한 파일:
- `hooks/run-hook.ps1`
- `C:\Users\rlgns\.claude\hooks\run-hook.ps1`

역할:
- Git Bash 절대 경로 사용
- 전역 훅 파일 존재 확인
- stdin JSON raw bytes를 Bash 훅으로 그대로 전달
- Bash 훅 exit code를 그대로 반환

Git Bash 경로:

```text
C:\Program Files\Git\bin\bash.exe
```

settings command 변경 예:

```text
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\rlgns\.claude\hooks\run-hook.ps1' 'doc-protection.sh'"
```

검증:
- repo settings에 `bash ~/.claude` 참조 없음
- 전역 settings에 `bash ~/.claude` 참조 없음
- repo settings에 `run-hook.ps1` 참조 있음
- 전역 settings에 `run-hook.ps1` 참조 있음
- 전역 settings command 경유 `run-hook.ps1` stdin raw bytes 전달 확인
- 전역 settings command 경유 한글 경로 `doc-protection.sh` 차단 경로 확인

### 6.3 마무리 더블체크에서 발견한 결함

마무리 검토 중 `run-hook.ps1`을 실제 전역 settings command와 같은 경로로 다시 호출했다.

처음 구현한 형태는 다음 문제가 있었다.

- `powershell -File ... run-hook.ps1 <hook>` 방식은 stdin을 Bash 훅에 안정적으로 넘기지 못했다.
- PowerShell pipeline binding을 거치면 JSON 안의 한글 경로가 `??`로 깨질 수 있었다.
- 그 결과 `C:\Users\rlgns\OneDrive\문서\하네스\docs\index.md` 같은 실제 작업 경로는 `doc-protection.sh`의 `[ -f "$FILE_PATH" ]` 검사에서 누락될 수 있었다.

수정한 내용:

- `run-hook.ps1`이 `[Console]::OpenStandardInput()`으로 stdin raw bytes를 읽도록 변경했다.
- Bash 훅 실행도 `System.Diagnostics.ProcessStartInfo`로 직접 실행하고 stdin bytes를 그대로 전달하도록 변경했다.
- settings command를 `-File`에서 `-Command "& '...\run-hook.ps1' '<hook>'"` 형태로 바꿔 PowerShell의 script pipeline binding을 피했다.
- repo `settings/settings.json`, `settings/settings.template.json`, 전역 `C:\Users\rlgns\.claude\settings.json`을 모두 같은 방식으로 갱신했다.

추가 검증:

- 전역 settings command 경유로 한글 경로 `docs/index.md` 기존 문서 Write 차단 확인
- 전역 settings command 경유로 `docs/codex_harness_refactor_2026-04-15.md` PostToolUse 검증 통과 확인
- repo와 전역 `run-hook.ps1` SHA256 해시 일치 확인

추가 정리:

- 훅 실행 중 repo 루트에 `.claude/harness-audit.log`가 생성되는 것을 확인했다.
- audit 로그는 작업 산출물이 아니므로 `.gitignore`에 `.claude/`를 추가했다.

## 7. 전역 동기화 기록

오늘 전역 `C:\Users\rlgns\.claude`에 여러 차례 동기화했다.

백업 위치:
- `C:\Users\rlgns\.claude\backups\harness-p0-20260415-162750`
- `C:\Users\rlgns\.claude\backups\harness-p1-20260415-193309`
- `C:\Users\rlgns\.claude\backups\harness-p1-feature-20260415-195756`
- `C:\Users\rlgns\.claude\backups\harness-p2-min-20260415-201726`
- `C:\Users\rlgns\.claude\backups\harness-p2-codedoc-20260415-203810`
- `C:\Users\rlgns\.claude\backups\harness-p2-doc-protection-20260415-212301`
- `C:\Users\rlgns\.claude\backups\harness-p2-post-verify-20260415-213626`
- `C:\Users\rlgns\.claude\backups\harness-run-hook-20260415-214852`
- `C:\Users\rlgns\.claude\backups\harness-run-hook-fix-20260415-final`
- `C:\Users\rlgns\.claude\backups\harness-settings-run-hook-command-20260415-final`

주요 전역 반영 파일:
- `C:\Users\rlgns\.claude\settings.json`
- `C:\Users\rlgns\.claude\hooks\_harness_common.sh`
- `C:\Users\rlgns\.claude\hooks\dev-checklist-guard.sh`
- `C:\Users\rlgns\.claude\hooks\doc-checklist-guard.sh`
- `C:\Users\rlgns\.claude\hooks\doc-protection.sh`
- `C:\Users\rlgns\.claude\hooks\post-edit-verify.sh`
- `C:\Users\rlgns\.claude\hooks\pre-commit-guard.sh`
- `C:\Users\rlgns\.claude\hooks\run-hook.ps1`
- `C:\Users\rlgns\.claude\hooks\code-doc-sync.sh`
- `C:\Users\rlgns\.claude\hooks\doc-template-guard.sh`
- `C:\Users\rlgns\.claude\hooks\wiki-index-guard.sh`
- `C:\Users\rlgns\.claude\hooks\graphify-reminder.sh`
- `C:\Users\rlgns\.claude\skills\*\SKILL.md`

전역에서 제거한 기존 훅:
- `C:\Users\rlgns\.claude\hooks\bash-doc-guard.sh`
- `C:\Users\rlgns\.claude\hooks\block-write-docs.sh`

참고:
- repo에서는 `lint-guard.sh`, `pre-commit-test.sh`, `bash-doc-guard.sh`, `block-write-docs.sh`가 삭제 상태다.
- 전역의 오래된 `lint-guard.sh`, `pre-commit-test.sh`는 settings에서 참조하지 않는다.

## 8. 추가한 테스트

### 8.1 `tests/test_checklist_guards.ps1`

검증 내용:
- docs 파일은 dev guard가 무시
- 코드 파일은 dev 체크리스트 없으면 차단
- 얕은 dev 체크리스트 차단
- 정상 dev 체크리스트 통과
- 문서 파일은 doc 체크리스트 없으면 차단
- 얕은 doc 체크리스트 차단
- 정상 doc 체크리스트 통과

### 8.2 `tests/test_feature_hooks.ps1`

검증 내용:
- `.harness.yml` 없음이면 optional 훅 무음
- `features.wiki: false` 무음
- `features.wiki: true` 경고
- `features.doc_templates: false` 무음
- `features.doc_templates: true` 신규 문서 frontmatter 차단
- `features.code_doc_sync: false` 무음
- `features.code_doc_sync: true`인데 인덱스 없으면 무음
- `features.code_doc_sync: true`이고 인덱스 있으면 리마인더
- `features.graphify: false` 무음
- `features.graphify: true` 리마인더

### 8.3 `tests/test_tiny_and_post_hooks.ps1`

검증 내용:
- tiny code edit은 dev 체크리스트 없이 통과
- large code edit은 dev 체크리스트 요구
- tiny doc edit은 doc 체크리스트 없이 통과
- large doc edit은 doc 체크리스트 요구
- 정상 Python 통과
- 깨진 Python 차단
- 정상 Markdown 링크 통과
- 깨진 Markdown 링크 차단
- 불완전 frontmatter 차단
- 완전 frontmatter 통과
- `features.doc_templates: true` 신규 문서 frontmatter 누락 차단
- 체크된 기존 dev 파일 통과
- 체크된 누락 dev 파일 차단
- 체크된 기존 related doc 통과
- 체크된 누락 related doc 차단

### 8.4 `tests/test_doc_protection.ps1`

검증 내용:
- 기존 문서 Write 차단
- 신규 문서 Write 허용
- 기존 코드 Write 허용
- Bash `sed -i` 문서 수정 차단
- Bash redirect 문서 쓰기 차단
- Bash `tee` 문서 쓰기 차단
- Bash `python open(...).write` 문서 쓰기 차단
- Bash PowerShell `Set-Content` 문서 쓰기 차단
- `git status` 허용
- `.backups` 관련 복사 허용

## 9. 검증 결과

오늘 실행해 통과한 검증:

- 전체 `hooks/*.sh` Bash 문법 검사
- 전역 주요 훅 Bash 문법 검사
- repo `settings/settings.json` JSON 검사
- repo `settings/settings.template.json` JSON 검사
- 전역 `C:\Users\rlgns\.claude\settings.json` JSON 검사
- `tests/test_checklist_guards.ps1`
- `tests/test_feature_hooks.ps1`
- `tests/test_tiny_and_post_hooks.ps1`
- `tests/test_doc_protection.ps1`
- 스킬 frontmatter 검사
- `git diff --check`
- 전역 settings command 경유 `run-hook.ps1` stdin raw bytes 전달 검사
- 전역 settings command 경유 한글 경로 `doc-protection.sh` 차단 경로 검사
- 전역 settings command 경유 Codex 기록 문서 `post-edit-verify.sh` 통과 검사

남은 경고:
- `git diff --check`는 통과했지만, Git이 여러 파일에 대해 LF to CRLF 경고를 냈다.
- 기능 오류는 아니지만, 이후 `.gitattributes`로 줄바꿈 정책을 명시하는 것이 좋다.

## 10. 현재 배포 상태

전역 `~/.claude`에는 오늘 변경이 반영되어 있다.

즉, Claude Code가 새 세션에서 전역 settings를 읽으면 다음이 동작한다.

- PreToolUse Bash 훅
- PreToolUse Edit 훅
- PreToolUse Write 훅
- PostToolUse Edit 훅
- PostToolUse Write 훅
- PowerShell `run-hook.ps1` 기반 Git Bash 실행

주의:
- 이미 떠 있는 Claude Code 세션이 settings를 시작 시점에 읽는 방식이면, Claude Code 재시작 후 확실히 적용된다.

## 11. 아직 커밋되지 않은 상태

오늘 변경은 아직 git commit으로 정리하지 않았다.

현재 작업 트리에는 다음 성격의 변경이 섞여 있다.

- P0 권한 축소와 pre-commit 병합
- P1 체크리스트 품질 검증
- P1 feature 파싱
- P1 스킬 frontmatter 통일
- P2 tiny edit 면제
- P2 PostToolUse 검증
- P2 문서 보호 훅 병합
- Windows `run-hook.ps1` 실행 경로 안정화
- 테스트 추가
- 문서 갱신

권장 커밋 분리:

1. `settings` 권한 축소와 템플릿 추가
2. pre-commit, checklist, doc-protection 훅 병합
3. checklist 품질 검증과 tiny edit 정책
4. `.harness.yml` feature 파싱과 optional 훅 정리
5. PostToolUse 검증 추가
6. 스킬 frontmatter 통일
7. Windows `run-hook.ps1` 실행 경로 안정화
8. 문서와 테스트 정리

다만 현재 변경량이 크므로, 실무적으로는 하나의 큰 커밋으로 먼저 보존한 뒤 이후 리팩터링 커밋으로 나누는 것도 가능하다.

## 12. 남은 리스크와 후속 작업

### 12.1 훅 테스트 속도

PowerShell 스모크 테스트는 정확하지만 느리다.

후속 제안:
- 공통 테스트 helper를 분리
- fixture 재사용
- PowerShell 프로세스와 Git Bash 호출 수 축소

### 12.2 줄바꿈 정책

Git이 LF to CRLF 경고를 계속 출력한다.

후속 제안:
- `.gitattributes` 추가
- `.sh`는 LF 고정
- `.ps1`은 CRLF 또는 LF 중 하나로 명시
- `.md`는 프로젝트 정책에 맞춰 명시

### 12.3 settings 이식성

현재 settings command에는 사용자 홈 경로가 절대 경로로 들어 있다.

장점:
- 현재 Windows 환경에서 즉시 안정적으로 동작

단점:
- 다른 사용자 또는 다른 PC로 옮길 때 경로 수정 필요

후속 제안:
- 설치 스크립트에서 `settings.template.json`의 사용자 경로를 치환
- `install.ps1` 추가

### 12.4 PostToolUse frontmatter 검증 범위

현재는 frontmatter가 있으면 필수 필드 존재만 본다.

후속 제안:
- `type` 허용값 검증
- `status` 허용값 검증
- `created` 날짜 형식 검증
- `related_code`, `related_docs` 경로 존재 검증

### 12.5 체크리스트 완료 항목 검증 범위

현재는 파일 경로가 있어야 하는 섹션만 검사한다.

후속 제안:
- `Verification` 완료 항목과 실제 테스트 실행 로그 연결
- 체크리스트 삭제 시 PostToolUse와 doublecheck guard 통합

## 13. 최종 판단

오늘 작업 후 하네스는 다음 상태가 됐다.

- 훅 수는 줄고 역할은 더 명확해졌다.
- 체크리스트는 파일 존재가 아니라 승인과 최소 품질을 강제한다.
- 작은 수정은 면제되어 작업 부담이 줄었다.
- 수정 후 깨진 Python/Markdown/frontmatter/checklist 상태를 즉시 잡는다.
- optional feature는 `.harness.yml`로 실제 제어된다.
- 문서 보호 훅은 하나로 합쳐졌고 우회 차단 범위가 넓어졌다.
- Windows에서 `bash` PATH 문제로 훅이 무력화될 가능성을 줄였다.

결론:

> 전역 Claude Code 사용 기준으로는 배포 가능한 상태다. 다만 repo 변경은 아직 커밋 전이므로, 다음 작업은 커밋 정리와 설치 스크립트화가 적절하다.
