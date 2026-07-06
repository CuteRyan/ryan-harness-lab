# [부록] 외부 리서치 의무 규칙 — 근거·출처·이력

> 이 문서는 글로벌 규칙 `~/.claude/rules/research-mandatory.md`의 **근거 보관용 부록**입니다.
> 규칙 본문은 짧게 유지하고(매 세션 로드), 왜 만들었는지·출처·적용 이력은 여기에 보존합니다(필요할 때만 열람).
> 원본 작성: 2026-05-02 | 부록 분리: 2026-07-06 (하네스 다이어트)

---

## 작성 배경

- 강도: **글로벌 강제** (모든 작업·모든 프로젝트 적용)
- 근거: 사용자 명시 요청 (2026-05-02) + 외부 리서치 1회 선행 (Phase D0, 아래 출처 참조)

## 메모리 연계 (원 규칙 §5)

- 메모리 `pm-external-research-mandatory.md` (PM 한정, 강제 + 출력 형식 추가) 와 글로벌 규칙은 **superset 관계** — 글로벌 규칙이 모든 작업에 적용되는 base, PM 메모리는 PM agent 에 추가 강도 부여.
- 충돌 시 글로벌 규칙 우선. PM 은 규칙 + α (출력 형식 + 가드레일 훅).

## 외부 리서치 결과 (Phase D0 선행, 규칙 도출 근거, 원 규칙 §6)

규칙 자체가 외부 리서치 의무인 만큼 **자기 적용**으로 작성 전 외부 리서치 1회 수행. 검색 키워드: "AI agent system prompt rule require external web search citation prevent hallucination grounding 2026".

### [Salesforce Engineering — Grounding Enterprise AI with Live Web Retrieval and Verifiable Citations](https://engineering.salesforce.com/grounding-enterprise-ai-with-live-web-retrieval-and-verifiable-citations/)
> 인용: "engineered citation architecture that allows users to verify AI-generated responses against original sources to reduce hallucination risk"

→ 규칙 "출력 형식(출처 명시 강제)"의 근거.

### [DEV Community (AWS) — Stop AI Agent Hallucinations: 4 Essential Techniques](https://dev.to/aws/stop-ai-agent-hallucinations-4-essential-techniques-2i94)
> 인용: "RAG inserts a retrieval step between the user (or agent) prompt and the generation phase, forcing the model to ground its answers in external, authoritative sources."

→ 규칙 "의무 조건(외부 사실 인용)" + "의무 도구(검색 단계)"의 근거.

### [arxiv 2509.18970 — LLM-based Agents Suffer from Hallucinations: A Survey of Taxonomy, Methods, and Directions](https://arxiv.org/html/2509.18970v1)
> 인용: "Expert knowledge serves as a robust external reference, significantly reducing the likelihood of hallucinations across various agentic operations."

→ 규칙 "예외 범위(신뢰 가능한 expert knowledge 는 외부 리서치 등가)"의 근거.

### [Microsoft Community Hub — Best Practices for Mitigating Hallucinations in LLMs](https://techcommunity.microsoft.com/blog/azure-ai-foundry-blog/best-practices-for-mitigating-hallucinations-in-large-language-models-llms/4403129)
> 인용 요약: "Some guardrails implement contextual grounding, requiring the AI to cite its sources or provide only pre-approved information in sensitive domains"

→ 규칙 "출처 명시" + 메모리 PM 가드레일 훅의 근거.

## 적용 이력 (원 규칙 "적용 시점")

- **즉시 발효**: 규칙 운영 동기화 (`~/.claude/rules/research-mandatory.md`) + `~/.claude/CLAUDE.md` 인덱스 추가 시점부터 모든 작업·모든 프로젝트.
- **PM agent 신설 시점** (Phase 1, `#015` PASS 후): PM 메모리 (`pm-external-research-mandatory.md`) 를 PM system prompt 에 흡수 + 가드레일 훅 신설.
- **2026-07-06 하네스 다이어트**: 규칙 본문 95줄 → 약 30줄로 압축. 근거·출처·이력을 본 부록으로 분리 (내용 삭제 아님).
