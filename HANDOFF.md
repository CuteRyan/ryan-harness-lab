# HANDOFF — 2026-05-05 Day 20 turn 4 인계서 (#009 大 사이클 5/6 PASS, #009-E + #021 잔여)

> 생성: 2026-05-05 turn 4 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 20 turn 4 메인 Claude (Opus 4.7 1M)
> **양식 v2 dogfood 13건째** — 6종 데이터 (🚨 섹션 생략 = 사용자 사전 조치 0건)

---

## 마지막 상태 (어디까지 했나)

### 본 세션 누적 (turn 1·2·3·4 = 4 turn, 2026-05-05 Day 20)
- **turn 1 (#009-B) PASS** — `presets/` 5 YAML 신설 (review·debug·research·docs-research·harness-design, 총 439줄). 마스터플랜 §2.4 1:1 정합 5/5 PASS. 운영 sync 5쌍 MATCH. commit `b853a84`.
- **turn 2 (#009-C) PASS** — `SKILL.md` v1.5 (244줄) → v2 (355줄, +111). PM·preset·hooks 보류 3건 흡수. hot-reload 작동 PASS. commit `37b20fb`.
- **turn 3 (#009-D-1) PASS** — `scripts/` 6 PowerShell 헬퍼 (~750줄). 단위 테스트 9/9 PASS. R-14 (운영 71 orphan)·R-15 (BOM 의무) 부수 발견. 운영 sync 6쌍 MATCH. commit `0d71034`.
- **turn 4 (#009-D-2) PASS** — `reference/` 4 (~530줄) + SKILL.md v2 (355) → v2.5 (387, +32). on-demand 로드 정책. 운영 sync 5쌍 MATCH. grep 7/7 PASS. commit `e7c60a6`.

### 본 turn 4 산출물 (commit `e7c60a6` 후 push 완료)
- `skills/agent-team-manager/reference/{patterns,anti-patterns,errors,presets}.md` × 4 (~530줄)
- `skills/agent-team-manager/SKILL.md` v2 (355) → v2.5 (387, +32)
- 운영 sync 5쌍 SHA256 MATCH
- `docs/history/2026-05-05.md` §13 (~80줄, 270 → ~350)
- `docs/history/index.md` Day 20 행 turn 4 결과 append
- `.todo.md` #009-D 완료 마킹 + #009-E 단일화
- `.checklist.md` archive (`.backups/.checklist.done.009-D-2.2026-05-05.md`)

### Working tree (commit `e7c60a6` 후 상태 = clean 예정)
- 본 HANDOFF.md commit 후 working tree clean
- 다음 세션 진입 시 `git status --short` = clean (Untracked 0건)

### 운영 변경 (git 추적 외)
- `~/.claude/skills/agent-team-manager/SKILL.md` v2.5 sync MATCH (`3D70CE05...`)
- `~/.claude/skills/agent-team-manager/reference/*.md` × 4 sync MATCH
- `~/.claude/skills/agent-team-manager/scripts/*.ps1` × 6 sync MATCH (turn 3 신설)
- `~/.claude/projects/.../memory/agent-office-vision.md` 갱신 (turn 1·2·3·4 결과 5 항목 추가)

## 미완 작업 (지금 하다 멈춘 것)

- [ ] **#009-E feature·security 2 preset** (마스터플랜 §2.4 표 中 보류 2/7) — 새 agent 7 (lead/frontend/backend/tester + SAST/DAST/compliance) 신설 선행 필요. 추정 2 turn.
- [ ] **#021 운영 71 orphan 팀 정리** — Day 20 turn 3 R-14 부수 발견. `validate-team -AllTeams` → `shutdown-team -Team <name>` 일괄 호출. 추정 30분.
- [x] HANDOFF turn 4 (본 파일) commit + push — 다음 세션 진입 시 `/handoff done` 으로 archive (소멸 정책 16회차 검증 예정)

## 다음 세션 시작 지점

### Quick Start (메인 Claude 가 새 세션 진입 직후 즉시 실행)

1. **사전 확인** (안전성 검증, 1분):
   - `Get-ChildItem Env:CLAUDE_CODE_SUBAGENT_MODEL` → 부재 확인 (fallback C+ 효과 유지)
   - `git status --short` → **clean** 확인 (turn 4 commit `e7c60a6` 후 working tree 깔끔)
2. **HANDOFF.md Read** (본 파일) → `/handoff done` (소멸 정책 **16회차 검증**)
3. **`.todo.md` Read** — #009-E + #021 잔여 백로그 확인

### 정식 절차 (사용자 컨펌 후)

#### 옵션 A — #009-E 진입 (feature·security 2 preset)
- **Step 1**: 새 agent 7 신설 = `agents/{lead,frontend,backend,tester}.md` (feature) + `agents/{sast-analyst,dast-analyst,compliance-checker}.md` (security)
- **Step 2**: agent 양식 = turn 11 #009-A 의 12 agent 양식 차용 (description + 핵심 행동 규칙 5 + 출력 형식 4 요소 + 면제 예외 + 전문 영역 + 협업 패턴 = R-10 정합)
- **Step 3**: model 배분 = lead (feature) = opus / 나머지 6 = sonnet (Haiku 0건)
- **Step 4**: 운영 sync 7쌍 SHA256 MATCH
- **Step 5**: `presets/{feature,security}.yaml` 신설 (Day 20 turn 1 양식 차용)
- **Step 6**: 운영 sync 2쌍 SHA256 MATCH
- **Step 7**: SKILL.md v2.5 §2.4 표 갱신 (feature·security 행 추가) + 마스터플랜 §2.4 정합 검증 7/7 PASS
- **Step 8**: history + .todo + commit + .checklist archive
- **추정**: 2 turn (Step 1~4 = 1 turn / Step 5~8 = 1 turn)

#### 옵션 B — #021 운영 71 orphan 팀 정리 (간단)
- **Step 1**: `~/.claude/skills/agent-team-manager/scripts/validate-team.ps1 -AllTeams -Format json` 실행 → orphan 列舉
- **Step 2**: 각 orphan team 에 대해 `shutdown-team.ps1 -Team <name>` (기본 archive) 일괄 호출
- **Step 3**: 재검증 (`validate-team -AllTeams` → invalid_count = 0)
- **추정**: 30분 (PowerShell 자동화 가능)

#### 옵션 C — Phase 2 진입 (`/agent-office` 통합 진입점 신설)
- 본 세션 #009 大 사이클 5/6 PASS = Phase 1 완료 단계.
- Phase 2 = `/agent-office` 통합 진입점 + 자동 분류 + UI 통합 + bypass_threshold 자동 적용
- 단 #009-E 보류 시 `/agent-office` 가 feature/security preset 호출 시 미지원 — **#009-E 선행 권장**

## 미결 결정 (다음 세션에 결정 필요)

### 결정 1 — 다음 세션 진입 시점 우선순위
- **A (권장)**: #009-E 진입 (Phase 1 완전 종결, 2 turn) — 마스터플랜 §2.4 표 7/7 PASS 의무 (현재 5/7)
- **B**: #021 진입 (30분, 가벼움) — 운영 위생 정리 후 #009-E 진입
- **C**: Phase 2 진입 (`/agent-office`) — #009-E 보류 시 feature/security 미지원, 권장 X
- **현재 기울기**: A 또는 B 후 A. **사용자 결정 의존**.

### 결정 2 — #009-E feature preset 멤버 양식
- 마스터플랜 §2.4 = "feature: 4명 (lead/frontend/backend/tester)" 명시
- **A**: lead = pm 재사용 (이미 존재, 전 preset lead) + 새 agent 3 (frontend/backend/tester)
- **B**: 새 agent 4 (lead 도 별도 신설, feature 전용 lead)
- **현재 기울기**: A (pm.md 재사용 = R-2 정합, 모든 preset lead 일관)

### 결정 3 — #009-E security preset 멤버 양식
- 마스터플랜 §2.4 = "security: 3명 (SAST/DAST/compliance)"
- 본 비전의 review preset 의 security-reviewer 와 차원 다름:
  - review/security-reviewer = OWASP/CVE 코드 리뷰 차원
  - security preset/SAST = 정적 분석 도구 운영
  - security preset/DAST = 동적 분석 도구 운영
  - security preset/compliance = 정책·표준 준수 검증
- **A**: 새 agent 3 신설 (sast-analyst·dast-analyst·compliance-checker)
- **B**: review/security-reviewer 재사용 + 새 agent 2 (DAST·compliance)
- **현재 기울기**: A (차원 명확 분리 = R-12 정합)

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유
- **#009 = Phase 1 본 공사** (마스터플랜 §10.2 v2 P0 항목 흡수). 본 세션 4 turn 진행으로 5/6 PASS, #009-E 만 잔여.
- **#009-E 진입 의무**: 마스터플랜 §2.4 표가 7 preset 명세인데 현재 5/7 PASS. feature/security 보류 = "표 정합 깨짐" 상태. Phase 2 (`/agent-office`) 진입 전 선결 의무.
- **#021 진입 가치**: Day 20 turn 3 부수 발견 = 운영 ~/.claude/teams/ 71개 全 orphan. validate-team / shutdown-team 의 실제 가치 결정적 검증. 운영 위생 정리 = 가벼운 작업.

### 본 세션 누적 결과 (Day 20 turn 1·2·3·4)
- **#009-B + #009-C + #009-D-1 + #009-D-2 全 PASS** = 4 turn 진행
- **D 결정 10건**: D-16~D-25 (단방향 정책 + 양식 SSOT + scripts 책임 분리 + reference on-demand)
- **R 부수 발견 5건**: R-11~R-15 (variations + dimension + §변경 이력 + orphan + BOM)
- **메모리 1건 갱신** (`agent-office-vision.md`): turn 1·2·3·4 결과 5 항목 추가
- **양식 v2 dogfood 12건 누적** (turn 4 = 12건째), `/checklist mode=mixed` 9건째 + mode=code 1건째

### 주의 사항

1. **🚨 섹션 생략** — 본 turn 4 종료 시 사용자 사전 조치 의무 0건. 단순 다음 turn 진입.
2. **글로벌 강제 규칙 5번째 의무 준수** (`~/.claude/CLAUDE.md` Agent Preferences) — 모든 Agent spawn `model` 명시. 강제 훅 활성 (turn 7 PASS, fallback C+ 영구 적용).
3. **글로벌 외부 리서치 의무** (`~/.claude/rules/research-mandatory.md`) — #009-E 진입 시 wshobson `preset-teams.md` 양식 차용은 외부 출처 인용 의무 (체크리스트 §근거 명시).
4. **agents/presets/scripts/reference 스테이징/운영 분리 정책** (D-11/D-16/D-22) — 단방향 sync, 역방향 금지.
5. **Haiku 0건 정책** (`feedback_no_haiku.md`) — #009-E 새 agent 7 全 model = opus (lead) 또는 sonnet (나머지).
6. **소멸 정책 16회차 검증** — 본 HANDOFF turn 4 가 다음 세션에서 `/handoff done` 처리되면 16회차.

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `HANDOFF.md` — 본 파일 (양식 v2 13건째 적용 케이스)
- `.todo.md` — #009-E + #021 잔여 백로그

### 옵션 A 입력 자료 (#009-E)
- `agents/*.md` × 12 (turn 11 신설) — 양식 차용 기준 (R-10 일관 정책 정합)
- `agents/pm.md` (turn 11) — feature preset lead 재사용 후보 (결정 2 A 안)
- `agents/security-reviewer.md` (turn 11) — security preset 재사용 후보 (결정 3 B 안 시)
- `presets/*.yaml` × 5 (Day 20 turn 1 신설) — 양식 차용 기준 (D-17 정합)
- `docs/research/agent-office-masterplan/04_masterplan.md §2.4` (L229~238) — feature·security 표 명세
- `docs/research/agent-office-masterplan/02_external-deep.md §6` — wshobson HEAD `ece811f23310a37ceb43496dbac0e244fe6845b6` `preset-teams.md` (feature/security preset 양식 차용)

### 옵션 B 입력 자료 (#021)
- `skills/agent-team-manager/scripts/validate-team.ps1` (turn 3 신설) — `-AllTeams -Format json` 으로 orphan 列舉
- `skills/agent-team-manager/scripts/shutdown-team.ps1` (turn 3 신설) — `-Team <name>` 으로 archive
- `skills/agent-team-manager/reference/anti-patterns.md` (turn 4 신설) — A14 (orphan) 검출·Fix 절차

### Phase 2 진입 자료 (옵션 C, 권장 X)
- `skills/agent-team-manager/SKILL.md` v2.5 §8 마이그레이션 안내 (Phase 1 → Phase 2 흐름도)
- `docs/research/agent-office-masterplan/04_masterplan.md §10.2` v2 P0/P1 항목

### 본 세션 산출물 (turn 1·2·3·4 결과)
- turn 1: `presets/*.yaml` × 5 (439줄) + 운영 sync + history §11 + index.md 갱신
- turn 2: `skills/agent-team-manager/SKILL.md` v2 (355줄) + 운영 sync + history §11 + index.md 갱신
- turn 3: `skills/agent-team-manager/scripts/*.ps1` × 6 (~750줄) + 운영 sync + history §12 + index.md 갱신
- turn 4: `skills/agent-team-manager/reference/*.md` × 4 (~530줄) + SKILL.md v2.5 (387줄) + 운영 sync + history §13 + index.md 갱신

### 메모리 (자동 로드)
- `agent-office-vision.md` — 본 turn 4 갱신 = Day 20 turn 1·2·3·4 결과 5 항목 추가
- `feedback_no_haiku.md` — Haiku 운영 제외 (#009-E 새 agent 7 全 model = opus 또는 sonnet)
- `pm-external-research-mandatory.md` — PM 한정 강제 (글로벌 superset 위에)
- `agent-team-skill-redesign.md` — v2 위치 재조정 (#009 진행 中)
- `feedback_commit_push.md` — commit + push 한 단위
- `skill-load-scope.md`, `project_deployment_target.md`

### Git
- 브랜치: main
- 마지막 커밋 (turn 4): `e7c60a6` (turn 4 #009-D-2 PASS)
- 본 turn 4 종료 시 commit (예정): `chore: HANDOFF turn 4 (#009-E + #021 잔여 인계)`
- push: 한 단위 (메모리 `feedback_commit_push.md`)

### 외부 출처 (옵션 A 진입 시 인용 의무)
- [wshobson/agents](https://github.com/wshobson/agents) HEAD `ece811f23310a37ceb43496dbac0e244fe6845b6` (2026-05-02) — `plugins/agent-teams/skills/team-composition-patterns/references/preset-teams.md` (feature/security preset 양식 차용)
- [aws-samples/sample-claude-code-agent-team](https://github.com/aws-samples/sample-claude-code-agent-team) HEAD `67840be315fad3ef252c06ccfe35d6ab9a2d43d6` (2026-04-29) — `skills/spec-workflow/SKILL.md:65` review cycle cap 인용 (preset YAML 양식 정합)
