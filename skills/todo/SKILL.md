---
name: todo
description: 미래에 할 일 백로그 관리. 프로젝트 루트 .todo.md 에 항목 추가·완료·아카이브. 세션 횡단 백로그 전용 (지금 작업은 /checklist, 세션 인계는 /handoff).
trigger: /todo
argument-hint: "[add|done|archive] [내용 또는 번호]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Todo (미래 백로그 관리자)

세션 횡단 백로그 — "언제 할지 모르지만 잊으면 안 되는 것" 을 프로젝트 루트 `.todo.md` 에 누적 관리한다.

비유: `.checklist.md` 가 오늘의 작업 지시서라면, `.todo.md` 는 냉장고 화이트보드 메모.

## Trigger
- "투두 추가", "할 일 추가", "이거 나중에 해줘"
- "투두 보여줘", "할 일 목록", "현재 투두 뭐 있어?"
- "이거 완료", "투두에서 X 지워줘"
- "투두 정리해줘" (오래된 항목 아카이브)
- `/todo` 직접 호출

## Commands
- `/todo` — 현재 백로그 조회 (`.todo.md` 표시)
- `/todo add [내용]` — 항목 추가
- `/todo done [번호 또는 키워드]` — 완료 처리 (`[ ]` → `[x]`)
- `/todo archive` — 완료 항목 10개 초과 시 `.backups/` 로 정리

## 파일 위치 (결정 4 = 프로젝트별만)

- 백로그: `{프로젝트 루트}/.todo.md`
- 완료 아카이브: `{프로젝트 루트}/.backups/.todo.done.{YYYY-MM-DD}.md`
- **글로벌 `~/.claude/.todo.md` 는 만들지 않는다** (Day 15 결정 4)

## .todo.md 양식

```markdown
# .todo.md

<!-- created: YYYY-MM-DD | project: {프로젝트명} -->

## 백로그
- [ ] #001 항목 내용 (added: 2026-04-29, priority: high)
- [ ] #002 항목 내용 (added: 2026-04-29, priority: normal)

## 완료 (최근 10개)
- [x] #000 이전 항목 (done: 2026-04-28)
```

번호(`#NNN`)는 단조 증가. 완료 후에도 보존 (감사 추적).

## How it works

### 조회 (`/todo`)
1. `.todo.md` 가 없으면 "백로그 비어있음" 표시
2. 있으면 백로그 + 완료 섹션을 그대로 출력

### 추가 (`/todo add [내용]`)
1. `.todo.md` 가 없으면 양식대로 신규 생성 (양식 참조)
2. 마지막 번호 + 1 로 항목 추가 (백로그 섹션 끝에 append)
3. `(added: YYYY-MM-DD)` 메타데이터 자동 부착
4. priority 는 사용자가 지정하지 않으면 `normal`

### 완료 (`/todo done [번호 또는 키워드]`)
1. 번호(`#001`) 또는 키워드로 항목 매칭
2. `[ ]` → `[x]` 변경 + `(done: YYYY-MM-DD)` 추가
3. 항목을 백로그 → "완료 (최근 10개)" 섹션으로 이동
4. 완료 항목 11개 이상이면 자동 archive 권고

### 아카이브 (`/todo archive`)
1. "완료 (최근 10개)" 섹션에서 가장 오래된 항목부터 cut
2. `.backups/.todo.done.{YYYY-MM-DD}.md` 에 paste (없으면 생성)
3. `.todo.md` 의 완료 섹션에 최근 10개만 남김

## 다른 스킬과의 책임 경계

### vs /checklist (Day 15 결정 1=A: 자동 트리거 없음)
| 구분 | /todo | /checklist |
|------|-------|------------|
| 시제 | 미래 ("나중에 할 것") | 현재 ("지금 하는 것") |
| 파일 | `.todo.md` (상시 유지) | `.checklist.md` (작업 단위 생성·소멸) |
| 승인 흐름 | 없음 (추가/완료 즉시) | 필수 (`approved: false` → 주인님 승인) |
| 완료 시 | 목록에서 완료 마킹 후 보존 | `.backups/` 로 이동 |
| 수명 | 프로젝트 존속 기간 내내 | 단일 작업 사이클 |

**연계 정책**: `/todo` 의 항목을 본 세션에서 시작하면 사용자가 명시적으로 `/checklist` 호출. 자동 동기화 없음 (결정 1=A).

### vs /handoff
| 구분 | /todo | /handoff |
|------|-------|----------|
| 발생 시점 | 상시 (언제든 추가) | 세션 종료 시점에만 |
| 미완 항목 성격 | "언제 할지 모르는 것" | "지금 하다 멈춘 것" (시급, 맥락 풍부) |
| 소멸 조건 | `done` 또는 `archive` | 다음 세션 확인 후 즉시 |

**연계 정책**: `/handoff done` 시 다음 세션이 미완 항목 중 지속 필요한 것을 `/todo add` 로 옮길 수 있다. 자동 이동 금지 (인계 받은 세션이 우선순위 재판단).

### vs /project-history
- `/todo` 는 **미래** 백로그, `/project-history` 는 **과거** 완료 기록
- `/todo done` 시 자동 히스토리 기록 X (사용자가 명시 요청 시에만)

## TaskCreate 호출 정책

기본: `.todo.md` 만 수정. TaskCreate 별도 호출 안 함.

이유: TaskCreate 는 팀/에이전트 작업 조율용. 개인 백로그와 혼용하면 TaskList 가 오염된다. 사용자가 "팀 작업으로도 등록" 명시할 때만 TaskCreate 병행.

## Rules
- **결정 4 준수** — 글로벌 `~/.claude/.todo.md` 만들지 않음. 프로젝트별 루트 `.todo.md` 만 운영
- **결정 1 준수** — `/checklist` 자동 트리거 없음, 사용자 명시 호출만
- **번호 보존** — 완료 후에도 `#NNN` 유지 (감사 추적, 재사용 금지)
- **추가 시 승인 불필요** — `.checklist.md` 와 달리 즉시 반영
- **`.gitignore` 권장** — 개인 백로그이므로 (팀 공유 시 예외)

## File Locations
- 백로그: `{프로젝트 루트}/.todo.md`
- 완료 아카이브: `{프로젝트 루트}/.backups/.todo.done.{YYYY-MM-DD}.md`
