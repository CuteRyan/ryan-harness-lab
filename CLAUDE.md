<!-- ============================================================
CLAUDE.md 헌법 (SSOT 5원칙) — 이 블록의 원본은 오직
`Harness-engineering/docs/templates/CLAUDE.md.template` 이다.
다른 곳에서 이 블록 문구가 수정되면 다음 audit 에서 drift 로
검출된다. 변경 필요 시 템플릿 파일에서만 고치고 재배포.

1. 단일 출처 — 같은 정보는 한 곳에만. 다른 곳엔 @import 로 참조.
2. 길이 세금 — 본체 60~100줄 유지. 넘으면 docs/ 로 이관 후 @import.
3. 스테이징→운영 단방향 — 스킬·템플릿은 Harness-engineering 이 원본.
   ~/.claude/ 운영 사본은 복사로만 갱신. 역방향 수정 금지.
4. Drift 감지는 기계로 — /claude-md audit 가 주기 검증. 수동 점검 X.
5. 내용 갱신은 사람이 — 스킬은 뼈대 생성·검증까지. 실제 수정은 사람.
============================================================ -->

# 하네스 프로젝트

> 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로)를 설계·개발·관리하는 프로젝트 · 이 프로젝트가 **CLAUDE.md 템플릿 원본 보유자**

## 프로젝트 범위
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅, 워크플로
- **역할**: 하네스 인프라의 설계·구현·테스트·문서화
- **⚠️ 리서치 문서(하네스 개념, 비교 분석 등)는 `문서/지식/` 프로젝트에 보관**
- **스테이징/운영 분리**: 스킬·훅·rules는 이 프로젝트(`Harness-engineering/`) = 스테이징, `~/.claude/` = 운영. 편집 후 동기화 책임은 이 프로젝트에 있음. 상세: `~/.claude/rules/dev-checklist.md` SSOT 섹션.
- **프리플라이트 SSOT**: `/checklist`·훅 차단 대응 등 프리플라이트는 글로벌 `~/.claude/CLAUDE.md`가 SSOT. **이 파일에 프리플라이트 블록 중복 추가 금지** (모든 프로젝트에 자동 적용되므로 중복 시 drift 원인).

## docs/ 구조
- `docs/project_harness_architecture.md` — 하네스 아키텍처 설계안 (Phase 0~4)
- `docs/harness_bypass_guide.md` — 훅 우회 가이드
- `docs/templates/CLAUDE.md.template` — CLAUDE.md 헌법 블록 + 표준 뼈대 (SSOT)
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

## 개발 명령 (복붙 가능)
- **CLAUDE.md 표준 감사**: `/claude-md audit` — 현재 프로젝트 또는 인자 경로의 CLAUDE.md 6기준 검증 (위치/길이/헌법/필수섹션/@import/플레이스홀더)
- **CLAUDE.md 신규 배포**: `/claude-md init [경로]` — 템플릿 복사 (기존 파일 있으면 거부)
- **스킬 동기화 (스테이징→운영, 단방향)**:
  ```powershell
  Copy-Item -LiteralPath "$PWD\skills\<스킬명>\SKILL.md" `
            -Destination "$HOME\.claude\skills\<스킬명>\SKILL.md" -Force
  # 검증: 양쪽 SHA256 비교로 drift 0 확인
  Get-FileHash "$PWD\skills\<스킬명>\SKILL.md", "$HOME\.claude\skills\<스킬명>\SKILL.md" -Algorithm SHA256
  ```
- **rules 동기화**: 동일 패턴으로 `rules/*.md` → `~/.claude/rules/*.md` (역방향 금지)
- **체크리스트 워크플로**: `/checklist` — 코드/문서 작업 전 자동 생성·검증·보고

## 참고 (세부는 @import 로 분리)
- @docs/history/index.md
- @docs/templates/CLAUDE.md.template
- @docs/project_harness_architecture.md

<!-- 개인 오버라이드가 필요하면 CLAUDE.local.md 를 작성하고 .gitignore 에 등재 -->
