# 외부 리서치 의무 규칙 (글로벌)

> 작성: 2026-05-02 | 강도: **글로벌 강제** (모든 작업·모든 프로젝트 적용)
> 근거: 사용자 명시 요청 (2026-05-02) + 외부 리서치 1회 선행 (Phase D0, 출처 §6 참조)

---

## 핵심 원칙

**판단을 위해 자체 지식 (training data) 에만 의존하지 말 것**. 외부 사실·통계·문법·공식 문서 인용 또는 자기 지식만으로 판단 불가능한 영역에 진입할 때는 **외부 리서치 후 출처 인용** 의무.

추측·환각 차단이 목적. 출처 없는 권위적 단언은 금지.

---

## 1. 의무 조건 (다음 중 1건이라도 해당 시 의무)

- 외부 사실·통계·시장 정보·뉴스 인용 필요
- 라이브러리·프레임워크·도구의 동작·옵션·버전 사양 인용
- 공식 문서·표준·규격·논문 인용
- 모범 사례·업계 패턴·디자인 결정 근거 인용
- 자기 지식 (training data) 의 신뢰도가 낮거나 cutoff 이후 변경 가능성 있는 사실
- 사용자가 "찾아봐", "리서치해", "근거 가져와", "왜 그런지 외부 자료로 확인해" 등 명시 요청

## 2. 의무 도구 (1순위 → 보조 순)

1. **`WebSearch`** (1순위, Claude 내장, 빠름) — 광범위 키워드 검색, 최신 정보
2. **`WebFetch`** (보조) — 1순위 결과 중 신뢰도 부족 시 특정 URL 깊이 분석 또는 사용자가 URL 직접 명시 시
3. **③ 외부 CLI (Codex / Gemini)** — 코드 리뷰·다른 모델 시각 한정 (이미 `/feedback` 으로 운영 중)
4. **`/research-knowledge` 스킬** — 한 번 검색 후 재사용 가치 있는 장기 지식 적재 시 (예: 라이브러리 사용법, 도메인 개념)

## 3. 출력 형식 (강제)

외부 사실 인용 시 **출처 명시 필수**. 형식:

- 출처 URL 또는 문서명·논문 제목
- 발행일·버전 (가능 시)
- **핵심 인용 1~2줄** (paraphrase 가 아닌 직접 인용 권장)
- 추측·"아마도"·"보통"·"일반적으로" 등 표현 금지

예시:
```
**근거**: [Salesforce Engineering — "Grounding Enterprise AI"](https://engineering.salesforce.com/...) (2025).
인용: "engineered citation architecture that allows users to verify AI-generated responses against original sources to reduce hallucination risk"
```

## 4. 예외 (외부 리서치 면제)

다음은 Read·Grep·Glob·git 명령으로 충분 (외부 리서치 무관):

- 코드 변수명·함수 시그니처·로컬 파일 경로
- 프로젝트 내부 파일 내용 (CLAUDE.md, docs/, skills/, rules/, history/)
- 이전 turn 결정 사항·메모리 기록·.todo.md·HANDOFF.md
- git history (`git log`, `git blame`)
- TaskList·TaskGet·TaskOutput
- 로컬 환경변수·시스템 상태 (`Get-ChildItem Env:` 등)

→ "내부 사실은 직접 확인, 외부 사실은 리서치 + 인용".

## 5. 메모리 연계

- 메모리 `pm-external-research-mandatory.md` (PM 한정, 강제 + 출력 형식 추가) 와 본 글로벌 규칙은 **superset 관계** — 본 규칙이 모든 작업에 적용되는 base, PM 메모리는 PM agent 에 추가 강도 부여.
- 충돌 시 본 글로벌 규칙 우선. PM 은 본 규칙 + α (출력 형식 + 가드레일 훅).

## 6. 외부 리서치 결과 (Phase D0 선행, 본 규칙 도출 근거)

본 규칙 자체가 외부 리서치 의무인 만큼 **자기 적용**으로 작성 전 외부 리서치 1회 수행. 검색 키워드: "AI agent system prompt rule require external web search citation prevent hallucination grounding 2026".

### 6-1. [Salesforce Engineering — Grounding Enterprise AI with Live Web Retrieval and Verifiable Citations](https://engineering.salesforce.com/grounding-enterprise-ai-with-live-web-retrieval-and-verifiable-citations/)
> 인용: "engineered citation architecture that allows users to verify AI-generated responses against original sources to reduce hallucination risk"

→ 본 규칙 §3 (출력 형식 = 출처 명시 강제) 의 근거.

### 6-2. [DEV Community (AWS) — Stop AI Agent Hallucinations: 4 Essential Techniques](https://dev.to/aws/stop-ai-agent-hallucinations-4-essential-techniques-2i94)
> 인용: "RAG inserts a retrieval step between the user (or agent) prompt and the generation phase, forcing the model to ground its answers in external, authoritative sources."

→ 본 규칙 §1 (의무 조건 = 외부 사실 인용) + §2 (의무 도구 = 검색 단계) 의 근거.

### 6-3. [arxiv 2509.18970 — LLM-based Agents Suffer from Hallucinations: A Survey of Taxonomy, Methods, and Directions](https://arxiv.org/html/2509.18970v1)
> 인용: "Expert knowledge serves as a robust external reference, significantly reducing the likelihood of hallucinations across various agentic operations."

→ 본 규칙 §4 (예외 범위 = 신뢰 가능한 expert knowledge 는 외부 리서치 등가) 의 근거.

### 6-4. [Microsoft Community Hub — Best Practices for Mitigating Hallucinations in LLMs](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/best-practices-for-mitigating-hallucinations-in-large-language-models-llms/4403129)
> 인용 요약: "Some guardrails implement contextual grounding, requiring the AI to cite its sources or provide only pre-approved information in sensitive domains"

→ 본 규칙 §3 (출처 명시) + 메모리 PM 가드레일 훅 (Phase 1 후) 의 근거.

---

## 적용 시점

- **즉시 발효**: 본 규칙 운영 동기화 (`~/.claude/rules/research-mandatory.md`) + `~/.claude/CLAUDE.md` 인덱스 추가 시점부터 모든 작업·모든 프로젝트.
- **PM agent 신설 시점** (Phase 1, `#015` PASS 후): PM 메모리 (`pm-external-research-mandatory.md`) 를 PM system prompt 에 흡수 + 가드레일 훅 신설.
