# Claude Code 하네스 과부하 문제 — Rules·Hooks·Memory·Skills 병목과 해결법

> 작성일: 2026-04-16 | 마지막 검증: 2026-04-16
> 출처 신뢰도: 공식 문서 + GitHub Issues + 커뮤니티 벤치마크 혼합

---

## 이 문서는 무엇인가?

> 한 줄 요약: Claude Code에서 하네스(Rules, Hooks, Memory, Skills)를 많이 쌓을수록 **오히려 AI 성능이 떨어지는 역설적 현상**의 원인, 증상, 해결법을 정리한 문서.
>
> 비유: 직원에게 업무 매뉴얼을 100페이지 주면 일을 잘 하지만, 1,000페이지 주면 매뉴얼 읽느라 정작 일을 못 한다. 하네스도 마찬가지 — **AI의 책상(컨텍스트 윈도우)이 매뉴얼로 가득 차면 실제 작업할 공간이 없다.**
>
> 예시: CLAUDE.md 500줄 + rules/ 15개 + hooks 11개 + MCP 서버 5개 → 세션 시작 시 이미 컨텍스트의 40~50%가 소진 → 2시간 작업 후 AI가 이전 결정을 잊고 빙빙 돈다.

---

## 목차

1. [쉬운 설명](#1-쉬운-설명)
2. [핵심 개념](#2-핵심-개념)
3. [상세 내용: 4대 병목 분석](#3-상세-내용-4대-병목-분석)
4. [증상 체크리스트: "내 하네스가 과부하인가?"](#4-증상-체크리스트-내-하네스가-과부하인가)
5. [해결법: 하네스 다이어트 전략](#5-해결법-하네스-다이어트-전략)
6. [실전 활용: 최적화 전후 비교](#6-실전-활용-최적화-전후-비교)
7. [제약사항 및 주의점](#7-제약사항-및-주의점)
8. [팩트체크](#8-팩트체크)
9. [용어 사전](#9-용어-사전)
10. [출처](#10-출처)
11. [관련 문서](#관련-문서)

---

## 1. 쉬운 설명

### 한마디로?

Claude Code의 하네스(환경 설정 체계)를 **너무 두껍게** 만들면, AI의 "작업용 메모리"를 하네스가 잡아먹어서 **오히려 성능이 떨어진다.** 매뉴얼이 책상을 다 차지하면 작업할 공간이 없는 것과 같다.

### 왜 이런 일이 생기는가?

```
AI의 컨텍스트 윈도우 = 책상 크기 (고정)

┌──────────────────────────────────────────┐
│          AI의 컨텍스트 윈도우 (책상)         │
│                                          │
│  ┌──────────┐  ┌──────────────────────┐  │
│  │ 하네스    │  │ 실제 작업 공간         │  │
│  │ (매뉴얼)  │  │ (코드 읽기, 생각하기)   │  │
│  │          │  │                      │  │
│  └──────────┘  └──────────────────────┘  │
│    ← 이게 커지면 →   이게 줄어든다         │
└──────────────────────────────────────────┘

하네스가 얇을 때:  매뉴얼 20% | 작업 80%  → AI가 깊이 생각할 수 있음
하네스가 두꺼울 때: 매뉴얼 50% | 작업 50%  → AI가 얕게 생각하고 실수 늘어남
```

### 핵심 숫자

| 컨텍스트 사용률 | AI 상태 |
|----------------|---------|
| **~20%** | 정상 작동. 하지만 복잡한 작업에선 이미 결정을 잊기 시작 |
| **~40%** | 성능 저하 시작. 반복, 이전 결정 망각, 자동 압축 발동 |
| **~48%** | AI가 스스로 "새 세션 시작을 권장합니다"라고 말함 |
| **~60%** | 심각한 저하. 같은 수정을 적용→되돌리기→재적용 반복 |
| **~80%+** | 사실상 사용 불가 |

> 1M 컨텍스트라고 광고하지만, **실질적으로 고품질 작업이 가능한 범위는 ~400K 토큰 이하**라는 것이 커뮤니티 관측 결과다.

---

## 2. 핵심 개념

### 컨텍스트 예산 (Context Budget)

- **한 줄 정의**: AI의 컨텍스트 윈도우를 "한정된 예산"으로 보는 개념. 하네스에 쓸수록 작업에 쓸 돈이 줄어든다.
- **비유**: 월급 300만원 중 고정비(월세, 보험)가 200만원이면 생활비로 쓸 수 있는 건 100만원뿐. 하네스 = 고정비, 실제 작업 = 생활비.
- **예시**: CLAUDE.md 18K 토큰 + MCP 12K + Memory 8K = 세션 시작 전에 이미 38K 토큰 소진.

### 고정 오버헤드 (Fixed Overhead)

- **한 줄 정의**: 매 세션마다 무조건 소비되는 토큰. 대화를 하기도 전에 차지하는 공간.
- **비유**: 매달 자동이체되는 고정 지출. 줄이지 않으면 매달 나간다.
- **예시**: 시스템 프롬프트(~33K) + MCP 도구 정의(~12K) + CLAUDE.md(~18K) + Memory(~8K) = **~71K 토큰이 대화 전에 이미 소진.**

### 주의력 예산 (Attention Budget)

- **한 줄 정의**: Anthropic이 공식적으로 사용하는 용어. 컨텍스트 윈도우에 토큰이 추가될 때마다 모델이 "중요한 것에 집중하는 능력"이 감소하는 현상.
- **비유**: 시끄러운 식당에서 대화하는 것. 주변 소음(불필요한 규칙)이 많아질수록 상대방 말(실제 작업 지시)을 듣기 어려워진다.
- **예시**: rules/ 파일 15개가 로딩되면, 각 규칙을 "처리"하느라 실제 코드에 대한 집중도가 떨어진다.

### 덤 존 (Dumb Zone)

- **한 줄 정의**: 컨텍스트가 과포화되어 AI가 "멍청해지는" 구간. 커뮤니티에서 사용하는 비공식 용어.
- **비유**: 너무 많은 탭을 열어서 컴퓨터가 느려지는 것. 브라우저 탭 50개 = 컨텍스트 과부하.
- **예시**: 컨텍스트 60% 이상에서 AI가 같은 실수를 반복, 이전 결정을 잊음, 원형 추론(circular reasoning)에 빠짐.

---

## 3. 상세 내용: 4대 병목 분석

### 3.1 Rules (CLAUDE.md + rules/) — "매뉴얼 과부하"

#### 문제

| 원인 | 증상 | 수치 |
|------|------|------|
| CLAUDE.md가 너무 길다 | 뒤쪽 규칙을 무시하기 시작 | 60~100줄 넘으면 준수율 저하 |
| rules/ 파일이 너무 많다 | 규칙 간 충돌 시 임의 선택 | 15개+ 에서 체감 저하 |
| 일반적 조언 형태의 규칙 | AI가 "읽고 잊는" 규칙이 됨 | 효과 없이 토큰만 소비 |
| 중복 규칙 | 같은 말을 다르게 쓰면 AI가 혼란 | 규칙 간 모순 발생 |

#### 실제 사례

> 한 개발자가 13개 에이전트 오케스트레이션 시스템을 위해 **8,157줄의 마크다운 규칙**을 작성했다. 결과: Claude의 추론 능력이 저하되어 **93%를 삭제**한 후에야 성능이 회복되었다.

#### ETH Zurich 연구 결과

> "repository context files(저장소 컨텍스트 파일, 즉 CLAUDE.md 같은 것)가 오히려 **작업 성공률을 낮추면서** 추론 비용은 20% 이상 증가시킨다"는 연구 결과가 나왔다.

---

### 3.2 Hooks — "과도한 검문소"

#### 문제

| 원인 | 증상 | 수치 |
|------|------|------|
| 훅이 너무 많다 | 모든 도구 호출마다 지연 | 11개 훅 → 프롬프트당 ~20초 지연 |
| 훅이 Node.js를 매번 spawn | 프로세스 생성 오버헤드 누적 | 각 훅당 ~1-2초 |
| 훅 출력이 컨텍스트에 들어감 | 성공 메시지가 토큰 낭비 | 테스트 결과 4,000줄 → 포커스 상실 |
| PreToolUse 훅이 모든 도구에 발동 | Read/Grep/Glob 같은 안전한 도구도 차단 검사 | 불필요한 지연 |

#### 실제 사례 (Ruflo/Claude Flow)

> `.claude/settings.json`에 **9개 라이프사이클 이벤트에 걸쳐 11개 이상의 훅**을 등록한 프로젝트에서, 프롬프트당 응답 시간이 **~4.8초 → ~18-21초**로 4배 증가했다. 같은 CLI를 프로젝트 디렉토리 밖에서 실행하면 정상 속도로 돌아왔다.

#### Anthropic의 공식 수정 (2026년)

- SessionStart 훅을 지연 실행(defer)하여 **~500ms 시작 속도 개선**
- O(n²) 메시지 누적 버그 수정 — progress 업데이트가 쌓여서 느려지는 문제
- Windows에서 훅 실패 문제 → Git Bash 사용으로 해결

---

### 3.3 Memory — "낡은 메모 더미"

#### 문제

| 원인 | 증상 | 수치 |
|------|------|------|
| MEMORY.md가 길어짐 | 오래된/잘못된 포인터가 남아있음 | 200줄 제한이지만 내용이 stale |
| topic 파일이 많아짐 | 삭제된 파일에 대한 메모리 잔존 | "모순과 구식 참조가 가득" |
| 메모리가 docs/와 중복 | 같은 정보를 두 번 로딩 | 토큰 이중 소비 |
| Auto Memory가 무분별 저장 | 불필요한 메모리가 쌓임 | 시간이 지날수록 노이즈 증가 |

#### 커뮤니티 관찰

> "Auto Memory를 몇 주 사용하면 노트가 낡아지고(stale), 삭제된 파일에 대한 항목이 남아있고, 인덱스가 모순과 구식 참조로 가득 찬다."

---

### 3.4 Skills & MCP — "필요 없는 도구까지 챙기기"

#### 문제

| 원인 | 증상 | 수치 |
|------|------|------|
| MCP 서버를 많이 연결 | 도구 정의만으로 ~12K 토큰 소비 | 사용 안 해도 자리 차지 |
| 스킬 설명이 컨텍스트에 로딩 | 호출 안 해도 설명문이 토큰 소비 | 스킬 10개 → 수천 토큰 |
| 중복 도구 (MCP vs CLI) | 같은 기능이 두 가지로 등록 | GitHub MCP + gh CLI = 중복 |

#### Anthropic 권장

> "MCP 서버가 CLI로 이미 할 수 있는 기능(GitHub, Docker, 대부분의 DB)을 복제한다면, CLI를 프롬프트로 사용하는 것이 더 낫다. CLI는 학습 데이터에 잘 반영되어 있어서 AI가 더 잘 활용한다."

---

## 4. 증상 체크리스트: "내 하네스가 과부하인가?"

> 아래 항목 중 **3개 이상 해당**하면 하네스 다이어트가 필요하다.

- [ ] AI가 세션 중반부터 이전 결정을 잊는다
- [ ] 같은 수정을 적용 → 되돌리기 → 재적용하는 원형 추론(circular reasoning)이 보인다
- [ ] "수정했습니다"라고 하지만 실제로 아무것도 안 바뀌어 있다
- [ ] `/context` 실행 시 30% 미만에서도 이미 성능 저하가 느껴진다
- [ ] 프롬프트 입력 후 응답까지 10초 이상 걸린다 (훅 지연)
- [ ] AI가 "새 세션을 시작하는 것을 권장합니다"라고 먼저 말한다
- [ ] 작업 중반에 갑자기 멈추고(stopping mid-task) 완료하지 않는다
- [ ] 규칙 A를 따르면서 규칙 B를 무시한다 (규칙 간 우선순위 혼란)
- [ ] CLAUDE.md가 200줄을 넘었다
- [ ] rules/ 파일이 10개를 넘었다

---

## 5. 해결법: 하네스 다이어트 전략

### 5.1 Rules 최적화 — "매뉴얼을 얇게"

#### 원칙: WHEN-DO 형식으로 전환

```markdown
# 나쁜 예 (일반적 조언 → AI가 읽고 잊음)
"코드 품질을 높이는 것이 중요합니다. 테스트를 작성하고, 
린팅을 통과시키고, 코드 리뷰를 받는 것이 좋습니다."

# 좋은 예 (트리거-액션 → AI가 실행 가능)
"WHEN: Edit/Write 실행 후 → DO: ruff check 실행"
"WHEN: 함수 시그니처 변경 → DO: 호출하는 테스트 파일도 수정"
```

#### 구체적 수치 목표

| 항목 | 현재 (과부하) | 목표 (최적) |
|------|-------------|-----------|
| CLAUDE.md | 200줄+ | **100줄 이내** |
| rules/ 파일 수 | 15개+ | **5~8개** |
| 단일 rule 파일 길이 | 100줄+ | **30줄 이내** |
| 규칙 형식 | 서술형 | **WHEN-DO** |

#### 병합/삭제 후보 찾기

```
1. rules/ 파일 중 "코드에서 이미 강제되는 것" → 삭제
   예: ruff 설정이 이미 있으면 "린팅 규칙" rule 불필요
   
2. "서로 겹치는 규칙" → 병합
   예: dev-checklist.md + documentation.md → 하나로

3. "한 번도 발동 안 된 규칙" → 삭제
   예: 배포 규칙인데 배포한 적 없는 프로젝트
   
4. "docs/에 있는 내용을 반복하는 규칙" → 포인터로 교체
   예: "상세는 docs/workflows/dev-checklist.md 참조" 한 줄로
```

### 5.2 Hooks 최적화 — "검문소를 줄이기"

#### 원칙: "성공은 침묵, 실패만 말하기"

```bash
# 나쁜 예 — 성공해도 4,000줄 출력 → 컨텍스트 오염
pytest tests/
# 출력: =================== 247 passed =================== (4,000줄)

# 좋은 예 — 실패한 것만 출력
pytest tests/ --tb=short -q 2>&1 | grep -E "FAILED|ERROR" || true
# 출력: (통과하면 아무것도 안 나옴)
```

#### 훅 최적화 전략

| 전략 | 설명 |
|------|------|
| **안전한 도구는 훅 제외** | Read, Grep, Glob 같은 읽기 전용 도구에는 PreToolUse 훅 불필요 |
| **훅 프로파일 사용** | `ECC_HOOK_PROFILE=minimal` 환경변수로 최소 훅만 활성화 |
| **특정 훅 비활성화** | `ECC_DISABLED_HOOKS=hook1,hook2`로 불필요한 훅 끄기 |
| **출력 최소화** | 훅 스크립트에서 성공 시 출력 억제, 실패 시만 에러 메시지 |
| **bash 직접 실행** | Node.js spawn 대신 가벼운 bash 스크립트 사용 (프로세스 생성 비용 절감) |

### 5.3 Memory 최적화 — "메모 정리"

#### 원칙: "포인터만 남기고, 내용은 docs/에"

```markdown
# 나쁜 예 — memory 파일에 내용을 직접 작성 (docs/와 중복)
---
name: db-schema
description: DB 스키마 설계
type: project
---
documents 테이블: id, title, content, category_id...
categories 테이블: id, name, parent_id...
(50줄 이어짐)

# 좋은 예 — 포인터 + 판단 요약 3줄만
---
name: db-schema
description: DB 스키마 설계 포인터
type: project
---
테이블 10개, ERD 확정. md→DB 매핑은 1:1 아닌 가공 저장 방식.
→ docs/architecture/db_schema.md 참조
```

#### 정기 정리 루틴

1. **월 1회**: MEMORY.md에서 더 이상 유효하지 않은 항목 삭제
2. **월 1회**: topic 파일 중 삭제된 파일을 참조하는 것 정리
3. **즉시**: docs/와 내용이 중복되는 memory 파일 → 포인터로 교체

### 5.4 Skills & MCP 최적화 — "필요한 도구만 꺼내기"

#### 원칙: "쓰지 않는 MCP 서버는 꺼두기"

```
현재 상태 확인:
  /mcp                        ← 연결된 MCP 서버 목록 확인
  /context                    ← MCP 도구 정의가 얼마나 차지하는지 확인

최적화:
  1. 사용 안 하는 MCP 서버 → disconnect
  2. CLI로 대체 가능한 MCP → 삭제 (GitHub MCP → gh CLI)
  3. Deferred Loading 활용 → 도구 정의가 필요할 때만 로딩
```

#### CLI > MCP인 경우

| MCP 서버 | CLI 대체 | 이유 |
|----------|---------|------|
| GitHub MCP | `gh` CLI | AI 학습 데이터에 gh가 더 잘 반영됨 |
| Docker MCP | `docker` CLI | 동일 기능, 토큰 절약 |
| DB MCP | DB 전용 CLI | 직접 쿼리가 더 정확 |

### 5.5 세션 관리 — "책상 정리"

| 전략 | 설명 | 커맨드 |
|------|------|--------|
| **주기적 압축** | 2시간마다 또는 컨텍스트 30%에서 압축 | `/compact "현재 작업 주제"` |
| **작업 단위 분리** | 한 세션에 한 작업. 설계와 구현을 분리 | `/clear` 후 새 작업 |
| **컨텍스트 모니터링** | 수시로 사용량 확인 | `/context` |
| **큰 파일 부분 읽기** | 1,000줄 파일 전체 대신 필요한 부분만 | `Read(limit=50, offset=100)` |
| **.claudeignore 설정** | build/, node_modules/ 등 제외 | 요청당 컨텍스트 40~70% 절감 |

---

## 6. 실전 활용: 최적화 전후 비교

### 시나리오: 하네스 엔지니어링 중심 프로젝트

```
■ 최적화 전 (과부하 상태)
  CLAUDE.md:         350줄 (~18K 토큰)
  rules/:            12개 파일 (~15K 토큰)
  hooks:             11개 (PreToolUse 6개 포함)
  MCP 서버:           5개 연결 (~12K 토큰)
  Memory:            15개 topic 파일 (~8K 토큰)
  ─────────────────────────────────
  세션 시작 시 고정 오버헤드: ~86K 토큰 (시스템 33K 포함)
  프롬프트당 지연:     ~15초
  실질 작업 가능 시간: ~1.5시간 후 성능 저하 시작

■ 최적화 후
  CLAUDE.md:         80줄 (~4K 토큰) — WHEN-DO 형식
  rules/:            6개 파일 (~6K 토큰) — 병합 + 포인터화
  hooks:             5개 (안전 도구 제외, 출력 최소화)
  MCP 서버:           2개 연결 (~4K 토큰) — CLI 대체
  Memory:            8개 topic 파일 (~3K 토큰) — 포인터만
  ─────────────────────────────────
  세션 시작 시 고정 오버헤드: ~50K 토큰
  프롬프트당 지연:     ~5초
  실질 작업 가능 시간: ~3시간+ (주기적 /compact 사용 시)
```

### 진단 명령어 모음

```bash
# 1. 현재 컨텍스트 사용량 확인
/context

# 2. 연결된 MCP 서버 확인
/mcp

# 3. CLAUDE.md 줄 수 확인 (터미널에서)
wc -l CLAUDE.md

# 4. rules/ 파일 수와 총 줄 수 확인
ls .claude/rules/ | wc -l
cat .claude/rules/*.md | wc -l

# 5. hooks 개수 확인
cat .claude/settings.json | grep -c "hook"

# 6. memory 파일 수 확인
ls ~/.claude/projects/*/memory/*.md | wc -l
```

---

## 7. 제약사항 및 주의점

### 다이어트해도 남는 한계

1. **시스템 프롬프트 ~33K는 줄일 수 없다** — Anthropic이 내부적으로 사용하는 고정 오버헤드. 사용자가 제어 불가.
2. **자동 압축(autocompact)은 맥락을 잃는다** — 압축 시 세부 사항이 요약되면서 정확도 하락. 특히 코드의 특정 라인 번호 같은 정밀 정보가 사라짐.
3. **1M 컨텍스트 ≠ 1M 고품질** — 실질적 고품질 작업은 ~400K까지. 이후는 점진적 저하.
4. **규칙을 너무 줄이면 본래 목적 상실** — 하네스의 핵심은 "AI를 올바르게 제약하는 것". 다이어트와 제약의 균형이 필요.
5. **컨텍스트 사용량은 세션 중 계속 증가** — 파일 읽기, bash 출력 등이 누적. `/compact`로만 줄일 수 있음.

### 흔한 실수

| 실수 | 왜 문제인가 | 올바른 방법 |
|------|-----------|-----------|
| 모든 규칙을 CLAUDE.md에 몰아넣기 | 매 세션 전체 로딩 | skills/로 분리 (온디맨드 로딩) |
| 훅에서 전체 테스트 실행 | 출력이 컨텍스트 오염 | 실패한 것만 출력 |
| MCP로 모든 것을 연결 | 도구 정의만으로 토큰 소비 | CLI로 대체 가능한 건 CLI |
| memory에 docs/ 내용 복사 | 이중 로딩 | 포인터만 남기기 |
| 하나의 긴 세션에서 모든 작업 | 컨텍스트 누적으로 성능 저하 | 작업 단위로 세션 분리 |

---

## 8. 팩트체크

### 검증된 사실 (공식 문서/직접 확인)

- [x] 컨텍스트 40%에서 성능 저하 시작, 48%에서 AI 자체 재시작 권고 — 출처: [GitHub Issue #34685](https://github.com/anthropics/claude-code/issues/34685)
- [x] 11개 훅 등록 시 프롬프트당 ~20초 지연 — 출처: [Ruflo Issue #1530](https://github.com/ruvnet/ruflo/issues/1530)
- [x] SessionStart 훅 지연 실행으로 ~500ms 개선 — 출처: [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [x] O(n²) 메시지 누적 버그 수정됨 — 출처: [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [x] Windows 훅 실패 → Git Bash로 해결 — 출처: [Claude Code Changelog](https://code.claude.com/docs/en/changelog)
- [x] `.claudeignore`로 요청당 컨텍스트 40~70% 절감 가능 — 출처: [spacecake.ai 분석](https://www.spacecake.ai/blog/claude-code-context-management)
- [x] "성공은 침묵, 실패만 출력" 원칙 — 출처: [HumanLayer Blog](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
- [x] Anthropic 공식: 컨텍스트 윈도우를 "주의력 예산"으로 취급할 것 — 출처: [Anthropic Docs](https://platform.claude.com/docs/en/build-with-claude/context-windows)

### 미검증 (추가 확인 필요)

- [ ] ETH Zurich "repository context files가 성공률을 낮춘다" 연구 — 커뮤니티 블로그에서 인용, 원본 논문 직접 미확인
- [ ] "CLAUDE.md 60~100줄 넘으면 준수율 저하" 수치 — 커뮤니티 벤치마크 기반, Anthropic 공식 수치 아님
- [ ] 실질 고품질 작업 범위 ~400K 토큰 — GitHub Issue 기반 사용자 관측, 공식 확인 없음
- [ ] 8,157줄 → 93% 삭제 사례 — 커뮤니티 블로그 기반, 독립 검증 없음

### 충돌/불일치 정보

- [ ] Anthropic은 1M 컨텍스트를 광고하지만, 커뮤니티 관측으로는 ~400K 이후 성능 저하 — 판단: 토큰 수 자체는 1M이 맞지만, "고품질 작업"의 기준이 다를 수 있음. Anthropic은 아직 공식 입장을 내지 않음 (Issue #34685 Open 상태)
- [ ] 고정 오버헤드 수치: 출처마다 다름 (33K~50K 범위) — 판단: 설정에 따라 달라지므로 "~33K 시스템 + 사용자 설정"으로 분리 이해

---

## 9. 용어 사전

| 용어 | 쉬운 설명 |
|------|----------|
| **컨텍스트 윈도우** | AI가 한 번에 기억할 수 있는 텍스트 양. 책상 크기에 비유 — 클수록 더 많이 펼쳐볼 수 있지만 한계가 있음 |
| **컨텍스트 예산** | 컨텍스트 윈도우를 "한정된 예산"으로 보는 개념. 하네스에 쓸수록 작업에 쓸 여유가 줄어듦 |
| **주의력 예산** | 토큰이 많아질수록 AI가 중요한 것에 집중하는 능력이 떨어지는 현상 (Anthropic 공식 용어) |
| **고정 오버헤드** | 매 세션마다 무조건 소비되는 토큰. 시스템 프롬프트, 도구 정의, CLAUDE.md 등 |
| **덤 존** | 컨텍스트 과포화로 AI가 멍청해지는 구간 (비공식 커뮤니티 용어) |
| **원형 추론** | AI가 수정 → 되돌리기 → 같은 수정을 반복하는 현상 (circular reasoning) |
| **자동 압축** | 컨텍스트가 차면 Claude Code가 자동으로 이전 대화를 요약하는 기능 (autocompact) |
| **훅 프로파일** | `ECC_HOOK_PROFILE` 환경변수로 훅을 minimal/standard/strict 중 선택 |
| **Deferred Loading** | 도구 정의를 처음부터 전부 로딩하지 않고, 필요할 때만 불러오는 방식 |
| **spawn** | 새로운 프로세스를 생성하는 것. 훅이 Node.js를 spawn하면 매번 새 프로그램이 실행됨 |
| **.claudeignore** | `.gitignore`처럼 Claude Code가 무시할 파일/폴더를 지정하는 설정 파일 |
| **WHEN-DO 형식** | "이 상황이면(WHEN) 이렇게 해라(DO)" 식의 트리거-액션 규칙 형태 |
| **토큰** | AI가 텍스트를 처리하는 단위. 대략 한국어 1글자 ≈ 1~2토큰, 영어 1단어 ≈ 1토큰 |
| **MCP** | Model Context Protocol. AI와 외부 도구를 연결하는 표준 규격 (USB 포트 같은 것) |

---

## 10. 출처

- [Claude Opus 4.6 1M context: self-reported degradation — GitHub Issue #34685](https://github.com/anthropics/claude-code/issues/34685) — 40% 컨텍스트에서 성능 저하 시작, 48%에서 자체 재시작 권고
- [Claude Code's memory tool ecosystem is mostly redundant — Jamie Lord](https://lord.technology/2026/04/11/claude-codes-memory-tool-ecosystem-is-mostly-redundant-with-its-own-defaults.html) — 93% 삭제 사례, ETH Zurich 연구 인용, 100줄 CLAUDE.md 권장
- [Master Claude Code's Context Window — spacecake.ai](https://www.spacecake.ai/blog/claude-code-context-management) — 고정 오버헤드 수치 (33K+12K+18K+8K), .claudeignore 절감 효과
- [Claude Code /context: What's Eating Your Context Window — Vincent Qiao](https://blog.vincentqiao.com/en/posts/claude-code-context/) — 고정 vs 동적 오버헤드, Deferred Loading
- [Hooks causing ~20s latency — Ruflo Issue #1530](https://github.com/ruvnet/ruflo/issues/1530) — 11개 훅 등록 시 프롬프트당 20초 지연
- [Skill Issue: Harness Engineering — HumanLayer Blog](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) — "성공은 침묵" 원칙, 도구 최소화 전략
- [Everything Claude Code: The Harness System — Menon Lab](https://themenonlab.blog/blog/everything-claude-code-harness-system) — 60% 비용 절감, 토큰 최적화
- [Explore the context window — Claude Code Docs](https://code.claude.com/docs/en/context-window) — 공식 컨텍스트 윈도우 관리 가이드
- [Context windows — Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/context-windows) — Anthropic 공식 "주의력 예산" 개념
- [Changelog — Claude Code Docs](https://code.claude.com/docs/en/changelog) — SessionStart 지연, O(n²) 버그 수정 등 공식 패치 내역
- [Claude Code Drama: 6,852 Sessions Prove Performance Collapse](https://scortier.substack.com/p/claude-code-drama-6852-sessions-prove) — 6,852개 세션 분석, thinking length 73% 감소

---

## 관련 문서

- [Claude Code 전체 기능 정리](claude_code_features_2026.md) — Rules, Skills, Hooks, Memory의 기본 사용법
- [AI 코딩 CLI 슬래시 커맨드 총정리](../ai-agent/ai_coding_cli_slash_commands_2026.md) — /compact, /context 등 관리 커맨드 상세
- [하네스 개념 정리](../harness/harness.md) — 하네스 엔지니어링의 정의와 원칙
- [하네스 딥다이브](../harness/harness_deep_dive.md) — 실제 프로젝트의 하네스 구조 분석
- [메모리 3계층 아키텍처](../architecture/memory_architecture.md) — CLAUDE.md + rules/ → memory/ → docs/ 체계 설계
