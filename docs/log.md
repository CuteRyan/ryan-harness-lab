# 문서 변경 기록

> append-only, 최신이 위.

---

- 2026-04-15 | `.claude/` audit 로그 ignore 추가 | 훅 실행 중 생성되는 `.claude/harness-audit.log`가 커밋 잡음이 되지 않도록 `.gitignore`에 `.claude/` 추가
- 2026-04-15 | `run-hook.ps1` stdin/한글 경로 결함 수정 | 마무리 더블체크에서 `-File` 호출의 PowerShell pipeline/인코딩 문제를 확인하고 raw stdin + `-Command` 방식으로 전역 settings 재배포
- 2026-04-15 | `codex_harness_refactor_2026-04-15.md` 생성 | Codex가 수행한 P0/P1/P2 하네스 리팩터링, 전역 배포, 검증 결과를 상세 기록
- 2026-04-15 | Windows 훅 실행 경로 안정화 | `run-hook.ps1` 추가, settings 훅 command를 Git Bash 절대 경로 래퍼 방식으로 변경
- 2026-04-15 | P2 PostToolUse 검증 확장 | frontmatter 필수 필드, 신규 문서 frontmatter, 체크리스트 완료 항목 파일 경로 대조 추가
- 2026-04-15 | P2 문서 보호 훅 병합 | `block-write-docs.sh` + `bash-doc-guard.sh`를 `doc-protection.sh`로 통합하고 Bash 우회 패턴 보강
- 2026-04-15 | P2 최소 검증/작업 규모 정책 적용 | tiny edit 체크리스트 면제, PostToolUse Python/Markdown 검증, code-doc-sync 무음화, 관련 테스트 추가
- 2026-04-15 | P1 feature/metadata 적용 | `.harness.yml` feature 파싱, 느린 훅 로그, 스킬 frontmatter 통일, feature 훅 테스트 추가
- 2026-04-15 | P1 체크리스트 가드 1차 적용 | 품질 검증, 승인 마커, 체크리스트 훅 스모크 테스트 추가
- 2026-04-15 | P0 하네스 리팩터링 적용 | 권한 축소, 문서/코드 체크리스트 분리, 잡음 훅 제거, pre-commit 훅 병합
- 2026-04-15 | `harness_refactor_plan.md` 생성 | 하네스 훅/권한/스킬 리팩터링 실행 계획 문서화
- 2026-04-15 | `index.md` 생성 | 문서 인덱스 초기 구성
- 2026-04-15 | `HISTORY.md` 생성 | 프로젝트 히스토리 초기 작성
- 2026-04-15 | `project_harness_architecture.md` 이동 | 지식 프로젝트에서 이동
- 2026-04-15 | `harness_bypass_guide.md` 이동 | 지식 프로젝트에서 이동
- 2026-04-15 | `workflows/*.md` 이동 | 4개 워크플로 문서 지식 프로젝트에서 이동
