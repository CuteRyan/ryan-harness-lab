# [부록] SSOT 즉시 동기화 규칙 — 근거·사례·출처

> 상태: 과거 규칙의 근거 기록. 글로벌 `ssot-immediate-sync.md`는 2026-07-22 제거되었으며 아래 내용은 현재 적용하지 않습니다.
> 원본 작성: 2026-05-26 | 부록 분리: 2026-07-06 (하네스 다이어트)

---

## 작성 근거

- 강도: **글로벌 강제** (모든 작업·모든 프로젝트)
- 근거: 누적 사고 100만원 (옛 cast_ballot 7필드 박제 폐기 + 30만원 candidate party_info 사고 + "인상" 격분 3회) + PM 부장 검토 (`ssot-drift-cleanup` 팀, 2026-05-26)

## 위험 + 차단 메커니즘 (원 규칙 §4)

### 위험
결정 시점 ↔ 메모리·SSOT 박제 시차 → 다음 사이클(PM·코덱스·메인)이 옛 SSOT 기반 판단 → 결과 폐기. 사례:
- 2026-05-21 "인상" 폐기 결정 → 메모리·harness §8 미반영 5일 누적 → 2026-05-26 코덱스·메인 둘 다 옛 어휘 끌어씀 → 격분 3회
- 2026-05-25 cast_ballot 3필드 결정 → [[rq1-main-experiment-runner]] L28 "2필드" 잔존 → 다음 사이클 잘못 끌어쓸 위험

### 현 차단 (수동)
규칙 수동 적용 (체크리스트 의무 + grep 잔존 검증).

### 향후 자동화 후보
`~/.claude/hooks/post-decision-ssot-sync.sh` — 결정 키워드("결정·확정·박제·SSOT·갈음·폐기") 감지 시 자동 동기화 체크리스트 생성 (Phase 2 후보).

## 예시 — 2026-05-26 적용 결과 (원 규칙 §6)

- ✅ "인상" → "생각"/"투표 의향"/"스스로 정리" 신 SSOT 박제 ([[term-impression-deprecated]] + harness.md §8 + 코드 + views/* 4축)
- ✅ cast_ballot 3필드 박제 ([[multi-week-simulation-design]] + [[rq1-main-experiment-runner]] + [[fc-tools-v3-candidate-focus]])
- ✅ "Full 만 R2+, 나머지 R1 단발" 박제 ([[multi-week-simulation-design]] L23)
- ✅ harness.md §10.2 도구 매트릭스 코드 정합
- ❌ "발사" 표현 갈음 결정 → 메모리 박제 시차로 같은 세션 2회 사용 사고 → [[term-no-launch-word]] 신설

## 외부 리서치 근거 (원 규칙 §7)

- [SSGM Framework — Governing Evolving Memory in LLM Agents](https://arxiv.org/html/2603.11768) (arxiv 2603.11768, 2026): "Stability and Safety Governed Memory (SSGM) Framework pairs a rapidly updatable Mutable Active Graph with an append-only Immutable Episodic Log (acting as the operational source of truth), enabling asynchronous reconciliation and periodic replay to correct drifted concepts"
- [Mastering LLM Guardrails 2026](https://orq.ai/blog/llm-guardrails): "Without source of truth validation, outputs may slowly become inaccurate or inconsistent without detection"

## 출처 (원 규칙 §8)

- **누적 사고**: 100만원 손실 패턴 — [[term-impression-deprecated]] 격분 3회 (2026-05-24 + 2026-05-26 ×2) / 옛 cast_ballot 7필드 박제 폐기 (5/13 30명 페어 + 5/19 8셀 1000명 + 5/24 R2) / 30만원 candidate party_info ↔ POLITICAL_CONTEXT 불일치 ([[preflight-input-audit]])
- **PM 검토**: `ssot-drift-cleanup` 팀 PM 부장 보고 (2026-05-26)
- **사장 결정**: 2026-05-26 주인님 명시 → 차단 메커니즘 박제 OK

## 관련 규칙·메모리 (원 규칙 §9)

- [[research-mandatory]] — 외부 사실 인용 출처 의무
- [[verify-before-claim]] — 추정 단정 어휘 금지
- [[verify-via-streamlit]] — 백엔드 변경 시 views/* 동기화 의무
- [[preflight-input-audit]] — 비싼 작업 전 입력 audit 의무
- [[term-impression-deprecated]] · [[term-no-launch-word]] · [[follow-spec-no-embellish]]
