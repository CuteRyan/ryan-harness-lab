# 프로젝트 하네스 아키텍처 설계안

> 작성일: 2026-04-12 | 마지막 검증: 2026-04-13
> 출처 신뢰도: 직접 조사 + 업계 표준 참고
> 상태: **구현 완료 — Phase 0~4 전체 완료 (2026-04-13)**

---

## 이 문서는 무엇인가?

> 한 줄 요약: opt-in한 코드 프로젝트에서 문서·코드·구조를 체계적으로 관리하기 위한 하네스(자동 품질 관리 시스템) 설계 및 구현 문서.
>
> 비유: 공장에서 제품을 만들 때, 작업자가 알아서 하는 게 아니라 컨베이어 벨트·센서·경보기가 알아서 품질을 잡아주는 것. 문서를 만들면 양식이 자동으로 강제되고, 코드를 고치면 관련 문서를 자동으로 알려주는 시스템.
>
> 예시: 코드에서 로그인 기능을 수정하면 → 훅이 "docs/auth-design.md도 확인하세요"라고 알려줌.

---

## 목차

1. [현황 분석](#1-현황-분석)
2. [목표 아키텍처](#2-목표-아키텍처)
3. [문서 템플릿 체계](#3-문서-템플릿-체계)
4. [훅 체계](#4-훅-체계)
5. [코드↔문서 양방향 동기화](#5-코드문서-양방향-동기화)
6. [위키 + 그래피파이 통합](#6-위키--그래피파이-통합)
7. [디렉토리 관리 스킬](#7-디렉토리-관리-스킬)
8. [구현 로드맵](#8-구현-로드맵)
9. [용어 사전](#9-용어-사전)

---

## 1. 현황 분석

### 1.1 프로젝트별 현황 (2026-04-12 파일시스템 기준)

| 프로젝트 | 위치 | docs/ .md 수 | index.md | log.md | 프론트매터 | 역색인 | GRAPH_REPORT.md |
|----------|------|-------------|----------|--------|-----------|--------|-----------------|
| PAA | 문서/PAA/ | 62 | ✅ | ❌ | ✅ 62/62 | ✅ 60d/66c | ❌ |
| election_simulator | 문서/논문/election_simulator/ | 72 | ✅ | ✅ | ✅ 72/72 | ✅ 47d/61c | ❌ |
| hsk_analyzer | 문서/HSK/hsk_analyzer/ | 1 | ❌ | ❌ | ❌ | ❌ | ❌ |
| candidate_orchestra | 문서/논문/candidate_orchestra/ | 1 | ❌ | ❌ | ❌ | ❌ | ❌ |
| 지식 | 문서/지식/docs/ | 24 | ✅ | ✅ | — | — | — |

> 산정 기준: `docs/**/*.md` 재귀 카운트 (.backups/, templates/ 제외, index/log/HISTORY 제외). 2026-04-13 Phase 3 완료 이후 상태.
> 프론트매터: 적용 문서/전체 문서. 역색인: d=매핑된 문서 수, c=코드 파일 키 수.
> CLAUDE.md 구분: 루트 CLAUDE.md는 에이전트가 즉시 읽는 파일, .claude/CLAUDE.md는 해당 디렉토리 작업 시에만 로드.
> PAA, election_simulator는 Phase 2에서 위키 체계(.harness.yml + docs/index.md) 도입 완료.

### 1.2 초기 문제점 (Phase 0 이전 기준)

> 아래는 하네스 도입 전 상태. Phase 0~2 구현으로 일부 해소됨 — 현재 남은 문제는 1.3 참조.

```
1. 문서 양식 통일 안 됨
   → 같은 "설계 문서"인데 프로젝트마다 형식이 다름
   → 에이전트가 메타데이터(관련 코드, 상태 등)를 파악할 수 없음

2. 코드 ↔ 문서 연결 없음
   → 코드를 고쳐도 어떤 문서가 영향받는지 모름
   → 문서를 고쳐도 어떤 코드를 반영해야 하는지 모름

3. 위키 체계 없음 (지식 폴더 제외)
   → index.md 없어서 에이전트가 문서 전체상을 파악 못함
   → 교차 참조 없어서 문서가 고립됨

4. 디렉토리 구조 비표준
   → src/ 레이아웃 미적용, 루트에 .py 산재
   → 루트 CLAUDE.md 미보유 프로젝트 존재
```

### 1.3 현재 남은 문제 (Phase 3 완료 이후, 2026-04-13 기준)

```
1. 기존 문서 양식 미적용 → ✅ 해소됨
   → PAA 62/62, election_simulator 72/72 프론트매터 적용 완료
   → Stage 3(전체 강제) 전환 가능 상태

2. 역색인 미구축 → ✅ 해소됨
   → PAA: 60 docs, 66 code keys
   → election_simulator: 47 docs, 61 code keys

3. PAA에 log.md 미도입
   → index.md는 있으나 log.md는 없음. 위키 체계 부분 적용 상태

4. 디렉토리 구조 비표준 (범위 밖)
   → src/ 레이아웃 미적용, 루트에 .py 산재 — 별도 리팩터링으로 분리
```

### 1.4 기존 하네스 인프라 (강점)

```
✅ 훅 16개 — 체크리스트, 백업, 문서 안전, 린트, 위키, 그래피파이, 코드↔문서 동기화 등
✅ 규칙 11개 — 코딩, 배포, 문서, 위키, 하네스, 메모리 아키텍처 등
✅ 스킬 8개 (SKILL.md 기준) — graphify, research-knowledge, project-structure, daily-report 등
→ 공통 인프라는 이미 존재하며, 프로젝트별 적용 계층이 부족하다.
```

> 산정 기준: 훅=~/.claude/hooks/*.sh, 규칙=~/.claude/rules/*.md(.backups 제외), 스킬=~/.claude/skills/*/SKILL.md

---

## 2. 목표 아키텍처

### 에이전트가 프로젝트에 진입하면

```
프로젝트 루트/
│
├── CLAUDE.md ──────────── 프로젝트 소개 + 규칙 → 즉시 읽음
├── graphify-out/
│   └── GRAPH_REPORT.md ── 코드 구조 그래프 → 즉시 참조
│
├── docs/
│   ├── index.md ──────── 전체 문서 인덱스 → 즉시 파악
│   ├── log.md ────────── 변경 기록 (append-only)
│   ├── templates/ ────── 종류별 양식 (참조용)
│   │   ├── design.md
│   │   ├── decision.md
│   │   ├── ops.md
│   │   ├── audit.md
│   │   └── research.md
│   ├── design/ ───────── 설계 문서
│   ├── decisions/ ─────── 결정 기록
│   ├── infra/ ────────── 운영/배포
│   ├── audit/ ────────── 감사/검증
│   └── research/ ──────── 조사/분석
│
├── src/ ──────────────── 소스코드 (권장 구조, 하네스 필수 범위 아님)
├── tests/ ────────────── 테스트 (권장 구조, 하네스 필수 범위 아님)
└── pyproject.toml ────── 의존성 (권장 구조, 하네스 필수 범위 아님)
```

### opt-in 활성화

```
프로젝트 루트에 `.harness.yml`이 있어야 하네스 훅이 동작함.
없으면 → 하네스 훅은 no-op (체크리스트·백업 등 기존 글로벌 훅은 그대로 동작)
```

> 기존 글로벌 훅 중 wiki-index-guard.sh, graphify-reminder.sh도
> Phase 0에서 `.harness.yml` opt-in 검사 로직을 추가한다.
> 즉, opt-in하지 않은 프로젝트에서는 이 두 훅도 no-op이 된다.

```yaml
# .harness.yml 예시
harness: true
features:
  wiki: true           # index.md, log.md 체계
  doc_templates: true   # YAML 프론트매터 강제
  code_doc_sync: true   # 코드↔문서 리마인더
  graphify: true        # GRAPH_REPORT.md 리마인더

# 메타데이터 정책 (doc_templates 세부 설정)
# Stage 1 기본값: 둘 다 false (신규 문서만 차단, 기존 문서 통과)
# Stage 2: warn_metadata: true (기존 문서 Edit 시 경고)
# Stage 3: strict_metadata: true (기존 문서 Edit 시 차단)
warn_metadata: false
strict_metadata: false
```

> **현재 구현 상태**: 훅은 `.harness.yml` 존재 여부만 검사하며, 개별 `features` 플래그는 참조하지 않는다.
> 즉, `.harness.yml`이 있으면 모든 하네스 훅이 동작한다. features별 세분화 제어는 향후 구현 예정.

> 왜 opt-in인가: 훅이 글로벌(~/.claude/settings.json)에 등록되므로, 모든 프로젝트에 적용됨.
> OneDrive 아래 다른 문서 작업까지 막는 오탐 방지를 위해, 프로젝트가 명시적으로 선택해야 함.

### 작업 중 (훅이 자동 강제 — .harness.yml이 있는 프로젝트만)

```
문서 생성 시:
  ① 양식 검증 훅 → 필수 필드(§3.1 참조: title, type, status, created) 없으면 차단 (신규 문서만)
  ② index.md 훅 → 미등록이면 경고 (차단 아님 — lint에서 최종 검증)

코드 수정 시:
  ③ 관련 문서 리마인더 → "docs/auth-design.md도 확인하세요"
  ④ graphify 리마인더 → GRAPH_REPORT.md 없으면 경고 (이미 구현됨)

문서 수정 시:
  ⑤ 관련 코드 리마인더 → "src/auth.py도 확인하세요"
```

---

## 3. 문서 템플릿 체계

### 3.1 공통 메타데이터 (모든 문서 상단 필수)

```yaml
---
title: 문서 제목
type: design | decision | ops | audit | research
status: (타입별 상태 모델 — 아래 참조)
created: YYYY-MM-DD
updated: YYYY-MM-DD
related_code:        # 이 문서와 관련된 코드 파일 (repo-relative 경로)
  - src/auth.py
  - src/login.py
related_docs:        # 이 문서와 관련된 다른 문서
  - design/auth-flow.md
superseded_by:       # status가 superseded일 때만 — 대체 문서 경로
---
```

### 3.1.1 타입별 status 모델

```
일반 문서 (design, ops, audit, research):
  draft → active → stale → archived
                  → superseded (→ superseded_by 필수)

결정 문서 (decision):
  proposed → accepted
           → rejected
           → superseded (→ superseded_by 필수)
```

- `type` — 문서 종류. 현재 훅은 필드 존재 여부를 확인하며, 타입별 의미 검증은 향후 확장 대상
- `status` — 현재 상태. 타입에 따라 허용 값이 다름
- `superseded_by` — status가 superseded일 때 필수. 대체한 새 문서 경로
- `related_code` — 코드↔문서 동기화의 핵심. YAML 파서가 이 필드를 읽음
- `related_docs` — 교차 참조. 위키 체계의 핵심

### 3.2 설계 문서 (design)

> 용도: "왜 이렇게 만들었나, 어떻게 동작하나"
> 기존 예시: agent-architecture.md, citizen_agent_redesign.md

```markdown
---
title:
type: design
status: draft
created:
updated:
related_code: []
related_docs: []
---

# [제목]

## 1. 문제 정의
왜 이걸 만들어야 하는가. 현재 구조의 한계.

## 2. 설계
어떻게 동작하는가. 다이어그램, 표, 흐름도 포함.

## 3. 대안 검토
다른 방법은 왜 안 되는가. 비교표 권장.

## 4. 미결정 사항
아직 정해지지 않은 것. 결정 기한이 있으면 명시.
```

### 3.3 결정 기록 (decision)

> 용도: "이걸 왜 채택/기각했나" — ADR(Architecture Decision Record) 패턴
> 기존 예시: browser-tool-sns-crawling.md

```markdown
---
title:
type: decision
status: proposed | accepted | rejected | superseded
created:
updated:
related_code: []
related_docs: []
superseded_by:       # superseded일 때만
---

# [제목]

## 배경
왜 이 결정이 필요했나.

## 결론
채택/기각 + 한 줄 요약.

## 사유
구체적 근거. 번호 매겨서 나열.

## 대안
검토했지만 선택하지 않은 것 + 왜 안 되는지.
```

### 3.4 인프라/운영 (ops)

> 용도: "어떻게 돌리나, 어떻게 배포하나"
> 기존 예시: deployment.md, ec2-claude-setup.md

```markdown
---
title:
type: ops
status: active
created:
updated:
related_code: []
related_docs: []
---

# [제목]

## 환경
서버, 포트, 경로 등. 표로 정리.

## 절차
단계별 실행 방법. 복사-붙여넣기 가능하게.

## 트러블슈팅
자주 발생하는 문제 + 해결법.
```

### 3.5 감사/검증 (audit)

> 용도: "코드가 설계문서와 일치하는가"
> 기존 예시: simulation_structure_audit.md

```markdown
---
title:
type: audit
status: active
created:
updated:
related_code: []
related_docs: []
---

# [제목]

## 대상
감사 대상 파일/모듈.

## 기준
어떤 설계문서/명세와 대조했는가.

## 결과
적합도(%), 불일치 항목. 표로 정리.

## 조치 필요
수정해야 할 것. 우선순위 포함.
```

### 3.6 조사/분석 (research)

> 용도: "조사 결과, 분석 결과"
> 기존 예시: gap-analysis, research 문서들

```markdown
---
title:
type: research
status: active
created:
updated:
related_code: []
related_docs: []
---

# [제목]

## 목적
무엇을 알아보려 했나.

## 방법
어떻게 조사했나. 출처 명시.

## 결과
핵심 발견 사항. 데이터/수치 포함.

## 시사점
이 결과가 프로젝트에 미치는 영향. 다음 행동 제안.
```

---

## 4. 훅 체계

### 4.1 기존 훅 (Phase 0에서 수정 완료)

| 훅 | 도입 전 동작 | 변경 결과 (현재) |
|---|---|---|
| `wiki-index-guard.sh` | index.md 미등록 → 차단 | → **경고로 완화** + `.harness.yml` opt-in 추가. lint에서 최종 검출 |
| `graphify-reminder.sh` | GRAPH_REPORT.md 없으면 경고 | → `.harness.yml` opt-in 추가 (opt-in 없으면 no-op) |

> 왜 경고로 바꿨나: 신규 문서 생성 시 index.md에 죽은 링크를 먼저 넣어야 하는 UX 문제.
> 생성은 허용하되, `/project-structure lint`에서 누락을 잡는 게 더 실용적.

### 4.2 Phase 1에서 추가된 훅

#### (a) `doc-template-guard.sh` — 문서 양식 검증

```
트리거: docs/ 내 .md 파일 Write (신규 생성) + Edit (기존 수정)
동작:
  Write(신규): 메타데이터(---) 없으면 → 차단 (Stage 1부터)
  Edit(기존): 메타데이터 없으면 → Stage 1은 통과, Stage 2는 경고, Stage 3은 차단
  필수 필드: §3.1 공통 메타데이터의 title, type, status, created (정의는 한 곳에서 관리)
강도: Write=Hard Block, Edit=Stage별 차등 (통과→경고→차단)
예외: index.md, log.md, HISTORY.md, templates/ 하위 파일
적용 범위: 코드 프로젝트의 docs/만. 지식 폴더는 기존 TEMPLATE.md 유지
```

#### (b) `code-doc-sync.sh` — 코드↔문서 양방향 리마인더

```
전제: .harness.yml이 있는 프로젝트에서만 동작
트리거: 모든 Edit (코드 파일 + docs/ 파일)

동작 방식: 역색인 + Python stdlib 프론트매터 파싱

  1단계 — 역색인 조회:
    docs/.harness-index.json에서 코드↔문서 매핑을 읽음
    (역색인이 없으면 코드/문서 양쪽 모두 경고만 출력하고 종료 — 프론트매터 파싱까지 도달하지 않음)
    (→ "/project-structure reindex 실행 권장")

  코드 파일 수정 시:
    → 역색인(code_to_docs)에서 해당 코드 경로를 조회
    → 매핑된 문서가 있으면 리마인더 출력
    → 경로는 repo-relative 정규화 (Windows \/POSIX / 통일)

  문서 파일 수정 시:
    → Python으로 프론트매터 --- 블록 내의 related_code 키만 구조적 파싱
    → related_docs 등 다른 키의 리스트 항목을 오탐하지 않음
    → 나열된 코드 파일 리마인더 출력

강도: 리마인더 (Soft Warning — exit 0)
```

#### (c) 역색인 `docs/.harness-index.json`

```
/project-structure reindex 명령으로 생성/갱신

구조:
{
  "code_to_docs": {
    "src/auth.py": ["docs/design/auth-flow.md"],
    "src/login.py": ["docs/design/auth-flow.md", "docs/ops/deploy.md"]
  },
  "doc_to_code": {
    "docs/design/auth-flow.md": {
      "code": ["src/auth.py", "src/login.py"],
      "mtime": 1712928000
    }
  },
  "last_indexed": "2026-04-12T10:00:00"
}

→ (향후 구현) 훅에서 doc_to_code[doc_path].mtime != current_doc_mtime 비교로 stale 판정
→ 현재 훅은 역색인 존재 여부 + 매핑 조회만 수행. mtime 비교는 미구현

생성 방식:
  - docs/ 내 모든 .md에서 --- 사이 프론트매터를 추출
  - Python stdlib 기반 경량 파서 사용 (PyYAML 의존성 없음)
    → key: value, key:\n  - item 수준만 파싱 (복잡한 YAML 불필요)
    → import yaml 실패 시에도 동작
  - related_code 필드에서 경로를 추출
  - repo-relative 경로로 정규화 (../src/auth.py → src/auth.py, \ → /)
  - 양방향 매핑 생성

신선도 관리 (향후 구현 예정):
  - 설계: 각 문서의 mtime을 역색인에 함께 기록
  - 설계: 훅에서 indexed_mtime != current_mtime 이면 stale 경고 출력
  - last_indexed는 표시용 메타데이터 (stale 판정에는 사용하지 않음)
  - /project-structure reindex로 갱신
  - 현재 상태: 역색인 스키마에 mtime 필드 포함, 훅에서의 비교 로직은 미구현
```

> 왜 grep이 아닌가: grep은 본문 예시 코드, 백업 파일, 중복 파일명에 오탐.
> Windows `\` vs POSIX `/` 경로 차이, 파일 이동/이름 변경에도 약함.
> 프론트매터만 정확히 읽고, 정규화된 경로로 비교해야 신뢰성 확보.
>
> 왜 PyYAML 없이: 훅/스킬이 외부 패키지 설치 없이 동작해야 함.
> 프론트매터는 key: value + list 수준이라 stdlib(re + 문자열 처리)으로 충분.

### 4.3 훅 연동 전체 흐름

```
전제:
  - .harness.yml opt-in 대상: doc-template-guard, wiki-index-guard, code-doc-sync, graphify-reminder
  - 기존 글로벌 정책 (opt-in 무관): block-write-docs, doc-checklist-guard, dev-checklist-guard, auto-backup, venv-guard
  - 아래 흐름은 문서 하네스 관련 훅 위주로 표시. 실제로는 글로벌 훅(dev-checklist-guard 등)도 함께 실행됨

에이전트가 docs/design/new-feature.md를 Write로 생성:

  block-write-docs.sh → 기존 파일이면 차단 (통과: 신규) [글로벌]
  doc-template-guard.sh → 메타데이터 없으면 차단 (신규 Write) [opt-in]
  wiki-index-guard.sh → index.md 미등록이면 경고 (차단 아님) [opt-in]
  doc-checklist-guard.sh → 체크리스트 확인 [글로벌]

  → block-write-docs + doc-template-guard + doc-checklist-guard 통과해야 문서 생성 가능
  → wiki-index-guard는 경고만 — lint에서 최종 검증

에이전트가 기존 docs/design/auth.md를 Edit:

  auto-backup.sh → 백업 생성 [글로벌]
  doc-checklist-guard.sh → 체크리스트 확인 [글로벌]
  doc-template-guard.sh → 프론트매터 없으면 Stage별 차등 (통과→경고→차단) [opt-in]

에이전트가 src/auth.py를 Edit:

  auto-backup.sh → 백업 생성 [글로벌]
  dev-checklist-guard.sh → 체크리스트 확인 [글로벌]
  code-doc-sync.sh → 역색인 조회 → "관련 문서 확인하세요" 리마인더 [opt-in]
  graphify-reminder.sh → GRAPH_REPORT.md 없으면 경고 [opt-in]
```

---

## 5. 코드↔문서 양방향 동기화

### 5.1 매핑 방식: `related_code` 필드

```yaml
# docs/design/auth-flow.md 상단
---
title: 인증 흐름 설계
type: design
related_code:
  - src/auth.py
  - src/login.py
  - src/middleware/session.py
---
```

- 문서 상단의 `related_code`에 관련 코드 파일 경로를 나열 (repo-relative)
- `/project-structure reindex`가 역색인(`docs/.harness-index.json`)을 생성
- 훅이 역색인을 조회해서 리마인더 발생 (grep 아님 — YAML 파싱 기반)
- **단방향 등록, 양방향 효과**: 문서에만 등록하면 코드→문서, 문서→코드 모두 작동

### 5.2 왜 이 방식인가

| 방식 | 장점 | 단점 | 판정 |
|------|------|------|------|
| 코드에 주석으로 문서 링크 | 코드에서 바로 확인 | 코드 오염, 유지보수 부담 | ❌ |
| 디렉토리 컨벤션 (src/auth/ → docs/auth.md) | 자동 추론 | 1:1 매핑 한계, 유연성 없음 | ❌ |
| **문서 메타데이터 (related_code) + 역색인** | 코드 무오염, 유연한 N:N 매핑, YAML 파싱으로 정확 | 문서 작성 시 수동 등록, reindex 필요 | **✅ 채택** |

### 5.3 마이그레이션 전략 (3단계 정책)

```
Stage 1 — 신규 문서만 강제 (즉시)
  ├── 새로 생성하는 문서: YAML 프론트매터 필수 (훅이 차단)
  ├── 기존 문서 수정: 프론트매터 없어도 통과 (리마인더만)
  └── 기존 문서 열람: 아무 제약 없음

Stage 2 — 기존 문서 수정 시 경고 (마이그레이션 중)
  ├── 기존 문서 Edit 시: "프론트매터가 없습니다, 추가를 권장합니다" 경고
  ├── 자주 수정되는 문서부터 자연스럽게 메타데이터 추가
  └── /project-structure lint로 미적용 문서 수 추적

Stage 3 — 전체 강제 (마이그레이션 완료 후)
  ├── 모든 문서에 프론트매터 필수 (hard block 전환)
  ├── 전환 기준: lint에서 미적용 문서 0건 확인 후
  └── .harness.yml에 strict_metadata: true 추가로 활성화
```

> 핵심: Stage 1→2→3 전환은 자동이 아니라 프로젝트 소유자가 판단.
> docs/는 이미 존재하나 index/log와 프론트매터가 없으므로, 신규 문서만 강제하고 기존 문서는 점진 마이그레이션.

---

## 6. 위키 + 그래피파이 통합

### 6.1 위키 체계 (docs/ 구조화)

```
docs/
├── index.md      ← 전체 문서 인덱스 (카테고리별)
├── log.md        ← 변경 기록 (append-only, 최신이 위)
├── templates/    ← 양식 모음 (참조용)
├── design/       ← 설계 문서
├── decisions/    ← 결정 기록
├── infra/        ← 운영/배포
├── audit/        ← 감사/검증
└── research/     ← 조사/분석
```

- `index.md` — 에이전트가 프로젝트 진입 시 가장 먼저 읽는 파일
- `log.md` — 문서 변경 이력 추적
- 교차 참조 — 문서 간 `related_docs`로 연결

### 6.2 그래피파이 (코드 구조화)

```
graphify-out/
├── GRAPH_REPORT.md  ← 에이전트가 코드 구조 파악용으로 읽음
├── graph.json       ← 프로그래밍 방식 접근
└── graph.html       ← 시각적 확인
```

- `/graphify .` 스킬로 생성
- 코드 구조 변경 시 `/graphify . --update`로 갱신
- `rules/graphify.md`가 리마인더 규칙 정의

### 6.3 통합: 에이전트 진입 흐름

```
1. CLAUDE.md 읽음 → "이 프로젝트가 뭔지" 파악
2. docs/index.md 읽음 → "문서가 뭐가 있는지" 파악
3. graphify-out/GRAPH_REPORT.md 읽음 → "코드 구조가 어떤지" 파악
4. 작업 시작 → 훅이 품질 강제
```

### 6.4 통합 지식 그래프 시각화 (독창적 확장)

> 상세 설계: [triple_layer_knowledge_graph.md](triple_layer_knowledge_graph.md) 참조

기존 도구들은 문서↔문서(Obsidian) 또는 코드↔코드(CodeGraph)만 시각화한다.
우리 시스템은 Graphify를 확장하여 **통합 지식 그래프**를 만든다.

```
Layer A: 문서↔문서  ← /graphify docs/ (related_docs 프론트매터 기반)
Layer B: 코드↔코드  ← /graphify src/ (import/call 분석, 기존 기능)
Layer C: 문서↔코드  ← /graphify . --cross-ref (related_code + 역색인 기반)
```

```
명령어:
  /graphify docs/            # 문서 그래프만
  /graphify src/             # 코드 그래프만 (기존)
  /graphify . --cross-ref    # 통합 지식 그래프

출력:
  graphify-out/graph.html    ← 노드 타입별 색상/모양 구분
  graphify-out/graph.json    ← 프로그래밍 접근
  graphify-out/GRAPH_REPORT.md ← 커버리지 분석 포함
    → "문서 없는 코드 모듈 N개" / "코드 삭제된 stale 문서 N개"
```

> 조사 범위 내에서는 문서↔코드 통합 그래프를 직접 제공하는 도구를 확인하지 못했다 (2026-04-12 기준).
> 데이터 소스: related_code 프론트매터 + .harness-index.json 역색인 (이미 설계됨).

---

## 7. 디렉토리 관리 스킬

### 7.1 스킬명: `/project-structure`

### 7.2 기능

#### (a) 진단 (audit)
```
/project-structure audit

출력:
  ✅ pyproject.toml — 있음
  ❌ CLAUDE.md — 없음 (생성 권장)
  ❌ docs/index.md — 없음 (위키 체계 미도입)
  ❌ graphify-out/ — 없음 (/graphify . 실행 권장)
  ⚠️  루트에 .py 파일 15개 — src/ 이동 권장
  ⚠️  .mypy_cache/ — .gitignore에 추가 권장
```

#### (b) 초기화 (init)
```
/project-structure init

생성:
  .harness.yml       ← opt-in 활성화 (기본 features 포함)
  docs/index.md      ← 빈 인덱스
  docs/log.md        ← 빈 로그
  docs/templates/    ← 5종 템플릿 복사
  CLAUDE.md          ← 프로젝트 소개 스켈레톤
```

#### (c) 위키 린트 (lint)
```
/project-structure lint

결과:
  고아 문서 2건 — index.md에 없는 파일
  깨진 링크 1건 — related_docs에 없는 파일 참조
  구식 문서 5건 — updated가 3개월 이상 지난 문서
  메타데이터 누락 8건 — YAML 프론트매터 없는 문서
```

### 7.3 최소 필수 구조 (모든 프로젝트 공통)

> 디렉토리 구조 표준화(src/ 레이아웃 등)는 이 설계안 범위 밖.
> 별도 리팩터링 프로젝트로 분리해야 함 — 문서 하네스와 묶으면 실패 확률 상승.

```
project-root/
├── .harness.yml         # opt-in 활성화 파일
├── CLAUDE.md            # AI 에이전트 지침
├── docs/                # 문서 (위키 체계)
│   ├── index.md
│   ├── log.md
│   └── templates/       # 양식 (init 시 복사)
└── graphify-out/        # 코드 그래프 (/graphify로 생성)
```

> `/project-structure audit`은 이 최소 구조가 갖춰졌는지만 검사.
> src/ 레이아웃, tests/ 구조 등 코드 디렉토리 관리는 향후 별도 설계.

---

## 8. 구현 로드맵

### Phase 0: Audit-Only — ✅ 스모크 테스트 완료 (2026-04-12)

> 훅 설계에서 가장 큰 리스크는 오탐(잘못된 차단). 먼저 관측하고 데이터를 모은 뒤 차단 결정.
> 2026-04-12 당일 구현 + 테스트 완료. 원래 설계의 "1주일 관측"은 생략하고 Phase 1로 진행함.

| # | 구현 | 목적 | 상태 |
|---|------|------|------|
| 0-1 | 기존 훅에 `.harness.yml` opt-in 검사 추가: `wiki-index-guard`는 차단→경고 전환, `graphify-reminder`는 경고 유지(이미 exit 0) | opt-in 없으면 no-op | ✅ 완료 |
| 0-2 | 샘플 프로젝트 1개에 `.harness.yml` + `docs/index.md` 배치 | opt-in 동작 확인 | ✅ 완료 |
| 0-3 | dry-run 로그 수집 | 어떤 파일에서 어떤 훅이 트리거되는지 기록 | ✅ 완료 |
| 0-4 | 우회 절차 문서화 | 훅이 잘못 차단할 때 빠른 우회 방법 (.harness.yml 삭제, 예외 추가) | ✅ 완료 |

### Phase 1: 핵심 훅 + 템플릿 — ✅ 완료 (2026-04-12)

| # | 구현 | 종류 | 강도 | 상태 |
|---|------|------|------|------|
| 1 | `doc-template-guard.sh` — 문서 양식 검증 훅 | 훅 | 차단 (신규만) | ✅ 완료 |
| 2 | `code-doc-sync.sh` — 코드↔문서 리마인더 훅 | 훅 | 경고 | ✅ 완료 |
| 3 | 문서 템플릿 5종 파일 생성 | 템플릿 | — | ✅ 완료 |
| 4 | settings.json에 새 훅 등록 | 설정 | — | ✅ 완료 |

### Phase 2: 스킬 + 위키 도입 — ✅ 완료 (2026-04-12)

| # | 구현 | 종류 | 상태 |
|---|------|------|------|
| 6 | `/project-structure` 스킬 생성 (audit/init/lint/reindex) | 스킬 | ✅ 완료 |
| 7 | PAA: index 기반 opt-in 도입 (.harness.yml + docs/index.md). election_simulator: index/log까지 도입 | 적용 | ✅ 완료 |
| 8 | CLAUDE.md 미보유 프로젝트에 생성 (election_simulator, candidate_orchestra) | 적용 | ✅ 완료 |

### Phase 3: 점진적 마이그레이션 — ✅ 완료 (2026-04-13)

| # | 구현 | 종류 | 상태 |
|---|------|------|------|
| 9-1 | PAA 62개 문서에 프론트매터 자동 삽입 (migrate_frontmatter.py) + 역색인 생성 (60 docs, 66 code keys) | 마이그레이션 | ✅ 완료 (2026-04-12) |
| 9-2 | election_simulator 72개 문서에 프론트매터 자동 삽입 (migrate_frontmatter.py) + 역색인 생성 (47 docs, 61 code keys) | 마이그레이션 | ✅ 완료 (2026-04-13) |
| 10 | lint 미적용 문서 0건 달성 — PAA 62/62, election_simulator 72/72 | 정책 전환 | ✅ 완료 (Stage 3 전환 가능) |

### Phase 4: 통합 지식 그래프 시각화 (3-Layer)

> 상세 설계: [triple_layer_knowledge_graph.md](triple_layer_knowledge_graph.md)

| # | 구현 | 종류 | 상태 |
|---|------|------|------|
| 11 | `/graphify docs/` — 문서↔문서 그래프 생성 (Layer A) | 스킬 확장 | ✅ 완료 (2026-04-13) — `--cross-ref` 시 프론트매터 `related_docs` 파싱으로 Layer A 엣지 생성 |
| 12 | `/graphify . --cross-ref` — 문서↔코드 통합 그래프 (Layer C) | 스킬 확장 | ✅ 완료 (2026-04-13) — Step 3.5에서 프론트매터 `related_code` + 역색인 파싱, 기존 AST/시맨틱 그래프에 머지 |
| 13 | GRAPH_REPORT.md에 문서↔코드 커버리지 분석 섹션 추가 | 리포트 | ✅ 완료 (2026-04-13) — Step 5.5에서 커버리지 %, 미문서화 코드, stale 참조 자동 보고 |

> ⚠️ 디렉토리 구조 표준화(src/ 레이아웃 등)는 이 로드맵에서 제외.
> 별도 리팩터링 프로젝트로 진행 — 문서 하네스와 묶지 않음.

### 적용 범위 주의

```
✅ .harness.yml이 있는 프로젝트만
   → opt-in한 프로젝트에만 문서 하네스 훅 적용
   → .harness.yml이 없으면 체크리스트·백업 등 opt-in 무관한 기존 글로벌 훅만 동작

❌ 지식 폴더 (문서/지식/)
   → .harness.yml 두지 않음 — 기존 TEMPLATE.md + research-knowledge 스킬 유지
   → related_code 불필요 (코드가 없으므로)
   → 위키 체계(index.md, log.md)는 이미 도입됨

⚠️ 신규 프로젝트
   → /project-structure init 시 .harness.yml 자동 생성
   → 기존 프로젝트는 수동으로 .harness.yml 추가 (프로젝트 소유자 판단)
```

---

## 9. 용어 사전

| 용어 | 쉬운 설명 |
|------|----------|
| **하네스(Harness)** | 자동으로 품질을 잡아주는 시스템. 공장의 컨베이어 벨트+센서 같은 것 |
| **훅(Hook)** | 특정 동작 전/후에 자동 실행되는 검사. 문 앞의 보안 검색대 같은 것 |
| **스킬(Skill)** | Claude Code에서 `/명령어`로 호출하는 자동화 기능 |
| **규칙(Rule)** | 에이전트가 따라야 할 지침. 가이드라인 (강제 아님) |
| **ADR** | Architecture Decision Record — 왜 이런 결정을 했는지 기록하는 양식 |
| **메타데이터** | 문서 정보를 요약한 데이터. 제목, 종류, 관련 코드 등 |
| **교차 참조** | 문서끼리 서로 링크로 연결하는 것. 위키처럼 |
| **src/ 레이아웃** | 소스코드를 src/ 폴더 안에 넣는 표준 구조 |
| **YAML 프론트매터** | 문서 맨 위에 `---`로 감싸서 넣는 메타데이터 영역 |
| **위키 린트** | 문서 체계가 올바른지 자동 검사하는 것 |
| **.harness.yml** | 프로젝트 루트에 두는 opt-in 파일. 이 파일이 있어야 하네스 훅이 동작 |
| **역색인(Reverse Index)** | "이 코드 파일 → 어떤 문서가 참조하나"를 빠르게 찾는 미리 만든 목록 |
| **dry-run** | 실제 차단 없이 "차단했을 것" 로그만 남기는 테스트 모드 |
| **opt-in** | 사용자가 명시적으로 선택해야 활성화되는 방식. 반대는 opt-out |

---

## 관련 문서

- [메모리 3계층 아키텍처](memory_architecture.md) — CLAUDE.md + rules/ → memory/ → docs/ 체계
- [AI 에이전트 지식 관리 도구](ai_agent_knowledge_tools_2026.md) — Graphify, 위키 도구 조사 결과
- [하네스 딥다이브](harness_deep_dive.md) — 하네스 엔지니어링 패턴 분석
