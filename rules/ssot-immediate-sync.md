# SSOT 즉시 동기화 강제 규칙 (글로벌)

> 작성: 2026-05-26 | 강도: **글로벌 강제** (모든 작업·모든 프로젝트 적용)
> 근거: 누적 사고 100만원 (옛 cast_ballot 7필드 박제 폐기 + 30만원 candidate party_info 사고 + 본 세션 "인상" 격분 3회) + PM 부장 검토 (`ssot-drift-cleanup` 팀, 2026-05-26)

---

## 핵심 원칙

**주인님 SSOT 결정은 즉시 메모리 + docs/design + 코드 3축 동기화 의무**. 결정-박제 시차 0 보장.

결정만 하고 박제 안 하면 다음 사이클이 옛 SSOT 끌어 작업 → 결과 폐기 → 비용 손실. 본 규칙 위반이 누적 100만원 손실의 직접 원인.

---

## 1. 의무 조건 (다음 중 1건이라도 해당 시 의무)

- 코드 어휘 변경 (변수명·함수명·라벨·시민 LLM 노출 텍스트 갱신)
- 도구·필드·인자 추가/제거 (예: cast_ballot 7필드 → 3필드)
- 후보·정당·인구 데이터 변경 (예: 5인 → 6인 등록 보강)
- 라운드/단계 분배 결정 (예: "Full 만 R2+, 나머지 R1 단발")
- 사용자 노출 텍스트 (시민 LLM 시스템 프롬프트·도구 description) 변경
- 도구 인자 형식 / 출력 형식 갱신

## 2. 의무 동기화 3축 (모두 동일 사이클에)

1. **메모리** (`~/.claude/projects/<project>/memory/`)
   - 관련 메모리 본문 + frontmatter description + `MEMORY.md` 인덱스
   - 옛 표기 폐기 명시 + 신 SSOT 박제
   - 결정 일자 + 사장 명시 표시
2. **docs/design** (프로젝트 SSOT 문서)
   - harness.md / 디자인 문서 / 계약 문서
   - 옛 표기 deprecated 마킹 + 신 표기 추가
   - 옛 박제 (시점 스냅샷) 는 보존, 갱신만 추가
3. **코드** (`agents/` · `scripts/` · `config/` · `tests/` · `views/`)
   - 함수·상수·테스트 정합
   - 주석 갱신 (옛 SSOT 표기 정리)
   - Streamlit views/* drift 동기 (백엔드 노출 텍스트 변경 시 [[verify-via-streamlit]] 정합)

## 3. 예외 (박제 면제)

- **단발성 실험** (스모크·테스트) 결과 — 박제 폐기 가능, 메모리 갱신 X
- **임시 진단 스크립트** (`_*.py`) — 박제 X
- **시점 스냅샷** (`.bak` 파일 / `[ARCHIVED]` 메모리) — 보존, 갱신 X (감사 추적)
- **주인님 소유 영역** (`docs/thesis/*` 등 문체·구조 소유 영역) — 손 안 댐, 보고만 ([[thesis-prose-ownership]])

## 4. 위험 + 차단 메커니즘

### 위험
결정 시점 ↔ 메모리·SSOT 박제 시차 → 다음 사이클 (PM·코덱스·메인) 가 옛 SSOT 기반 판단 → 결과 폐기. 본 세션 사례:
- 2026-05-21 "인상" 폐기 결정 → 메모리·harness §8 미반영 5일간 누적 → 2026-05-26 본 세션 코덱스·내 작업 둘 다 옛 어휘 끌어씀 → 격분 3회
- 2026-05-25 cast_ballot 3필드 결정 → [[rq1-main-experiment-runner]] L28 "2필드" 잔존 → 다음 코덱스 사이클 잘못된 표기 끌어쓸 위험

### 현 차단 (수동)
본 규칙 수동 적용 (체크리스트 의무 + grep 잔존 검증).

### 향후 자동화 후보
`~/.claude/hooks/post-decision-ssot-sync.sh` — 주인님 결정 키워드 ("결정", "확정", "박제", "SSOT", "갈음", "폐기") 감지 시 자동 동기화 체크리스트 생성 (Phase 2 후보).

## 5. 절차 (결정 직후 3단계)

1. **결정 인지** — 주인님 명시 결정 시 즉시 SSOT 후보 식별 (어떤 영역에 영향?)
2. **3축 동시 Edit** — 메모리 + docs/design + 코드 한 묶음으로 처리 (분리 금지). 단 본 규칙 §3 예외 (스모크·테스트) 는 박제 면제
3. **검증** — `Grep` 옛 표기 잔존 0 + 신 SSOT 정합 확인 + 관련 테스트 (`make check`·pytest) 통과

## 6. 예시 — 본 세션 적용 결과 (2026-05-26)

- ✅ "인상" → "생각"/"투표 의향"/"스스로 정리" 신 SSOT 박제 ([[term-impression-deprecated]] 메모리 + harness.md §8 + 코드 + views/* 4축 동기화)
- ✅ cast_ballot 3필드 박제 ([[multi-week-simulation-design]] + [[rq1-main-experiment-runner]] + [[fc-tools-v3-candidate-focus]] 메모리 갱신)
- ✅ "Full 만 R2+, 나머지 R1 단발" 박제 ([[multi-week-simulation-design]] L23)
- ✅ harness.md §10.2 도구 매트릭스 코드 정합
- ❌ "발사" 표현 갈음 결정 (한 번 받았는데 메모리 박제 시차 → 같은 세션 2회 사용 사고 → [[term-no-launch-word]] 신설 박제)

## 7. 외부 리서치 근거

- [SSGM Framework — Governing Evolving Memory in LLM Agents](https://arxiv.org/html/2603.11768) (arxiv 2603.11768, 2026): "Stability and Safety Governed Memory (SSGM) Framework pairs a rapidly updatable Mutable Active Graph with an append-only Immutable Episodic Log (acting as the operational source of truth), enabling asynchronous reconciliation and periodic replay to correct drifted concepts"
- [Mastering LLM Guardrails 2026](https://orq.ai/blog/llm-guardrails): "Without source of truth validation, outputs may slowly become inaccurate or inconsistent without detection"

## 8. 출처

- **누적 사고**: 100만원 손실 패턴
  - [[term-impression-deprecated]] 격분 3회 (2026-05-24 + 2026-05-26 × 2)
  - 옛 cast_ballot 7필드 박제 폐기 (5/13 30명 페어 + 5/19 8셀 1000명 + 5/24 R2 1라운드)
  - 30만원 candidate party_info ↔ POLITICAL_CONTEXT 불일치 사고 ([[preflight-input-audit]])
- **PM 검토**: `ssot-drift-cleanup` 팀 PM 부장 (pm-reviewer) 보고 (2026-05-26)
- **사장 결정**: 2026-05-26 주인님 명시 ("메모리·SSOT 수정할 거 엄청 많은 거 같다") → 차단 메커니즘 박제 진행 OK

## 9. 관련 규칙·메모리

- [[research-mandatory]] — 외부 사실 인용 시 출처 의무 (본 규칙 §7 적용)
- [[verify-before-claim]] — 추정 단정 어휘 금지
- [[verify-via-streamlit]] — 백엔드 변경 시 views/* 동기화 의무 (§2.3 코드 축)
- [[preflight-input-audit]] — 비싼 작업 전 입력 audit 의무 (보완 규칙)
- [[term-impression-deprecated]] — 인상 폐기 박제
- [[term-no-launch-word]] — "발사" 표현 금지 박제
- [[follow-spec-no-embellish]] — 명시 스펙 외 추가 금지
