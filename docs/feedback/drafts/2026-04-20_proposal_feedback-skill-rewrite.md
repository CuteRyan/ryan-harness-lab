---
title: /feedback 스킬 제로베이스 재설계 제안 (v4 draft)
type: proposal
status: draft
created: 2026-04-20
patched: 2026-04-21 — 과거 피드백 수렴 (4/18~4/19 누락분 4건 반영: codex_workdir 파싱·Gemini 홈 복사본·UTF-8 prefix 후순위·프로필 재측정)
author: Claude (Opus 4.7) + 주인님 결정
---

# /feedback 스킬 제로베이스 재설계 제안

## 1. 재설계 근거

### 1.1 Day 7 dogfood 실측 결과
- **Codex/Gemini 병렬 호출 6회 실패** (다양한 원인)
- **Claude Code 서브인스턴스 1회 성공** — 환경 이슈 0건, 유효 지적 7개, Codex/Gemini 미발견 4건 단독 발견 포함 (치명 1)
- 비용 $0.20 (Max 구독자는 실제 청구 아님 — 환산치)

### 1.2 실패 원인 분해 (Windows vs CLI 고유)
| 원인 | Windows 고유 | 리눅스/맥 |
|------|:-:|:-:|
| PowerShell Constrained Language `PropertySetterNotSupportedInConstrainedLanguage` | ✅ | ❌ |
| CP949 locale 한글 파일 깨짐 | ✅ | ❌ |
| Bash → `.cmd` shim 멀티라인 인자 잘림 | ✅ | ❌ |
| Codex `--output-schema` 강제로 early return | ❌ | ✅ 동일 |
| Gemini `--approval-mode plan` 대체 도구 미사용 | ❌ | ✅ 동일 |
| Gemini `--include-directories` workspace 경계 실패 | ❌ | ❔ |

**오늘 실패의 60%는 Windows 고유**. 리눅스/맥 이주해도 Codex/Gemini 고유 제약은 남음.

### 1.3 구조적 결함 (Claude Sub가 발견, 현재 스킬)
- **[치명]** Phase 6.1 "마지막 유효 JSON 채택"이 **유효 JSON 0개 케이스 미처리**
- **[높음]** `findings: []` + `error_note: ""`가 스키마 통과 → 빈 결과 정상 통과
- **[높음]** Phase 5 / Codex 스키마 / Gemini JSON **삼중 포맷 불일치** (SSOT 없음)
- **[높음]** `--output-schema <FILE>` 동작 모호 (읽기/쓰기 미명시)
- **[중간]** anti-contrarian vs anti-rubber-stamp 긴장 미해소
- **[중간]** 5규칙이 프롬프트 예산 15% 고정 소비, 계상 누락

## 2. 설계 원칙

1. **안정성 > 모델 다양성** (현 Windows 환경)
2. **단일 호출 단순화 > 복합 병렬** (3파일 복합 fragile, 1파일 분할 안정)
3. **환경 중립 > 환경 특화** (Claude Code는 메인 세션과 동일 환경)
4. **SSOT 명확화** (출력 포맷 단일화)
5. **실패 폴백 경로 명시** (모든 분기에 처리 규정)

## 3. 아키텍처 — 2-Tier

### Tier 1 (기본, 항상 호출) — Claude Code 서브인스턴스
```powershell
claude -p "<프롬프트>" \
  --permission-mode plan \
  --allowed-tools "Read,Grep,Glob" \
  --output-format json \
  --model sonnet \
  --no-session-persistence \
  --add-dir <권한루트>
```

**실측 장점** (Day 7):
- 환경 이슈 0건 (한글·Constrained Language·sandbox 전부 해결됨)
- JSON 네이티브 출력 (`result.result` 필드 = 최종 리뷰 본문)
- 비용: Max 구독으로 커버 (환산치 $0.20/회)
- 파일:줄 정확도 높음, 환각 0건
- 1회 호출 성공 (vs Codex 6회)

**단점**:
- 동일 계열 모델 편향 가능 (Codex/Gemini 같은 "다른 회사" 교차검증 없음)
- Max 구독 한도 초과 시 실제 과금 발생 가능

### Tier 2 (선택, 설계 결정 시) — Codex/Gemini
- 다른 계열 모델의 교차검증 필요한 경우에만 호출
- **필수 조건**: 1파일 + 짧은 프롬프트 + 5규칙 프리앰플 유지
- 실패 시 Claude Sub 결과만으로 판정 (1자 리뷰 폴백)

**선택 기준** (Tier 2 호출 정당화):
- 아키텍처 설계 / 기술 선택 결정
- 보안 리뷰 (다른 계열 LLM의 관점 가치)
- 공식 문서 대조가 필요한 사실 검증 (Codex `--search` 웹검색)

**일상 리뷰는 Tier 1만으로 충분**.

## 4. 호출 패턴 원칙

1. **파일당 1회 분할 호출** — N ≥ 2 파일이면 N회 병렬 호출
2. **프리앰블 5규칙 생략 금지** (Gemini rubber-stamp 방지)
3. **프롬프트 예산 계상**: 3,000자 중 5규칙 450자 + 배경·경로 300자 = 점검 포인트 실제 2,200자
4. **Rule 6 분리**: "접근 실패·맥락 부족은 추측 말고 명시" 별도 규칙화

## 5. Phase 구조 (v4 초안)

### Phase 0 — 프리플라이트
1. Claude Code 로그인 확인 (`claude /status` 금지 — 서브 호출 발생. 대신 `test -z "$ANTHROPIC_API_KEY"`로 Max 사용 확인)
2. Tier 선택 판단 (일반 리뷰 → Tier 1만, 설계 결정 → Tier 1+2)
3. Codex/Gemini 사용 시만 기존 Phase 0 (한글 경로, shim, 인코딩)
4. Tier 2 사용 시 프로젝트 루트 CLAUDE.md에서 `codex_workdir` 1회 파싱, 없으면 원본 경로 사용 (2026-04-19 C4 반영)

### Phase 1 — 컨텍스트
1. 대상 파일 경로 절대경로화
2. **권한 루트(--add-dir 대상)와 읽기 대상 명시 분리** (Codex 중간 #3 반영)
3. 슬러그 결정
4. 이전 피드백 인덱스 1개만 메모

### Phase 2 — 호출

#### Tier 1 Claude Sub (기본)
```powershell
claude -p "<프롬프트>" --permission-mode plan --allowed-tools "Read,Grep,Glob" --output-format json --model sonnet --no-session-persistence --add-dir "<권한루트>"
```

#### Tier 2 Codex (선택)
```powershell
codex.cmd exec -p feedback --skip-git-repo-check -C "<workdir>" --output-schema "<schema>" "<프롬프트>" </dev/null
```
- **인코딩 대응 우선순위**: (1) 영문 workdir + 복사본이 기본 / (2) `chcp 65001` + `[Console]::OutputEncoding` prefix는 후순위 시도 (Constrained Language에서 실패 가능, 2026-04-20 Codex 높음 #2 반영)
- 1파일 기본, 복합 시 분할

#### Tier 2 Gemini (선택)
```powershell
gemini.cmd -p "<프롬프트>" -o json --approval-mode plan --include-directories "<루트>"
```
- 대상이 `~/.claude/` 내부면 프로젝트 내 복사본으로 전달 (Gemini workspace 경계 엄격 — 2026-04-19 MVP 환각 원인)

### Phase 3 — 프롬프트 + 6규칙 (분리)
**고정 꼬리**:
```
1. no-explore: 지정 파일만 읽고 폴더 재귀 탐색 금지
2. anti-contrarian: 문제 없으면 "없음 — 근거: X"로 답 (근거 있는 없음 명시)
3. anti-rubber-stamp: 근거 없는 찬성 금지. 모든 ✅에 증거 제시
4. evidence-based: 각 지적에 파일:줄 인용 / 명령 출력 / 공식 문서 URL 중 하나. 줄 번호 애매하면 "줄 미특정" 태그 + 신뢰도 낮음 표기 (날조 방지)
5. proportional: 중요도 비례 분량. 마지막 Top 3
6. explicit-limits: 접근 실패나 맥락 부족은 추측 말고 명시 (Rule 6 별도 분리)
```

### Phase 4 — 역할 분담
- **Claude Sub** (Tier 1): 주 리뷰어, SSOT
- **Codex** (Tier 2 선택): 날카로운 사실 검증
- **Gemini** (Tier 2 선택): 넓은 방향성·장기 비용

### Phase 5 — 출력 포맷 (SSOT)
**정규 포맷** = Claude Sub의 `result.result` Markdown:
- 중요도(치명/높음/중간/낮음) 섹션
- 파일:줄, 근거
- Top 3 표

Codex/Gemini는 **동일 Markdown 포맷 요청**, 스키마 강제는 선택적.

### Phase 6 — 수집 + 합성

#### 6.1 파싱
- **Claude Sub**: `json.load(stdout).get('result')` → Markdown 바로 사용
- **Codex `--output-schema`**: stdout 마지막 유효 JSON + `error_note` 확인
  - **신규: 유효 JSON 0개 시 → stdout 원문 Markdown 폴백** (Claude Sub 치명 지적 반영)
  - **신규: `findings: []` + `error_note: ""` 동시 시 → 빈 결과 감지, Claude 재호출 또는 [유보]** (Claude Sub 높음 #2)
- **Gemini `-o json`**: `response` 키 Markdown 사용

#### 6.2 폴백 체크
- 결과 < 100자 또는 에러만 → 재시도
- 재시도 실패 → Claude Sub 결과로 단독 판정

#### 6.3 Claude 검토 (합성 전 필수)
- 기본: Claude Sub 리뷰를 **기본 근거**로 채택 (환경 이슈 0건, 환각 0건 실측)
- Tier 2 호출 시: Codex/Gemini 지적에 [반영]/[유보]/[반박] 판정, Claude Sub과의 차이 비교
- 스키마 강제 환각 탐지 유지
- 1자 리뷰 폴백: Claude Sub만 성공해도 OK (Tier 1 안정성)

#### 6.4 보고 구조
```
## Claude Sub 지적 + 판정 (주 리뷰)
## Codex 지적 + 판정 (선택)
## Gemini 지적 + 판정 (선택)
## 공통 지적 + 판정
## 반박·유보 사유 (빈 값 금지)
## 상충 지점 (판정 + 근거)
## 반영 우선순위 표 ([반영]만)
## 호출 메타 (Tier 1 비용, Tier 2 토큰)
```

### Phase 7 — 저장
- `docs/feedback/{날짜}_claude-sub_{슬러그}.md` — 주 리뷰 원문
- `docs/feedback/{날짜}_codex_{슬러그}.md` — Tier 2 호출 시만
- `docs/feedback/{날짜}_gemini_{슬러그}.md` — Tier 2 호출 시만
- `docs/feedback/{날짜}_claude_{슬러그}-종합.md` — Claude 오케스트레이터 합성 (판정 + 우선순위)

## 6. 이관 계획

### Phase A — 실험 (1주, Day 7+1 ~ Day 7+7)
- 현재 `feedback.md` 유지 (롤백 안전)
- `feedback-v4.md` draft로 병렬 작성
- 실전 5회 dogfood (Tier 1 only 3회, Tier 1+2 2회)
- 성공 기준: 실패 < 20%, 리뷰 품질 Claude Sub 대비 동등 이상

### Phase B — 점진 교체 (1주, Day 7+8 ~ Day 7+14)
- Phase A 성공 시 `feedback.md` → `.backups/feedback-v3.bak-2026-04-20.md`로 이관
- `feedback-v4.md` → `feedback.md` 승격
- 실패 시 Phase A로 복귀

### Phase C — 안정화
- Tier 1/2 구분 원칙 정착
- 실전 20회 누적 데이터로 재측정:
  - Claude Sub 비용 (Max 한도 대비)
  - Tier 2 호출 빈도 (적정 5~10% 목표)
  - 리뷰 품질 (반영 비율, 치명 지적 발견률)

## 7. 미결정 사항

| # | 사항 | 결정 필요 시점 |
|---|------|--------------|
| U1 | Max 한도 초과 시 실제 과금 체계 — Anthropic 공식 문서로 확인 | Phase A 시작 전 |
| U2 | Tier 2 선택 기준의 구체 케이스 리스트 (설계 결정 vs 일반) | Phase A 중 |
| U3 | 긴 파일 (1000줄+) 전략 — Claude Sub 분할 호출 표준 | Phase A 중 |
| U4 | Claude Sub의 `--json-schema` 플래그 활용 여부 (구조화 출력 네이티브) | Phase B 전 |
| U5 | 리뷰 아티팩트 저장 패턴 (`.omc/artifacts/` 차용 검토) — Day 5 리서치 보류분 | Phase C |
| U6 | `-p feedback` 프로필(`model_reasoning_effort=high`)의 복합 리뷰에서 실제 절감 효과 재측정. Day 7 V3에서 8.5배 절감 관찰했으나 6차(복합)에서 20k 토큰 — 짧은 프롬프트에서만 효과일 가능성 | Phase A 중 |

## 8. 리스크

### R1 — Claude Sub 장애 시 폴백 부재 (중간)
- Claude Code 2.1.113 bug 또는 Anthropic 서버 장애 시 Tier 1 실패
- Tier 2(Codex/Gemini)가 Windows에서 6회 실패 실적 → 폴백으로 약함
- **완화**: 장애 발견 시 수동 리뷰 (Claude 메인 세션이 직접 Read + 분석)

### R2 — Max 한도 초과 시 실제 과금 (낮음)
- 일반 리뷰 1건당 $0.20 수준. 월 10건이면 $2. Max 한도 초과 가능성 낮음
- 대형 파일 대량 리뷰 시 주의. `--max-budget-usd` 플래그 활용 검토

### R3 — 동일 계열 편향 (중간)
- Claude Sub이 Claude 메인 세션을 리뷰하면 "같은 성향의 blind spot" 공유 가능
- **완화**: 설계 결정에서만 Tier 2 호출, 다른 계열 교차검증

### R4 — Claude Sub 비인터랙티브 모드 `/status` 등 슬래시 커맨드 실행 (낮음)
- `claude /status`처럼 호출 시 서브 프로세스 1개 더 생성 → 비용·오염
- **완화**: 프리플라이트에서 슬래시 커맨드 금지 명시

## 9. 성공 기준 (재설계 승격 조건)

Phase A 1주 후 다음 모두 만족:
- Tier 1 Claude Sub 호출 성공률 ≥ 90%
- 리뷰 품질 (유효 지적 수, 치명 발견률) ≥ 현 v3 Codex 평균
- 비용 (Max 한도 대비) < 50%
- 주인님 체감 품질 승인

## 10. 다음 단계

1. **주인님 승인** (이 제안서 검토)
2. `feedback-v4.md` draft 작성 (Phase 0~7 상세)
3. Phase A 실험 시작 (실전 5회 dogfood)
4. Phase B 교체 결정
