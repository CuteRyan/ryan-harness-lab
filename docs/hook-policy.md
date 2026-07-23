# 전역 훅 정책

## 결론

전역 훅은 모든 프로젝트에 공통인 복구하기 어려운 Git 명령만 다룬다. 문서 수정 방식과 특정 서버 배포 절차는 전역에서 강제하지 않는다.

## 변경

- Bash `PreToolUse` 진입점을 `hooks/pretooluse-guard.ps1` 하나로 통합했다.
- `git reset --hard`, 강제 `git clean`, 작업 파일을 버리는 `git restore`·`git checkout --`, `git rm`, 일반 강제 push와 강제 refspec을 차단한다.
- `git push --force-with-lease`는 차단하지 않고 경고한다.
- 대문자 명령, 명령 체인, `git -C`와 `--git-dir` 같은 전역 옵션을 같은 기준으로 판정한다.
- 기존 문서 Write와 Bash 문서 수정을 막던 전역 훅을 제거했다.
- 특정 서버 IP, 버전 파일, 변경 기록, GitHub CI를 결합한 배포 훅을 전역에서 제거했다.
- Git Bash 래퍼와 사용하지 않는 공통 셸 함수를 제거했다.

## 이유

문서 수정 방식과 배포 절차는 프로젝트마다 다르다. 이를 전역 정규식으로 강제하면 정상 작업을 막으면서도 우회 경로는 남는다. 전역에는 데이터 손실 위험이 명확한 Git 작업만 남기고, 배포 검사는 대상 프로젝트의 CI나 프로젝트별 검사에서 수행한다.

## 검증

- 정책·허용·오탐 회귀 검사 28건과 stdin 통합 검사 통과
- 원본 및 템플릿 설정의 Bash 단일 등록 검사 통과
- PowerShell 구문 분석 통과
- 일반 허용 명령의 훅 실행 시간: 5회 측정 386~441ms
- `scripts/install-global-hook.ps1`을 격리된 임시 `.claude`에 적용해 사용자 설정 보존, 기존 훅 백업, 새 훅 해시 일치를 확인
- 실제 운영 `.claude` dry-run으로 교체 대상 5개와 새 진입점 확인
- 실제 운영 `.claude` 반영 후 원본·운영본 SHA-256 일치 확인
- 운영 훅에서 일반 Git 조회 허용, force-with-lease 경고, 대문자 hard reset과 `git -C` 강제 clean 차단 확인
- 운영 호출 4건 측정: 590~657ms

운영 반영은 `scripts/install-global-hook.ps1 -Apply`처럼 명시적으로 실행한다. 스크립트는 기존 설정과 교체 대상 훅을 `.claude/.archive/`에 보관하고, 관련 없는 사용자 설정과 훅 등록은 유지한다.
