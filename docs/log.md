# 문서 변경 기록

> append-only, 최신이 위.

---

- 2026-04-23 | `docs/research/feedback-encoding-fix/` 신규 | /feedback 한글 mojibake 반복 재발 원인 규명. 01_root-cause(3 레이어: stdout/argv/Start-Job) + 02_web-evidence(hy2k.dev, MS Learn, gemini-cli#20186, codex#4498 등 10건) + 03_fix-plan(Step A 최소 / B 중간 / C Gemini argv 우회 / D PS7 이주) 3편. 후속: /checklist 로 구현 체크리스트 생성 예정
- 2026-04-17 | 히스토리 폴더 마이그레이션 | 단일 `docs/HISTORY.md` → `docs/history/index.md` + 일별 파일 3개(2026-04-15/16/17). index.md 최상단 "🔄 진행 중" 섹션이 세션 인계 SSOT. 원본은 `.backups/HISTORY.md.20260417_pre-migration.bak`로 백업. 양식: `[시작일] 상태 | 작업 | 다음 | 미결`. 한계: 7개 OR 14일
- 2026-04-17 | 세션 인계 도입 (Phase 1 → 즉시 Phase 2) | project-history 스킬에 handoff 명령 + Phase 1/2 단계 + 7개/14일 한계 + 역방향 SSOT(index 상단) 규칙 추가
- 2026-04-17 | 3라운드 크로스 리뷰 반영 | Codex/Gemini 3라운드 리뷰로 18개 문제 수정. doc-protection git 보호 전면 재설계, MultiEdit 배선, fail-closed, skipDangerous 제거
- 2026-04-17 | docs/feedback/ 신규 | 피드백 문서 7개 + index.md 생성. `/feedback` 스킬 체계화 (docs/feedback/ 저장 필수, 맥락 주입 규칙)
- 2026-04-16 | 훅→스킬 전환 | `/checklist` 스킬 신규, doc-protection 백업 추가, deploy-version-guard CI 체크 추가, 체크리스트 훅 2개+doublecheck 훅 제거, settings 11→7 훅
- 2026-04-16 | rules 병합 | `communication.md` + `workflow.md` → `work-style.md`, `deployment.md` 포인터화. rules 12→9개
- 2026-04-16 | 훅 병목 제거 | check-streamlit universal 삭제, auto-backup 삭제, feature-gated 훅 배선 제거. Edit당 7→3개 훅
- 2026-04-16 | 중복 rules 축소 | dev-checklist, document-safety, wiki, graphify를 1줄 포인터로. CLAUDE.md graphify 중복 제거
- 2026-04-16 | Codex 후속 수정 | skipDangerousModePermissionPrompt 실제 제거, dead hooks 3개 삭제, MEMORY.md 스테일 포인터 정리
- 2026-04-16 | Codex 작업 전체 커밋 | 35개 파일 커밋 (ac9f6ce). 전역에만 반영되어 있던 Codex 작업을 repo에 보존
- 2026-04-16 | `claude_code_harness_overhead_2026.md` 복사 | 지식 프로젝트에서 작성한 하네스 과부하 리서치 문서를 하네스 프로젝트에 복사. Rules·Hooks·Memory·Skills 4대 병목, 컨텍스트 예산, 다이어트 전략
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
