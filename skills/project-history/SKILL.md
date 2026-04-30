---
name: project-history
description: 프로젝트 개발 히스토리(완료 기록) 폴더 기반 관리. 조회, 갱신, 마이그레이션, 검색. 단일 세션 인계는 /handoff 사용.
trigger: /project-history
argument-hint: "[update|migrate|search] [키워드]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Project History Manager

프로젝트 개발 히스토리를 폴더 기반 인덱싱으로 관리하는 글로벌 스킬.

## Trigger
- "히스토리", "개발 기록", "지금까지 뭐 했지", "어디까지 했지", "프로젝트 상태"
- 새 세션 시작 시 완료 기록 조회 (단일 세션 인계는 `/handoff` 참조)
- `/project-history` 직접 호출

## Commands
- `/project-history` — 최근 5일 요약 + 장기 진행 중 포인터 표시
- `/project-history update` — 현재 세션의 **완료된** 작업을 일자별 파일에 추가
- `/project-history migrate` — 단일 HISTORY.md → 폴더 구조로 마이그레이션 (Phase 2 진입)
- `/project-history search <키워드>` — 히스토리 전체에서 키워드 검색

> 단일 세션 인계(진행 중 상태 전달)는 `/handoff` 스킬 사용. 본 스킬은 완료 기록만 다룬다.

## 구조 (Phase 1 / Phase 2 단계 구분)

### Phase 1: 단일 HISTORY.md (현재 단계)
```
docs/HISTORY.md
├── ## 🔄 진행 중 (다음 세션 인계)   ← 장기 항목 포인터 (SSOT는 HANDOFF.md)
├── ## 프로젝트 개요
├── ## Day 0 (YYYY-MM-DD)
├── ## Day 1 (YYYY-MM-DD)
└── ...
```

### Phase 2: 폴더 구조 (1주 검증 후 마이그레이션)
```
docs/history/
├── index.md              ← 진행 중 포인터 + 인덱스 표 (SSOT는 HANDOFF.md)
├── 2026-03-05.md         ← Day 1 상세 (완료 아카이브)
├── 2026-03-06.md         ← Day 2 상세 (완료 아카이브)
└── ...
```

**Phase 1 → Phase 2 전환 기준** (다음 중 하나):
- 진행 중 항목이 일상적으로 3개 이상 운영됨 (복잡도 임계)
- 인계 누락 1회 발생 (실패 신호)
- 1주 안정 운영 후 회고에서 "패턴 잡힘" 합의

### 진행 중 섹션 양식 (index.md 상단 — 장기 추적용 포인터)
```markdown
## 🔄 진행 중 (다음 세션 인계)

> 단일 세션 인계는 프로젝트 루트 HANDOFF.md (`/handoff` 스킬) 참조.
> 이 섹션은 **14일 이상 지속되거나 여러 세션에 걸친 장기 항목**만 추적.
> 양식: `[시작일] 상태 | 작업명 | 다음: (동사 시작) | 미결: 없음/내용`
> 한계: 7개 초과 또는 14일 초과 시 즉시 정리

- [2026-04-17] 진행 중 | 작업명 | 다음: 다음 단계 | 미결: 없음
```

**SSOT 위치 (Day 15 결정 2=C 적용)**:
- 단일 세션 인계: `HANDOFF.md` (루트, `/handoff` 스킬 SSOT)
- 장기 진행 항목: `docs/history/index.md` 상단 = 포인터. HANDOFF.md 와 동일 정보 중복 금지

### index.md 포맷 (Phase 2)
```markdown
# Project History Index

## 🔄 진행 중 (다음 세션 인계)
- [YYYY-MM-DD] 상태 | 작업명 | 다음: ... | 미결: ...

---

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
1. 오늘 날짜 파일/섹션 생성 or 수정 — **완료된 작업만 기록**
2. 포맷 규칙:
   - 시간순 (최신이 아래)
   - 각 항목에 "왜(Why)" 포함
   - 번호 붙인 섹션 (`## 1.`, `## 2.`)
3. **진행 중/미완 항목은 `/handoff` 가 담당** — 본 스킬은 일자별 파일에 손대지 않음
4. 14일 이상 지속된 장기 항목만 index.md 진행 중 포인터 섹션에 등록 (7개/14일 한계 검사)

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
- **단일 세션 인계 SSOT = `HANDOFF.md` (`/handoff` 스킬)** — index.md 진행 중 섹션은 14일 이상 장기 항목 포인터용. 동일 정보 중복 금지 (Day 15 결정 2=C)
- **/handoff 와 책임 분리** — "지금 하다 멈춘 것"은 `/handoff`, "완료된 기록"은 본 스킬, "언제 할지 모르는 백로그"는 `/todo`
- **진행 중 한계: 7개 OR 14일** — 둘 중 하나라도 걸리면 즉시 정리 (완료/폐기). 시각적 한계로 누적 방지
- **양식 엄격 준수** — `[시작일] 상태 | 작업명 | 다음: (동사) | 미결: 내용`. Phase 1부터 동일 형식 사용 (Phase 2 마이그레이션 부채 회피)
- **index.md는 200줄 이내 유지** — 메모리 인덱스와 동일 원칙
- **일별 파일 1개 = 1일** — 같은 날 여러 세션이면 같은 파일에 append
- **폴더 구조 우선** — `docs/history/` 있으면 단일 HISTORY.md 무시
- **마이그레이션은 주인님 승인 후** — 자동 실행 금지
- 히스토리 파일이 없으면 새로 생성
- 미완료 항목은 `/handoff` 로 세션 인계; 일자 파일에는 완료된 작업만 기록
- 장기 진행 항목 종결 시 cut → 해당 일자별 파일로 paste (단기 인계는 `/handoff` 가 처리)

## File Locations
- 히스토리 폴더: `{프로젝트}/docs/history/`
- 히스토리 인덱스: `{프로젝트}/docs/history/index.md`
- 레거시 (폴백): `{프로젝트}/docs/HISTORY.md`
- 프로젝트 메모리: `~/.claude/projects/{프로젝트키}/memory/MEMORY.md`
