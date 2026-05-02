# HANDOFF — 2026-05-02 Day 18 후속 turn 4 인계서

> 생성: 2026-05-02 (Day 18 후속 turn 4 종료 시점) | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 18 후속 turn 4 메인 Claude (Opus 4.7 1M)
> **양식 v2 첫 적용 케이스 (dogfood)** — 🚨 CRITICAL + Quick Start + 6종 데이터

---

## 🚨 다음 세션 진입 전 사용자 결정 사항 (CRITICAL)

**#015 = fallback C+ 최종 확정 = Phase 1 진입 차단 조건** (turn 3 그대로 인계, 본 turn 결과 무관)

메인 Claude Code **process 자체 재시작** 필요 (`/clear` 만으로 부족). settings.json hot-reload 비작동, 06 §2.2 + turn 3 §9.3 결정적 재현.

### 사용자가 선택할 사전 조치 2 안

**A. 운영 환경 보존 + 별도 검증 세션** (권장):
1. 본 turn 의 settings.json (env=sonnet 환원본) 그대로 유지
2. 메인 Claude Code **종료 → 재실행** → 본 프로젝트 진입 → `Get-ChildItem Env:` → SUBAGENT_MODEL=sonnet 인지 빈 값인지 확인
3. (만약 sonnet 이면) settings.json 임시 편집 → SUBAGENT_MODEL 라인 제거 → 다시 메인 종료 → 재실행 → 검증 → 검증 후 환원

**B. 영구 변경 + 새 세션** (적극적):
1. settings.json 의 `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 라인 영구 제거 (단 워커 디폴트 = Sonnet 보장 메커니즘 준비 필요)
2. 메인 Claude Code 종료 → 재실행 → 본 프로젝트 진입 → 검증
3. 검증 PASS 시 모든 spawn 에 model 파라미터 강제 명시 + 강제 훅 신설 (Phase 1 인프라)

→ **A 권장**. 운영 안정 우선. B 는 fallback C+ 최종 확정 후 진행.

---

## 마지막 상태 (어디까지 했나)

### turn 4 미션 = 4 스킬 메타 평가 + 패치 (자체 발생, HANDOFF turn 3 진입 후 #015 차단 발견 → 다른 작업 전환)

- **HANDOFF turn 3** `/handoff done` → `.backups/HANDOFF.done.2026-05-02-v4.md` (소멸 정책 **9회차 검증**)
- **4 스킬 메타 평가** 1차 셀프 진단 (양식 drift 2 + 책임 경계 공백 3 + dogfood 5건)
- **`/feedback` 외부 검수** — 합본 입력 1회 호출 (4 SKILL.md + 1차 진단, ~600줄) → **3/3 VALID, 합집합 14건, 환각 0**
- **Top 3 만장일치** + **메인 1차 진단이 놓친 5종/6종 모순** 발견 (게이트 5 자기 비판)
- **`/checklist`** mode=mixed, 16 항목 (A 4 + B 1 + C 2 + D 4 + E 4 + F 2 + 자체 검토 후 **D0 신설** = 외부 리서치 선행 의무)
- **Phase D0 외부 리서치 1회** — WebSearch (Salesforce/AWS/arxiv/MS 4 출처 인용) — **자기 모순 회피** (외부 리서치 의무 규칙을 만들면서 외부 리서치 0건 = 자기 위반 → 자체 발견 → 보강)
- **Phase A·B·C·D·E·F 진행** — 7 SKILL/Rule 변경 + 운영 SHA256 4쌍 MATCH + .todo.md #016·#017 신설
- **V1~V10 검증 PASS** — 단 V1 중 **handoff L95 "5종" 잔존 자기 발견** → 즉시 정정 + 운영 재동기화 + SHA 재검증 (더블 체크 의의 입증)
- **Phase 6 정리** — 영구 기록 가치 평가 5/5 조건 중 4 해당 → `/project-history update` 의무 → docs/history/2026-05-02.md §10 추가 + index.md Day 18 행 갱신
- **결정**: 본 turn 의 양식 v2 첫 적용 케이스 = 본 HANDOFF (turn 4) = dogfood 검증 가치

### 마지막 편집 파일
- `HANDOFF.md` (본 파일, 양식 v2)
- `docs/history/2026-05-02.md` §10 (+~50줄, 276→~330)
- `docs/history/index.md` Day 18 행 갱신 (turn 4 추가)
- `.backups/.checklist.md.완료_4skill-meta-patch_2026-05-02.md` (체크리스트 종결)

### Working tree (commit 직전 상태)
- modified: `.todo.md` / `docs/feedback/index.md` / `docs/history/2026-05-02.md` / `docs/history/index.md` / `skills/checklist/SKILL.md` / `skills/handoff/SKILL.md` / `skills/todo/SKILL.md`
- renamed: `.checklist.md → .backups/.checklist.md.완료_4skill-meta-patch_2026-05-02.md`, `HANDOFF.md (turn 3) → .backups/HANDOFF.done.2026-05-02-v4.md`
- untracked (신설): `HANDOFF.md` (본 파일, turn 4) / `rules/research-mandatory.md` / `docs/feedback/2026-05-02_*_input_combined_*.md` 4건 / `docs/research/2026-05-02_4skill-meta-review/`

### 운영 변경 (git 추적 외)
- `~/.claude/skills/handoff/SKILL.md` (SHA 5E4E3536ED32856C..)
- `~/.claude/skills/todo/SKILL.md` (SHA 824B31A1F2236AC9..)
- `~/.claude/skills/checklist/SKILL.md` (SHA 576DFAAA75149783..)
- `~/.claude/rules/research-mandatory.md` (SHA 80C5EB34B1F1F186.., 신설)
- `~/.claude/CLAUDE.md` (Core Principles 1줄 추가, 44→45줄)

## 미완 작업 (지금 하다 멈춘 것)

- [x] **commit** — `c66c611` (14 파일, +1074 -86)
- [x] **push** — origin/main `02eca15..c66c611`
- [ ] **#015** — 사용자 메인 재시작 후 (위 🚨 섹션 참조)

본 turn 자체 작업은 종결. Working tree clean.

## 다음 세션 시작 지점

### Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)
1. **PowerShell**: `Get-ChildItem Env: | Where-Object Name -like "*CLAUDE*"` — SUBAGENT_MODEL 값 확인 (빈 값 / sonnet / 다른 값) → 06 §9.7 한계 §1 해소
2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **10회차 검증**)
3. **`.todo.md` Read** — #015 우선순위 high (#014 blocked_by #015), #016·#017 백로그 신설 확인

### 정식 절차 (체크리스트 승인 후)
4. **사용자에게 #015 진입 의사 확인** — 위 🚨 사전 조치 A/B 어느 안 채택할지
5. (의사 확인 후) **`/checklist`** 호출 → 작업명: "issue#32732 fallback C+ 최종 확정 (#015) — 06 §9.8 절차"
6. #015 절차 = 06 §9.8:
   - **Step 1**: 메인 process env 실측 (PowerShell). SUBAGENT_MODEL=빈 값 확인
   - **Step 2** (Step 1 = 빈 값): TeamCreate + Agent spawn (pm-test, model X 또는 model="opus") → 자식 자기보고 = Opus 검증
   - **Step 2-fail** (Step 1 = sonnet 또는 다른 값): 메인 process env 갱신 메커니즘 추가 조사 (또는 settings.json 영구 제거 + 다시 메인 재시작)
   - **Step 3 PASS**: fallback C+ 최종 확정 → `06 §10` 추가 + `04 §8.2` 최종 재작성 + Phase 1 진입 가능 마킹
   - **Step 3 FAIL**: fallback B (별도 인스턴스) 검토 + #015 → fallback B 검증 task 로 분리
7. **#015 PASS 후** → **#014 진행** (PM 외부 리서치 + 근거 인용 의무화) — 글로벌 `rules/research-mandatory.md` superset 위에 PM agent system prompt 강제 (메모리 `pm-external-research-mandatory.md` 흡수 + 가드레일 훅 신설)

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — #015 의 사전 조치 (사용자 선택)
- **A 안**: 본 turn settings.json 그대로 유지 + 메인 재시작만으로 검증 (env=sonnet 인 채로 빈 값 안 나올 수 있음)
- **B 안**: settings.json env 영구 제거 + 메인 재시작 + 새 세션
- **현재 기울기**: A (운영 안정 우선). 단 A = SUBAGENT_MODEL 빈 값 가능성 낮음 → 실질적으로 B 필요

### 결정 2 — #015 결과 분기
- **PASS** (env 빈 값 + 명시 model 작동): fallback C+ 최종 확정 → Phase 1 진입 가능
- **FAIL** (env 잔존 또는 명시 model 무력): fallback B (별도 인스턴스) 검토 + agent-office-vision D-4 (모델 배분) 재설계 가능
- **현재 기울기**: PASS

### 결정 3 — settings.json 영구 변경 시점
- **A**: #015 검증 직전 영구 제거 (B 안 시행 시 자동)
- **B**: #015 검증용 임시 제거 → 검증 후 즉시 환원 → fallback C+ 인프라 (강제 훅) 완성 후 영구 제거
- **현재 기울기**: B (운영 안정 + 인프라 준비 후 영구 변경, 누락 방지 훅 없이 영구 변경 시 워커가 Opus 로 잘못 spawn 될 위험 ⚠️)

### 결정 4 — #014 처리 시점 (PM 외부 리서치 의무화)
- **A**: #015 PASS + Phase 1 PM 신설 시 같이 적용
- **B**: #015 PASS 직후, Phase 1 진입 전 마스터플랜 §3.2 + §9 보강만 먼저
- **현재 기울기**: A (PM 메커니즘 안정 후 한 번에 디자인 완결). 본 turn 신설 글로벌 `rules/research-mandatory.md` 가 PM 메모리 superset 이므로 base 는 이미 깔림 → PM 한정 강화는 #015 PASS 후 PM agent system prompt 에 흡수.

### 결정 5 (turn 4 신규) — 4 스킬 양식 v2 dogfood 회고 시점
- **본 HANDOFF (turn 4) 가 양식 v2 첫 적용 케이스**. 다음 세션이 본 양식을 보고 진입 시 자연 dogfood 발생.
- **A**: 다음 세션 1~2회 경험 후 회고 (즉시 회고)
- **B**: 1주 후 (#008 /feedback 2주 회고 due 2026-05-08 와 같은 시점) 통합 회고
- **현재 기울기**: B (다른 회고와 통합 효율)

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유
- **4 스킬 만듦새 평가 = 사용자 요청** (turn 4 첫 메시지). #015 차단으로 인한 다른 작업 전환 케이스.
- **본 turn 결과** = 4 스킬 양식·책임 경계 정상화 + 사용자 추가 요청 (글로벌 외부 리서치 의무) 흡수. 양식 drift 가 다른 프로젝트로 전파되기 전 차단 + 추측·환각 리스크 차단.
- **자기 모순 발견 + 회복** = 외부 리서치 의무 규칙을 만들면서 외부 리서치 0건 의 자기 위반을 자체 검토에서 자기 발견 → Phase D0 신설 → 출처 4건 인용으로 자기 적용 완료. **본 규칙의 첫 적용 케이스 = 본 turn 자체** = 의미 있는 dogfood.

### 주의 사항
1. **메인 process env cache 갱신 = 메인 재시작 only** (turn 3 §9.3 결정적 재현). settings.json hot-reload 안 됨. `/clear` 만으로는 부족.
2. **양식 v2 적용** — 다음 세션 진입 후 `/handoff` 양식·`/todo` 양식·`/checklist` Trigger·Phase 6 모두 새 정의 적용. drift 발견 시 즉시 보고.
3. **글로벌 외부 리서치 의무** — 외부 사실 인용 시 출처 명시 필수 (`~/.claude/rules/research-mandatory.md` §3 형식). 추측·"아마도"·"보통" 표현 금지.
4. **글로벌 CLAUDE.md "Agent Preferences" 4-step** — TeamCreate + TaskCreate + Agent + SendMessage 준수.
5. **소멸 정책 10회차 검증** — 본 HANDOFF 가 다음 세션 진입 시 `/handoff done` 처리되면 10회차.

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (양식 v2, 확인 후 `/handoff done`)
- `.todo.md` — #015 high (priority 1), #014 blocked_by #015, **#016·#017 신설** (4 스킬 메타 디테일·유보), #012 normal, #009 normal, #008 normal due 2026-05-08

### 본 turn 산출물 (turn 4 결과)
- `rules/research-mandatory.md` (87줄, 신설) — 글로벌 외부 리서치 의무 규칙
- `~/.claude/rules/research-mandatory.md` (운영 사본)
- `~/.claude/CLAUDE.md` Core Principles L24 (인덱스 1줄)
- `skills/handoff/SKILL.md` (양식 v2 + 책임 경계 + 6종 정정)
- `skills/todo/SKILL.md` (priority enum + 4 필드)
- `skills/checklist/SKILL.md` (Trigger 분석/리뷰 경계 + Phase 6 영구 기록 5 조건)
- `docs/feedback/2026-05-02_claude__input_combined_20260502-202220-종합.md` (외부 검수 종합)
- `docs/research/2026-05-02_4skill-meta-review/_input_combined.md` (입력 합본)
- `docs/history/2026-05-02.md §10` — 본 turn 상세 기록

### 운영 자산 (#015 입력)
- `~/.claude/agents/pm-test.md` (frontmatter `model: opus`, 보존됨) — #015 검증 입력
- `~/.claude/teams/.archived/model-fallback-verify_2026-05-02/` — turn 3 실험 팀 archive
- `~/.claude/settings.json` — env `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` (D-4 정합 환원 상태)
- `~/.claude/settings.json.bak.20260502_phaseB` — Phase B 직전 상태 백업

### 운영 스킬 (양식 v2 적용 후)
- `~/.claude/skills/agent-team-manager/SKILL.md` (252줄, 부트스트랩 가이드, 무변경)
- `~/.claude/skills/feedback/SKILL.md` (외부 검수 표준, 무변경)
- `~/.claude/skills/checklist/SKILL.md` (양식 v2)
- `~/.claude/skills/handoff/SKILL.md` (양식 v2)
- `~/.claude/skills/todo/SKILL.md` (양식 v2)
- `~/.claude/skills/project-history/SKILL.md` (무변경)

### 메모리 (자동 로드)
- `agent-office-vision.md`, `agent-team-skill-redesign.md`, `skill-load-scope.md`, `project_deployment_target.md`
- `pm-external-research-mandatory.md` — PM 한정 강제. 본 turn 신설 글로벌 `rules/research-mandatory.md` 가 superset.
- `feedback_commit_push.md`

### Git
- 브랜치: main
- 마지막 커밋: `02eca15` (turn 3 종료, "docs+chore: Day 18 후속 turn 3 — issue#32732 새 세션 fallback 검증 (#013 완료, #015 신설 high)")
- 본 turn 마무리 커밋 (예정): `docs+chore: Day 18 후속 turn 4 — 4 스킬 메타 패치 + 글로벌 외부 리서치 의무 (#013 후속, 양식 v2 dogfood)`
- push: origin/main (사용자 명시 요청 시 — 메모리 `feedback_commit_push.md` 따라 commit + push 한 단위)
