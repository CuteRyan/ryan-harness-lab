---
title: 4개 스킬 일상 워크플로 시나리오
type: design
status: draft
created: 2026-04-29
updated: 2026-04-29
author: workflow-ux teammate
related_docs:
  - 01_todo_spec.md
  - 02_handoff_spec.md
  - 05_data_flow.md
---

# 4개 스킬 일상 워크플로 시나리오

> 작성자: workflow-ux (팀: skill-quartet-planning) | 2026-04-29
> 한 사이클(출근→작업→퇴근) + 엣지 케이스(세션 중단 복원) 자연어 narration

---

## 시나리오 A: 정상 사이클 (출근 → 퇴근)

### A-1. 출근 — 오늘 할 일 파악

**상황**: 주인님이 새 세션을 시작합니다.

주인님: "오늘 `/feedback` 스킬에 엣지 케이스 처리 추가하고, `SKILL.md` 문서도 업데이트해야겠다."

**트리거된 스킬**: `/todo`

**자연어 호출**: "오늘 할 일 추가해줘: 1) /feedback 엣지 케이스 처리 추가, 2) SKILL.md 문서 업데이트"

**파일 갱신**:
```
.todo.md (Write)
─────────────────────────────
# 할 일 목록 — 2026-04-29

## 미완료
- [ ] /feedback 엣지 케이스 처리 추가
- [ ] SKILL.md 문서 업데이트

## 완료
(없음)
```

**비주얼**: TaskCreate 체크박스 2개 생성. 주인님 화면에 `[ ] /feedback 엣지 케이스 처리 추가` 형태로 표시.

---

### A-2. 이전 세션 컨텍스트 복원 확인

**상황**: 이전 세션 HANDOFF.md가 존재하는 경우.

**트리거된 스킬**: `/handoff` (읽기 모드)

**자연어 호출**: "/handoff 상태 확인해줘" 또는 세션 시작 시 자동 참조

**파일 읽기**: `HANDOFF.md`
```
## 미완 항목
- [ ] /feedback 스킬 sycophancy 감지 threshold 조정 (어제 50% 기준 보류)

## 다음 진입점
- hooks/data/sycophancy-keywords.txt 수정 후 dogfood 재실행

## 컨텍스트
- Day 14 PM 작업 이어서 진행
```

**파일 갱신**: 없음 (읽기만)

**비주얼**: 이전 세션 미완 항목이 텍스트로 표시. `/todo`와 대조하여 중복 없이 오늘 목록에 편입.

---

### A-3. 첫 번째 작업 시작 — 체크리스트 생성

**상황**: 주인님이 `/feedback` 엣지 케이스 처리 작업을 시작하기로 결정.

**트리거된 스킬**: `/checklist`

**자연어 호출**: "/checklist /feedback 엣지 케이스 처리 추가"

**Claude 동작 (Phase 1)**:
1. git status --short 실행 → 기준선 기록
2. `.checklist.md` 생성:

```
.checklist.md (Write)
─────────────────────────────
# 체크리스트: /feedback 엣지 케이스 처리 추가

approved: false
status: draft
mode: code
작성일: 2026-04-29
근거: 주인님 요청

## 배경 / 목적
/feedback 스킬에서 빈 응답·네트워크 오류 케이스를 처리하지 않아
타임아웃 시 무한 대기 발생 가능.

## 작업 전 기준선
(git status --short 출력)

## 작업 항목
- [ ] scripts/run-codex.ps1 에 타임아웃 처리 추가
- [ ] scripts/run-gemini.ps1 에 빈 응답 처리 추가
- [ ] SKILL.md 에 에러 케이스 섹션 추가

...
```

3. 체크리스트 작성 완료 → **주인님께 승인 요청 후 턴 종료**

**비주얼**: `.checklist.md` 파일 생성. Claude가 구현을 시작하지 않고 승인 요청 메시지만 출력하고 대기.

---

### A-4. 주인님 승인 → 구현 진행

**상황**: 주인님이 "승인" 또는 "진행해"라고 응답.

**Claude 동작 (Phase 2)**:
- `.checklist.md` → `approved: true`, `status: approved`로 변경
- 항목별 구현 진행하며 `[x]` 체크

**파일 갱신**:
```
.checklist.md (Edit)
─────────────────────────────
approved: true          ← 변경
status: approved        ← 변경

## 작업 항목
- [x] scripts/run-codex.ps1 에 타임아웃 처리 추가
- [x] scripts/run-gemini.ps1 에 빈 응답 처리 추가
- [ ] SKILL.md 에 에러 케이스 섹션 추가  ← 진행 중
```

**비주얼**: 체크박스가 `[x]`로 업데이트되며 진행 상황 시각화.

---

### A-5. 검증 + 더블 체크

**Claude 동작 (Phase 3~4)**:
- 각 수정 파일을 Read하여 반영 확인 (인용 증거 남김)
- lint 실행
- git diff --stat 결과와 체크리스트 1:1 대조

**파일 갱신**:
```
.checklist.md (Edit)
─────────────────────────────
## 검증 항목
- [x] lint 통과
- [x] git diff 일치
- [x] 기존 기능 영향 없음
```

---

### A-6. /todo 완료 처리

**트리거된 스킬**: `/todo`

**자연어 호출**: (자동) 또는 "첫 번째 할 일 완료 처리해줘"

**파일 갱신**:
```
.todo.md (Edit)
─────────────────────────────
## 미완료
- [ ] SKILL.md 문서 업데이트   ← 남은 항목

## 완료
- [x] /feedback 엣지 케이스 처리 추가   ← 이동
```

**비주얼**: 완료 항목이 `## 완료` 섹션으로 이동. 미완료 1건 남음 시각적 확인.

---

### A-7. 히스토리 기록 (Phase 6)

**트리거된 스킬**: `/history update` (또는 `/checklist` Phase 6에서 자동 안내)

**자연어 호출**: "/history update" 또는 `/checklist` Phase 6 진행 시 Claude가 안내

**파일 갱신**:
```
docs/history/2026-04-29.md (Write 또는 Edit)
─────────────────────────────
# Day 15 — 2026-04-29 — /feedback 엣지 케이스 처리

## 1. /feedback 엣지 케이스 처리 추가
- 타임아웃 + 빈 응답 처리
- **왜**: 타임아웃 시 무한 대기 발생 가능성 제거
- 변경 파일: `scripts/run-codex.ps1`, `scripts/run-gemini.ps1`

## 다음 작업
- [ ] SKILL.md 문서 업데이트
```

```
docs/history/index.md (Edit)
─────────────────────────────
| 2026-04-29 | 15 | /feedback 엣지 케이스 처리 추가 | [상세](2026-04-29.md) |
```

**비주얼**: `.checklist.md`가 `.backups/`로 이동. 히스토리 파일 2개 갱신.

---

### A-8. 세션 종료 — 핸드오프 저장

**상황**: 두 번째 작업(SKILL.md 업데이트)은 시간 부족으로 다음 세션으로 이월.

**트리거된 스킬**: `/handoff`

**자연어 호출**: "오늘 작업 마무리하고 핸드오프 저장해줘"

**파일 갱신**:
```
HANDOFF.md (Write 또는 Edit)
─────────────────────────────
# 세션 핸드오프 — 2026-04-29 퇴근

## 완료 항목
- [x] /feedback 엣지 케이스 처리 추가 (docs/history/2026-04-29.md 기록됨)

## 미완 항목
- [ ] SKILL.md 문서 업데이트 (미착수)

## 다음 진입점
- skills/feedback/SKILL.md 열어서 에러 케이스 섹션 추가

## 컨텍스트
- Day 15 오전 작업. 오후에 이어서 진행 예정.
- .todo.md 에 미완 항목 1건 남아있음.
```

**비주얼**: HANDOFF.md 저장 완료. 세션 종료.

---

## 시나리오 B: 엣지 케이스 — 세션 중간 단절

> 핵심 질문: 세션이 작업 도중에 끊기면 어떻게 복원하는가?

### B-1. 단절 직전 상태

```
진행 중 상태:
- .todo.md:
    - [x] /feedback 엣지 케이스 처리 추가
    - [ ] SKILL.md 문서 업데이트  ← 진행 중
- .checklist.md:
    approved: true
    status: approved
    - [x] SKILL.md에 에러 케이스 섹션 추가
    - [ ] SKILL.md에 예시 추가          ← 체크 전 단절
- HANDOFF.md: (어제 것 — 오늘 세션 핸드오프 미저장)
- docs/history/2026-04-29.md: 첫 번째 작업만 기록됨
```

**단절 원인**: Claude Code 프로세스 강제 종료 또는 네트워크 끊김

---

### B-2. 다음 세션 — 상태 파악

**주인님**: "어디까지 했지?"

**Claude 복원 순서**:

1. **`.checklist.md` 확인 (최우선)**
   - `approved: true`, `status: approved` 확인
   - 체크된 항목과 미체크 항목 목록 파악
   - → "SKILL.md 에러 케이스 섹션까지 완료, 예시 추가가 남았습니다"

2. **`.todo.md` 확인**
   - 미완료 항목 1건 확인: "SKILL.md 문서 업데이트"
   - → "SKILL.md 문서 업데이트 작업 중이었음"

3. **`HANDOFF.md` 확인**
   - 어제 것이므로 오늘 컨텍스트 없음
   - → "세션 핸드오프가 저장되지 않아 어제 HANDOFF.md 기준으로 복원"

4. **`docs/history/2026-04-29.md` 확인**
   - 첫 번째 작업만 기록됨
   - → "두 번째 작업은 히스토리 미기록 상태"

**복원 결과 요약**:
- `.checklist.md` 기반: SKILL.md 예시 추가 1건 남음 (신뢰도: 높음)
- `.todo.md` 기반: SKILL.md 업데이트 미완료 (신뢰도: 높음)
- `HANDOFF.md` 기반: 오늘 컨텍스트 없음 (손실)

---

### B-3. 복원 후 작업 재개

**주인님**: "이어서 진행해줘"

**Claude 동작**:
- `.checklist.md` 체크 상태부터 이어서 Phase 2 재진입
- 새로 체크할 항목: "SKILL.md에 예시 추가"
- 완료 후 Phase 3~6 정상 진행

**손실 없이 복원 가능한 것**:
- 구현 진행 상태 (`.checklist.md` 체크 현황)
- 할 일 목록 (`.todo.md` 항목)

**복원 불가한 것**:
- "왜 이 작업을 하고 있었는지" 즉각적 컨텍스트 (`HANDOFF.md` 미저장으로 손실)
- 작업 중 Claude와 나눈 대화 맥락

**시사점**: `/handoff` 는 가능하면 작업 단위 완료 시점 + 세션 종료 직전 2회 호출하는 것이 안전.

---

## 스킬 호출 빈도 요약

| 시점 | 스킬 | 호출 예시 자연어 |
|------|------|----------------|
| 세션 시작 | `/handoff` (읽기) | "어디까지 했지?", "이전 상태 확인" |
| 할 일 추가 | `/todo` | "오늘 할 일 추가해줘: ..." |
| 작업 시작 | `/checklist` | "/checklist [작업명]" |
| 구현 완료 | `/todo` (완료처리) | 자동 또는 "첫 번째 완료 처리해줘" |
| 완료 기록 | `/history update` | "/history update" |
| 세션 종료 | `/handoff` (저장) | "핸드오프 저장해줘", "오늘 마무리" |

---

## 5게이트 검증

### (1) 라인 실측

- checklist SKILL.md 30~31줄: "Phase 1 완료 시 구현 파일을 절대 수정하지 않는다. 주인님께 승인 요청만 하고 턴을 종료한다." → 시나리오 A-3 반영 확인.
- checklist SKILL.md 65~68줄: "Phase 6에서 `.backups/`로 이동", "docs/history/{YYYY-MM-DD}.md 업데이트" → 시나리오 A-7 반영 확인.
- project-history SKILL.md 68~74줄: "오늘 날짜 파일 생성 or 수정", "index.md에 한 줄 추가" → 시나리오 A-7 반영 확인.

### (2) 반박/유보

**비현실적 가능성**: 시나리오 A에서 `/checklist` Phase 6가 자동으로 `/history update`를 안내 또는 트리거하는 것으로 서술했으나, 현재 checklist SKILL.md(68줄)는 "필요 시 업데이트"라고 표현 — 자동 트리거가 아닌 수동 단계일 가능성이 높음. 시나리오가 자동화 수준을 과도하게 묘사했을 수 있으며, critic 단계에서 확인 필요.

### (3) 근거 강도

- 승인 대기 후 턴 종료: **강** (checklist SKILL.md 30~31줄 직접 인용)
- `/handoff` 파일 구조(미완 항목 + 다음 진입점): **중** (index.md 진행 중 섹션 패턴 기반 — 02_handoff_spec.md 미완성)
- `/todo` 완료 처리 후 항목 이동 방식: **약** (01_todo_spec.md 미완성 — 추정)

### (4) 자기 비판

이번 시나리오에서 놓쳤을 가능성: `/todo`와 `/checklist` 간 데이터 흐름을 "수동 호출" 기반으로 서술했는데, 실제 구현 시 `/todo`에서 `/checklist`를 자동 트리거하는 방식을 채택한다면 A-3 단계 시나리오 전체를 재작성해야 함. 01_todo_spec.md 완성 전까지는 이 흐름이 확정적이지 않다는 점을 명시한다.
