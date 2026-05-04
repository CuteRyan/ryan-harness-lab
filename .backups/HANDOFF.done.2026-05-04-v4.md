# HANDOFF — 2026-05-04 Day 19 turn 9 인계서 (#014 PASS + 다음 = #012 출처 보강)

> 생성: 2026-05-04 turn 9 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 19 turn 9 메인 Claude (Opus 4.7 1M)
> **양식 v2 dogfood 4건째** — 6종 데이터 (CRITICAL 섹션 생략 = 사용자 사전 조치 불필요)

---

## 마지막 상태 (어디까지 했나)

### 본 세션 (turn 8 + turn 9) 미션 = #019 + #014 PASS + Phase 1 사전 정리 1/2
- HANDOFF turn 7 → `.backups/HANDOFF.done.2026-05-04-v3.md` (소멸 정책 **13회차 검증**)
- **turn 8 (#019) PASS** — env 부재 환경 라이브 4 spawn 검증 4/4 정합 (A=opus→Opus / B=sonnet→Sonnet / C=누락→차단 / D=haiku→Haiku) → fallback C+ 효과 검증 완료, **issue#32732 종결**, Phase 1 진입 가능 최종 마킹. commit `f252915` push.
- **사용자 후속 합의 1**: Haiku 모델 = "너무 구리다" → 운영 제외 (메모리 `feedback_no_haiku.md` 신설). 운영 모델 = Opus + Sonnet 2종만, 4단 비용 배분 옵션 폐기.
- **사용자 후속 합의 2**: PM 흐름 정합 확인 (5층 위계 + 4갈래 워커 = 본 비전 그대로). 단 협의는 PM ↔ 사장 사이, 사용자는 컨펌.
- **사용자 후속 명시**: "제대로 한 번에" → agents 스테이징 도입 + pm-test 강화 + 마스터플랜 보강 통합.
- **turn 9 (#014) PASS** — agents/ 스테이징 폴더 신설 (skills·rules 와 일관 단방향 sync) + pm-test 강화 (외부 리서치 의무 + 4 요소 강제 + 면제 예외) + 마스터플랜 §2.3 5번 + §9.1 가드레일 새 행. **D-11 + D-12 결정**. commit `ba25349` push.
- **vision 메모리 보강** — turn 9 결과 (D-11/D-12 + #014 PASS) 반영 완료 (git 외부 = 추가 commit 불필요).

### 마지막 편집 파일 (turn 9)
- `Harness-engineering/agents/pm-test.md` (스테이징, 신설, ~70줄, SHA256 `C6EFD48C...05CBB`)
- `~/.claude/agents/pm-test.md` (운영 sync)
- `docs/research/agent-office-masterplan/04_masterplan.md` (§2.3 5번 + §9.1 새 행)
- `docs/history/2026-05-04.md` (Day 19 turn 9 §12 추가, 288→~360줄)
- `docs/history/index.md` (Day 19 행 turn 9 결과 갱신)
- `.todo.md` (#014 완료 + 백로그 제거)
- `~/.claude/projects/.../memory/agent-office-vision.md` (L115 다음에 #014 항목 추가, git 외부)

### Working tree (인계 시점 상태)
- **clean** — 모든 turn 9 변경 commit `ba25349` + push 완료
- 미staged 항목: 본 HANDOFF.md (신설 직후 commit 예정)

### 운영 변경 (git 추적 외)
- `~/.claude/agents/pm-test.md` (강화 결과 sync, SHA256 `C6EFD48C...05CBB`)
- `~/.claude/projects/.../memory/agent-office-vision.md` (#014 항목 추가)
- `~/.claude/projects/.../memory/feedback_no_haiku.md` (신설)
- `~/.claude/projects/.../memory/MEMORY.md` (인덱스 1줄 추가)

## 미완 작업 (지금 하다 멈춘 것)

- [ ] **#012 — 마스터플랜 출처 보강** (Phase 1 진입 전 의무, priority normal): Anthropic 블로그 (Multi-Agent Research System) URL · 게재 일자 · 실험 조건 · +90.2% 산정 기준 + aws-samples/claude-code-cookbook 리포지토리 URL · 커밋 SHA · 파일 경로 → `04_masterplan.md §8.3 비용 효과` (L650~660) 의 "출처 미보강 항목" 채우기. 외부 리서치 = WebSearch + WebFetch.
- [ ] HANDOFF turn 9 (본 파일) commit + push (다음 세션 진입 시 archive 처리)

## 다음 세션 시작 지점

### Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)

1. **사전 확인** (안전성 검증, 1분):
   - `Get-ChildItem Env:CLAUDE_CODE_SUBAGENT_MODEL` → 부재 확인 (env 영구 제거 효과 유지 확인)
   - `git status --short` → clean 확인
2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **14회차 검증**)
3. **`.todo.md` Read** — 백로그 우선순위:
   - **#012** (priority normal, 1순위 = Phase 1 사전 정리 2/2 의무)
   - #009 (Phase 1 본 공사, 큰 작업, #012 후 진입)
   - 기타 #001·#002·#003·#006·#007·#008·#016·#017 = low/normal 백로그

### 정식 절차 (체크리스트 승인 후)

4. **`/checklist`** 호출 → 작업명: "#012 마스터플랜 출처 보강 (Anthropic 블로그 + aws-samples 리포 SHA)"
5. **#012 절차**:
   - **Step 1 외부 리서치 (WebSearch)**: "Anthropic multi-agent research system Opus Sonnet 90.2%" (블로그 URL 발견)
   - **Step 2 외부 리서치 (WebFetch)**: 발견한 Anthropic 블로그 URL 깊이 분석 → 정확한 게재 일자 + 실험 조건 (데이터셋·태스크·평가 지표) + 90.2% 산정 기준 (토큰? 작업 성공률? 다른 지표?)
   - **Step 3 외부 리서치 (WebSearch)**: "aws-samples claude-code-cookbook" (깃허브 리포 URL 발견)
   - **Step 4 외부 리서치 (WebFetch)**: 발견한 깃허브 리포 → 정확한 URL · 커밋 SHA · 관련 파일 경로 (PM 패턴 / coding=Sonnet review=Opus 패턴 등)
   - **Step 5 마스터플랜 보강**: `04_masterplan.md §8.3` 의 "출처 미보강 항목" (L656~660) 4개 항목 채우기 (Anthropic URL/일자/조건/산정 / aws-samples URL/SHA/경로)
   - **Step 6 외부 리서치 결과 인용 형식**: 글로벌 `rules/research-mandatory.md` §3 형식 (URL + 발행일 + 직접 인용 1~2줄) + 본 turn 9 #014 PM 4 요소 형식 차용
   - **Step 7 정리**: `.todo.md` #012 완료 + history Day 19 turn 10 (또는 별도 일자) + index.md + commit + push
6. **#012 PASS 후** → **#009 Phase 1 본 공사 진입** (큰 작업, 여러 turn)

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — #012 PASS 후 다음 작업
- **A**: #009 Phase 1 본 공사 즉시 진입 (큰 작업, 여러 turn)
- **B**: 본 turn 부수 발견인 4단 비용 배분 (Haiku 제외 → 3단 = PM=Opus / 워커=Sonnet / 트리비얼=어떻게?) 마스터플랜 §3.2 재검토 먼저
- **C**: 백로그 작은 항목 (#016 디테일 4건 / #017 양식 메타 3건) 일괄 처리 후 #009
- **현재 기울기**: A (Phase 1 본 공사 우선, B 는 #009 도중 발생 시 흡수, C 는 별도 백로그 처리)

### 결정 2 — #012 외부 리서치 깊이
- **A**: 표면 (URL + 일자만 + 직접 인용 1~2줄)
- **B**: 깊이 (실험 조건 + 산정 기준 + 일반화 가능성 평가) — 글로벌 `rules/research-mandatory.md` §3 형식 차용
- **현재 기울기**: B (마스터플랜 §8.3 미보강 항목 자체가 "깊이 보강 의무" 명시)

### 결정 3 — Haiku 운영 제외 메모리 적용 시점
- 본 turn 9 에서 메모리 (`feedback_no_haiku.md`) 신설했으나 마스터플랜 §3.2 (8행 핵심표 中 트리비얼 작업) + #009 직책별 agent 신설 시 **Haiku 박을 자리 어떻게 처리?**
- **A**: 트리비얼 작업도 Sonnet 으로 흡수 (3단 = PM=Opus / 워커=Sonnet / 트리비얼=Sonnet, Haiku 자리 = Sonnet 으로 대체)
- **B**: 트리비얼 작업 자체를 직책 갈래에서 제거 (PM=Opus / 워커=Sonnet 2단)
- **현재 기울기**: A (단순화 + 작업 분류 변경 최소화)
- **결정 시점**: #009 진입 시점 또는 #012 中 마스터플랜 §3.2 비용 시뮬레이션 정정 시점

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유

- **#012 = Phase 1 진입 전 의무** (마스터플랜 §8.3 명시 = "출처 미보강 항목 (Phase 1 진입 전 보강 의무)") — 본 세션 turn 9 #014 PASS 로 사전 정리 1/2 완료, 남은 1건 = #012
- **외부 리서치 의무** (글로벌 `rules/research-mandatory.md`) = 본 turn 9 #014 PM 강화로 "PM 한정 강도 추가" 결정 → 마스터플랜 자체에 박힌 출처 미보강 항목도 본 글로벌 규칙에 따라 채워야 정합

### 본 세션 누적 결과 (turn 8·9)
- **issue#32732 종결** (turn 8 #019 PASS) — 5단계 검증 사이클 완주 (#011 → #013 → #015 → #018 → #019)
- **#014 PASS** (turn 9) — PM 외부 리서치 의무화 + agents 스테이징 도입
- **D-10·D-11·D-12·R-7·R-8 결정 5건 추가**
- **메모리 1건 신설** (`feedback_no_haiku.md`)
- **양식 v2 dogfood 5건 누적** (turn 5·6·7·8·9), `/checklist mode=mixed` 3건 누적

### 주의 사항
1. **CRITICAL 섹션 생략** — 본 turn 9 종료 시 사용자 사전 조치 의무 없음 (env·메인 재시작 등). 단순 #012 진입.
2. **글로벌 강제 규칙 5번째 의무 준수** (`~/.claude/CLAUDE.md` Agent Preferences) — 모든 Agent spawn `model` 명시. PM=opus / 워커=sonnet. 강제 훅 활성 (turn 7 PASS) = 위반 시 즉시 차단.
3. **글로벌 외부 리서치 의무** (`~/.claude/rules/research-mandatory.md`) 적용 중. **#012 = 본 글로벌 규칙의 가장 직접 적용 사례**.
4. **PM 외부 리서치 의무** (turn 9 #014 PASS) — pm-test 강화 = #009 정식 PM 입력. #012 이후 #009 진입 시 본 강화 사양 그대로 흡수.
5. **소멸 정책 14회차 검증** — 본 HANDOFF (turn 9) 이 다음 세션에서 `/handoff done` 처리되면 14회차.
6. **agents 스테이징 정책** (turn 9 D-11) — 새 agent 신설 시 `Harness-engineering/agents/` 작성 후 운영 sync. 운영 직접 편집 금지 (skills·rules 와 일관).

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (양식 v2 4건째 적용 케이스)
- `.todo.md` — #012 normal (1순위), #009 normal (2순위), 기타 백로그

### #012 입력 자료
- `docs/research/agent-office-masterplan/04_masterplan.md §8.3` (L650~660) — 출처 미보강 4 항목
- `docs/research/agent-office-masterplan/02_external-deep.md` — aws-samples · wshobson 인용 (동일 보강 원칙 적용)
- 외부 출처 (외부 리서치 대상):
  - "Anthropic Engineering — Multi-Agent Research System" (2025년 추정, +90.2% 출처)
  - "aws-samples/claude-code-cookbook" GitHub (coding=Sonnet, review=Opus 패턴)

### 본 세션 산출물 (turn 8·9 결과)
- `agents/pm-test.md` (스테이징, 신설 turn 9, SHA256 `C6EFD48C...05CBB`)
- `~/.claude/agents/pm-test.md` (운영 sync)
- `docs/research/agent-office-masterplan/04_masterplan.md` (§8.2 5차 실험 박스 turn 8 + §2.3 5번 + §9.1 새 행 turn 9)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md §12` (turn 8 신설 ~85줄)
- `docs/history/2026-05-04.md` (Day 19 turn 8 §11 + turn 9 §12 = 본 세션 누적 ~360줄)
- `docs/history/index.md` (Day 19 행 turn 9 까지 누적)

### 운영 자산 (#012 / #009 입력)
- `~/.claude/agents/pm-test.md` (turn 9 강화, 정식 PM 신설 시 입력)
- `~/.claude/hooks/pretooluse-agent-model-required.{sh,py}` (강제 훅 활성, turn 7 PASS)
- `~/.claude/settings.json` (env 영구 제거 + matcher `Task|Agent`)
- `~/.claude/rules/agent-spawn-model.md` (§4 활성)
- `~/.claude/rules/research-mandatory.md` (글로벌 외부 리서치 의무, #014 superset)

### 메모리 (자동 로드)
- `agent-office-vision.md` — D-11/D-12 + #014 PASS 반영 (본 turn 9 보강)
- `feedback_no_haiku.md` — Haiku 운영 제외 (본 turn 신설)
- `pm-external-research-mandatory.md` — PM 한정 강제 (글로벌 superset 위에)
- `agent-team-skill-redesign.md` — v2 위치 재조정 (#009)
- `feedback_commit_push.md` — commit + push 한 단위
- `skill-load-scope.md`, `project_deployment_target.md`

### Git
- 브랜치: main
- 마지막 커밋: `ba25349` (turn 9 #014 PASS)
- 본 HANDOFF 신설 commit (예정): `chore+docs: Day 19 turn 9 종료 인계 — HANDOFF turn 9 신설 (#012 / #009 진입 입력) + vision 메모리 #014 반영`
- push: 사용자 명시 시 (메모리 `feedback_commit_push.md` — commit + push 한 단위)

### 외부 출처 (turn 9 핵심 인용, 글로벌 `rules/research-mandatory.md` §3 형식)
- 글로벌 `rules/research-mandatory.md` §6-1·§6-2·§6-3·§6-4 (Salesforce / AWS / arxiv / MS) — 본 turn 9 #014 superset 근거
- 본 turn 9 외부 리서치 미수행 (글로벌 규칙의 4 출처 그대로 차용)
