---
title: 하네스 리팩터링 실행 계획
type: design
status: draft
created: 2026-04-15
updated: 2026-04-15
related_code:
  - settings/settings.json
  - settings/settings.template.json
  - hooks/_harness_common.sh
  - hooks/run-hook.ps1
  - hooks/dev-checklist-guard.sh
  - hooks/doc-checklist-guard.sh
  - hooks/doc-protection.sh
  - hooks/pre-commit-guard.sh
  - hooks/code-doc-sync.sh
  - hooks/doc-template-guard.sh
  - hooks/graphify-reminder.sh
  - hooks/venv-guard.sh
  - tests/test_checklist_guards.ps1
related_docs:
  - project_harness_architecture.md
  - harness_bypass_guide.md
  - workflows/dev-checklist.md
  - workflows/document-work.md
  - workflows/wiki-management.md
  - workflows/graphify-guide.md
---

# 하네스 리팩터링 실행 계획

## 1. 결론

현재 하네스의 방향은 맞다. 다만 훅이 많고 얕으며, rules는 강하지만 실제 강제력은 약하다.

리팩터링 목표는 단순하다.

> 훅은 적게, 깊게. 규칙은 적게, 강제로.

즉, 매번 잡음을 내는 훅은 줄이고, 실제 품질을 올리는 훅만 남긴다. 체크리스트 파일 존재 여부가 아니라 체크리스트 내용, 승인 상태, 수정 후 검증까지 다루는 구조로 바꾼다.

## 2. 현재 문제

### 2.1 얕은 강제

현재 체크리스트 훅은 `.dev-checklist.md` 또는 `.doc-checklist.md` 존재 여부만 주로 확인한다. 그래서 빈 체크리스트나 형식만 있는 체크리스트도 통과한다.

필요한 검증은 다음이다.

| 현재 확인 | 실제 필요한 확인 |
|---|---|
| 체크리스트 파일 존재 | 필수 섹션과 최소 항목 수 |
| 문서 파일 확장자 | 문서 간 계약 충돌 여부 |
| YAML 프론트매터 존재 | 프론트매터 값의 정확성 |
| git commit 명령 감지 | 수정 직후 lint/test 피드백 |

### 2.2 잡음 훅

일부 훅은 작업 흐름 중 계속 경고를 내지만, 바로 해결할 성격의 문제가 아니다. 대표적으로 `graphify-reminder.sh`, 현재 형태의 `code-doc-sync.sh`, `venv-guard.sh`가 그렇다.

이런 훅은 차단 훅이 아니라 audit 또는 명시 호출 스킬로 이동해야 한다.

### 2.3 우회 가능한 안전장치

기존 `bash-doc-guard.sh`는 `echo > file.md`, `sed -i`, `tee` 같은 일부 패턴만 막았고, `python -c`, `powershell`, `Out-File` 등은 충분히 우회 경로가 됐다. 현재는 `doc-protection.sh`가 Write 덮어쓰기와 Bash 문서 쓰기 패턴을 함께 차단한다.

따라서 훅만 강화할 것이 아니라 `settings.json`의 광범위 권한을 먼저 줄여야 한다.

### 2.4 설계와 구현의 불일치

`.harness.yml`에는 `features` 설정이 설계되어 있지만, 현재 훅은 파일 존재 여부만 확인한다. 즉 `wiki: false`, `graphify: false` 같은 선택적 제어가 실제로는 동작하지 않는다.

또한 `docs/templates/`는 설계 문서에서 필수 구조처럼 언급되지만 현재 하네스 프로젝트에는 없다.

## 3. 목표 구조

### 3.1 훅 분류

훅을 세 종류로 분리한다.

| 분류 | 역할 | 예시 |
|---|---|---|
| Hard block | 실행하면 실제 손상 가능성이 큰 작업 차단 | 기존 문서 전체 덮어쓰기, 미승인 코드 수정 |
| Soft verify | 수정 직후 빠른 검증 | lint, 체크리스트 구조 검증 |
| Audit | 작업 중 잡음 없이 별도 진단 | venv, graphify, code-doc index |

### 3.2 최종 훅 세트

목표는 PreToolUse 훅을 5개 안팎으로 줄이는 것이다.

| 훅 | 상태 | 역할 |
|---|---|---|
| `checklist-guard.sh` | 신규/병합 | 코드/문서 체크리스트 분기, 품질 검증, 승인 마커 확인 |
| `doc-protection.sh` | 신규/병합 | `Write` 덮어쓰기와 Bash 문서 수정 차단 통합 |
| `pre-commit-guard.sh` | 신규/병합 | commit 전 lint/test 통합 실행 |
| `deploy-guard.sh` | 유지/개선 | 배포 전 버전/HISTORY/test 확인 |
| `auto-backup.sh` | 유지/개선 | 파일 기준 프로젝트 루트에 백업 생성 |

다음 훅은 기본 훅에서 제외하거나 audit로 이동한다.

| 훅 | 조치 |
|---|---|
| `graphify-reminder.sh` | 기본 비활성화, `/project-structure audit`로 이동 |
| `venv-guard.sh` | 기본 비활성화, Python 프로젝트 audit 항목으로 이동 |
| `code-doc-sync.sh` | 역색인 없으면 완전 무음, 성숙 전까지 기본 비활성화 |
| `doc-template-guard.sh` | 신규 문서 프론트매터 검증만 남기고 단순화 |
| `wiki-index-guard.sh` | `.harness.yml.features.wiki=true`일 때만 경고 |
| `doc-doublecheck-guard.sh` | `checklist-guard.sh`에 통합 |

## 4. P0: 즉시 안정화

진행 상태: 2026-04-15에 1차 적용 완료. 권한 축소, docs 체크리스트 데드락 제거, 잡음 훅 기본 배선 제거, pre-commit 훅 병합, 공식 훅 회피 전략 제거를 반영했다.

### 4.1 `settings.json` 권한 축소

가장 먼저 한다. 광범위 권한이 남아 있으면 훅을 강화해도 우회된다.

작업:
- `skipDangerousModePermissionPrompt` 제거 또는 `false` 전환
- 일회성 base64 파일 생성 허용 제거
- `Bash(python:*)`, `Bash(powershell:*)`, `Bash(dir:*)`, `Bash(echo:*)` 같은 광범위 허용 제거
- 프로젝트별 절대경로 허용을 최소화
- `settings/settings.json`은 추적 대상이 아니므로 `settings/settings.template.json` 생성

적용:
- `skipDangerousModePermissionPrompt` 제거
- 일회성 base64 파일 생성 허용 제거
- Python/PowerShell 직접 실행 광범위 허용 제거
- `settings/settings.template.json` 추가

완료 기준:
- 새 환경에서 template 기반으로 설치 가능
- 문서 파일을 Python/PowerShell로 직접 쓰는 우회 경로가 기본 허용 목록에 없음

### 4.2 docs 작업 데드락 제거

문서 작업에는 `.doc-checklist.md`만 요구한다. 코드 작업에는 `.dev-checklist.md`만 요구한다.

작업:
- `dev-checklist-guard.sh`에서 `docs/**/*.md`, `rules/**/*.md`, `*.md` 문서 파일 예외 처리
- `doc-checklist-guard.sh`는 docs/rules 문서만 담당
- 체크리스트 자체 파일은 계속 예외

적용:
- `dev-checklist-guard.sh`에서 문서 경로 예외 처리
- `doc-checklist-guard.sh`의 프로젝트 루트 탐색을 cwd 기준에서 파일 경로 기준으로 변경

완료 기준:
- 코드 파일 수정 시 `.dev-checklist.md` 필요
- 문서 파일 수정 시 `.doc-checklist.md`만 필요
- 문서 수정에 `.dev-checklist.md`를 요구하지 않음

### 4.3 잡음 훅 비활성화

작업 흐름 중 해결하지 않을 경고는 제거한다.

작업:
- `settings.json` Edit matcher에서 `graphify-reminder.sh` 제거
- `settings.json` Edit matcher에서 `code-doc-sync.sh` 제거하거나 역색인 없을 때 무음 처리
- `settings.json` Edit matcher에서 `venv-guard.sh` 제거

적용:
- Edit matcher에서 `graphify-reminder.sh`, `code-doc-sync.sh`, `venv-guard.sh` 제거

완료 기준:
- 일반 Edit 한 번에 의미 없는 경고가 출력되지 않음
- graphify/venv/code-doc 상태는 `/project-structure audit`에서 확인

### 4.4 pre-commit 훅 병합

작업:
- `pre-commit-test.sh`와 `lint-guard.sh`를 `pre-commit-guard.sh`로 병합
- stdin JSON 파싱 1회
- 실행 순서: staged Python 파일 lint -> tests 존재 시 pytest
- ruff/pytest 미설치 시 차단하지 않고 audit 로그만 남김

적용:
- `hooks/pre-commit-guard.sh` 추가
- `hooks/pre-commit-test.sh`, `hooks/lint-guard.sh` 제거
- Bash matcher에서 `pre-commit-guard.sh`만 호출

완료 기준:
- git commit 명령에서 lint와 test가 한 훅에서 순서대로 실행됨
- 실패 메시지가 한 번만 출력됨

### 4.5 공식 우회 전략 제거

작업:
- `skills/project-history/SKILL.md`의 "훅 회피 전략"을 제거
- 히스토리 파일 예외가 필요하면 훅 정책에 명시적으로 추가
- `harness_bypass_guide.md`는 오탐 대응 가이드로 유지하되, 일반 작업 절차가 되지 않게 수정

적용:
- `skills/project-history/SKILL.md`의 "훅 회피 전략"을 "훅 정책"으로 변경

완료 기준:
- 스킬 문서에 "훅 회피"를 정상 경로로 권장하는 문장이 없음

## 5. P1: 1-2주 내 개선

진행 상태: 2026-04-15 적용 완료. 체크리스트 품질 검증, 승인 게이트, `.harness.yml` feature 파싱, 훅 실행 시간 측정, 스킬 메타데이터 통일, 훅 스모크 테스트를 반영했다.

### 5.1 체크리스트 품질 검증

`checklist-guard.sh`를 만든다.

적용: 별도 신규 훅 대신 기존 `dev-checklist-guard.sh`, `doc-checklist-guard.sh`와 `_harness_common.sh`에 공통 검증 함수를 추가했다. 운영 체크리스트는 한글 섹션명과 영문 섹션명을 모두 허용한다.

검증 기준:
- `## 구현 항목` 또는 `## 작업 항목` 존재
- 또는 `## Tasks`, `## Implementation` 존재
- `## 수정 대상 파일` 존재
- 또는 `## Changed Files`, `## Target Files`, `## Files` 존재
- `## 검증 항목` 존재
- 또는 `## Verification` 존재
- `## 더블 체크` 존재
- 또는 `## Double Check` 존재
- 미완료 항목 최소 3개 이상
- 항목 텍스트가 `구현`, `확인`, `수정`, `fix`, `check` 같은 단어 하나로만 구성되면 차단

문서 체크리스트 기준:
- `## 작업 범위` 존재
- 또는 `## Scope`, `## Work Scope`, `## Content` 존재
- `## 연관 문서` 존재
- 또는 `## Related Docs`, `## Related Documents` 존재
- `## 교차 검증` 존재
- 또는 `## Cross Check`, `## Cross Verification` 존재
- `## 더블 체크` 존재
- 또는 `## Double Check` 존재

완료 기준:
- 빈 체크리스트가 차단됨
- 형식만 있고 내용이 없는 체크리스트가 차단됨
- `tests/test_checklist_guards.ps1`에서 실패/성공 경로를 검증함

### 5.2 승인 게이트 도입

체크리스트에 승인 마커를 둔다.

적용: `status: approved`, `approved: true`, `- [x] 승인`, `- [x] approved` 중 하나가 있어야 코드/문서 수정이 통과한다.

예시:

```markdown
## Status
- approved: false
```

또는:

```markdown
status: approved
```

정책:
- 기본값은 `draft`
- 코드/문서 수정 전 `approved` 마커 필요
- 단, 3줄 이하의 아주 작은 수정은 P2의 작업 규모 정책에서 별도 처리

완료 기준:
- 체크리스트 생성만으로는 수정 불가
- 승인 마커가 있어야 수정 가능

### 5.3 `.harness.yml` feature 파싱

현재는 `.harness.yml` 존재만 확인한다. 실제 feature 제어를 구현한다.

예시:

```yaml
harness: true
features:
  checklist: true
  docs: true
  wiki: false
  graphify: false
  code_doc_sync: false
  doc_templates: true
```

작업:
- `_harness_common.sh`에 `harness_feature_enabled` 함수 추가
- 외부 YAML 파서 없이 단순 key/value 수준만 지원
- 명시되지 않은 feature는 보수적으로 false 또는 documented default 적용

적용:
- `_harness_common.sh`에 `harness_feature_enabled`와 `harness_feature_value` 추가
- `features.wiki`, `features.graphify`, `features.code_doc_sync`, `features.doc_templates` 지원
- `features:` 블록과 `features.<name>: true` 단일 키 형태 모두 지원
- optional feature의 기본값은 `false`
- `find_harness_yml`은 git repo뿐 아니라 파일 경로 기반 프로젝트 루트도 탐색

완료 기준:
- `features.graphify: false`이면 graphify 관련 훅이 완전 무음
- `features.doc_templates: true`일 때만 문서 템플릿 검증 동작
- `tests/test_feature_hooks.ps1`에서 false/true 경로를 검증함

### 5.4 훅 실행 시간 측정

작업:
- `_harness_common.sh`에 타이머 함수 추가
- 500ms 이상 걸린 훅은 `.claude/harness-audit.log`에 기록

적용:
- `_harness_common.sh`에 `harness_timer_start`, `harness_timer_stop` 추가
- 주요 훅은 `trap`으로 종료 시점에 500ms 이상이면 `slow` 로그 기록
- 로그는 `PROJECT_ROOT`가 확인된 프로젝트의 `.claude/harness-audit.log`에만 기록

완료 기준:
- 느린 훅을 데이터로 식별 가능
- "느낌상 느림"이 아니라 로그로 판단 가능

### 5.5 테스트 추가

훅은 테스트 가능한 프로그램이어야 한다.

구조:

```text
tests/
  test_checklist_guards.ps1
  test_feature_hooks.ps1
```

검증:
- 각 테스트 입력에 대한 exit code 확인
- 차단 메시지 핵심 문구 확인
- Windows 경로와 POSIX 경로 모두 확인

적용: 초기 테스트는 임시 프로젝트를 만들어 `dev-checklist-guard.sh`, `doc-checklist-guard.sh`의 누락/얕은 체크리스트/정상 체크리스트 경로를 검증한다. fixture 파일 분리는 훅 종류가 더 늘어나는 시점에 진행한다.

추가 적용: `test_feature_hooks.ps1`로 `wiki-index-guard.sh`, `doc-template-guard.sh`, `code-doc-sync.sh`, `graphify-reminder.sh`의 feature false/true 경로를 검증한다.

완료 기준:
- 주요 훅 변경 전후 테스트 가능
- 신규 훅 추가 시 fixture도 함께 추가

### 5.6 스킬 메타데이터 통일

작업:
- `user_invocable` vs `user-invocable` 중 하나로 통일
- `trigger`, `argument-hint`, `allowed-tools` 사용 여부 표준화
- 대형 스킬은 `SKILL.md`에 전체 구현을 넣지 않고 `scripts/` 또는 별도 CLI로 분리

적용:
- 모든 `skills/*/SKILL.md`에 frontmatter 추가 또는 보강
- `user-invocable`로 통일하고 `user_invocable` 제거
- 모든 스킬에 `name`, `description`, `trigger`, `user-invocable` 필드 존재 확인
- `argument-hint`, `allowed-tools`는 호출형 스킬에 맞춰 추가

완료 기준:
- 모든 `skills/*/SKILL.md` frontmatter가 같은 스키마를 사용

## 6. P2: 1개월 내 구조 개선

### 6.1 PostToolUse 도입

수정 전 차단만으로는 부족하다. 수정 후 검증을 추가한다.

진행 상태: 2026-04-15 적용 완료. `post-edit-verify.sh`를 PostToolUse Edit/Write에 연결했고, 최소 검증에 더해 체크리스트 완료 항목 파일 대조와 frontmatter 사후 검증까지 반영했다.

후보:
- Python 파일 Edit/Write 후 `py_compile` 문법 검증
- Markdown 파일 Edit/Write 후 상대 로컬 링크 존재 여부 검사
- 모든 파일에서 병합 충돌 마커 검사
- 체크리스트 `[x]` 변경 시 실제 수정 파일 존재 확인
- 프론트매터 변경 후 필수 필드 검증

적용:
- `hooks/post-edit-verify.sh` 추가
- `settings/settings.json`, `settings/settings.template.json`에 `PostToolUse` Edit/Write matcher 추가
- Python 문법, Markdown 로컬 링크, 병합 충돌 마커 검사
- frontmatter가 있으면 `title`, `type`, `status`, `created` 필수 필드 검사
- `features.doc_templates: true`인 프로젝트의 신규 docs 문서는 PostToolUse에서도 frontmatter 존재를 재검증
- `.dev-checklist.md`의 완료된 `Changed Files` 항목과 `.doc-checklist.md`의 완료된 `Related Docs` 항목이 실제 파일을 가리키는지 검사

완료 기준:
- "수정은 됐지만 바로 깨진 상태"를 다음 commit까지 방치하지 않음
- `tests/test_tiny_and_post_hooks.ps1`에서 성공/실패 경로를 검증함

### 6.2 작업 규모별 정책

모든 수정에 무거운 체크리스트를 요구하지 않는다.

진행 상태: 2026-04-15 tiny edit 면제 적용 완료. `Edit`의 `old_string`, `new_string`이 각각 3줄 이하이고 240자 이하일 때 체크리스트를 면제한다. `Write`는 면제하지 않는다.

정책 초안:

| 작업 규모 | 기준 | 요구 |
|---|---|---|
| tiny | 3줄 이하, 문서 오탈자, 주석 수정 | 체크리스트 면제, audit 로그 |
| normal | 일반 코드/문서 변경 | 체크리스트 + 승인 |
| risky | 배포, DB, 인증, 결제, 삭제, 대량 변경 | 체크리스트 + 승인 + 사후 검증 |

적용:
- `_harness_common.sh`에 `harness_tiny_edit_allowed` 추가
- `dev-checklist-guard.sh`, `doc-checklist-guard.sh`에서 tiny edit이면 `tiny-exempt` audit 로그 후 통과
- 기본 기준: `HARNESS_TINY_EDIT_LINES=3`, `HARNESS_TINY_EDIT_CHARS=240`
- 큰 수정, 신규 Write, 삭제/배포 Bash 명령은 면제 대상이 아님

완료 기준:
- 사소한 수정에 6단계 프로세스를 강제하지 않음
- 위험한 수정은 더 강하게 검증
- `tests/test_tiny_and_post_hooks.ps1`에서 tiny/large 경로를 검증함

### 6.3 code-doc-sync 재도입

역색인 체계가 성숙한 프로젝트에서만 켠다.

진행 상태: 2026-04-15 적용 완료. `features.code_doc_sync: true`이고 `docs/.harness-index.json`이 있을 때만 사용자에게 리마인더를 출력한다. 인덱스가 없으면 audit 로그만 남기고 사용자 출력 없이 통과한다.

조건:
- `docs/.harness-index.json` 존재
- `.harness.yml.features.code_doc_sync: true`
- 역색인 freshness 검증 구현

동작:
- 코드 수정 시 관련 문서 리마인더
- 문서 수정 시 관련 코드 리마인더
- 역색인이 없으면 경고하지 않음

완료 기준:
- 준비된 프로젝트에서는 유용하게 동작
- 준비 안 된 프로젝트에서는 완전 무음
- `tests/test_feature_hooks.ps1`에서 인덱스 없음/있음 경로를 검증함

### 6.4 Graphify는 audit로 통합

Graphify는 매 Edit 훅이 아니라 구조 진단 결과로 다룬다.

작업:
- `/project-structure audit`에 graphify 상태 추가
- 코드 파일 10개 이상 + `graphify-out/GRAPH_REPORT.md` 없음이면 audit에서 제안
- 사용자가 명시 요청할 때만 `/graphify` 실행

완료 기준:
- Edit 중 graphify 경고 없음
- 구조 진단 시에는 graphify 상태 확인 가능

### 6.5 문서 보호 훅 병합

진행 상태: 2026-04-15 적용 완료. `block-write-docs.sh`와 `bash-doc-guard.sh`를 `doc-protection.sh` 하나로 병합했다.

적용:
- 기존 문서/설정 파일에 대한 `Write` 전체 덮어쓰기 차단
- Bash의 `sed -i`, `perl -i`, `>`, `>>`, `tee`, PowerShell `Set-Content`/`Out-File`, 스크립트 `open(...).write`, `write_text`, `writeFileSync` 계열 문서 쓰기 차단
- `.backups`와 `git` 명령은 예외 유지
- `settings/settings.json`, `settings/settings.template.json`에서 Bash/Write matcher가 모두 `doc-protection.sh`를 호출하도록 변경
- `tests/test_doc_protection.ps1`로 Write/Bash 성공/차단 경로 검증

완료 기준:
- 문서 보호 목적의 PreToolUse 훅이 하나로 줄어듦
- Python/PowerShell 기반 문서 쓰기 우회도 기본 차단됨

## 7. 변경 순서

권장 커밋 단위:

1. `settings` 정리와 template 추가
2. checklist/doc-protection/pre-commit 훅 병합
3. noisy 훅 비활성화와 audit 이동
4. checklist 품질 검증과 테스트 fixture 추가
5. `.harness.yml` feature 파싱
6. PostToolUse와 작업 규모별 정책

각 커밋은 독립적으로 되돌릴 수 있어야 한다.

## 8. 검증 기준

리팩터링 완료 후 다음을 만족해야 한다.

- 새 환경에서 하네스 설치 절차가 문서화되어 있다.
- `settings.template.json`은 추적되고, 개인별 `settings.json`은 무시된다.
- 광범위 Bash/Python/PowerShell 쓰기 권한이 기본 허용 목록에 없다.
- Windows에서 `bash`가 PATH에 없어도 `run-hook.ps1`을 통해 Git Bash 훅이 실행된다.
- 코드 수정은 `.dev-checklist.md`, 문서 수정은 `.doc-checklist.md`만 요구한다.
- 빈 체크리스트는 차단된다.
- 신규 문서는 프론트매터 없으면 차단된다.
- graphify/venv/code-doc-sync는 작업 중 잡음이 아니라 audit 결과로만 나온다.
- 주요 훅은 fixture 기반 테스트를 가진다.
- 훅 실행 시간이 audit 로그에 남는다.

## 9. 남은 결정

아래는 구현 전에 결정해야 한다.

1. 승인 마커 형식: `status: approved` vs `## Status` 섹션
2. tiny 작업의 기준: 3줄 이하로 할지, 파일 종류별로 다르게 할지
3. `settings.template.json` 설치 방식: 수동 복사 vs `install.ps1`
4. `code-doc-sync` 기본값: off가 맞는지, `.harness.yml` opt-in만으로 충분한지
5. `doc-template-guard`를 신규 문서 전용으로 남길지, Stage 2/3 정책을 계속 유지할지

## 10. 최종 원칙

하네스는 에이전트에게 일을 더 많이 시키는 장치가 아니다. 에이전트가 놓치기 쉬운 핵심 위험을 적은 비용으로 막는 장치다.

따라서 다음 원칙을 유지한다.

- 잡음은 실패다.
- 존재 검사는 품질 검사가 아니다.
- 우회 전략은 정책이 아니라 예외다.
- 모든 강제 규칙은 테스트 가능해야 한다.
- 훅은 적게, 깊게 둔다.
