# 하네스 프로젝트

> 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로)를 설계·개발·관리하는 프로젝트

## 프로젝트 범위
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅, 워크플로
- **역할**: 하네스 인프라의 설계·구현·테스트·문서화
- **⚠️ 리서치 문서(하네스 개념, 비교 분석 등)는 `문서/지식/` 프로젝트에 보관**

## docs/ 구조
- `docs/project_harness_architecture.md` — 하네스 아키텍처 설계안 (Phase 0~4)
- `docs/harness_bypass_guide.md` — 훅 우회 가이드
- `docs/workflows/` — 워크플로 상세 절차 (dev-checklist, document-work, wiki-management, graphify-guide)
- `docs/history/` — 프로젝트 히스토리 (일별 파일 + `index.md` SSOT, 진행 중 섹션 포함)

## 경로 설정
- **원본 경로**: `C:\Users\rlgns\OneDrive\문서\하네스` (한글 포함, OneDrive 동기화 대상)
- **codex_workdir**: `C:\Users\rlgns\codex-cwd` — Codex CLI 전용 **영문 workdir (표준 패턴)**
  - **Why**: Codex가 한글 경로에서 CP949 깨짐 / UTF-8 재시도 정책 차단 / 재귀 스캔 폭주 (2026-04-19 실측 3종). Gemini는 영향 없어 원본 경로 사용
  - **표준 사용 패턴** (`/feedback` 스킬 호출 시):
    1. 대상 파일을 `$HOME\codex-cwd\<슬러그>.md`로 복사
    2. `cd $HOME\codex-cwd`
    3. `codex.cmd exec --sandbox read-only "<workdir의 파일만 읽고 다른 경로 탐색 금지하는 프롬프트>"`
    4. `--add-dir`은 최소 사용 (재귀 스캔 트리거)
  - **대안 (비추)**: Junction `C:\Users\rlgns\harness` → 원본 경로. 존재하지만 `--add-dir` 조합에서 git loop 실패 관찰됨. 백업용
