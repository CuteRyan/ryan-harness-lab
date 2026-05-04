# HANDOFF — 2026-05-04 Day 19 turn 6 인계서 (#015 PASS + 글로벌 강제 규칙 신설)

> 생성: 2026-05-04 turn 6 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 19 turn 6 메인 Claude (Opus 4.7 1M)
> **양식 v2 두 번째 적용 케이스 (dogfood 누적 1건)** — 🚨 CRITICAL + Quick Start + 6종 데이터

---

## 🚨 다음 세션 진입 전 사용자 결정 사항 (CRITICAL)

**#018 = PreToolUse Agent matcher 강제 훅 신설 = Phase 1 진입 사전조건 = settings.json env 영구 제거 안전 보장 메커니즘** (turn 6 §3-5 부수 발견 → §10.4 정당성 결정적 강화)

### 사용자가 선택할 처리 방식 3 안

**A. #018 단독 진행** (간결, 권장):
1. `~/.claude/hooks/pretooluse-agent-model-required.sh` 신설 + 테스트
2. settings.json `PreToolUse` 훅에 등록 (matcher = `Agent`)
3. 검증 후 settings.json env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 영구 제거
4. fallback C+ 영구 적용 → Phase 1 진입 가능

**B. #018 + #009 묶음** (Phase 1 인프라 통합):
1. #018 (강제 훅) + #009 (agent-team-manager v2 본체, 마스터플랜 §5 Phase 1) 동시 진행
2. preset YAML + scripts/ 6개 + reference/ 4개 신설 (4-22 리서치 v2 스펙 기반)
3. 한 turn 통합 = 비효율 위험 (양 작업 모두 분량 큼)

**C. #018 + #014 묶음** (PM 운영 의무 통합):
1. #018 (강제 훅) + #014 (PM 외부 리서치 + 근거 인용 의무화) 동시 진행
2. PM agent system prompt 강화 + pm-test rename 또는 폐기
3. PM 운영 메커니즘 안정 후 Phase 1 진입

→ **A 권장** (위험 최소 + 명확한 단위). B·C 는 #018 PASS 후 별도 turn 자연 진입.

---

## 마지막 상태 (어디까지 했나)

### turn 6 미션 = #015 fallback C+ 최종 확정 검증 + 글로벌 강제 규칙 신설 (Step 1~6 PASS)
- **HANDOFF turn 5** `/handoff done` → `.backups/HANDOFF.done.2026-05-04.md` (172줄, 소멸 정책 **11회차 검증**)
- **사전 체크 4건** (settings.json B-1 setup·백업·라이브 env·정합 stale 2건)
- **`/checklist`** mode=mixed 1차 (Step 1~6) → **사용자 지적** ("글로벌 메모리·룰도 관련해서 수정해야 하지 않니??") → **Step 6 분할** (6-A 마스터플랜 / 6-B 글로벌 강제 규칙 / 6-C 인계 정리) — 게이트 5 자기 비판 영구 보존
- **Step 1 PASS** — env 빈 값 확인 (PowerShell + settings.json 양쪽)
- **Step 2** — `model-fallback-verify-v2` 팀 + TaskCreate × 4 + Agent spawn × 4 (병렬, A=opus 명시 / B=pm-test frontmatter / C=디폴트 / D=sonnet 명시)
- **Step 3** — SendMessage 회신 의무 발견 (spawn 텍스트 출력만으로는 lead 미수신) → 4 spawn 모두 자기보고 회신 수신
- **Step 4 PASS** — A=Opus AND B=Opus AND D=Sonnet 4/4 정합. **부수 발견** = C 디폴트 = Opus → 강제 훅 정당성 결정적 강화 (#018 신설 근거)
- **Step 5 PASS** — settings.json mandatory 환원 (SHA256 백업↔환원본 MATCH `5D708DBA...089E4`)
- **Step 6-A** — `06 §10` 신설 (~75줄) + `04 §8.2` 3차 실험 박스 + `§9.1` 갱신
- **Step 6-B (사용자 지적 핵심 부수 효과)** — `rules/agent-spawn-model.md` 신설 (스테이징↔운영 SHA256 MATCH `7AF2BB63...A174E`) + `~/.claude/CLAUDE.md` Agent Preferences 5번째 규칙 (45→46줄) + `memory/agent-office-vision.md` L115 정정
- **Step 6-C** — TeamDelete + `.todo.md` #015 완료·#014 unblock·**#018 신설** + HANDOFF turn 5 archive + turn 6 신설 (본 파일) + history Day 19 신설 + index.md Day 19 행

### 마지막 편집 파일
- `HANDOFF.md` (본 파일, turn 6, 양식 v2 dogfood 누적 1건)
- `.backups/HANDOFF.done.2026-05-04.md` (turn 5 인계서, 172줄)
- `docs/history/2026-05-04.md` (Day 19 신설)
- `docs/history/index.md` (Day 19 행)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md` (§10 신설 ~75줄)
- `docs/research/agent-office-masterplan/04_masterplan.md` (§8.2 + §9.1)
- `rules/agent-spawn-model.md` (스테이징, 신설)
- `.todo.md` (#015 완료 + #014 unblock + #018 신설)
- `.checklist.md` (Step 1~6 PASS, .backups 이동 대기)

### Working tree (commit 직전 상태)
- modified: `.todo.md`, `docs/history/index.md`, `docs/research/agent-office-masterplan/06_issue32732_experiment.md`, `docs/research/agent-office-masterplan/04_masterplan.md`
- renamed: `HANDOFF.md (turn 5) → .backups/HANDOFF.done.2026-05-04.md`
- untracked (신설): `HANDOFF.md` (본 파일, turn 6), `rules/agent-spawn-model.md`, `docs/history/2026-05-04.md`, `.checklist.md`

### 운영 변경 (git 추적 외)
- `~/.claude/rules/agent-spawn-model.md` (신설, SHA256 7AF2BB63AF36DC8D...A174E)
- `~/.claude/CLAUDE.md` (Agent Preferences 5번째 규칙, 45→46줄)
- `~/.claude/settings.json` (Step 5 환원, env=sonnet 복구, SHA256 5D708DBA...089E4)
- `~/.claude/projects/.../memory/agent-office-vision.md` (L115 정정)
- `~/.claude/teams/model-fallback-verify-v2/` (TeamDelete 호출로 디렉토리+worktree 자동 정리 완료, archive 아닌 직접 삭제)

## 미완 작업 (지금 하다 멈춘 것)

- [x] **TeamDelete** — `model-fallback-verify-v2` 자동 정리 완료 (디렉토리+worktree 직접 삭제, archive 아님)
- [x] **`.checklist.md` → `.backups/`** — `.backups/.checklist.md.완료_issue32732-fallback-Cplus-verify_2026-05-04.md` 이동 완료
- [x] **stale 4건 정정** — TeamDelete archive 표기 → "직접 삭제" 정정 (history Day 19 §6 + HANDOFF 운영 변경/자산 섹션 + index.md Day 19 행)
- [ ] **commit + push** — 본 인계서 작성 후 진행 (사용자 명시 = 본 turn 6 종결 단위)

**본 turn 6 종결 의지**: 사용자 결정 = "HANDOFF 제대로 작성 + commit + history 까지". `#018·#014·#012·#016/#017` 등 후속 작업은 **모두 다음 세션 인계** (본 인계서 §🚨 + §다음 세션 시작 지점 참조).

## 다음 세션 시작 지점

### Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)
1. **PowerShell**: `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` — `CLAUDE_CODE_SUBAGENT_MODEL` 값 확인
   - **`sonnet`** → settings.json env=sonnet 환원 정상 (Step 5 결과 보존)
   - **빈 값** → settings.json 변경 후 메인 재시작 안 한 상태 (이상, 조사 필요)
2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **12회차 검증**)
3. **`.todo.md` Read** — #018 priority high (1순위), #014 normal (unblocked, 2순위), #009 normal (Phase 1 인프라)
4. **`.checklist.md` 존재 확인** — 본 turn 미정리 시 Phase 6 정리 (사용자 승인 후 `.backups/` 이동)

### 정식 절차 (체크리스트 승인 후)
5. **사용자에게 #018 진입 의사 확인** — 위 🚨 사전 조치 A/B/C 어느 안 채택할지
6. (의사 확인 후) **`/checklist`** 호출 → 작업명: "PreToolUse Agent matcher 강제 훅 신설 (#018) — fallback C+ 영구 적용 사전조건"
7. #018 절차 (권장 = A 안):
   - **Step 1**: `~/.claude/hooks/pretooluse-agent-model-required.sh` 신설 (또는 .py)
   - **Step 2**: settings.json `PreToolUse` 훅 등록 (matcher = `Agent`)
   - **Step 3**: 더미 spawn 검증 (model 누락 → 차단 + 명시 → 통과)
   - **Step 4**: settings.json env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 영구 제거
   - **Step 5**: env 제거 후 spawn 검증 (디폴트 차단 + 명시 model 정상)
   - **Step 6**: fallback C+ 영구 적용 마킹 + Phase 1 진입 가능
8. **#018 PASS 후** → **#014 진행** (PM 외부 리서치 의무화) 또는 **#009** (agent-team-manager v2 본체)

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — #018 처리 방식 (사용자 선택, 위 🚨 참조)
- **A 안**: #018 단독 진행 (간결, 권장)
- **B 안**: #018 + #009 묶음 (Phase 1 인프라 통합)
- **C 안**: #018 + #014 묶음 (PM 운영 의무 통합)
- **현재 기울기**: A (위험 최소 + 명확한 단위)

### 결정 2 — 강제 훅 구현 언어 (sh / py / ps1)
- **sh**: bash 의존, 글로벌 호환성 좋음 (다른 훅 동일 패턴)
- **py**: Python 의존, 검증 로직 풍부
- **ps1**: PowerShell 전용, Windows 우선
- **현재 기울기**: sh (글로벌 일관성, `dev-checklist-guard.sh` 등 동일 패턴)

### 결정 3 — 강제 훅 매칭 범위
- **strict**: 모든 Agent spawn 차단 (model 없으면 무조건 fail)
- **soft**: 경고만 출력 + 통과 (Stage 1 마이그레이션)
- **현재 기울기**: strict (fallback C+ 영구 적용 = 누락 0% 보장)

### 결정 4 — settings.json env 영구 제거 시점
- **A**: #018 PASS 직후 즉시 영구 제거
- **B**: #018 PASS + 1주 안정 운영 후 영구 제거
- **현재 기울기**: A (강제 훅 검증 PASS = env 의존성 차단 완료 = 즉시 적용 안전)

### 결정 5 (turn 6 신규) — 양식 v2 dogfood 회고 시점
- 본 turn 6 = 양식 v2 두 번째 적용 (1건 누적). drift 발견 안 됨.
- **A**: 다음 1~2 turn 후 회고
- **B**: #008 due 2026-05-08 (1주 후) 통합 회고 (#016 4 스킬 메타 디테일·#017 양식 정합 함께)
- **현재 기울기**: B (회고 효율 + 데이터 누적)

### 결정 6 (turn 6 신규) — 다음 세션 묶음 처리 단위
- **A**: #018 단독 turn (분량 1~2시간, 명확한 사전조건 PASS 단위) — **권장**
- **B**: #018 + #014 + #012 + #016/#017 4 묶음 turn (오늘 사용자 의지 = "다 마무리" 의 정신 계승, 단 분량 3~4시간)
- **C**: #018 + #009 + Phase 1 진입 = mega turn (4~8시간+, 비현실적)
- **사용자 의지 진화** (turn 6 내): "다 마무리" → 분량 평가 후 → "HANDOFF + commit + history 만" 으로 명확화. 다음 세션 진입 시 사용자 재컨펌 후 A/B 선택.
- **현재 기울기**: A (위험 최소 + 단위 명확). B 는 사용자 시간 여유 있을 때.

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유
- **#015 = Phase 1 진입 차단 조건** (turn 3 결정적 재현, turn 5 setup) → 본 turn 6 PASS 로 차단 해제
- **사용자 지적 핵심 의의**: 검증 작업이 단순 "결과 측정" 으로 끝나면 운영 메커니즘에 강제되지 않음 = 본 검증 의미 절반 손실. 글로벌 rules + CLAUDE.md + memory 까지 묶어야 fallback C+ 가 실효 강제력 가짐.
- **Phase 1 진입 가능 마킹**: 사전조건 = #018 강제 훅 신설 + settings.json env 영구 제거. 이후 Phase 1 (PM 신설 + agent-team-manager v2 + ④ 파이프라인 등) 자유 진입.

### 주의 사항
1. **settings.json env=sonnet 환원 보존** (Step 5) — env 빈 값 보존 시 워커 디폴트 = Opus 자동 배치 위험 (Spawn C 부수 발견). #018 PASS 후에만 영구 제거.
2. **글로벌 강제 규칙 5번째 규칙 의무 준수** (`~/.claude/CLAUDE.md` L32 추가분) — 모든 Agent spawn `model` 명시. PM=opus / 워커=sonnet. 누락 spawn 발견 시 즉시 정정.
3. **글로벌 외부 리서치 의무 (`~/.claude/rules/research-mandatory.md`)** 적용 중. 외부 사실 인용 시 출처 명시 필수.
4. **글로벌 CLAUDE.md "Agent Preferences" 5-step** 준수: TeamCreate + TaskCreate + Agent (model 명시) + SendMessage + (5) model 강제 명시.
5. **소멸 정책 12회차 검증** — 본 HANDOFF (turn 6) 이 다음 세션에서 `/handoff done` 처리되면 12회차.

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (양식 v2 두 번째 적용 케이스)
- `.todo.md` — #018 high (1순위), #014 normal (2순위, unblocked), #009 normal, #016·#017 low

### 본 turn 산출물 (turn 6 결과)
- `rules/agent-spawn-model.md` (스테이징, 신설, ~50줄)
- `~/.claude/rules/agent-spawn-model.md` (운영 sync, SHA256 MATCH)
- `~/.claude/CLAUDE.md` Agent Preferences 5번째 규칙 (L32, 45→46줄)
- `~/.claude/projects/.../memory/agent-office-vision.md` L115 (정정)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md` §10 (신설, ~75줄)
- `docs/research/agent-office-masterplan/04_masterplan.md` §8.2 (3차 실험 박스) + §9.1 (model override 행 갱신)
- `docs/research/agent-office-masterplan/05_migration_plan.md` 3 stale 정정 (L249·L377·L399, 정합성 보강 commit)
- `docs/research/agent-office-masterplan/agent-office-vision.md` D-4 footnote 추가 (docs SSOT 본체, 정합성 보강 commit)
- `docs/history/2026-05-04.md` (Day 19 일자 파일, 신설 + §10-A 정합성 보강 회고)
- `docs/history/index.md` (Day 19 행 추가)

### 운영 자산 (#018 입력)
- `~/.claude/settings.json` env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (환원 상태, #018 PASS 후 영구 제거 대상)
- `~/.claude/settings.json.bak.20260503_phaseB1` (env 제거본 백업, #018 검증 입력 가능)
- `~/.claude/agents/pm-test.md` (frontmatter `model: opus`, 보존됨, Phase 1 PM 신설 시 폐기 또는 rename)
- `~/.claude/teams/model-fallback-verify-v2/` (turn 6 실험 팀, TeamDelete 로 정리 완료 — archive 디렉토리 부재)

### 운영 스킬 / 규칙
- `~/.claude/rules/agent-spawn-model.md` (신설, 글로벌 강제)
- `~/.claude/rules/research-mandatory.md` (외부 리서치 의무, 본 turn 본 규칙 §5 인용)
- `~/.claude/skills/checklist/SKILL.md` (양식 v2)
- `~/.claude/skills/handoff/SKILL.md` (양식 v2)
- `~/.claude/skills/todo/SKILL.md` (양식 v2)

### 메모리 (자동 로드)
- `agent-office-vision.md` — D-4 SSOT + L115 fallback C+ 최종 확정 (본 turn 정정)
- `agent-team-skill-redesign.md` — v2 위치 재조정 (#009)
- `pm-external-research-mandatory.md` — PM 한정 강제 (글로벌 `rules/research-mandatory.md` 가 superset)
- `feedback_commit_push.md` — commit + push 한 단위
- `skill-load-scope.md`, `project_deployment_target.md`

### Git
- 브랜치: main
- 마지막 커밋: `56ce2de` (turn 4 마킹 commit)
- 본 turn 마무리 커밋 (예정): `feat+docs: Day 19 turn 6 — #015 PASS (fallback C+ 최종 확정) + 글로벌 강제 규칙 신설 (rules/agent-spawn-model.md + CLAUDE.md Agent Preferences 5번째 규칙 + memory L115 정정) + #018 신설`
- push: 사용자 명시 시 (메모리 `feedback_commit_push.md` — commit + push 한 단위)
