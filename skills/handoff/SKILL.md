---
name: handoff
description: 다음 세션이 이어갈 인계서(HANDOFF.md) 하나를 갱신하고, 보여 주고, 확인 상태를 기록한다. 완료 기록은 /project-history, 백로그는 /todo.
trigger: /handoff
argument-hint: "[create|done]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Handoff (세션 인계 관리자)

Maintain one current `HANDOFF.md` at the project's designated location. Read it before editing,
then update the same file across sessions with the current state, remaining work, next steps,
and unresolved decisions. Keep completed details in their existing history source and link to it;
do not accumulate repeated completed-task sections in the handoff.

## Trigger
- "인계해줘", "세션 마무리", "오늘 작업 인계해줘"
- "다음 세션 위해 정리해줘", "내일 이어할 수 있게 정리해줘"
- "지금 어디까지 했지?" (새 세션 시작 시)
- "인계서 보여줘", "HANDOFF 내용 뭐야?"
- "인계 완료", "인계 받았어"
- `/handoff` 직접 호출

## Commands
- `/handoff` — 조회 (`HANDOFF.md` 있으면 표시, 없으면 "진행 중 없음")
- `/handoff create` — Update the current file; create it only if it is missing.
- `/handoff done` — Record receipt in the same file. Keep unresolved work and decisions open.

## 파일 위치

- 인계서: `{프로젝트 루트}/HANDOFF.md` ← 세션 인계의 기준 파일

Dates belong in the document, not new filenames. Keep the current file in place on receipt;
do not move it to an archive or create date/time-specific copies. Existing historical files
are outside this update unless the user separately requests their cleanup.

**프로젝트가 인계 위치를 따로 정했으면 그것을 따른다.** 에이전트나 작업마다 worktree를
나눈 프로젝트는 각 worktree의 `HANDOFF.md`가 그 작업의 인계서다. 이때 루트 인계서에는
어디를 보라는 한 줄만 남기고 내용을 옮겨 적지 않는다. 여러 세션이 한 파일을 동시에
고치면 서로의 글이 사라진다. 규칙은 프로젝트의 `AGENTS.md` 또는 `CLAUDE.md`에 있다.
All commands below use this project-designated handoff path.

`docs/history/index.md` 의 `## 🔄 진행 중` 섹션은 **14일 이상 장기 항목 링크** 전용이다. HANDOFF.md 내용을 반복하지 않는다.

## HANDOFF.md 양식

```markdown
# HANDOFF — {YYYY-MM-DD} 세션 인계서

> 갱신: YYYY-MM-DD HH:MM | 상태: 인계 대기 또는 확인 완료

## 🚨 다음 세션 진입 전 사용자 결정 사항
> 선택 섹션 — 사용자 결정·재시작·외부 조치가 다음 세션 진입 전 필요할 때만 추가. 없으면 본 섹션 자체 생략.

(결정 사항 + 선택지 A/B + 현재 기울기 + 사전 조치 절차)

## 마지막 상태 (어디까지 했나)
- 작업: [작업명]
- 진행률: [완료 단계/전체 단계]
- 마지막 편집 파일: `path/to/file` (L번호)

## 미완 작업 (지금 하다 멈춘 것)
- [ ] 항목 1 — 이유: 시간 부족 / 블로커 발생 / 결정 대기
- [ ] 항목 2

## 다음 세션 시작 지점
1. [동사로 시작하는 첫 행동, 예: "PowerShell `Get-ChildItem Env:` 으로 X 확인"]
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

6종 데이터 (마지막 상태 / 미완 / 다음 시작 / 미결 / 컨텍스트 / 관련 파일) 모두 필수. 🚨 결정 사항 섹션은 선택 (다음 세션 진입 전 사용자 결정·재시작·외부 조치 필요 시에만). 누락 시 인계 실패로 간주.

## How it works

### 조회 (`/handoff`)
1. 프로젝트 루트 `HANDOFF.md` 존재 확인
2. 있으면 그대로 출력
3. 없으면 "진행 중 인계서 없음. /handoff create 로 생성 가능" 안내

### Update (`/handoff create`)
1. **수집**:
   - Read the existing handoff first and preserve unresolved items that still matter.
   - `git status --short` + `git diff --stat` → 수정 파일 목록
   - Check unfinished work in the task status available in this session.
   - `docs/history/index.md` 진행 중 섹션 → 장기 항목 참조 (링크만 보고, HANDOFF 본문에 같은 내용을 옮겨 적지 않음)
   - 대화 맥락에서 미결 결정 추출
2. **Update**: Revise the same `HANDOFF.md`. Remove resolved items from current work,
   link to existing completion records, and retain a concise last-state summary. Create the
   file only when absent. A request to update the handoff authorizes these edits without
   another confirmation merely because the file already exists.
3. **검증**: 6종 데이터 누락 여부 확인 (🚨 결정 사항 섹션은 선택). 부족하면 사용자에게 보강 질문
4. **부수 효과**:
   - 14일 이상 지속될 가능성이 큰 항목은 `index.md` 진행 중 섹션 갱신 권고 (자동 X)
   - 백로그성 항목은 `/todo add` 권고

### Acknowledge (`/handoff done`)
1. Read the current handoff and record its receipt in that same file.
2. Receipt does not complete unresolved work, risks, or decisions. Preserve those items;
   when none remain, say so briefly and retain the file for its next update.
3. Move remaining work to a backlog only when the user asks. Link long-running items to
   existing project records without copying the handoff into another file.

## 다른 스킬과의 책임 경계

### vs /checklist
| 구분 | /handoff | /checklist |
|------|----------|------------|
| 시제 | 세션 종료 (단절 시점) | 세션 내 작업 단위 |
| 파일 | `HANDOFF.md` (루트) | `.checklist.md` (루트, 작업 단위) |
| 승인 흐름 | Within the user's handoff update request | 없음 (사용자가 요청할 때만 실행) |
| 확인 이후 | 같은 파일에서 현재 상태 갱신 | 사용자가 요청할 때 보관 |
| 수명 | 같은 파일을 계속 사용 | 단일 작업 |

**연계**: `/checklist`에서 끝내지 못한 항목을 다음 세션에 넘기려면 사용자가 `/handoff create`를 요청한다. 같은 세션에서 둘 다 호출 가능.

### vs /project-history
| 구분 | /handoff | /project-history |
|------|----------|------------------|
| 대상 | 미완 / 진행 중 | 완료된 것 |
| 지속성 | 같은 파일에서 현재 상태 갱신 | 영구 (추가만 하는 기록) |
| 작성 시점 | 세션 종료 직전 | 작업 완료 후 |
| 파일 | `HANDOFF.md` (루트) | `docs/history/{날짜}.md` |
| 용도 | 다음 세션 재개용 | 감사 추적, 회고 |

**연계**: `/handoff create`가 `/project-history update`를 자동으로 부르지 않는다. 같은 세션에서 둘 다 호출 가능.

### vs /todo
| 구분 | /handoff | /todo |
|------|----------|-------|
| 발생 시점 | 세션 종료 (단절 시점) | 상시 |
| 미완 항목 성격 | "지금 하다 멈춘 것" (시급, 맥락 풍부) | "언제 할지 모르는 것" (백로그) |
| 확인 이후 | 같은 파일에서 현재 상태 갱신 | `done` 또는 `archive` |
| 수명 | 같은 파일을 계속 사용 | 프로젝트 존속 기간 |

**Boundary**: Move remaining items to `/todo add` only when the user asks. Receiving a
handoff does not authorize moving or completing those items.

### vs index.md 진행 중 섹션
| 구분 | HANDOFF.md (`/handoff`) | index.md 진행 중 섹션 (`/project-history`) |
|------|--------------------------|---------------------------------------------|
| 범위 | 세션 인계 | 14일 이상 장기 항목 링크 |
| 수명 | 같은 파일을 계속 사용 | 7개 한계 / 14일 한계까지 |
| 역할 | 세션 인계의 기준 파일 | HANDOFF.md 내용을 반복하지 않는 링크 목록 |

## Rules
- **6종 데이터 모두 기록** — 마지막 상태 / 미완 / 다음 시작 / 미결 / 컨텍스트 / 관련 파일 (🚨 결정 사항 섹션은 선택, 본문 중 양식 블록 참조)
- **One current file** — Reuse the designated path; dates and receipt status update inside it.
- **Remaining work** — Move it to `.todo.md` only when the user asks; receipt alone leaves it open.
- **인계와 장기 항목 분리** — 세션 인계는 HANDOFF.md, 장기 항목은 index.md 진행 중 섹션에 링크만 둔다
- **다음 시작 지점은 동사로 시작** — "Read X 하기", "테스트 실행" 등 행동 명령형
- **Existing handoff** — Read and update it within the user's request. Preserve unresolved
  work and other sessions' edits; file existence alone does not require renewed approval.

## File Locations
- 인계서: `{프로젝트 루트}/HANDOFF.md`
