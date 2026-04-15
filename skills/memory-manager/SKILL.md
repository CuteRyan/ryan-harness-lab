---
name: memory-manager
description: 프로젝트 메모리 구조를 초기화·정리·최적화하는 스킬. CLAUDE.md/rules/memory 3계층 아키텍처 기반.
trigger: /memory-manager
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob
---

# 메모리 관리 스킬

## 목적
프로젝트의 메모리 구조를 Claude Code 베스트 프랙티스에 맞게 **초기화·정리·최적화**한다.
3계층 아키텍처(CLAUDE.md + rules + memory)를 기반으로 역할 분리를 유지한다.

## Trigger
- `/memory-manager` 명령어로 직접 호출
- "메모리 정리해줘", "메모리 구조 잡아줘", "메모리 초기화" 등

## 3계층 아키텍처 (핵심 원칙)

```
자동 로딩 (매 세션)
├── CLAUDE.md                    ← 프로젝트 소개 + 핵심 규칙 (200줄 이내)
├── {하위폴더}/CLAUDE.md         ← 파트별 스코핑 규칙
├── .claude/rules/*.md           ← 세부 규칙 분리 (자동 로딩)
└── memory/MEMORY.md             ← 순수 인덱스 (200줄 이내)

on-demand (필요 시 로딩)
└── memory/*.md (topic files)    ← 포인터 + 핵심 판단 요약 3줄
```

### 역할 분리 원칙

| 구분 | 역할 | 내용 | 작성자 |
|------|------|------|--------|
| `CLAUDE.md` | 강제 (진입점) | 프로젝트 소개, 빌드 명령, 핵심 규칙 | 사용자 |
| `.claude/rules/*.md` | 강제 (세부) | 코딩 규칙, 워크플로, 테스트 전략 등 | 사용자 |
| `{하위폴더}/CLAUDE.md` | 강제 (파트별) | 해당 모듈/파트 전용 규칙 | 사용자 |
| `memory/MEMORY.md` | 인덱스 | 포인터만. 한 줄에 하나 | Claude |
| `memory/*.md` | 메모 | 포인터 + 핵심 판단 요약 (3~5줄) | Claude |
| `docs/` | 실제 내용 | Single Source of Truth | 사용자/Claude |

### 절대 규칙
- **CLAUDE.md, rules/ = "하라/하지 마라"** (행동 강제)
- **memory/ = "여기에 이런 게 있다"** (포인터 + 왜 그렇게 결정했는지 3줄)
- **docs/ = Single Source of Truth** (실제 내용은 여기만)
- **내용 중복 금지** — memory에 docs/ 내용을 복사하지 않음
- **MEMORY.md, CLAUDE.md 각각 200줄 이내** — 초과 시 분리

## 실행 프로세스

### 모드 1: `init` (신규 프로젝트 초기화)

프로젝트에 메모리 구조가 없을 때 기본 골격을 생성한다.

1. **현재 구조 파악** — 프로젝트 디렉토리, 주요 모듈/파트 식별
2. **아래 구조 생성**:

```
{프로젝트}/
├── CLAUDE.md                     ← 프로젝트 전체 규칙
├── .claude/
│   └── rules/
│       ├── coding.md             ← 코딩 규칙 (린터, 타입, 스타일)
│       └── workflow.md           ← 워크플로 규칙 (PR, 커밋, 리뷰)
├── docs/                         ← Single Source of Truth
│   └── HISTORY.md
└── {파트별}/
    └── CLAUDE.md                 ← 파트 전용 규칙 (필요 시)
```

3. **프로젝트별 memory 인덱스 확인** — `~/.claude/projects/{프로젝트키}/memory/MEMORY.md` 존재 여부 확인, 없으면 생성

4. **주인님에게 보고** — 생성된 구조, 각 파일의 역할 설명

### 모드 2: `audit` (기존 프로젝트 점검)

기존 메모리 구조를 점검하고 개선점을 제안한다.

1. **CLAUDE.md 줄 수 확인** — 200줄 초과 시 rules/로 분리 제안
2. **MEMORY.md 줄 수 확인** — 200줄 초과 시 정리 필요
3. **memory/*.md 점검**:
   - 내용이 docs/와 중복되는 파일 탐지
   - frontmatter(name, description, type) 누락 파일 탐지
   - 오래된/부정확한 메모리 탐지 (파일 수정일 기준)
   - 포인터가 가리키는 docs/ 파일이 실제 존재하는지 확인
4. **rules/ 점검**:
   - CLAUDE.md에 규칙이 과도하게 들어있으면 rules/로 분리 제안
   - rules/ 파일 간 중복 탐지
5. **파트별 CLAUDE.md 점검**:
   - 주요 모듈에 CLAUDE.md가 없으면 생성 제안
6. **승격 후보 식별**:
   - 2개 이상 프로젝트에서 반복되는 메모리 → 글로벌로 승격 제안
7. **결과를 주인님에게 보고** — 문제점 + 개선 액션 제안 (실행은 승인 후)

### 모드 3: `clean` (정리 실행)

audit 결과를 기반으로 실제 정리를 수행한다. **반드시 주인님 승인 후 실행.**

1. **중복 메모리 제거** — docs/와 내용이 중복되는 memory 파일 정리
2. **CLAUDE.md → rules/ 분리** — 200줄 초과 시 규칙을 카테고리별로 분리
3. **MEMORY.md 인덱스 재정비** — 깨진 포인터 제거, 새 파일 추가, 200줄 이내 유지
4. **topic 파일 정규화** — frontmatter 추가, 핵심 판단 요약 3줄 보강
5. **글로벌 승격** — 2+ 프로젝트 공통 메모리를 글로벌로 이동
6. **.bak 백업 생성** — 변경 전 원본 백업 (주인님 선호)

## topic 파일 양식

```markdown
---
name: {토픽명}
description: {한 줄 설명 — 관련성 판단용}
type: {user | feedback | project | reference}
---

{핵심 판단 요약 3~5줄: 무엇을, 왜 그렇게 결정했는지}

→ 상세: `docs/{파일명}.md`
```

### 좋은 예
```markdown
---
name: 뉴스 파이프라인 v2 설계
description: 뉴스 수집·요약·전달 파이프라인 설계 결정사항
type: project
---

RSS 기반 수집 → LLM 요약 → DB 저장 구조 채택.
실시간 크롤링 대신 RSS를 선택한 이유: 법적 리스크 회피 + 안정성.
요약 모델은 비용 대비 품질로 Haiku 선택.

→ 상세: `docs/design/news_pipeline_v2.md`
```

### 나쁜 예
```markdown
뉴스 파이프라인은 RSS로 뉴스를 수집하고 LLM으로 요약하여
DB에 저장하는 시스템이다. RSS 피드는 config.yaml에서 관리하며
수집 주기는 1시간이다. 요약 프롬프트는 prompts/news_summary.txt에
있고, 최대 토큰 수는 500이다... (이하 docs/ 내용 복사)
```

## rules/ 파일 양식

```markdown
# {규칙 카테고리}

## 규칙 1
- 내용

## 규칙 2
- 내용
```

rules/는 frontmatter 없이 바로 규칙을 작성한다. CLAUDE.md와 동일한 형식.

## 작성 규칙

1. **승인 없이 삭제/이동 금지** — audit으로 제안 → 주인님 승인 → clean으로 실행
2. **.bak 백업 필수** — 변경 전 원본 백업 생성
3. **200줄 제한 엄수** — CLAUDE.md, MEMORY.md 각각 200줄 이내
4. **내용 중복 금지** — docs/의 내용을 memory에 복사하지 않음. 포인터 + 판단 요약만
5. **kebab-case 네이밍** — 파일명은 영문 kebab-case (예: `news-pipeline.md`)
6. **파일 1개 = 토픽 1개** — 하나의 파일에 여러 주제 혼합 금지

## 주인님 정보
- 글로벌 CLAUDE.md: `C:/Users/rlgns/.claude/CLAUDE.md`
- 글로벌 메모리: `C:/Users/rlgns/.claude/memory/`
- 프로젝트별 메모리: `C:/Users/rlgns/.claude/projects/{프로젝트키}/memory/`
