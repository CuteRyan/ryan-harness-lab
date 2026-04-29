---
title: /checklist 스킬 Delta 분석 — /todo 신설에 따른 책임 변경
type: research
status: draft
created: 2026-04-29
updated: 2026-04-29
author: integration-auditor
---

# /checklist 스킬 Delta 분석

## 1. 현재 /checklist의 역할 (라인 실측)

**파일**: `Harness-engineering/skills/checklist/SKILL.md` (174줄)

### 1-1. 핵심 역할 선언 (L10–L13)
```
작업 전 체크리스트를 만들고, 완료 후 검증까지 하나의 흐름으로 관리하는 스킬.
코드 수정이든 문서 수정이든 하나의 `.checklist.md`로 통합 관리한다.
```

### 1-2. 트리거 범위 (L16–L20)
```
- 사용자가 작업을 지시할 때 (코드 수정, 문서 작성, 리팩터링 등)
- "체크리스트 만들어", "작업 시작", "이거 해줘" 등
- `/checklist` 직접 호출
- `/checklist 로그인 버그 수정` 처럼 작업명과 함께 호출
```
> **관찰**: 트리거 목록에 "백로그 등록", "나중에 할 일 추가" 같은 명시적 백로그 관리 문구가 없다.
> 현재 /checklist는 **현재 세션의 작업**에 집중하며, 미래 작업을 별도로 추적하는 구조는 없다.

### 1-3. 현재 /checklist가 **암묵적으로 담당하는** 백로그 관련 동작
- Phase 2(L34–L35): "예상 외 이슈 발생 시 체크리스트에 항목 추가" → 세션 내 발견 사항을 .checklist.md에 쌓음
- Phase 6(L68): "docs/history/{YYYY-MM-DD}.md 업데이트 + docs/history/index.md 갱신" → 완료 후 히스토리로 이동
- Rules(L146–L162): "하나의 체크리스트 — 코드든 문서든 .checklist.md 하나로 관리"

**문제**: 세션 중 발견된 미완 항목이 .checklist.md에 쌓이면, Phase 6에서 `.backups/`로 이동되어 **사라진다**. 다음 세션 복원을 위한 별도 저장소가 현재 구조에 없다.

---

## 2. /todo 신설 후 책임 변경

### 2-1. /checklist에서 제거되는 책임

| 기존 암묵적 책임 | 변경 후 담당 | 근거 강도 |
|---|---|---|
| 세션 내 발견된 미완 항목 추적 | /todo 로 이전 | 중 (설계 원리 기반) |
| 다음 세션에 이어야 할 작업 목록 관리 | /todo 로 이전 | 중 |
| "나중에 할 일"의 백로그 버퍼 역할 | /todo 로 이전 | 중 |

### 2-2. /checklist에 유지되는 책임

| 책임 | 유지 이유 | 근거 강도 |
|---|---|---|
| 현재 세션 작업의 체크리스트 생성·검증 | 핵심 정체성 | 강 (L10–L13 인용) |
| Phase 1~6 워크플로 (생성→승인→구현→검증→보고→정리) | 완결된 구조 | 강 (L23–L67) |
| tiny edit 예외 판단 | 변경 없음 | 강 (L151–L162) |
| 완료 체크리스트를 .backups/로 이동 | 변경 없음 | 강 (L65–L67) |

### 2-3. 경계 정의 (중요)

```
/checklist = "지금 이 작업을 어떻게 할 것인가" (현재 세션 범위)
/todo      = "앞으로 무엇을 해야 하는가" (세션 횡단 백로그)
```

경계 모호 케이스:
- Phase 2에서 추가된 항목이 "이번 세션에 완료 가능한가?" → 가능하면 .checklist.md에 유지, 불가능하면 /todo로 이동
- Phase 6 정리 시 미완 항목 발견 → /todo add 호출하여 이전 (수동 or Phase 6 자동화)

---

## 3. 변경 대상 라인

### 3-1. SKILL.md 수정 필요 라인

| 위치 | 현재 내용 | 변경 제안 | 이유 |
|---|---|---|---|
| L68 (Phase 6) | "docs/history/{YYYY-MM-DD}.md 업데이트 + docs/history/index.md 갱신" | 앞에 "미완 항목은 /todo add로 이전 후" 추가 | 완료 체크리스트 정리 시 미완 항목 명시적 이전 |
| L35 (Phase 2) | "예상 외 이슈 발생 시 체크리스트에 항목 추가" | "(이번 세션 완료 가능 항목만 추가; 불가능하면 /todo add)" 주석 추가 | 경계 명시 |
| Rules 섹션 | 백로그 관련 규칙 없음 | "/todo와 책임 분리: 세션 완료 가능 항목은 .checklist.md, 세션 횡단 항목은 /todo" 추가 | 경계 명문화 |

### 3-2. 글로벌 CLAUDE.md 프리플라이트 영향 분석

**현재 내용** (`C:/Users/rlgns/.claude/CLAUDE.md` L2):
```
- **코드/문서 수정** → `/checklist` 스킬로 체크리스트 생성 후 진행 (tiny edit 제외)
```

**영향 없음** — 이 문장은 "작업 진입 시 /checklist 사용"을 강제하는 것이며,
/todo는 별도 독립 동작(백로그 관리)으로 프리플라이트 흐름을 건드리지 않는다.

**추가 검토 필요**: 프리플라이트에 "세션 시작 시 /todo 확인 권장" 문구 추가 여부
- 추가 시: 세션마다 백로그 확인 → 작업 선택 → /checklist 호출의 명확한 흐름 형성
- 미추가 시: /todo는 명시적 호출 시에만 동작 (현 패턴 유지)
- **결론**: critic 단계에서 판단 필요. 강제 추가 시 현 프리플라이트 단순성 훼손 위험.

---

## 4. dev-checklist.md (SSOT) 영향

**파일**: `C:/Users/rlgns/.claude/rules/dev-checklist.md` (13줄)

현재 내용은 /checklist 스킬의 존재와 SSOT 위치만 명시한다 (L1–L13).
/todo 신설로 인한 직접 변경 사항 없음.

**단, 동기화 주의**: `rules/dev-checklist.md`가 "스테이징/운영 분리" SSOT를 담당하므로,
/checklist SKILL.md가 수정될 때 반드시 `~/.claude/skills/checklist/SKILL.md`로 동기화 필요.
(스테이징 = `Harness-engineering/skills/checklist/SKILL.md`, 운영 = `~/.claude/skills/checklist/SKILL.md`)

---

## 5게이트

### (1) 라인 실측
- SKILL.md 174줄 직접 Read 완료
- L2, L10–L13, L16–L20, L34–L35, L65–L68, L146–L162 인용 검증
- CLAUDE.md L2 프리플라이트 직접 확인

### (2) 반박/유보
- **약점**: 이 delta 분석은 /todo의 SKILL.md가 아직 작성 중인 시점(task #1 in_progress)에 작성되었다. /todo의 정확한 trigger 조건·데이터 구조가 확정되지 않아 "세션 완료 가능 항목" 경계 판단이 추측에 기반한다. skill-architect의 01_todo_spec.md 완성 후 재검증 권장.

### (3) 근거 강도
- /checklist 현재 역할: **강** (L10–L68 직접 인용)
- /todo 신설 후 경계: **중** (설계 원리 기반, /todo SKILL.md 미확정)
- 글로벌 CLAUDE.md 영향: **강** (L2 직접 확인, 변경 불필요 판단)
- dev-checklist.md 영향: **강** (L1–L13 직접 확인, 변경 불필요 판단)

### (4) 자기 비판
이번 delta 분석에서 놓쳤을 가능성: /checklist Phase 6의 `.backups/` 이동 로직과 /todo의 자동 연동 여부. 현재는 "수동 or Phase 6 자동화"로 열어뒀으나, 자동화 없으면 미완 항목 손실이 여전히 발생할 수 있다. 구현 단계에서 반드시 Phase 6 자동 /todo 연동 여부를 결정해야 한다.
