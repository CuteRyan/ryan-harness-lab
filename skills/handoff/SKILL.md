---
name: handoff
description: 세션 종료 시 다음 세션을 위한 인계서(HANDOFF.md) 생성·조회·소멸. 단일 세션 인계의 SSOT (장기 기록은 /project-history, 백로그는 /todo).
trigger: /handoff
argument-hint: "[create|done]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Handoff (세션 인계 관리자)

세션 종료 시 다음 세션이 즉시 이어갈 수 있게 **현재 상태·미완 작업·다음 시작 지점·미결 결정**을 프로젝트 루트 `HANDOFF.md` 에 기록한다. 다음 세션이 확인하면 `.backups/` 로 이동해 소멸한다.

비유: 교대 근무 인계 노트. 퇴근 시 다음 사람을 위해 쓰고, 출근한 사람이 읽으면 버린다.

## Trigger
- "인계해줘", "세션 마무리", "오늘 작업 인계해줘"
- "다음 세션 위해 정리해줘", "내일 이어할 수 있게 정리해줘"
- "지금 어디까지 했지?" (새 세션 시작 시)
- "인계서 보여줘", "HANDOFF 내용 뭐야?"
- "인계 완료", "인계 받았어"
- `/handoff` 직접 호출

## Commands
- `/handoff` — 조회 (`HANDOFF.md` 있으면 표시, 없으면 "진행 중 없음")
- `/handoff create` — 인계서 생성 (현재 세션 상태 기반)
- `/handoff done` — 인계서 소멸 (`.backups/HANDOFF.done.{YYYY-MM-DD}.md` 로 이동)

## 파일 위치 (Day 15 결정 2=C)

- 인계서: `{프로젝트 루트}/HANDOFF.md` ← **단일 세션 인계 SSOT**
- 완료 아카이브: `{프로젝트 루트}/.backups/HANDOFF.done.{YYYY-MM-DD}.md`

`docs/history/index.md` 의 `## 🔄 진행 중` 섹션은 **14일 이상 장기 항목 포인터** 전용 (HANDOFF.md 와 동일 정보 중복 금지).

## HANDOFF.md 양식

```markdown
# HANDOFF — {YYYY-MM-DD} 세션 인계서

> 생성: YYYY-MM-DD HH:MM | 소멸 조건: 다음 세션 확인 후 `/handoff done`

## 마지막 상태 (어디까지 했나)
- 작업: [작업명]
- 진행률: [완료 단계/전체 단계]
- 마지막 편집 파일: `path/to/file` (L번호)

## 미완 작업 (지금 하다 멈춘 것)
- [ ] 항목 1 — 이유: 시간 부족 / 블로커 발생 / 결정 대기
- [ ] 항목 2

## 다음 세션 시작 지점
1. [명확한 첫 번째 행동 — 동사 시작]
2. [두 번째 행동]

## 미결 결정 (다음 세션에 결정 필요)
- 결정 사항: ... | 선택지: A / B | 현재 기울기: A

## 컨텍스트 (배경 이해용)
- 이 작업을 하는 이유: [간단히]
- 주의 사항: [있으면]

## 관련 파일
- `path/to/main_file` — 핵심 편집 대상
- `path/to/ref_doc` — 참조 문서
```

5종 데이터 (마지막 상태 / 미완 / 다음 시작 / 미결 / 관련 파일) 모두 필수. 누락 시 인계 실패로 간주.

## How it works

### 조회 (`/handoff`)
1. 프로젝트 루트 `HANDOFF.md` 존재 확인
2. 있으면 그대로 출력
3. 없으면 "진행 중 인계서 없음. /handoff create 로 생성 가능" 안내

### 생성 (`/handoff create`)
1. **수집**:
   - `git status --short` + `git diff --stat` → 수정 파일 목록
   - `TaskList` → 미완 task 확인 (in_progress / pending)
   - `docs/history/index.md` 진행 중 섹션 → 장기 항목 참조
   - 대화 맥락에서 미결 결정 추출
2. **합성**: 위 데이터를 양식대로 채워 `HANDOFF.md` 작성
3. **검증**: 5종 데이터 누락 여부 확인. 부족하면 사용자에게 보강 질문
4. **부수 효과**:
   - 14일 이상 지속될 가능성이 큰 항목은 `index.md` 진행 중 섹션 갱신 권고 (자동 X)
   - 백로그성 항목은 `/todo add` 권고

### 소멸 (`/handoff done`)
1. 다음 세션이 인계서 확인 후 호출
2. `HANDOFF.md` → `.backups/HANDOFF.done.{YYYY-MM-DD}.md` 로 이동 (삭제 금지 — 감사 추적)
3. 미완 항목 중 지속 필요한 것 → 사용자에게 `.todo.md` 이동 여부 질문
4. 14일 이상 지속될 항목 → `index.md` 진행 중 포인터 섹션 갱신 권고

## 다른 스킬과의 책임 경계

### vs /project-history (강한 분리)
| 구분 | /handoff | /project-history |
|------|----------|------------------|
| 대상 | 미완 / 진행 중 | 완료된 것 |
| 지속성 | 임시 (다음 세션 확인 시 소멸) | 영구 (append-only 기록) |
| 작성 시점 | 세션 종료 직전 | 작업 완료 후 |
| 파일 | `HANDOFF.md` (루트) | `docs/history/{날짜}.md` |
| 용도 | 다음 세션 재개용 | 감사 추적, 레트로스펙트 |

**연계 정책**: `/handoff create` 시 `/project-history update` 자동 연동 없음 (사용자 제어 유지). 같은 세션에서 둘 다 호출 가능.

### vs /todo
| 구분 | /handoff | /todo |
|------|----------|-------|
| 발생 시점 | 세션 종료 (단절 시점) | 상시 |
| 미완 항목 성격 | "지금 하다 멈춘 것" (시급, 맥락 풍부) | "언제 할지 모르는 것" (백로그) |
| 소멸 조건 | 다음 세션 확인 후 즉시 | `done` 또는 `archive` |
| 수명 | 1~2 세션 | 프로젝트 존속 기간 |

**경계 규칙**: `/handoff done` 시 미완 항목을 `/todo add` 로 옮길 수 있다. 자동 이동 금지 — 인계 받은 세션이 우선순위 재판단.

### vs index.md 진행 중 섹션 (Day 15 결정 2=C)
| 구분 | HANDOFF.md (`/handoff`) | index.md 진행 중 섹션 (`/project-history`) |
|------|--------------------------|---------------------------------------------|
| 범위 | 단일 세션 인계 | 14일 이상 장기 항목 포인터 |
| 수명 | 1~2 세션 | 7개 한계 / 14일 한계까지 |
| SSOT | **단일 세션 인계의 SSOT** | 장기 항목 포인터 (HANDOFF.md 동일 정보 중복 금지) |

## Rules
- **5종 데이터 누락 금지** — 마지막 상태 / 미완 / 다음 시작 / 미결 / 관련 파일 모두 필수
- **소멸 시 삭제 금지** — `.backups/` 로 이동만 (감사 추적)
- **자동 이동 금지** — 미완 항목을 `.todo.md` 로 이동할지는 인계 받은 세션이 결정
- **SSOT 분리 (결정 2=C)** — 단일 세션 인계는 HANDOFF.md, 장기 항목은 index.md 진행 중 섹션 (포인터). 동일 정보 중복 금지
- **다음 시작 지점은 동사로 시작** — "Read X 하기", "Phase 2 진입" 등 행동 명령형
- **`HANDOFF.md` 가 이미 있으면** — 덮어쓰기 전에 사용자에게 확인 (이전 인계 미소멸 상태 = 누적 시그널)

## File Locations
- 인계서: `{프로젝트 루트}/HANDOFF.md`
- 완료 아카이브: `{프로젝트 루트}/.backups/HANDOFF.done.{YYYY-MM-DD}.md`
