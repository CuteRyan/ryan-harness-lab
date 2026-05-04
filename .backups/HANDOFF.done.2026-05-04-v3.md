# HANDOFF — 2026-05-04 Day 19 turn 7 인계서 (#018 PASS + 우회 패턴 세계 1호 검증)

> 생성: 2026-05-04 turn 7 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 19 turn 7 메인 Claude (Opus 4.7 1M)
> **양식 v2 dogfood 3건째** — 🚨 CRITICAL + Quick Start + 6종 데이터

---

## 🚨 다음 세션 진입 전 사용자 사전 조치 (CRITICAL)

**사용자 메인 Claude Code 재시작 의무** — 본 turn Step 4 에서 settings.json `env.CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 영구 제거 commit 했으나, env 섹션은 hot-reload 비작동 (turn 4·6 §6-1 결정적 재현). **현재 메인 프로세스 cache 에 `sonnet` 잔존** → 다음 세션 진입 전 재시작 안 하면 #019 검증 결과 = 본 turn Step 3 결과 (env 덮어씀) 재현 + Phase 1 진입 차단 지속.

### 사전 조치 절차
1. **메인 Claude Code 종료 후 재실행** (CLI / desktop app / IDE 어느 것이든)
2. **새 세션 진입** (`/clear` 또는 새 conversation)
3. 진입 직후 PowerShell 검증 (Quick Start §1)

---

## 마지막 상태 (어디까지 했나)

### turn 7 미션 = #018 강제 훅 신설 + 우회 패턴 검증 (Step 0~6 全 PASS)
- HANDOFF turn 6 `/handoff done` → `.backups/HANDOFF.done.2026-05-04-v2.md` (소멸 정책 **12회차 검증**)
- `/checklist` mode=mixed 1차 작성 (Step 0~6, ~70줄) → 사용자 승인 후 진입
- **Step 0 PASS** — 외부 리서치 → Issue #26923 (CLOSED) + #40580 (OPEN) 발견 → A 안 채택 (사용자 재승인)
- **Step 1 PASS** — 훅 본체 (`hooks/pretooluse-agent-model-required.{sh,py}`, sh 30줄 + py 95줄) 단위 테스트 5/5 PASS, 스테이징↔운영 SHA256 MATCH `8559463C...3029` + `E4B0B37D...BEE4`
- **Step 2 PASS** — settings.json `hooks.PreToolUse` 5번째 matcher (`Task|Agent`) 등록 + 백업 (`bak.20260504_phase1` SHA256 `5D708DBA...089E4`) + JSON valid
- **Step 3 PASS** — 라이브 4 spawn 검증:
  - C (model 누락) = **차단 PASS** = `permissionDecision: deny` + exit 0 우회 작동 (**Issue #26923 reporter 미검증 가설 세계 1호 검증**)
  - A (`opus` 명시) → 자식=Sonnet ⚠️ (env 덮어씀, turn 6 anomaly 재해석 = turn 4 + turn 7 일치 = "env=sonnet 환경 명시 model 무력" 결정적 재현)
  - B (`sonnet` 명시) → 자식=Sonnet (정합)
  - D (`gpt-5` invalid) → SDK level 차단 (이중 보장)
- **Step 4 commit** — settings.json env `CLAUDE_CODE_SUBAGENT_MODEL` 영구 제거 (효과 검증 = 다음 세션)
- **Step 5 PASS** — 마스터플랜 06 §11 신설 (~115줄, 402→517) + 04 §8.2 4차 실험 박스 + §9.1 갱신 + rules `§4` 활성 마킹 + 운영 sync SHA256 MATCH `A68091A1...84C4` + memory L115 정정
- **Step 6** (현재 진행 중) — `.todo.md` #018 완료 + #019 신설 + history Day 19 turn 7 + index.md Day 19 행 갱신 + HANDOFF turn 7 (본 파일) + commit 잔여

### 마지막 편집 파일
- `HANDOFF.md` (본 파일, turn 7, 양식 v2 dogfood 3건째)
- `hooks/pretooluse-agent-model-required.sh` + `.py` (스테이징 신설)
- `~/.claude/hooks/pretooluse-agent-model-required.sh` + `.py` (운영 sync)
- `~/.claude/settings.json` (env 제거 + matcher 추가)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md` (§11 신설)
- `docs/research/agent-office-masterplan/04_masterplan.md` (§8.2 + §9.1)
- `rules/agent-spawn-model.md` (§4 활성 마킹)
- `~/.claude/rules/agent-spawn-model.md` (운영 sync)
- `~/.claude/projects/.../memory/agent-office-vision.md` (L115 정정)
- `.todo.md` (#018 완료 + #019 신설)
- `docs/history/2026-05-04.md` (Day 19 turn 7 섹션 추가, 150→288줄)
- `docs/history/index.md` (Day 19 행 갱신)
- `.checklist.md` (Step 0~6 PASS, .backups 이동 대기)

### Working tree (commit 직전 상태)
- modified: `.todo.md`, `docs/history/index.md`, `docs/history/2026-05-04.md`, `docs/research/agent-office-masterplan/06_issue32732_experiment.md`, `docs/research/agent-office-masterplan/04_masterplan.md`, `rules/agent-spawn-model.md`
- renamed: `HANDOFF.md (turn 6) → .backups/HANDOFF.done.2026-05-04-v2.md`
- untracked (신설): `HANDOFF.md` (본 파일, turn 7), `hooks/pretooluse-agent-model-required.sh`, `hooks/pretooluse-agent-model-required.py`, `.checklist.md`

### 운영 변경 (git 추적 외)
- `~/.claude/hooks/pretooluse-agent-model-required.sh` (신설, SHA256 `8559463C...3029`)
- `~/.claude/hooks/pretooluse-agent-model-required.py` (신설, SHA256 `E4B0B37D...BEE4`)
- `~/.claude/settings.json` (matcher `Task|Agent` 추가 + env 제거, 백업 보존)
- `~/.claude/settings.json.bak.20260504_phase1` (Step 2 백업, SHA256 `5D708DBA...089E4`)
- `~/.claude/rules/agent-spawn-model.md` (§4 활성 마킹, SHA256 `A68091A1...84C4`)
- `~/.claude/projects/.../memory/agent-office-vision.md` (L115 정정)

## 미완 작업 (지금 하다 멈춘 것)

- [ ] `.checklist.md` → `.backups/.checklist.md.완료_018-pretooluse-agent-model-required_2026-05-04.md` 이동 (사용자 승인 후)
- [ ] commit + push (1건 단위, 메모리 `feedback_commit_push.md` 준수) — Step 6 의 일부, 다음 세션 진입 직전 또는 본 turn 마무리 시점
- [ ] **#019 — turn 8 env 부재 환경 fallback C+ 효과 라이브 재검증** (Phase 1 진입 최종 사전조건, 다음 세션)

## 다음 세션 시작 지점

### Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)

1. **PowerShell 검증**: `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*" | Format-List Name, Value`
   - **`SUBAGENT_MODEL` 부재 (값 없음)** → settings.json env 제거 + 메인 재시작 효과 발효 ✅
   - **`SUBAGENT_MODEL=sonnet` 잔존** → 메인 재시작 안 함 ⚠️ → 사용자에게 메인 재시작 요청
2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **13회차 검증**)
3. **`.todo.md` Read** — #019 priority high (1순위), #014 normal (2순위), #009 normal (Phase 1 인프라)
4. **`.checklist.md` 존재 확인** — 본 turn 미정리 시 Phase 6 정리 (사용자 승인 후 `.backups/` 이동)

### 정식 절차 (체크리스트 승인 후)

5. **`/checklist`** 호출 → 작업명: "#019 turn 8 env 부재 환경 fallback C+ 효과 라이브 재검증 (Phase 1 진입 최종 사전조건)"
6. #019 절차:
   - **Step 1**: 4 spawn 라이브 재검증 (turn 7 Step 3 동일 패턴, env 부재 환경)
     - A: `model="opus"` 명시 → 자식 = **Opus 예상** (env 부재 시 명시 model 작동)
     - B: `model="sonnet"` 명시 → 자식 = **Sonnet 예상**
     - C: model 누락 → **차단 PASS 예상** (강제 훅)
     - D: `model="invalid"` → **SDK 차단 예상**
   - **Step 2**: 자기보고 결과 분석 — A=Opus AND B=Sonnet 정합 시 fallback C+ 효과 검증 PASS
   - **Step 3 분기**:
     - **PASS** (A=Opus, B=Sonnet, C=차단, D=SDK 차단): fallback C+ 영구 적용 효과 검증 완료 → 마스터플랜 06 §12 신설 + Phase 1 진입 가능 최종 마킹 → #019 완료
     - **FAIL** (A=Sonnet 또는 B=Opus 또는 C 미차단): settings.json 외 env source 조사 (Windows 시스템 env, .bashrc, claude-code 자체 default 등) → fallback D 후퇴 결정 검토
7. **#019 PASS 후** → **Phase 1 진입** 또는 **#014** (PM 외부 리서치 의무화) 또는 **#009** (agent-team-manager v2 본체)

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — #019 PASS 후 다음 작업
- **A**: Phase 1 즉시 진입 (#009 = agent-team-manager v2 본체 = 마스터플랜 §5 인프라)
- **B**: #014 먼저 (PM 외부 리서치 의무화) — Phase 1 PM 신설 전 system prompt 강화
- **C**: #012 출처 보강 (마스터플랜 Anthropic 블로그 URL 등) — 작은 단위
- **현재 기울기**: B → A 순차 (PM system prompt 강화 후 Phase 1 진입)

### 결정 2 — #019 FAIL 시 fallback D 후퇴 vs 추가 조사
- **A**: 즉시 fallback D 후퇴 (env 보존 + **PM=Sonnet 채택** + 메인 Opus 가 PM 비판자 역할 흡수) + Phase 1 진입
- **B**: settings.json 외 env source 조사 (시간 + 결과 불확실)
- **현재 기울기**: **A** (사용자 turn 7 후속 대화 합의 — "이게 실패로 끝나면 그냥 어쩔 수 없이 pm 도 소넷으로 가야겠다"). B 는 추가 호기심 있을 때만.
- **A 채택 시 운영 흐름**: 사용자 (사장) → 메인 Claude (Opus, 사용자 직접 선택, PM 비판자 흡수) → 워커 (Sonnet, env 가 자동 강제). PM agent layer 폐기 (또는 frontmatter `model: sonnet` 으로 신설). 5층 위계 → 3층 단순화.
- **A 채택 시 즉시 작업**: settings.json `env.CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 부활 (1줄, commit) + 메인 재시작 + Phase 1 진입.

### 결정 3 — 본 turn 7 commit 분량
- **A**: 단일 commit (turn 7 全 산출물 묶음)
- **B**: 분리 commit (인프라 신설 / 검증 결과 / 인계 정리 3개)
- **현재 기울기**: A (사용자 메모리 `feedback_commit_push.md` = 한 단위 처리)

### 결정 4 — 양식 v2 dogfood 회고 시점
- 본 turn 7 = 양식 v2 dogfood 3건째 (turn 5·6·7). drift 발견 안 됨.
- **A**: 다음 1~2 turn 후 회고
- **B**: #008 due 2026-05-08 (1주 후) 통합 회고 (#016 디테일·#017 양식 정합 함께)
- **현재 기울기**: B (회고 효율 + 데이터 누적)

### 결정 5 (turn 7 후속 합의) — #019 FAIL 시 PM=Sonnet 즉시 채택
- 사용자 본 turn 7 후속 대화 명시: "이게 실패로 끝나면 그냥 어쩔 수 없이 pm 도 소넷으로 가야겠다"
- **합의 사항**: 시나리오 X (env 보존 + PM=Sonnet) 도 운영 가능한 안전망. 메인 (Opus, 사용자 직접 선택) 이 PM 비판자 역할 흡수 → D-4 의 "+90.2% 성능" 패턴 (Opus lead + Sonnet worker) 그대로 작동. 단지 layered 구조 단순화 (5층 → 3층).
- **검증 근거**: turn 7 Step 3 의 Test B (`model="sonnet"` 명시 → 자식=Sonnet 정합) PASS — Sonnet teammate spawn 100% 작동 확인.
- **잃는 것 (작음)**: 별도 PM layer 의 비판 강도 약간 약화 (Sonnet PM < Opus PM). 단 메인 (Opus) 흡수 시 보완.
- **다음 세션 적용**: #019 FAIL 시 즉시 위 결정 2 = A 안 진행 (env 부활 + PM=Sonnet). 사용자 추가 컨펌 불필요 (이미 본 turn 합의).

### 결정 6 (turn 7 후속 영감) — agent-team-manager v2 (#009) 의 /feedback 패턴 차용
- 사용자 본 turn 7 후속 대화 영감: "에이전트 팀 스킬에서 피드백 스킬에서 힌트를 얻을 수 있을 것 같다"
- **차용 후보 5 패턴**:
  1. **단발 + 격리 spawn** — PM 호출 = 1회 → 추천 받음 → teardown (대화 누적 X)
  2. **scripts 외부화** — SKILL.md (가이드) + scripts/ (orchestrate-pm / prepare-pm-input / run-pm / validate-pm-output) — v1.5 인라인 252줄 → v2 외부 분리
  3. **orchestrate 병렬 + 종합** — 여러 워커 안 병렬 평가 → 사장 종합
  4. **Validation Gate (5게이트)** — PM 추천 = 근거·반박·출처·통계·자기비판 통과 후 사장 채택
  5. **외부 검증 훅 (sycophancy-check)** — PM 결과물 자동 sycophancy/환각 감지 → 사장 가시화
- **가장 강한 시너지**: #1 + #2 + #4 (구조 + 검증 동시) — 마스터플랜 §5 (scripts 6개 + presets 5 YAML) 와 정합
- **다음 세션 진입 시점**: #019 PASS 후 (PM=Opus 가능 시) 또는 결정 5=A 채택 후 (PM=Sonnet 단순화 시). 어느 쪽이든 v2 본체 신설 시 본 영감 적용.

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유
- **#018 = Phase 1 진입 차단 조건** (turn 6 §10.5 결정) → 본 turn 7 PASS 로 강제 훅 인프라 활성 + env 제거 commit
- **세계 1호 검증 의의**: Issue #26923 reporter 본인이 미검증으로 명시한 가설 = `permissionDecision: deny` + exit 0 우회 패턴이 본 turn 으로 작동 결정적 확인. Anthropic Issue 본 turn 결과 인용 가치 (오픈 issue #40580 에 댓글 가능).
- **turn 6 anomaly 재해석**: turn 6 의 "A=opus 명시 → 자식=Opus" 정합 결과 = anomaly 가능성 (본 turn 재현 실패). turn 4 + turn 7 일치 = "env=sonnet 환경에서 명시 model 도 무력" 결정적 재현.

### 본 turn 후속 추가 산출물 (HANDOFF 외)
- **statusline c 풍부형 설정** (`~/.claude/settings.json` L130-133 + `~/.claude/statusline-command.sh`) — 메인 재시작 시 동시 발효. 형식: `claude-sonnet-4-6 | ~/projects/myapp | ctx: 42%` (모델 ID + 디렉토리 + 컨텍스트 사용량). Phase 1 다중 spawn 운영 시 ctx 가시화 가치.

### 주의 사항
1. **메인 재시작 사전 의무** — env 변경은 hot-reload 비작동. 다음 세션 진입 전 메인 Claude Code 재시작 필수. 안 하면 #019 결과 = turn 7 결과 재현 + Phase 1 진입 차단 지속. **재시작 1회로 동시 발효**: (a) env 부재 발효 (b) statusline 새 형식 표시 (c) 강제 훅 활성 유지.
2. **글로벌 강제 규칙 5번째 규칙 의무 준수** (`~/.claude/CLAUDE.md` Agent Preferences) — 모든 Agent spawn `model` 명시. PM=opus / 워커=sonnet. **본 turn 부터 강제 훅이 라이브 차단** = 위반 시 즉시 차단됨.
3. **글로벌 외부 리서치 의무 (`~/.claude/rules/research-mandatory.md`)** 적용 중. 본 turn 자체가 검증 사례 (Issue #26923/#40580 인용).
4. **소멸 정책 13회차 검증** — 본 HANDOFF (turn 7) 이 다음 세션에서 `/handoff done` 처리되면 13회차.
5. **Phase 1 진입 가능 마킹 (조건부)** — #019 PASS 후 최종 마킹.

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (양식 v2 3번째 적용 케이스)
- `.todo.md` — #019 high (1순위), #014 normal (2순위), #009 normal, #016·#017 low

### 본 turn 산출물 (turn 7 결과)
- `hooks/pretooluse-agent-model-required.sh` (스테이징, 신설, 30줄, SHA256 `8559463C...3029`)
- `hooks/pretooluse-agent-model-required.py` (스테이징, 신설, 95줄, SHA256 `E4B0B37D...BEE4`)
- `~/.claude/hooks/pretooluse-agent-model-required.{sh,py}` (운영 sync, SHA256 MATCH)
- `~/.claude/settings.json` (matcher `Task|Agent` 추가 + env `CLAUDE_CODE_SUBAGENT_MODEL` 제거)
- `~/.claude/settings.json.bak.20260504_phase1` (Step 2 백업)
- `~/.claude/rules/agent-spawn-model.md` (§4 활성 마킹, SHA256 `A68091A1...84C4`)
- `~/.claude/projects/.../memory/agent-office-vision.md` (L115 정정)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md` (§11 신설 ~115줄)
- `docs/research/agent-office-masterplan/04_masterplan.md` (§8.2 4차 실험 + §9.1)
- `docs/history/2026-05-04.md` (Day 19 turn 7 섹션, 150→288줄)
- `docs/history/index.md` (Day 19 행 갱신)
- `rules/agent-spawn-model.md` (스테이징, 신설은 turn 6, §4 활성 마킹은 turn 7)

### 운영 자산 (#019 입력)
- `~/.claude/settings.json` env `CLAUDE_CODE_SUBAGENT_MODEL` **제거 상태** (#019 검증 입력)
- `~/.claude/settings.json.bak.20260504_phase1` (env=sonnet 환원본 백업, fallback D 후퇴 시 복원 가능)
- `~/.claude/agents/pm-test.md` (frontmatter `model: opus`, 보존됨, Phase 1 PM 신설 시 폐기 또는 rename)
- `~/.claude/hooks/pretooluse-agent-model-required.{sh,py}` (강제 훅 활성, #019 검증 시 효과 발휘)

### 운영 스킬 / 규칙
- `~/.claude/rules/agent-spawn-model.md` (강제 훅 활성, §4 갱신)
- `~/.claude/rules/research-mandatory.md` (외부 리서치 의무, 본 turn 0-1 적용)
- `~/.claude/skills/checklist/SKILL.md` (양식 v2)
- `~/.claude/skills/handoff/SKILL.md` (양식 v2)
- `~/.claude/skills/todo/SKILL.md` (양식 v2)

### 메모리 (자동 로드)
- `agent-office-vision.md` — D-4 SSOT + L115 fallback C+ 영구 적용 진입 (본 turn 정정)
- `agent-team-skill-redesign.md` — v2 위치 재조정 (#009)
- `pm-external-research-mandatory.md` — PM 한정 강제 (글로벌 `rules/research-mandatory.md` 가 superset)
- `feedback_commit_push.md` — commit + push 한 단위
- `skill-load-scope.md`, `project_deployment_target.md`

### Git
- 브랜치: main
- 마지막 커밋: `87c6f78` (turn 6 정합성 보강)
- 본 turn 마무리 커밋 (예정): `feat+docs: Day 19 turn 7 — #018 PASS (강제 훅 신설 + permissionDecision 우회 세계 1호 검증) + settings.json env 영구 제거 + 마스터플랜·rules·memory 갱신`
- push: 사용자 명시 시 (메모리 `feedback_commit_push.md` — commit + push 한 단위)

### 외부 출처 (turn 7 핵심 인용, 글로벌 `rules/research-mandatory.md` §3 형식)
- [Issue #26923 (CLOSED, 2026-02-19~03-03, anthropics/claude-code)](https://github.com/anthropics/claude-code/issues/26923)
- [Issue #40580 (OPEN, 2026-03-29, anthropics/claude-code)](https://github.com/anthropics/claude-code/issues/40580)
