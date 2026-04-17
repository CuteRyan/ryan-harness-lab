# 하네스 프로젝트 — 개발 히스토리

## 프로젝트 개요
- **목적**: 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로) 설계·개발·관리
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅
- **분리 배경**: 지식 프로젝트(리서치 문서 축적)와 역할 혼재 → 2026-04-15 독립 프로젝트로 분리

---

## Day 0 (2026-04-15)

### 프로젝트 초기화
- **지식 프로젝트에서 분리**: 하네스 인프라 관련 문서를 독립 프로젝트로 이동
- **이동 파일**:
  - `project_harness_architecture.md` — 하네스 아키텍처 설계안 (Phase 0~4)
  - `harness_bypass_guide.md` — 훅 우회 가이드
  - `workflows/dev-checklist.md` — 개발 체크리스트 워크플로
  - `workflows/document-work.md` — 문서 작업 워크플로
  - `workflows/wiki-management.md` — 위키 관리 워크플로
  - `workflows/graphify-guide.md` — Graphify 가이드
- **프로젝트 구조**: git init, venv, .vscode, CLAUDE.md, docs/
- 왜: 지식 프로젝트는 "리서치 → 문서화"가 역할인데, 훅/스킬/rules 개발까지 섞이면 역할이 불분명해짐

### P0 하네스 리팩터링
- **권한 축소**: `settings/settings.json`에서 위험한 광범위 Bash/Python/PowerShell 허용과 dangerous prompt skip 제거
- **템플릿 추가**: 추적 가능한 `settings/settings.template.json` 생성
- **체크리스트 분리**: 코드 수정은 `.dev-checklist.md`, 문서 수정은 `.doc-checklist.md`만 요구하도록 `dev-checklist-guard.sh`, `doc-checklist-guard.sh` 조정
- **잡음 훅 제거**: Edit matcher에서 `venv-guard.sh`, `graphify-reminder.sh`, `code-doc-sync.sh` 제거
- **pre-commit 병합**: `pre-commit-test.sh`, `lint-guard.sh`를 `pre-commit-guard.sh`로 통합
- **스킬 정책 수정**: `project-history` 스킬의 훅 회피 전략 제거
- 왜: 훅 개수를 줄이고, 작업 중 잡음을 줄이며, 우회 가능한 권한을 먼저 정리하기 위함

### P1 체크리스트 가드 1차 적용
- **품질 검증 추가**: `_harness_common.sh`에 체크리스트 섹션, 항목 수, 얕은 항목 검증 함수 추가
- **승인 게이트 추가**: `status: approved`, `approved: true`, `- [x] 승인`, `- [x] approved` 중 하나가 있어야 수정 통과
- **영문 섹션명 허용**: Windows PowerShell 인코딩 문제를 피할 수 있도록 한글 섹션명과 `Tasks`, `Changed Files`, `Verification`, `Double Check` 같은 영문 섹션명을 함께 허용
- **스모크 테스트 추가**: `tests/test_checklist_guards.ps1`로 dev/doc 체크리스트 누락, 얕은 체크리스트, 정상 체크리스트 경로 검증
- 왜: "체크리스트 파일 존재"가 아니라 "작업 승인과 최소 품질"을 실제 훅이 강제하게 만들기 위함

### P1 feature/metadata 적용
- **feature 파싱 추가**: `_harness_common.sh`에 `harness_feature_enabled`를 추가해 `.harness.yml`의 `features.*` 값을 실제 훅 동작에 연결
- **optional 훅 opt-in화**: `wiki-index-guard.sh`, `doc-template-guard.sh`, `code-doc-sync.sh`, `graphify-reminder.sh`는 각 feature가 true일 때만 동작
- **느린 훅 로그 추가**: 주요 훅에 실행 시간 타이머를 연결해 500ms 이상이면 `.claude/harness-audit.log`에 `slow` 기록
- **스킬 frontmatter 통일**: 모든 `skills/*/SKILL.md`에 `name`, `description`, `trigger`, `user-invocable` 메타데이터를 갖추고 `user_invocable` 제거
- **feature 테스트 추가**: `tests/test_feature_hooks.ps1`로 optional feature false/true 경로 검증
- 왜: `.harness.yml`을 장식이 아니라 실제 제어면으로 만들고, 스킬 발견 규칙을 일관되게 하기 위함

### P2 최소 검증/작업 규모 정책
- **tiny edit 면제**: `Edit`의 old/new가 각각 3줄 이하, 240자 이하이면 dev/doc 체크리스트 없이 통과하고 `tiny-exempt` audit 로그 기록
- **PostToolUse 검증 추가**: `post-edit-verify.sh`로 수정 후 Python 문법, Markdown 상대 링크, 병합 충돌 마커를 즉시 검증
- **code-doc-sync 무음화**: `features.code_doc_sync: true`여도 `docs/.harness-index.json`이 없으면 사용자 경고 없이 통과하고, 인덱스가 있을 때만 관련 문서/코드 리마인더 출력
- **설정 연결**: `settings/settings.json`, `settings/settings.template.json`에 PostToolUse Edit/Write matcher 추가
- **테스트 추가**: `tests/test_tiny_and_post_hooks.ps1`로 tiny/large edit, Python 성공/실패, Markdown 링크 성공/실패 경로 검증
- 왜: 작은 오탈자까지 무거운 절차를 요구하지 않되, 실제로 깨진 파일은 수정 직후 잡기 위함

### P2 문서 보호 훅 병합
- **훅 병합**: `block-write-docs.sh`, `bash-doc-guard.sh`를 `doc-protection.sh` 하나로 통합
- **Write 보호 유지**: 기존 문서/설정 파일에 대한 Write 전체 덮어쓰기는 차단하고 신규 파일 Write는 허용
- **Bash 우회 보강**: `sed -i`, 리다이렉션, `tee`, PowerShell 파일 쓰기, Python/Node 파일 쓰기 API 기반 문서 수정을 차단
- **settings 단순화**: Bash/Write matcher에서 각각 `doc-protection.sh`만 호출하도록 변경
- **테스트 추가**: `tests/test_doc_protection.ps1`로 Write/Bash 차단과 예외 경로 검증
- 왜: 같은 목적의 훅을 줄이고, 기존 Bash 보호 훅의 Python/PowerShell 우회 허점을 줄이기 위함

### P2 PostToolUse 검증 확장
- **frontmatter 사후 검증**: Markdown frontmatter가 있으면 `title`, `type`, `status`, `created` 필수 필드를 즉시 확인
- **신규 문서 재검증**: `features.doc_templates: true`인 프로젝트에서 신규 docs 문서는 PostToolUse에서도 frontmatter 존재를 확인
- **체크리스트 파일 대조**: `.dev-checklist.md`의 완료된 `Changed Files`, `.doc-checklist.md`의 완료된 `Related Docs` 항목이 실제 존재하는 파일을 가리키는지 확인
- **테스트 확장**: `tests/test_tiny_and_post_hooks.ps1`에 frontmatter 누락/정상, 체크리스트 파일 존재/누락 케이스 추가
- 왜: 체크박스만 완료 처리하고 실제 파일이 없거나, frontmatter가 깨진 문서를 다음 작업까지 방치하지 않기 위함

### Windows 훅 실행 경로 안정화
- **문제 확인**: PowerShell 환경에서 `bash`가 PATH에 없어서 `bash ~/.claude/hooks/*.sh` 설정은 Claude Code에서 실패할 수 있음
- **래퍼 추가**: `hooks/run-hook.ps1`이 `C:\Program Files\Git\bin\bash.exe` 절대 경로로 전역 훅을 실행하고 stdin raw bytes를 그대로 전달
- **settings 변경**: 모든 훅 command를 `powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\rlgns\.claude\hooks\run-hook.ps1' '<hook>'"` 형태로 변경
- **마무리 결함 수정**: `-File` 방식은 PowerShell pipeline binding과 인코딩 때문에 한글 경로 stdin이 깨질 수 있음을 확인하고 `-Command` + raw stdin 전달 방식으로 교체
- **실행 검증**: 전역 settings command 경유로 한글 경로 `docs/index.md` Write 차단, Codex 기록 문서 PostToolUse 통과, 전체 훅 테스트 통과 확인
- **로그 ignore 추가**: 훅 실행 중 생성되는 `.claude/harness-audit.log`가 커밋 잡음이 되지 않도록 `.gitignore`에 `.claude/` 추가
- 왜: 하네스가 설치되어 있어도 `bash` PATH 문제로 훅이 무력화되는 상태를 방지하기 위함

## Day 1 (2026-04-16)

### Codex 작업 검증 + 후속 수정
- **skipDangerousModePermissionPrompt 제거**: Codex가 P0에서 제거했다고 기록했지만 전역 settings에 남아있던 것을 발견하여 실제 제거
- **전역 dead hooks 삭제**: `lint-guard.sh`, `pre-commit-test.sh`, `venv-guard.sh` — settings에서 미참조 파일 3개 제거
- **MEMORY.md 스테일 포인터**: 존재하지 않는 `presentation.md` 참조 제거
- **Codex 작업 전체 커밋**: 35개 파일, +3265/-296줄 (`ac9f6ce`)
- 왜: Codex가 전역에 배포만 하고 repo 커밋을 안 했으므로, 검증 후 보존

### 훅 병목 제거 (성능 최적화)
- **check-streamlit.sh 제거**: matcher 없이 모든 도구(Read/Glob/Grep 포함)에 발동하던 universal 훅 삭제
- **auto-backup.sh 제거**: git이 이미 버전관리하므로 매 Edit마다 cp하는 훅 불필요
- **feature-gated 훅 기본 배선 제거**: `wiki-index-guard.sh`, `doc-template-guard.sh` — 매번 프로세스 생성 후 flag만 보고 exit하던 훅을 기본 배선에서 제거
- **결과**: Edit당 훅 7→3개, 프로세스 생성 14→6개 (57% 감소)
- 왜: Windows에서 프로세스 생성 비용이 높아 훅 하나당 200~500ms. Edit 한 번에 2~3초 소요되던 것을 1초 이하로

### Rules 최적화
- **중복 rules 축소**: `dev-checklist.md`, `document-safety.md`, `wiki.md`, `graphify.md` — 훅이 이미 강제하므로 1줄 포인터로 축소
- **rules 병합**: `communication.md` + `workflow.md` → `work-style.md` (협업 스타일 통합)
- **deployment.md 포인터화**: `deploy-version-guard.sh` 훅이 강제하므로 1줄 포인터로 축소
- **CLAUDE.md graphify 중복 제거**: 스킬 frontmatter와 동일한 안내 삭제
- **결과**: rules 12→9개 (실질 4개 + 포인터 5개), 총 ~600줄 → ~80줄
- 왜: 리서치 문서(하네스 과부하 문제)의 분석 — 훅이 강제하는 규칙을 rules에서 또 서술하면 컨텍스트 토큰만 낭비

## Day 2 (2026-04-16, 오후)

### 훅→스킬 아키텍처 전환
- **설계 원칙 전환**: 훅은 "사고 방지"만, 나머지는 스킬(온디맨드)로
- **`/checklist` 스킬 신규**: `dev-checklist-guard` + `doc-checklist-guard` 이원화를 하나의 통합 스킬로 대체. 코드/문서 자동 감지, 6단계 워크플로 (선언→백업→체크→구현→검증→보고)
- **`doc-protection` 백업 추가**: Edit 시 기존 문서를 `.backups/{name}.{timestamp}.bak`에 자동 복사. 코드는 git이 담당하므로 문서만
- **`deploy-version-guard` CI 체크 추가**: 기존 버전업/HISTORY 체크에 GitHub Actions CI 상태(gh run list) 확인 추가. CI 실패/실행 중이면 배포 차단
- **훅 대폭 축소**: settings 연결 11→7개 (Bash 4→3, Edit 2→1, Write 3→1, PostToolUse 2 유지)
- **dead hook 정리**: `dev-checklist-guard.sh`, `doc-checklist-guard.sh`, `doc-doublecheck-guard.sh`, `auto-backup.sh`, `check-streamlit.sh` 글로벌에서 삭제
- **`skipDangerousModePermissionPrompt` 재제거**: Day 1에서 제거했으나 다시 남아있던 것을 최종 제거
- **CLAUDE.md 프리플라이트 단순화**: dev/doc 이원화 안내 → `/checklist` 단일 안내로
- 왜: Windows에서 훅 하나 = 프로세스 2개(PS+Bash). 체크리스트를 훅으로 강제하면 매 Edit/Write마다 비용 발생. 스킬은 필요할 때만 호출하므로 0 비용

## Day 3 (2026-04-17)

### Codex/Gemini 크로스 리뷰 3라운드 — 18개 문제 수정
- **방법**: `/feedback` 스킬로 Codex(GPT-5.4)와 Gemini(2.5)에 병렬 리뷰 요청, 3라운드 반복
- **1차 리뷰 → 6개 수정**:
  - rules↔settings 정합성 충돌: rules 4개에서 '훅 강제' → '스킬 권장, 훅 강제 아님' 명시
  - post-edit-verify `.checklist.md` 인식 추가
  - doc-protection `.backups` blanket allow → 경로 기반 허용
  - doc-protection git 전체 면제 → 읽기 전용만 허용
  - MultiEdit 배선 추가 (settings Pre+Post)
  - `skipDangerousModePermissionPrompt` 제거
- **2차 리뷰 → 6개 수정**:
  - MultiEdit 훅 본문 미처리 → `Edit|MultiEdit)` 분기 추가
  - git 화이트리스트 redirect/체인 우회 → `[;|&>]` 포함 시 거부
  - git 파괴적 명령 확장자 의존 → 확장자 무관 즉시 차단
  - git whitelist 서브커맨드 미제한 → 파괴 옵션 부정 체크
  - `.backups` Windows 백슬래시 → `[/\\]` 대응
  - 배포 가드 jq 부재/파싱 실패 → unknown → fail-closed
- **3차 리뷰 → 6개 수정**:
  - **치명: BLOCKED=false 재초기화** → 파괴적 git 즉시 `block()` (exit 1)
  - **치명: newline/$() 우회** → 금지 문자에 `\n`, `$(`, 백틱 추가
  - git `--output`/`--ext-diff` 옵션 우회 → 차단 추가
  - branch/tag/remote prefix 매치 → 파괴 옵션(-D/-d, add/remove) 별도 부정 체크
  - `.backups` cp 의도 충돌 → 목적지가 .backups인 cp/mv는 백업 목적 허용
  - 배포 가드 unknown 메시지 → gh 없음/jq 없음/파싱 실패 세분화
- **결과**: settings 7→9 발동 (MultiEdit 추가), doc-protection git 보호 전면 재설계
- **Gemini 최종 평가**: "Production Ready"
- 왜: 하네스 훅은 보안 경계이므로 단일 모델 자체 검증으로는 blind spot 발생. 크로스 리뷰로 제어 흐름 버그(BLOCKED 재초기화) 같은 치명적 문제 발견

### 피드백 스킬 체계화
- **`/feedback` 스킬 수정**: 결과를 `docs/feedback/`에 저장 (기존 선택→필수)
- **파일명 규칙**: `{날짜}_{작성자}_{피드백-대상}.md` (작성자: codex/gemini/claude)
- **Claude 종합 문서**: 두 피드백 분석·종합한 별도 파일 생성
- **인덱스**: `docs/feedback/index.md`로 피드백 이력 관리
- **맥락 주입 규칙 추가**: Codex/Gemini는 싱글턴이므로 매번 충분한 배경+변경+코드를 프롬프트에 포함
- 왜: 피드백이 대화 안에서만 소비되고 사라지면 재활용 불가. 문서화해서 이력 추적

→ 피드백 상세: `docs/feedback/index.md`
