---
title: /project-history 스킬 Delta 분석 — /handoff 신설에 따른 책임 변경
type: research
status: draft
created: 2026-04-29
updated: 2026-04-29
author: integration-auditor
---

# /project-history 스킬 Delta 분석

## 1. 현재 /project-history의 역할 (라인 실측)

**파일**: `Harness-engineering/skills/project-history/SKILL.md` (114줄)

### 1-1. 핵심 역할 선언 (L10–L13)
```
프로젝트 개발 히스토리를 폴더 기반 인덱싱으로 관리하는 글로벌 스킬.
```

### 1-2. Commands (L19–L23)
```
- /project-history            — 인덱스 기반 히스토리 요약 표시
- /project-history update     — 현재 세션 작업을 히스토리에 추가
- /project-history migrate    — 기존 단일 HISTORY.md → 폴더 구조로 마이그레이션
- /project-history search <키워드> — 히스토리 전체에서 키워드 검색
```

### 1-3. 진행 중 섹션 연결 (현재 SKILL.md에서의 처리)
- L107: "미완료 항목은 해당 일자 파일의 `## 다음 작업`에 유지"
- **관찰**: 진행 중 섹션 (`index.md`의 `## 🔄 진행 중`) 관리를 명시적으로 SKILL.md에서 다루지 않는다.
  → 현재는 **index.md에서 수동으로 관리**되고 있으며, project-history 스킬이 이 섹션을 자동 업데이트하는 기능이 없다.

### 1-4. index.md 진행 중 섹션 룰 (실측)
**파일**: `Harness-engineering/docs/history/index.md` L3–L9
```
> **양식**: `[시작일] 상태 | 작업명 | 다음: (동사 시작) | 미결: 없음/내용`
> **선택 메타**: 대형/장기 작업에만 `(브랜치: x, 커밋: hash)` 추가
> **한계**: 7개 초과 또는 14일 초과 시 즉시 정리 (완료 → 일자별 파일로 cut & paste, 폐기 → 삭제)
> **SSOT**: 이 섹션이 진행 중 정보의 유일한 원본. 다른 파일에 동일 정보 두지 않음.
```

현재 진행 중 항목 5개 (L10–L14):
1. `[2026-04-17]` 진행 중 — 세션 인계 + 폴더 마이그레이션
2. `[2026-04-18]` 부분 종결 — venv 규칙 개정 + VS Code Sync + /feedback 개정
3. `[2026-04-22]` 종결 — /feedback 구조 승격
4. `[2026-04-23]` 부분 종결 — Day 10 이월 + Gemini rubber-stamp
5. `[2026-04-28]` 종결 — /feedback B 방식 완료

**관찰**: 5개 중 3개("종결", "부분 종결")가 이미 완료되었으나 index.md에 남아 있다. 이는 수동 정리 부담이 높아 방치된 것이다. /handoff 신설로 이 구조적 문제를 해결할 기회가 있다.

---

## 2. /handoff 신설 후 책임 변경

### 2-1. /project-history에서 이전되는 책임

| 기존 동작 | 변경 후 담당 | 근거 강도 |
|---|---|---|
| 세션 인계 정보 생성 (다음 세션이 알아야 할 것) | /handoff 로 이전 | 중 (설계 원리) |
| 진행 중 섹션 수동 업데이트 | /handoff 가 자동화 | 중 |
| "다음 작업" 섹션 관리 | /handoff + /todo 분담 | 중 |

### 2-2. /project-history에 유지되는 책임

| 책임 | 유지 이유 | 근거 강도 |
|---|---|---|
| 완료된 세션 히스토리 기록 (`update`) | 핵심 정체성 | 강 (L69–L75 인용) |
| 인덱스 조회 (조회 명령) | 변경 없음 | 강 (L63–L66) |
| 마이그레이션 (`migrate`) | 독립 기능 | 강 (L76–L82) |
| 히스토리 검색 (`search`) | 독립 기능 | 강 (L84–L87) |

### 2-3. 경계 정의

```
/project-history = "과거에 무엇을 했는가" (완료된 작업의 기록·조회)
/handoff         = "다음 세션에 무엇을 전달하는가" (진행 중·미완 상태 이전)
```

경계 모호 케이스:
- `/project-history update` 호출 후 미완 항목이 있을 때 → /handoff도 자동 호출할지, 분리 유지할지
- "세션 종료 시 한 번에 /project-history update + /handoff" 패턴 vs "분리 호출"

---

## 3. docs/history/index.md 진행 중 섹션 처리 방안

### 옵션 A: 제거 (진행 중 섹션 폐지)

**설명**: index.md에서 `## 🔄 진행 중` 섹션을 완전히 삭제하고, /handoff가 별도 `HANDOFF.md` 파일로 인계 정보를 관리한다.

**Trade-off**:
- 장점: index.md가 순수 히스토리 인덱스로 단순화됨. 수동 정리 부담 완전 제거.
- 단점: 기존 `## 🔄 진행 중` 양식(L3–L9)의 SSOT 규칙이 사라지고 HANDOFF.md로 이전되어야 함. index.md와 HANDOFF.md 간 동기화 문제 발생 가능. 현재 5개 항목의 마이그레이션 필요.
- 위험: /handoff 미호출 시 인계 정보가 완전히 소실됨 (현재는 index.md에 fallback이 있음).

### 옵션 B: 자동 동기화 (진행 중 섹션 유지 + /handoff가 자동 업데이트)

**설명**: index.md의 `## 🔄 진행 중` 섹션을 유지하되, /handoff 호출 시 이 섹션을 자동으로 업데이트한다.

**Trade-off**:
- 장점: 기존 SSOT 구조 보존. fallback 경로 유지. 기존 사용 패턴 최대 호환.
- 단점: /handoff와 index.md 간 양방향 의존성 생성. "HANDOFF.md가 SSOT인가, index.md가 SSOT인가" 혼란 가능. 구현 복잡도 상승.
- 위험: 두 파일 중 하나가 stale 되었을 때 어느 쪽이 정답인지 판단이 어려움.

### 옵션 C: 최소 유지 (진행 중 섹션 경량화)

**설명**: index.md의 `## 🔄 진행 중` 섹션을 유지하되 역할을 최소화한다. /handoff는 별도 HANDOFF.md를 주 저장소로 쓰고, index.md 진행 중 섹션은 "HANDOFF.md 포인터만" 남긴다.

예시:
```
## 🔄 진행 중
> 상세: HANDOFF.md 참조 (최신 인계 정보)
- 현재 활성 세션: [2026-04-29] (HANDOFF.md에서 읽기)
```

**Trade-off**:
- 장점: index.md 변경 최소화. HANDOFF.md가 SSOT로 명확. index.md 폴백 포인터 역할 유지.
- 단점: "진행 중 섹션 7개 한계" 등 기존 룰이 유명무실화됨. 두 파일 모두 읽어야 하는 번거로움.
- 위험: 포인터만 남으면 index.md의 독립적 유용성 감소.

### 권고 (critic 단계에서 최종 판단)

세 옵션 모두 trade-off가 있으므로 **critic이 최종 결정**. 단, 통합-auditor 관점에서:
- 구조적 단순성 우선이면 → **옵션 A**
- 기존 호환성 우선이면 → **옵션 B**
- 점진적 전환 선호이면 → **옵션 C**

---

## 4. /project-history SKILL.md 변경 대상 라인

| 위치 | 현재 내용 | 변경 제안 | 이유 |
|---|---|---|---|
| L107 (Rules) | "미완료 항목은 해당 일자 파일의 `## 다음 작업`에 유지" | "미완료 항목은 /handoff로 이전 (세션 인계); 히스토리 기록만 해당 일자 파일에" 추가 | 책임 분리 명시 |
| Commands 섹션 | 인계 관련 명령 없음 | "세션 인계는 /handoff 스킬 참조" 크로스레퍼런스 추가 | 사용자 혼란 방지 |
| L104 (폴더 구조 우선) | 변경 없음 | 유지 | 독립 기능 |

---

## 5게이트

### (1) 라인 실측
- project-history/SKILL.md 114줄 직접 Read 완료
- L10–L13, L19–L23, L63–L87, L101–L107 인용 검증
- index.md L3–L14 진행 중 섹션 직접 확인 (현재 5개 항목 실측)

### (2) 반박/유보
- **약점**: 옵션 A/B/C 분석이 /handoff SKILL.md가 아직 미작성인 상태에서 작성되었다. HANDOFF.md의 정확한 파일 구조, 자동 업데이트 메커니즘이 확정되지 않아 "자동 동기화" 가능성 판단이 추측 기반이다. skill-architect의 02_handoff_spec.md 완성 후 재검증 권장.

### (3) 근거 강도
- /project-history 현재 역할: **강** (L10–L107 직접 인용)
- 진행 중 섹션 현황: **강** (index.md L3–L14 직접 확인)
- 옵션별 trade-off: **중** (설계 원리 기반, /handoff 미확정)
- 책임 이전 판단: **중** (설계 원리, 구현 전)

### (4) 자기 비판
이번 delta 분석에서 놓쳤을 가능성: index.md의 `## 🔄 진행 중` 섹션이 "14일 초과 시 정리" 규칙(L7)을 가지고 있는데, 현재 5개 항목 중 일부가 이 규칙을 위반하고 있음에도 그 원인(정리 도구 부재)을 분석하는 데 그쳤다. /handoff가 이 자동 정리를 담당해야 하는지 명시적으로 설계에 포함시켜야 한다.
