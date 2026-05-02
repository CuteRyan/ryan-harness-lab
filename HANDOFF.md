# HANDOFF — 2026-05-02 Day 18 후속 turn 3 인계서

> 생성: 2026-05-02 (Day 18 후속 turn 3 종료 시점) | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 18 후속 turn 3 메인 Claude (Opus 4.7 1M)

---

## 🚨 다음 세션 진입 전 사용자 결정 사항 (CRITICAL)

**#015 검증 = fallback C+ 최종 확정 = Phase 1 진입 차단 조건**

이는 **메인 Claude Code 자체를 재시작** 해야만 검증 가능 (settings.json hot-reload 비작동, 06 §2.2 + 후속 turn 3 §9.3 결정적 재현). 즉 "단순 새 세션 (`/clear`)" 으로는 부족 — **메인 process 재시작 (앱 종료 후 재실행) 필요**.

### 사용자가 선택할 사전 조치 2 안

**A. 운영 환경 보존 + 별도 검증 세션** (권장):
1. 본 turn 의 settings.json (env=sonnet 환원본) 그대로 유지
2. 메인 Claude Code **종료 → 재실행** → 본 프로젝트 진입 → `Get-ChildItem Env:` → SUBAGENT_MODEL=sonnet 인지 빈 값인지 확인
3. (만약 sonnet 이면) settings.json 임시 편집 → SUBAGENT_MODEL 라인 제거 → 다시 메인 종료 → 재실행 → 검증 → 검증 후 환원

**B. 영구 변경 + 새 세션** (적극적):
1. settings.json 의 `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 라인 영구 제거 (단 워커 디폴트 = Sonnet 보장 메커니즘 준비 필요)
2. 메인 Claude Code 종료 → 재실행 → 본 프로젝트 진입 → 검증
3. 검증 PASS 시 모든 spawn 에 model 파라미터 강제 명시 + 강제 훅 신설 (Phase 1 인프라)

→ **A 권장**. 본 turn 결과 운영 안정 우선. B 는 fallback C+ 최종 확정 후 진행.

---

## 마지막 상태 (어디까지 했나)

### 본 turn 의 미션 = `.todo.md` #013 (issue#32732 새 세션 fallback 검증) — **완료**

- **HANDOFF.md** (turn 2 작성) `/handoff done` → `.backups/HANDOFF.done.2026-05-02-v3.md` (소멸 정책 **8회차 검증**)
- **Quick Start §1**: PowerShell 실측 → `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 캐시 확인, 출처 = settings.json env (06 §6-1 한계 1차 해소)
- **`/checklist`** (mode=mixed, 21 항목 = Phase A 3 + B 4 + C 4 + D 6 + E 3) 주인님 승인 → 진입
- **TeamCreate `model-fallback-verify`** (이전 `model-priority-test` leader context 잔존 → TeamDelete 후 재생성)
- **4 spawn 실험** (Step B / C / D-1 / D-2) — **모두 자식 자기보고 = Sonnet** (cache stale 가설 결정적 기각, settings.json hot-reload 비작동 결정적 재현)
- **결정 1 확정 = Step C = Sonnet 분기** — 새 세션 환경에서도 frontmatter 무력
- **결정 2 잠정 확정 = fallback C+** (3중화: settings.json env 영구 제거 + 메인 재시작 + 모든 spawn model 명시 + PreToolUse Agent matcher 강제 훅)
- **결정 3 확정** — pm-test agent 보존 (#015 입력) + Phase 1 진입 시 폐기/rename
- **결정 4 처리** — #014 blocked_by #013 → **blocked_by #015** 로 갱신
- **산출물**: `06 §9` 신설 (+90줄, 258→348) + `04 §8.2 D-32732-A2` (+18) + `04 §9.1` 가드레일 model override 항목 (+1) + `.todo.md` (#013 완료 + **#015 신설 high** + #014 blocked_by 갱신) + `2026-05-02.md §9` (+~80) + `index.md` Day 18 행 갱신
- **정리** — 실험 팀 archive (`~/.claude/teams/.archived/model-fallback-verify_2026-05-02/`) + TeamDelete 성공 + settings.json 환원 (D-4 정합) + pm-test agent 보존 + 체크리스트 종결 (`.backups/.checklist.md.완료_013_fallback검증_2026-05-02.md`) + settings.json 수동 백업 (`~/.claude/settings.json.bak.20260502_phaseB`)

### 마지막 편집 파일
- `HANDOFF.md` (본 파일, 본 turn 종료 직전 신설)
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md` (L262 §9 신설)
- `docs/research/agent-office-masterplan/04_masterplan.md` (L616 §8.2 + L653 §9.1)

### Working tree (commit 직전 상태)
- modified: `.todo.md` / `docs/history/2026-05-02.md` / `docs/history/index.md` / `04_masterplan.md` / `06_issue32732_experiment.md`
- renamed (이전 turn 정리): `HANDOFF.md → .backups/HANDOFF.done.2026-05-02-v3.md`
- untracked: `HANDOFF.md` (본 파일, 신설)
- (자동 백업) `~/.claude/settings.json.bak.20260502_phaseB` — Phase 1 인프라 확정 후 정리 가능

## 미완 작업 (지금 하다 멈춘 것)

본 turn 자체는 종결. 다만 마무리 절차 진행 중:
- [ ] **commit** — 본 turn 변경 6건 (modified 5 + untracked 1)
- [ ] **push** — origin/main (사용자 명시 요청 시)
- [ ] **#015** — 사용자 메인 Claude Code 재시작 후 새 세션 (위 🚨 섹션 참조)

## 다음 세션 시작 지점

> **Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)**:
>
> 1. **PowerShell**: `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` — SUBAGENT_MODEL 값 확인 (빈 값 / sonnet / 다른 값) → 06 §9.7 한계 §1 해소
> 2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **9회차 검증**)
> 3. **`.todo.md` Read** — #015 우선순위 high 확인 (#014 blocked_by #015)
> 4. **사용자에게 #015 진입 의사 확인** — 위 🚨 사전 조치 A/B 어느 안 채택할지
> 5. (의사 확인 후) **`/checklist`** 호출 → 작업명: "issue#32732 fallback C+ 최종 확정 (#015) — 06 §9.8 절차"

### 정식 절차 (체크리스트 승인 후)

1. **`HANDOFF.md` Read 후 `/handoff done`** 처리 (소멸 정책 **9회차 검증**)
2. **#015 진입** — 06 §9.8 절차:
   - **Step 1**: 메인 process env 실측 (PowerShell). SUBAGENT_MODEL=빈 값 확인
   - **Step 2** (Step 1 = 빈 값): TeamCreate + Agent spawn (pm-test, model X 또는 model="opus") → 자식 자기보고 = Opus 검증
   - **Step 2-fail** (Step 1 = sonnet 또는 다른 값): 메인 process env 갱신 메커니즘 추가 조사 (또는 settings.json 영구 제거 시도 + 다시 메인 재시작)
   - **Step 3 PASS**: fallback C+ 최종 확정 → `06 §10` 추가 + `04 §8.2` 최종 재작성 + Phase 1 진입 가능 마킹
   - **Step 3 FAIL**: fallback B (별도 인스턴스) 검토 + #015 → fallback B 검증 task 로 분리
3. **#015 PASS 후** → **#014 진행** (PM 외부 리서치 + 근거 인용 의무화) — 마스터플랜 §3.2 PM 컨셉 + §9 가드레일 보강 + pm-agent (rename 후) frontmatter/system prompt 에 외부 리서치 강제

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — #015 의 사전 조치 (사용자 선택)
- **A 안**: 본 turn settings.json 그대로 유지 + 메인 재시작만으로 검증 (env=sonnet 인 채로 빈 값 안 나올 수 있음)
- **B 안**: settings.json env 영구 제거 + 메인 재시작 + 새 세션
- **현재 기울기**: A (운영 안정 우선). 단 A = SUBAGENT_MODEL 빈 값 가능성 낮음 → 실질적으로 B 필요

### 결정 2 — #015 결과 분기
- **PASS** (env 빈 값 + 명시 model 작동): fallback C+ 최종 확정 → Phase 1 진입 가능
- **FAIL** (env 잔존 또는 명시 model 무력): fallback B (별도 인스턴스) 검토 + agent-office-vision D-4 (모델 배분) 재설계 필요 가능
- **현재 기울기**: PASS (B 안 시행 시 메인 process 가 settings.json env 를 새로 캐시할 텐데 라인 자체가 없으면 SUBAGENT_MODEL 미설정될 가능성 높음)

### 결정 3 — settings.json 영구 변경 시점
- **A**: #015 검증 직전 영구 제거 (B 안 시행 시 자동)
- **B**: #015 검증용 임시 제거 → 검증 후 즉시 환원 → fallback C+ 인프라 (강제 훅) 완성 후 영구 제거
- **현재 기울기**: B (운영 안정 + 인프라 준비 후 영구 변경 — 누락 방지 훅 없이 영구 변경 시 워커가 Opus 로 잘못 spawn 될 위험 ⚠️)

### 결정 4 — #014 처리 시점 (PM 외부 리서치 의무화)
- **A**: #015 PASS + Phase 1 PM 신설 시 같이 적용
- **B**: #015 PASS 직후, Phase 1 진입 전 마스터플랜 §3.2 + §9 보강만 먼저
- **현재 기울기**: A (PM 메커니즘 안정 후 한 번에 디자인 완결)

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유
- **Phase 1 (`/agent-office` 신설) 진입 차단 조건** — PM=Opus 강제가 작동하지 않으면 D-4 (모델 배분) 핵심 + R-2 (PM 비판자 보호막) 약화
- 본 turn 으로 frontmatter + 명시 model 모두 본 환경에서 무력화 결정적 확인 → fallback C+ 잠정 채택 → #015 최종 확정 절차 분리

### 주의 사항
1. **메인 process env cache 갱신 = 메인 재시작 only** (06 §2.2 + §9.3 결정적 재현). settings.json hot-reload 안 됨. `/clear` 만으로는 부족.
2. **settings.json 영구 제거 시 워커 디폴트 = Sonnet 보장 메커니즘 필요** — 누락 방지 훅 (PreToolUse Agent matcher) 신설 전 영구 제거 시 워커가 Opus 로 잘못 spawn 될 위험. fallback C+ 의 3 번째 메커니즘 (강제 훅) 이 그것.
3. **TeamCreate leader context 잔존 현상** — 이전 archive 처리한 팀이 leader context 에 남아있어 새 TeamCreate 시 충돌. TeamDelete 로 클리어 필요. Phase 1 agent-team-manager v2 §6 cleanup 에 명시 필요.
4. **Agent spawn prompt 미전달 가능성** — Step D-1·D-2 첫 spawn 후 응답 없이 idle notification 만 도착 → SendMessage 로 task 재요청 후 정상 응답. spawn 의 prompt 파라미터가 mailbox 로 전달되는 메커니즘이 비결정적일 수 있음 — Phase 1 시 SendMessage 후속 표준화 검토.
5. **자기 모델 보고 신뢰성** — 시스템 프롬프트 + env + 자가 스타일 3중 단서 일치로 판단. Anthropic API 응답 헤더 분석 가치 (cross-check) 있음.
6. **글로벌 CLAUDE.md "Agent Preferences" 4-step** — TeamCreate + TaskCreate + Agent + SendMessage 준수.

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (확인 후 `/handoff done`)
- `.todo.md` — #015 high (priority 1), #014 blocked_by #015, #012 normal, #009 normal, #008 normal due 2026-05-08
- `docs/research/agent-office-masterplan/06_issue32732_experiment.md §9` (L262-323) — turn 3 검증 결과 + #015 절차 §9.8
- `docs/research/agent-office-masterplan/04_masterplan.md §8.2` (L616-624) — D-32732-A2 + #015 차단 조건
- `docs/research/agent-office-masterplan/04_masterplan.md §9.1` (L653) — model override 가드레일

### 운영 자산 (#015 입력)
- `~/.claude/agents/pm-test.md` (frontmatter `model: opus`, 보존됨) — #015 검증 입력
- `~/.claude/teams/.archived/model-fallback-verify_2026-05-02/` — 본 turn 실험 팀 archive
- `~/.claude/settings.json` — env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (D-4 정합 환원 상태)
- `~/.claude/settings.json.bak.20260502_phaseB` — Phase B 직전 상태 백업 (fallback C+ 인프라 확정 후 정리 가능)

### 운영 스킬 (즉시 사용 가능)
- `~/.claude/skills/agent-team-manager/SKILL.md` (252줄, 부트스트랩 가이드)
- `~/.claude/skills/feedback/SKILL.md` (외부 검수 표준)
- `~/.claude/skills/checklist/SKILL.md` (모든 작업 진입 의무)
- `~/.claude/skills/handoff/SKILL.md` (세션 인계)

### 메모리 (자동 로드)
- `agent-office-vision.md` — 5층 위계 + 4가지 워커 + 모델 배분
- `agent-team-skill-redesign.md` — v2 위치 재조정 (Phase 1 인프라)
- `skill-load-scope.md` — `~/.claude/skills/` 만 자동 로드
- `project_deployment_target.md` — 최종 Linux 배포 (Windows 네이티브 의존 피하기)

### Git
- 브랜치: main
- 마지막 커밋: `8391c9e` (HANDOFF.md Quick Start 섹션 추가, 직전 turn 마무리)
- 본 turn 마무리 커밋 (예정): `docs+chore: Day 18 후속 turn 3 — issue#32732 새 세션 fallback 검증 (#013 완료, #015 신설 high)`
- push: origin/main (사용자 명시 요청 시)

## 기억 보강 — PM 외부 리서치 의무화 (#014) 와 본 turn 의 관계

본 turn 종료 직전 사용자 질문: "PM 이 이제 외부 리서치도 좀 하는건가?"

**답**: **아직 안 함**. PM agent 자체가 Phase 1 진입 전이라 외부 리서치 의무화도 자연 보류. 진행 순서 = **#015 PASS → Phase 1 진입 (PM agent 신설) → #014 진행**.

현재 pm-test agent (frontmatter `model: opus` 만 있는 실험용) 는 외부 리서치 강제 X. #014 가 그 의무화를 다루는데 blocked_by #015 로 갱신됨 (PM 운영 메커니즘 안정 후 의무 추가가 안전, 06 §9.6).
