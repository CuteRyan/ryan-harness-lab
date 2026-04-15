---
name: project-history
description: 프로젝트 개발 히스토리를 폴더 기반 인덱스로 조회, 갱신, 마이그레이션, 검색.
trigger: /project-history
argument-hint: "[update|migrate|search] [키워드]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Project History Manager

프로젝트 개발 히스토리를 폴더 기반 인덱싱으로 관리하는 글로벌 스킬.

## Trigger
- "히스토리", "개발 기록", "지금까지 뭐 했지", "어디까지 했지", "프로젝트 상태"
- 새 세션 시작 시 이전 작업 맥락 파악
- `/project-history` 직접 호출

## Commands
- `/project-history` — 인덱스 기반 히스토리 요약 표시
- `/project-history update` — 현재 세션 작업을 히스토리에 추가
- `/project-history migrate` — 기존 단일 HISTORY.md → 폴더 구조로 마이그레이션
- `/project-history search <키워드>` — 히스토리 전체에서 키워드 검색

## 구조

```
docs/history/
├── index.md              ← 인덱스 (날짜 | Day N | 한줄 요약 | 링크)
├── 2026-03-05.md         ← Day 1 상세
├── 2026-03-06.md         ← Day 2 상세
└── ...
```

### index.md 포맷
```markdown
# Project History Index

| 날짜 | Day | 요약 | 파일 |
|------|-----|------|------|
| 2026-03-05 | 1 | 프로젝트 초기 설계 및 핵심 아키텍처 결정 | [상세](2026-03-05.md) |
| 2026-03-06 | 2 | 여론조사/후보/대시보드 설계 | [상세](2026-03-06.md) |
```

### 일별 파일 포맷
```markdown
# Day N — YYYY-MM-DD — 한줄 요약

## 1. 작업 제목
- 상세 내용
- **왜**: 이유
- 변경 파일: `path/to/file.py`

## 2. 작업 제목
- ...

## 다음 작업
- [ ] 항목
```

## How it works

### 조회 (`/project-history`)
1. `docs/history/index.md` 읽기 (없으면 `docs/HISTORY.md` 폴백)
2. 최근 5일치 요약 표시
3. 상세 필요 시 해당 날짜 파일만 Read

### 업데이트 (`/project-history update`)
1. 오늘 날짜 파일 생성 or 수정 (`docs/history/YYYY-MM-DD.md`)
2. `index.md`에 한 줄 추가 (이미 있으면 요약 업데이트)
3. 포맷 규칙:
   - 시간순 (최신이 아래)
   - 각 항목에 "왜(Why)" 포함
   - 번호 붙인 섹션 (`## 1.`, `## 2.`)

### 마이그레이션 (`/project-history migrate`)
1. 기존 `docs/HISTORY.md` 읽기
2. `## YYYY-MM-DD` 구분자로 날짜별 분리
3. 각 날짜를 `docs/history/YYYY-MM-DD.md`로 저장
4. `docs/history/index.md` 자동 생성
5. 원본 `docs/HISTORY.md` → `docs/.backups/HISTORY.md.bak`으로 백업
6. 주인님 확인 후 원본 삭제

### 검색 (`/project-history search <키워드>`)
1. `docs/history/` 전체 파일에서 Grep
2. 매칭된 날짜 + 컨텍스트 표시

## 훅 정책

히스토리 파일도 프로젝트 문서이므로 일반 문서 안전 규칙을 우회하지 않는다.

| 명령 | 파일 수 | 방법 | 원칙 |
|------|---------|------|------|
| `migrate` | 수십 개 | 승인 후 일괄 작업 | 실행 전 영향 범위와 백업 위치를 보고 |
| `update` (신규 파일) | 1~2개 | Write | 신규 문서 양식과 인덱스 갱신 준수 |
| `update` (기존 파일 수정) | 1~2개 | Edit | 기존 문서 전체 덮어쓰기 금지 |
| `search` / 조회 | 0 | Read/Grep | 읽기 전용 |

대량 마이그레이션이 훅과 충돌하면 훅을 우회하지 말고, 예외 범위를 문서화한 뒤 주인님 승인 후 진행한다.

## Rules
- **index.md는 200줄 이내 유지** — 메모리 인덱스와 동일 원칙
- **일별 파일 1개 = 1일** — 같은 날 여러 세션이면 같은 파일에 append
- **폴더 구조 우선** — `docs/history/` 있으면 단일 HISTORY.md 무시
- **마이그레이션은 주인님 승인 후** — 자동 실행 금지
- 히스토리 파일이 없으면 새로 생성
- 미완료 항목은 해당 일자 파일의 `## 다음 작업`에 유지

## File Locations
- 히스토리 폴더: `{프로젝트}/docs/history/`
- 히스토리 인덱스: `{프로젝트}/docs/history/index.md`
- 레거시 (폴백): `{프로젝트}/docs/HISTORY.md`
- 프로젝트 메모리: `~/.claude/projects/{프로젝트키}/memory/MEMORY.md`
