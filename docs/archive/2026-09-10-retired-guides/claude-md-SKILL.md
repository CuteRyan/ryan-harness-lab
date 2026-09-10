---
name: claude-md
description: CLAUDE.md 표준 템플릿 적용(init) + 품질 감사(audit). 하네스 프로젝트 일관성 유지.
trigger: /claude-md
argument-hint: "[init|audit] [경로]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# /claude-md — CLAUDE.md 표준 관리 스킬

**SSOT 5원칙**: `Harness-engineering/docs/templates/CLAUDE.md.template` 최상단 헌법 블록이 유일한 원본. 이 스킬 문서는 그 원칙을 **중복 기재하지 않는다** — drift 방지.

## Commands
- `/claude-md init [경로]` — 새 프로젝트에 표준 CLAUDE.md 배포
- `/claude-md audit [경로]` — 기존 CLAUDE.md 품질 검증 (화면 리포트만)
- 경로 생략 시 **현재 작업 디렉토리** 기준

## 위치 (스테이징 / 운영 단방향)
- **원본(스테이징)**: `Harness-engineering/skills/claude-md/SKILL.md`
- **운영 사본**: `~/.claude/skills/claude-md/SKILL.md`
- 스테이징만 편집, 편집 후 운영으로 복사. 역방향 금지. (dev-checklist.md SSOT 섹션 준수)

## `/claude-md init [경로]`

### 절차
1. 대상 디렉토리 결정 (인자 > 현재 cwd)
2. **위치 검증** — `.claude/CLAUDE.md` 생성 시도 시 차단 (반드시 프로젝트 루트)
3. **기존 CLAUDE.md 존재 검사** — 있으면 즉시 중단, 덮어쓰기 거부 (사람이 수동 병합)
4. 템플릿 Read: `Harness-engineering/docs/templates/CLAUDE.md.template`
5. `{{프로젝트명}}` → 대상 디렉토리 basename 치환 (1곳: 제목, 1곳: 코드펜스)
6. 나머지 `{{...}}` 플레이스홀더는 **그대로 남김** — 사람이 직접 채움
7. `{경로}/CLAUDE.md` 에 Write

### 안전장치
- 헌법 블록은 항상 그대로 복사 — 제거·수정 금지
- 덮어쓰기 방지: 기존 파일이 한 글자라도 있으면 중단

## `/claude-md audit [경로]`

### 검사 항목
| # | 항목 | 기준 | 근거 |
|---|------|------|------|
| 1 | 위치 이상 | `.claude/CLAUDE.md` 존재하면 🔴 — 자동 로드 안 됨 | PAA 실측 사례 (2026-04-24) |
| 2 | 길이(본체) | 60~100줄 ✅ · 100~300 ⚠️ · 300+ 🔴 | 80줄 이상 일부 무시 / 300줄 이상 드리프트 보고 |
| 3 | 헌법 블록 | 최상단 SSOT 5원칙 주석 블록 존재 | 템플릿 준수 |
| 4 | 필수 섹션 | `## 개요` / `## 개발 명령` / `## 워크플로` 누락 여부 | 최소 뼈대 |
| 5 | `@import` 유효성 | `@docs/...` 로 참조한 파일 실제 존재 | drift 감지 |
| 6 | 플레이스홀더 잔존 | `{{...}}` 미치환 남아있으면 ⚠️ | init 후 방치 방지 |

### 출력
- **화면 리포트만** — 파일 저장 X (옵션 A, drift 이력 추적은 필요 시 승격)
- 프로젝트별 ✅/⚠️/🔴 판정 + 개선 권고 한 줄

### 불변
- audit 는 **읽기 전용** — 자동 수정 금지 (Anthropic 공식 "수동 정제" 원칙)

## 호출 예시
```
/claude-md audit                            # 현재 프로젝트
/claude-md audit ~/OneDrive/문서/HSK        # 특정 경로
/claude-md init ~/OneDrive/문서/새-프로젝트  # 새 프로젝트 초기화
```

## 연관 규칙
- 프리플라이트: `~/.claude/CLAUDE.md`
- 스테이징 동기화 책임: `~/.claude/rules/dev-checklist.md` SSOT 섹션
- 메모리 3계층: `~/.claude/rules/memory-architecture.md`
- 템플릿(구조 SSOT): `Harness-engineering/docs/templates/CLAUDE.md.template`

## 공식 `/init` 과의 관계

Claude Code 내장 `/init` 은 **코드베이스 스캔 기반 발견형** — `pyproject.toml`·`Makefile`·`tests/` 등을 읽어 빌드·테스트·컨벤션을 자동 파악 후 CLAUDE.md 초안 생성. 이 스킬은 **템플릿 기반 스켈레톤 형** — 구조만 주고 사람이 Why 를 채우도록 강제. 역할이 달라 대체 관계 아님.

- 남의 레거시 코드 첫 분석 → `/init` 으로 현황만 참고
- 하네스 일관성 배포 → 이 스킬 단독
- 이미 `CLAUDE.md` 있는 프로젝트 → `/claude-md audit` 만, init 스킵

공식 문서: https://code.claude.com/docs/en/memory.md ("If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting it. Refine from there with instructions Claude wouldn't discover on its own.")
