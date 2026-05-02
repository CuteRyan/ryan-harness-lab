# 4 스킬 메타 리뷰 입력 자료

> 작성일: 2026-05-02 | 용도: `/feedback` 외부 검수 입력
> 대상: `/checklist` + `/todo` + `/handoff` + `/project-history` 4 스킬 통합 평가
> 기간: Day 16 (2026-04-30) 신설/수정 후 ~3일 dogfood

---

## 검수 요청 사항 (3 CLI 모두 이 관점으로 검토할 것)

본 자료는 일반 코드가 아닌 **워크플로 스킬(LLM agent 행동 규약)** 의 메타 리뷰입니다.
**보안/성능 관점은 무관합니다**. 다음 3 관점으로 평가해 주세요:

### A. 본체 품질
- 각 SKILL.md 자체의 명확성·일관성·누락·중복
- 강제력 (rules/금지/의무) 이 실효적인가
- 양식 (template) 이 실제 운영을 따라가는가 (drift 여부)

### B. 4 스킬 간 책임 분리 (SSOT)
- 정보 중복 없이 잘 분리됐는가
- 책임 경계 공백 (어느 스킬도 다루지 않는 영역) 없는가
- 한쪽 스킬에서만 명시하고 반대쪽에서 모르는 비대칭 없는가

### C. dogfood 결과 (실사용 흔적 기반)
- 양식 ↔ 실사용 drift
- 사용자가 우회/생략하는 패턴
- 누적/한계 도달 시 핸들링 부재

### 출력 형식 (모든 CLI 공통)
- 각 지적은 `[치명]·[높음]·[중간]·[낮음]` 중요도 태그를 **줄 시작**에 붙일 것 (불릿 `-` 다음 OK)
- 각 지적은 본 입력 자료의 **라인 번호 인용** 필수 (환각 방지)
- 추상적 권고가 아닌 **구체 수정 제안** 1건 이상
- "잘 됐다", "탁월하다" 등 sycophancy 단어 금지 — 비판 모드 강제

---

## 평가 관점별 메인 Claude 1차 진단 (객관 검증 대상)

### A 관점 1차 진단 — 양식 drift 2건 검출

**1. `/todo` SKILL.md 양식 ↔ 실사용 drift**
- SKILL.md 양식 (L37~L48): `priority` 만 명시, `due`/`blocked_by` 없음
- 실제 `.todo.md` 사용 (Harness-engineering 프로젝트 .todo.md):
  - #008: `(added: 2026-05-01, priority: normal, due: 2026-05-08, source: ...)` ← `due` 사용
  - #014: `(added: 2026-05-02, priority: normal, blocked_by: #015, source: ...)` ← `blocked_by` 사용
  - #001·#006·#007: `priority: low` ← 양식에 `low` 미명시 (양식은 `high`/`normal` 만 보임)
- → SKILL.md 가 실사용을 못 따라감

**2. `/handoff` SKILL.md 양식 ↔ 실사용 drift**
- SKILL.md 양식 (L38~L66): 5종 데이터 (마지막상태/미완/다음시작/미결/관련파일/컨텍스트) 만 명시
- 실제 HANDOFF.md (2026-05-02 turn 3):
  - `## 🚨 다음 세션 진입 전 사용자 결정 사항 (CRITICAL)` 섹션 존재 ← 양식 누락
  - `## 다음 세션 시작 지점` 안에 `Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)` 부절 ← 양식 누락
  - 커밋 8391c9e 에서 추가됐는데 SKILL.md 미반영
- → SKILL.md 가 운영 관행을 추월당함

### B 관점 1차 진단 — 책임 경계 공백 3건

| | /checklist | /todo | /handoff | /project-history |
|-|-----------|-------|----------|------------------|
| /checklist | — | Rules | Rules | **(없음)** |
| /todo | 표 | — | 표 | 1줄 |
| /handoff | **(없음)** | 표 | — | 표 |
| /project-history | **(없음)** | Rules | Rules | — |

**공백 1**: `/checklist` ↔ `/project-history` 양방향 명시 없음.
- /checklist Phase 6: "필요 시 docs/history/ 업데이트" 만 있음 — 누가 판단? 트리거 모호.
- /project-history 도 /checklist 종결 후 호출 권고 없음.

**공백 2**: `/handoff` ↔ `/checklist` 비대칭.
- /checklist Rules: `/handoff 와 책임 분리 — 세션 종료 시 미완 항목 인계는 /handoff 사용` 명시.
- /handoff SKILL.md 에는 `/checklist` 와의 관계 명시 없음 — 한쪽만 SSOT 인식.

**공백 3**: 4 스킬 통합 정보 흐름 다이어그램/메타 문서 없음.

### C 관점 1차 진단 — dogfood 실측 데이터

**HANDOFF 실측**:
- 소멸 8회 (`.backups/HANDOFF.done.*` 8건) — 매 세션 사용 ✅
- **자동 백업 4건** (`.backups/HANDOFF.md.*.bak`) — doc-protection 훅 발동
  - 2026-05-02 14:05:28, 14:05:36 (8초 차이) → 같은 세션에서 Edit 2회
  - 2026-05-01 23:22:05, 23:25:14 (3분 차이) → 같은 세션에서 Edit 2회
- 의미: **HANDOFF 1회 작성으로 안 끝남** = 양식이 운영 따라가지 못한 신호

**.todo.md 실측**:
- 백로그 활성 9건 (#001·#002·#003·#006·#007·#008·#009·#012·#014·#015 중 #010·#011·#013 완료 제외)
- priority 분포: high 1, normal 6, low 2
- 양식에 없는 필드 사용: due (1건), blocked_by (1건)

**history 실측**:
- 17 일자 파일 (Day 0~18, 일부 누락 = 작업 안 한 날 = 정상)
- index.md 65줄 / 200 한계 (안전)
- 진행 중 섹션 비어있음 (Day 16 정리 후) — 실효성 불분명

**`/checklist` 실측**:
- `.backups/.checklist.md.완료_*` 파일 보존 (HANDOFF 언급 기준)
- **본 메타 평가 작업 자체에서 `/checklist` 미호출** — 분석/리뷰는 의무 아니라고 판단했으나 결과가 SKILL.md 수정으로 이어지면 그때부터 의무 발생 = 경계 모호

---

## SKILL.md 본체 4종 (검수 대상 원본)

---

### [SKILL 1/4] `/checklist` SKILL.md

```markdown
---
name: checklist
description: 작업 전 체크리스트 생성 → 구현 → 검증 → 보고까지 통합 워크플로. 코드/문서 구분 자동 감지.
trigger: /checklist
argument-hint: "[작업 설명]"
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Checklist (통합 작업 체크리스트)

작업 전 체크리스트를 만들고, 완료 후 검증까지 하나의 흐름으로 관리하는 스킬.
코드 수정이든 문서 수정이든 하나의 `.checklist.md`로 통합 관리한다.

## Trigger
- 사용자가 작업을 지시할 때 (코드 수정, 문서 작성, 리팩터링 등)
- "체크리스트 만들어", "작업 시작", "이거 해줘" 등
- `/checklist` 직접 호출
- `/checklist 로그인 버그 수정` 처럼 작업명과 함께 호출

## 워크플로

### Phase 1: 체크리스트 생성 + 승인 대기
1. 작업 내용 분석 → mode 자동 감지: `code | doc | design | mixed`
2. 작업 전 `git status --short` 실행 → 결과를 체크리스트의 "작업 전 기준선" 섹션에 그대로 기록
3. 프로젝트 루트에 `.checklist.md` 생성
   - 기본값: `approved: false`, `status: draft`
   - mode별 필수 섹션을 모두 포함
   - "실패 시 복구 방법(롤백 계획)" 섹션 필수 작성
4. 체크리스트 작성 후 구현 파일을 절대 수정하지 않는다. 주인님께 승인 요청만 하고 턴을 종료한다.
5. 다음 사용자 메시지에서 명시적 승인이 있을 때만, 다음 턴에서 approved: true + status: approved로 변경하고 Phase 2로 진입한다.

### Phase 2: 구현
- 체크리스트 항목을 하나씩 수행하며 [x] 체크
- 예상 외 이슈 발생 시 체크리스트에 항목 추가 (치명/높음 항목 변경은 재승인 필요)
- 이번 세션 완료 가능 항목만 추가; 세션 횡단 백로그는 /todo add 로 이전 (책임 분리)

### Phase 3: 검증 (구현 대조 + 증거 보존)
1. 항목별 1:1 대조 — 체크리스트 각 항목에 대해 실제 파일을 Read하여 반영 확인
2. Read 호출 결과를 응답에 증거로 남긴다 — "확인했다"는 선언만으로는 부족하다.
3. 누락 탐지 — 체크리스트에 없지만 추가로 변경한 파일이 있으면 소급 추가
4. git 차이 대조 — git status --short / git diff --stat 실행 → Phase 1 기준선과 차이가 체크리스트 "수정 대상 파일"과 1:1 일치하는지 확인
5. mode별 검증:
   - code: ruff/lint 통과 + 관련 테스트 실행 + 사이드 이펙트 확인
   - doc: 연관 문서 교차 검증 (용어/개념 일치, 링크 정상, 스키마/필드명 실코드와 일치)
   - design: 입출력 계약 명세 + 실패 케이스 처리 + 의존 관계 명시 확인
   - mixed: 위 모든 항목 적용

### Phase 4: 더블 체크
1. 체크리스트 자체 검증 — 빠진 항목 없는가?
2. 실행 검증 — 체크만 하고 실제 반영 안 된 것은 없는가?
3. 일관성 검증 — 수정 내용이 다른 코드/문서와 여전히 일치하는가?

### Phase 5: 보고
주인님께 구조화된 리포트 제출. "완료했습니다"만 말하는 것은 금지.

필수 포함:
1. 완료 항목 — 무엇을 했는가 (파일명:라인 포함)
2. 검증 결과 — 린팅/테스트/교차검증 각각 통과/실패
3. 발견된 이슈 — 예상 외 문제 (없으면 "없음")
4. 미완료/보류 — 있으면 사유 (없으면 "없음")
5. 대조 결과 — N개 중 N개 완료, 불일치 N건
6. .checklist.md 최종 상태 — 파일 전체를 코드블록으로 첨부

### Phase 6: 정리
- 미완 항목 분류 (책임 분리):
  - 세션 횡단 백로그성 → /todo add [항목명] 으로 이전
  - 다음 세션 즉시 이어가야 할 인계성 → /handoff create 호출
- 주인님 승인 후 .checklist.md를 .backups/ 디렉토리로 이동 (삭제 금지)
  - 권장 파일명: .backups/.checklist.md.완료_{슬러그}_{YYYY-MM-DD}.md
- 필요 시 docs/history/{YYYY-MM-DD}.md 업데이트 + docs/history/index.md 갱신

## mode별 가이드

### mode: code
- 수정 대상 파일 (경로 + 변경 내용)
- 린트/포매터 통과 항목
- 테스트 항목
- 사이드 이펙트 검증

### mode: doc
- 연관 문서 목록
- 교차 검증 항목
- 용어 대조
- 링크 유효성

### mode: design
- 입출력 계약
- 실패/에러 케이스 처리
- 트랜잭션 범위
- 의존 관계

### mode: mixed
- 코드 + 문서 양쪽 섹션 모두 포함
- 동기화 책임 명시

## Rules
- 하나의 체크리스트 — 코드든 문서든 .checklist.md 하나로 관리
- 승인 마커 — 기본값 approved: false + status: draft
- 턴 종료 의무 — Phase 1 완료 시 구현 진입 금지
- 더블 체크 필수
- Read 증거 의무
- tiny edit 예외 (의미 조건):
  - 한 파일의 단일 Edit, old_string과 new_string이 각각 3줄 이하 + 240자 이하여야 함
  - blanket 예외 제거 — 다음은 줄 수와 무관하게 반드시 체크리스트 필요:
    - conftest.py, setup.py
    - 공개 API
    - DB 스키마 / 마이그레이션
    - 권한·보안 관련 설정
    - 배포 설정
    - 테스트 비활성화
    - 데이터 마이그레이션 스크립트
- 백업은 doc-protection 훅이 담당
- 체크리스트 보존 — Phase 6에서 삭제 금지, .backups/로 이동
- /todo 와 책임 분리 — 세션 완료 가능 항목만 .checklist.md 보관
- /handoff 와 책임 분리 — 세션 종료 시 미완 항목 인계는 /handoff 사용
```

---

### [SKILL 2/4] `/todo` SKILL.md

```markdown
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

비유: .checklist.md 가 오늘의 작업 지시서라면, .todo.md 는 냉장고 화이트보드 메모.

## Trigger
- "투두 추가", "할 일 추가", "이거 나중에 해줘"
- "투두 보여줘", "할 일 목록", "현재 투두 뭐 있어?"
- "이거 완료", "투두에서 X 지워줘"
- "투두 정리해줘"
- /todo 직접 호출

## Commands
- /todo — 현재 백로그 조회
- /todo add [내용] — 항목 추가
- /todo done [번호 또는 키워드] — 완료 처리
- /todo archive — 완료 항목 10개 초과 시 .backups/ 로 정리

## 파일 위치 (결정 4 = 프로젝트별만)

- 백로그: {프로젝트 루트}/.todo.md
- 완료 아카이브: {프로젝트 루트}/.backups/.todo.done.{YYYY-MM-DD}.md
- 글로벌 ~/.claude/.todo.md 는 만들지 않는다 (Day 15 결정 4)

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

번호(#NNN)는 단조 증가. 완료 후에도 보존.

## How it works

### 조회 (/todo)
1. .todo.md 가 없으면 "백로그 비어있음" 표시
2. 있으면 백로그 + 완료 섹션 출력

### 추가 (/todo add [내용])
1. .todo.md 가 없으면 양식대로 신규 생성
2. 마지막 번호 + 1 로 항목 추가
3. (added: YYYY-MM-DD) 메타데이터 자동 부착
4. priority 는 사용자가 지정하지 않으면 normal

### 완료 (/todo done [번호 또는 키워드])
1. 번호 또는 키워드로 항목 매칭
2. [ ] → [x] 변경 + (done: YYYY-MM-DD) 추가
3. 항목을 백로그 → "완료 (최근 10개)" 섹션으로 이동
4. 완료 항목 11개 이상이면 자동 archive 권고

### 아카이브 (/todo archive)
1. "완료 (최근 10개)" 섹션에서 가장 오래된 항목부터 cut
2. .backups/.todo.done.{YYYY-MM-DD}.md 에 paste
3. .todo.md 의 완료 섹션에 최근 10개만 남김

## 다른 스킬과의 책임 경계

### vs /checklist (Day 15 결정 1=A: 자동 트리거 없음)
| 구분 | /todo | /checklist |
|------|-------|------------|
| 시제 | 미래 ("나중에 할 것") | 현재 ("지금 하는 것") |
| 파일 | .todo.md (상시 유지) | .checklist.md (작업 단위 생성·소멸) |
| 승인 흐름 | 없음 | 필수 (approved: false → 주인님 승인) |
| 완료 시 | 목록에서 완료 마킹 후 보존 | .backups/ 로 이동 |
| 수명 | 프로젝트 존속 기간 내내 | 단일 작업 사이클 |

### vs /handoff
| 구분 | /todo | /handoff |
|------|-------|----------|
| 발생 시점 | 상시 | 세션 종료 시점에만 |
| 미완 항목 성격 | "언제 할지 모르는 것" | "지금 하다 멈춘 것" |
| 소멸 조건 | done 또는 archive | 다음 세션 확인 후 즉시 |

### vs /project-history
- /todo 는 미래 백로그, /project-history 는 과거 완료 기록
- /todo done 시 자동 히스토리 기록 X

## Rules
- 결정 4 준수 — 글로벌 ~/.claude/.todo.md 만들지 않음
- 결정 1 준수 — /checklist 자동 트리거 없음
- 번호 보존 — 완료 후에도 #NNN 유지
- 추가 시 승인 불필요
- .gitignore 권장
```

---

### [SKILL 3/4] `/handoff` SKILL.md

```markdown
---
name: handoff
description: 세션 종료 시 다음 세션을 위한 인계서(HANDOFF.md) 생성·조회·소멸. 단일 세션 인계의 SSOT (장기 기록은 /project-history, 백로그는 /todo).
trigger: /handoff
argument-hint: "[create|done]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Handoff (세션 인계 관리자)

세션 종료 시 다음 세션이 즉시 이어갈 수 있게 현재 상태·미완 작업·다음 시작 지점·미결 결정을 프로젝트 루트 HANDOFF.md 에 기록한다. 다음 세션이 확인하면 .backups/ 로 이동해 소멸한다.

비유: 교대 근무 인계 노트.

## Trigger
- "인계해줘", "세션 마무리", "오늘 작업 인계해줘"
- "다음 세션 위해 정리해줘"
- "지금 어디까지 했지?" (새 세션 시작 시)
- "인계서 보여줘", "HANDOFF 내용 뭐야?"
- "인계 완료", "인계 받았어"
- /handoff 직접 호출

## Commands
- /handoff — 조회
- /handoff create — 인계서 생성
- /handoff done — 인계서 소멸

## 파일 위치 (Day 15 결정 2=C)

- 인계서: {프로젝트 루트}/HANDOFF.md ← 단일 세션 인계 SSOT
- 완료 아카이브: {프로젝트 루트}/.backups/HANDOFF.done.{YYYY-MM-DD}.md

docs/history/index.md 의 ## 🔄 진행 중 섹션은 14일 이상 장기 항목 포인터 전용 (HANDOFF.md 와 동일 정보 중복 금지).

## HANDOFF.md 양식

```markdown
# HANDOFF — {YYYY-MM-DD} 세션 인계서

> 생성: YYYY-MM-DD HH:MM | 소멸 조건: 다음 세션 확인 후 /handoff done

## 마지막 상태 (어디까지 했나)
- 작업: [작업명]
- 진행률: [완료 단계/전체 단계]
- 마지막 편집 파일: path/to/file (L번호)

## 미완 작업 (지금 하다 멈춘 것)
- [ ] 항목 1 — 이유: 시간 부족 / 블로커 발생 / 결정 대기
- [ ] 항목 2

## 다음 세션 시작 지점
1. [명확한 첫 번째 행동 — 동사 시작]
2. [두 번째 행동]

## 미결 결정 (다음 세션에 결정 필요)
- 결정 사항: ... | 선택지: A / B | 현재 기울기: A

## 컨텍스트 (배경 이해용)
- 이 작업을 하는 이유
- 주의 사항

## 관련 파일
- path/to/main_file — 핵심 편집 대상
- path/to/ref_doc — 참조 문서
```

5종 데이터 (마지막 상태 / 미완 / 다음 시작 / 미결 / 관련 파일) 모두 필수. 누락 시 인계 실패로 간주.

## How it works

### 조회 (/handoff)
1. 프로젝트 루트 HANDOFF.md 존재 확인
2. 있으면 그대로 출력
3. 없으면 안내

### 생성 (/handoff create)
1. 수집:
   - git status --short + git diff --stat
   - TaskList → 미완 task
   - docs/history/index.md 진행 중 섹션
   - 대화 맥락에서 미결 결정 추출
2. 합성: 양식대로 HANDOFF.md 작성
3. 검증: 5종 데이터 누락 여부 확인
4. 부수 효과:
   - 14일 이상 지속될 항목은 index.md 진행 중 섹션 갱신 권고
   - 백로그성 항목은 /todo add 권고

### 소멸 (/handoff done)
1. 다음 세션이 인계서 확인 후 호출
2. HANDOFF.md → .backups/HANDOFF.done.{YYYY-MM-DD}.md 로 이동
3. 미완 항목 중 지속 필요한 것 → 사용자에게 .todo.md 이동 여부 질문
4. 14일 이상 지속될 항목 → index.md 진행 중 포인터 섹션 갱신 권고

## 다른 스킬과의 책임 경계

### vs /project-history (강한 분리)
| 구분 | /handoff | /project-history |
|------|----------|------------------|
| 대상 | 미완 / 진행 중 | 완료된 것 |
| 지속성 | 임시 (다음 세션 확인 시 소멸) | 영구 (append-only) |
| 작성 시점 | 세션 종료 직전 | 작업 완료 후 |
| 파일 | HANDOFF.md (루트) | docs/history/{날짜}.md |
| 용도 | 다음 세션 재개 | 감사 추적, 레트로 |

### vs /todo
| 구분 | /handoff | /todo |
|------|----------|-------|
| 발생 시점 | 세션 종료 | 상시 |
| 미완 성격 | "지금 하다 멈춘 것" | "언제 할지 모르는 것" |
| 소멸 조건 | 다음 세션 확인 후 즉시 | done 또는 archive |
| 수명 | 1~2 세션 | 프로젝트 존속 기간 |

### vs index.md 진행 중 섹션 (Day 15 결정 2=C)
| 구분 | HANDOFF.md (/handoff) | index.md 진행 중 (/project-history) |
|------|----------------------|---------------------------------------|
| 범위 | 단일 세션 인계 | 14일 이상 장기 항목 포인터 |
| 수명 | 1~2 세션 | 7개 / 14일 한계까지 |
| SSOT | 단일 세션 인계의 SSOT | 장기 항목 포인터 (중복 금지) |

## Rules
- 5종 데이터 누락 금지
- 소멸 시 삭제 금지 — .backups/ 로 이동만
- 자동 이동 금지 — 미완 항목을 .todo.md 로 이동할지는 인계 받은 세션이 결정
- SSOT 분리 (결정 2=C)
- 다음 시작 지점은 동사로 시작
- HANDOFF.md 가 이미 있으면 덮어쓰기 전에 사용자에게 확인
```

---

### [SKILL 4/4] `/project-history` SKILL.md

```markdown
---
name: project-history
description: 프로젝트 개발 히스토리(완료 기록) 폴더 기반 관리. 조회, 갱신, 마이그레이션, 검색. 단일 세션 인계는 /handoff 사용.
trigger: /project-history
argument-hint: "[update|migrate|search] [키워드]"
user-invocable: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Project History Manager

프로젝트 개발 히스토리를 폴더 기반 인덱싱으로 관리.

## Trigger
- "히스토리", "개발 기록", "지금까지 뭐 했지", "어디까지 했지"
- 새 세션 시작 시 완료 기록 조회 (단일 세션 인계는 /handoff)
- /project-history 직접 호출

## Commands
- /project-history — 최근 5일 요약 + 장기 진행 중 포인터
- /project-history update — 완료된 작업을 일자별 파일에 추가
- /project-history migrate — 단일 HISTORY.md → 폴더 구조로 마이그레이션
- /project-history search <키워드> — 히스토리 전체 검색

## 구조 (Phase 1 / Phase 2 단계 구분)

### Phase 1: 단일 HISTORY.md
docs/HISTORY.md
├── ## 🔄 진행 중 (장기 항목 포인터, SSOT는 HANDOFF.md)
├── ## 프로젝트 개요
├── ## Day 0 ...
└── ## Day N ...

### Phase 2: 폴더 구조
docs/history/
├── index.md (진행 중 포인터 + 인덱스 표)
├── 2026-03-05.md (Day 1 완료 아카이브)
└── ...

Phase 1 → Phase 2 전환 기준:
- 진행 중 항목 일상적으로 3개 이상 운영
- 인계 누락 1회 발생
- 1주 안정 운영 후 회고에서 합의

### 진행 중 섹션 양식 (장기 추적용 포인터)
```
## 🔄 진행 중 (다음 세션 인계)

> 단일 세션 인계는 HANDOFF.md (/handoff) 참조.
> 이 섹션은 14일 이상 지속되거나 여러 세션에 걸친 장기 항목만 추적.
> 양식: [시작일] 상태 | 작업명 | 다음: (동사) | 미결: 내용
> 한계: 7개 초과 또는 14일 초과 시 즉시 정리

- [2026-04-17] 진행 중 | 작업명 | 다음: 다음 단계 | 미결: 없음
```

SSOT 위치 (Day 15 결정 2=C):
- 단일 세션 인계: HANDOFF.md (/handoff SSOT)
- 장기 진행 항목: docs/history/index.md = 포인터. HANDOFF.md 와 동일 정보 중복 금지

### index.md 포맷
| 날짜 | Day | 요약 | 파일 |
|------|-----|------|------|
| 2026-03-05 | 1 | 프로젝트 초기 설계 | [상세](2026-03-05.md) |

### 일별 파일 포맷
# Day N — YYYY-MM-DD — 한줄 요약

## 1. 작업 제목
- 상세 내용
- 왜: 이유
- 변경 파일: path/to/file.py

## How it works

### 조회 (/project-history)
1. docs/history/index.md 읽기
2. 최근 5일치 요약
3. 상세 필요 시 해당 날짜 파일 Read

### 업데이트 (/project-history update)
1. 오늘 날짜 파일 생성 or 수정 — 완료된 작업만 기록
2. 포맷:
   - 시간순 (최신이 아래)
   - "왜(Why)" 포함
   - 번호 붙인 섹션
3. 진행 중/미완 항목은 /handoff 가 담당
4. 14일 이상 지속된 장기 항목만 index.md 진행 중 포인터 섹션에 등록

### 마이그레이션 (/project-history migrate)
1. 기존 docs/HISTORY.md 읽기
2. ## YYYY-MM-DD 구분자로 분리
3. 각 날짜를 docs/history/YYYY-MM-DD.md로 저장
4. docs/history/index.md 자동 생성
5. 원본 → docs/.backups/HISTORY.md.bak 백업
6. 주인님 확인 후 원본 삭제

### 검색 (/project-history search <키워드>)
1. docs/history/ 전체 Grep
2. 매칭된 날짜 + 컨텍스트 표시

## 훅 정책

| 명령 | 파일 수 | 방법 | 원칙 |
|------|---------|------|------|
| migrate | 수십 개 | 승인 후 일괄 작업 | 영향 범위와 백업 위치 보고 |
| update (신규) | 1~2개 | Write | 신규 문서 양식 + 인덱스 갱신 |
| update (수정) | 1~2개 | Edit | 전체 덮어쓰기 금지 |
| search / 조회 | 0 | Read/Grep | 읽기 전용 |

## Rules
- 단일 세션 인계 SSOT = HANDOFF.md
- /handoff 와 책임 분리 — "지금 하다 멈춘 것"은 /handoff, "완료된 기록"은 본 스킬, "백로그"는 /todo
- 진행 중 한계: 7개 OR 14일
- 양식 엄격 준수
- index.md는 200줄 이내
- 일별 파일 1개 = 1일
- 폴더 구조 우선 — docs/history/ 있으면 단일 HISTORY.md 무시
- 마이그레이션은 주인님 승인 후
- 미완료 항목은 /handoff 로 인계
```

---

## 검수 종료

위 4 SKILL.md 본체 + 1차 진단 결과를 종합 검토해 주세요.
이 입력 자료의 라인 번호를 직접 인용하여 지적해 주시기 바랍니다.
