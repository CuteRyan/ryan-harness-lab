---
title: 4스킬 Migration 계획 — /todo + /handoff 신설 + 기존 스킬 delta 적용
type: research
status: draft
created: 2026-04-29
updated: 2026-04-29
author: integration-auditor
---

# Migration 계획: 4스킬 체계 전환

## 전제

현재 상태:
- /checklist: 존재 (174줄, 스테이징+운영 모두 배포됨)
- /project-history: 존재 (114줄, 스테이징+운영 모두 배포됨)
- /todo: 미존재
- /handoff: 미존재
- index.md 진행 중 섹션: 5개 항목 (수동 관리 중)

목표 상태:
- /checklist: 백로그 책임 제거 + /todo 크로스레퍼런스 추가 (수정)
- /project-history: 인계 책임 이전 + /handoff 크로스레퍼런스 추가 (수정)
- /todo: 신규 생성
- /handoff: 신규 생성
- index.md 진행 중 섹션: critic 결정에 따라 옵션 A/B/C 적용

---

## Phase 0: 사전 백업 (안전 기준선 확보)

목적: 실패 시 롤백 기준점 확보.

```
1. skills/checklist/SKILL.md → skills/checklist/.backups/SKILL.md.bak.2026-04-29
2. skills/project-history/SKILL.md → skills/project-history/.backups/SKILL.md.bak.2026-04-29
3. docs/history/index.md → docs/history/.backups/index.md.bak.2026-04-29
4. ~/.claude/skills/checklist/SKILL.md → ~/.claude/skills/checklist/.backups/SKILL.md.bak.2026-04-29
5. ~/.claude/skills/project-history/SKILL.md → ~/.claude/skills/project-history/.backups/SKILL.md.bak.2026-04-29
```

완료 판정: 위 5개 파일 백업 확인 후 Phase 1 진입.

---

## Phase 1: 신규 스킬 생성 (기존 스킬 미수정)

목적: 기존 시스템 무중단 상태에서 신규 스킬 추가.

순서:
1. skill-architect의 `01_todo_spec.md` 기반으로 `/todo` SKILL.md 생성
   - 위치: `Harness-engineering/skills/todo/SKILL.md`
   - 내용: task #1 산출물 확정 후 적용

2. skill-architect의 `02_handoff_spec.md` 기반으로 `/handoff` SKILL.md 생성
   - 위치: `Harness-engineering/skills/handoff/SKILL.md`
   - 내용: task #1 산출물 확정 후 적용

3. settings.json에 신규 스킬 등록 (스킬 트리거 활성화)

**중요**: Phase 1 완료 후 /todo, /handoff 스모크 테스트 통과 확인 전까지 Phase 2 진입 금지.

스모크 테스트 기준:
- /todo: 항목 1개 추가 → 조회 → 삭제 정상 동작
- /handoff: 인계 메모 1건 생성 → 다음 세션 복원 시뮬레이션

---

## Phase 2: 기존 스킬 수정

Phase 1 스모크 통과 후 진행.

### 2-A: /checklist SKILL.md 수정

**수정 위치 및 내용**:

(a) Phase 2 (L35) 뒤에 주석 추가:
```
- 예상 외 이슈 발생 시 체크리스트에 항목 추가
  (이번 세션 완료 가능 항목만; 세션 횡단 항목은 `/todo add`로 이전)
```

(b) Phase 6 (L68) 앞에 단계 추가:
```
- 미완 항목이 있으면 `/todo add [항목명]`으로 이전 후 .checklist.md를 .backups/로 이동
```

(c) Rules 섹션 말미에 추가:
```
- **/todo와 책임 분리**: 세션 완료 가능 항목은 `.checklist.md` 보관;
  세션 횡단 백로그는 `/todo`로 관리.
```

### 2-B: /project-history SKILL.md 수정

**수정 위치 및 내용**:

(a) Rules L107 수정:
```
기존: "미완료 항목은 해당 일자 파일의 `## 다음 작업`에 유지"
변경: "미완료 항목은 `/handoff`로 세션 인계; 일자 파일에는 완료된 작업만 기록"
```

(b) Commands 섹션 말미에 추가:
```
- 세션 인계(진행 중 상태 전달)는 `/handoff` 스킬 사용
```

### 2-C: 글로벌 동기화

스테이징 수정 후 운영으로 복사:
```powershell
# /checklist 동기화
Copy-Item "skills/checklist/SKILL.md" "$HOME/.claude/skills/checklist/SKILL.md" -Force
# 검증
Get-FileHash "skills/checklist/SKILL.md", "$HOME/.claude/skills/checklist/SKILL.md" -Algorithm SHA256

# /project-history 동기화
Copy-Item "skills/project-history/SKILL.md" "$HOME/.claude/skills/project-history/SKILL.md" -Force
# 검증
Get-FileHash "skills/project-history/SKILL.md", "$HOME/.claude/skills/project-history/SKILL.md" -Algorithm SHA256

# 신규 스킬 운영 배포
Copy-Item "skills/todo/SKILL.md" "$HOME/.claude/skills/todo/SKILL.md" -Force
Copy-Item "skills/handoff/SKILL.md" "$HOME/.claude/skills/handoff/SKILL.md" -Force
```

완료 판정: 4개 스킬 운영 경로 SHA256 일치 확인.

---

## Phase 3: index.md 진행 중 섹션 처리

**critic 결정 후 적용**. 옵션별 절차:

### 옵션 A (제거) 실행 절차:
```
1. index.md의 `## 🔄 진행 중` 섹션 전체를 HANDOFF.md 초기 내용으로 이전
2. index.md에서 해당 섹션 삭제 (16줄 → 제거)
3. index.md 상단에 "인계 정보: HANDOFF.md 참조" 주석 추가
```

### 옵션 B (자동 동기화) 실행 절차:
```
1. /handoff가 HANDOFF.md 생성 시 index.md 진행 중 섹션도 자동 업데이트
2. SKILL.md에 "index.md 동기화 의무" 명시
3. 기존 5개 항목은 HANDOFF.md로 복사 후 index.md에 유지 (중복 초기화)
```

### 옵션 C (최소 유지) 실행 절차:
```
1. index.md 진행 중 섹션을 "포인터 전용"으로 축소
2. 기존 5개 항목 중 "종결" 상태인 3개 → 삭제 (정리 과잉 방치 해소)
3. 남은 2개("진행 중", "부분 종결") → HANDOFF.md로 이전, index.md에는 포인터만
```

---

## Phase 4: 현재 진행 중 5개 항목 /handoff 이전

**/handoff SKILL.md 확정 후 실행**.

현재 진행 중 항목 처리 방법:

| 항목 | 상태 | 처리 |
|---|---|---|
| [2026-04-17] 세션 인계 + 폴더 마이그레이션 | 진행 중 | 1주 회고 기한 불명확 → HANDOFF.md로 이전 |
| [2026-04-18] venv 규칙 + /feedback 개정 | 부분 종결 | B5/B7 미완 → HANDOFF.md로 이전 |
| [2026-04-22] /feedback 구조 승격 | 종결 | /todo 다음 작업 있음 → /todo로 이전 |
| [2026-04-23] Day 10 이월 ④ Gemini | 부분 종결 | .checklist.md 미승인 잔존 → HANDOFF.md로 이전 |
| [2026-04-28] /feedback 3단계 완료 | 종결 | 1주 회고 예정 → /todo로 이전 |

파일 형식 변환:
```
# 현재 index.md 포맷
[시작일] 상태 | 작업명 | 다음: ... | 미결: ...

# 변환 후 HANDOFF.md 포맷 (추정 — /handoff 확정 후 조정 필요)
## [작업명]
- 시작: 시작일
- 상태: 상태값
- 다음 할 일: 다음 내용
- 미결 사항: 미결 내용
- 관련 파일: (있으면)
```

---

## 롤백 절차

### 롤백 트리거
- /todo 또는 /handoff 스모크 실패 (Phase 1)
- 수정된 /checklist 또는 /project-history가 기존 워크플로를 깨뜨림 (Phase 2)
- index.md 진행 중 섹션 손실 후 HANDOFF.md 미생성 (Phase 3)

### 롤백 방법 (Phase별)

**Phase 1 롤백** (신규 스킬 되돌리기):
```
1. Harness-engineering/skills/todo/ 폴더 삭제
2. Harness-engineering/skills/handoff/ 폴더 삭제
3. ~/.claude/skills/todo/ 폴더 삭제 (배포했다면)
4. ~/.claude/skills/handoff/ 폴더 삭제 (배포했다면)
5. settings.json에서 신규 스킬 트리거 제거
```

**Phase 2 롤백** (기존 스킬 수정 되돌리기):
```
1. skills/checklist/.backups/SKILL.md.bak.2026-04-29 → skills/checklist/SKILL.md로 복원
2. skills/project-history/.backups/SKILL.md.bak.2026-04-29 → skills/project-history/SKILL.md로 복원
3. 운영 경로에도 동일하게 복원 (백업 5, 4번 파일)
4. SHA256으로 복원 완료 확인
```

**Phase 3 롤백** (index.md 되돌리기):
```
1. docs/history/.backups/index.md.bak.2026-04-29 → docs/history/index.md로 복원
2. 진행 중 섹션 5개 항목 복원 확인 (L10–L14)
```

**Phase 4 롤백** (항목 이전 실패):
```
1. Phase 3 롤백 후
2. HANDOFF.md 생성됐다면 삭제 (기준선 복원 완료)
```

### 롤백 완료 판정
- 모든 SKILL.md가 백업본과 SHA256 일치
- index.md 진행 중 섹션 5개 항목 정상 확인
- /checklist, /project-history 트리거 정상 동작 확인

---

## 글로벌 dev-checklist.md SSOT 변경 여부

**파일**: `C:/Users/rlgns/.claude/rules/dev-checklist.md` (13줄)

현재 역할: `/checklist` 스킬의 SSOT 위치 명시 + 스테이징/운영 분리 원칙.

**변경 필요 없음** — 이유:
- SSOT 원칙 자체는 변경 없음 (스테이징 = 프로젝트, 운영 = ~/.claude/)
- /todo, /handoff 신설은 새로운 스킬 추가이므로 기존 규칙을 건드리지 않음
- **단, 권장 추가**: "신규 스킬(/todo, /handoff)도 동일 스테이징/운영 분리 원칙 적용" 명시 (13줄에 추가)

---

## 5게이트

### (1) 라인 실측
- checklist/SKILL.md L35, L65–L68 직접 인용 (수정 대상 라인)
- project-history/SKILL.md L107 직접 인용 (수정 대상 라인)
- index.md L10–L14 진행 중 5개 항목 직접 확인
- dev-checklist.md L1–L13 (13줄 전체) 직접 확인

### (2) 반박/유보
- **약점**: Phase 3 "파일 형식 변환" 섹션의 HANDOFF.md 포맷이 추정 기반이다. /handoff SKILL.md가 확정되지 않은 상태에서 HANDOFF.md 포맷을 임의로 제시했으며, 실제 구조와 달라질 수 있다. Phase 3는 반드시 02_handoff_spec.md 완성 후 재검토 필요.

### (3) 근거 강도
- Phase 0 백업 절차: **강** (배포 규칙 일반론 준수)
- Phase 1 스모크 기준: **강** (bot-deploy.md 패턴 준용)
- Phase 2 수정 라인: **강** (SKILL.md 직접 인용 기반)
- Phase 3 옵션별 절차: **중** (/handoff 미확정 → 추정 포함)
- Phase 4 형식 변환: **약** (/handoff 포맷 미확정)
- 롤백 절차: **강** (deployment.md 패턴 준용, 백업 경로 실측 기반)

### (4) 자기 비판
이번 migration 계획에서 놓쳤을 가능성: Phase 2 글로벌 동기화 시 `/todo`, `/handoff` 스킬이 `~/.claude/skills/` 디렉토리에 신규 폴더로 배포될 때, settings.json의 skills 등록 방식(트리거 경로, skills 섹션 유무)이 기존 스킬과 동일한지 확인하지 않았다. settings.json 구조를 사전에 Read하여 신규 스킬 등록 패턴을 검증해야 한다.
