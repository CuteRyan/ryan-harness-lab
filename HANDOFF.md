# HANDOFF — 2026-05-01 후속3 세션 인계서

> 생성: 2026-05-01 PM (Day 17 후속3 turn 종료 시점) | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 작성자: Day 17 후속3 turn 메인 Claude

---

## 마지막 상태 (어디까지 했나)

- 작업: **Day 17 후속3** — agent-team-manager v2 #009 구현 직전 토론에서 **Agent-office 비전 확장 발견** → 4인 리서치 팀 별건 진행 결정
- 진행률:
  - ✅ v2 스펙 (X1) vs Sub-agent only (X2/X4) vs 2-runtime 분리 (X5) 5 옵션 비교 토론
  - ✅ 외부 9 사례 재확인 (`02_community-patterns.md` 4가지 결합 모델: Plugin-as-team / Runtime-split / Pattern-library / Meta-factory)
  - ✅ 주인님 비전 추출 = **Agent-office** (큰 그림)
    - 프로젝트별 영속 PM 에이전트 + 영속 워커
    - 2단계 호출 (메인 Claude → PM 1인 팀 → PM 이 패턴·실행방식 동적 결정)
    - PM 이 Sub-agent / Agent Teams 빌딩 / 외부 CLI 중 적합한 거 선택
  - ✅ /feedback 단발성 본질 = **앵커링 회피** (검증 시 fresh 인스턴스 필수)
  - ✅ 결정 3건 확정 (D-1/D-2/D-3 — 아래 §결정 포인트 참조)
  - ✅ 4인 리서치 팀 구성 + 산출물 6개 파일 합의
  - ✅ HANDOFF/.todo/히스토리/메모리 갱신 (본 turn 산출물)
- 마지막 편집 파일: `HANDOFF.md` (본 파일)
- working tree: 커밋 직전

## 미완 작업 (지금 하다 멈춘 것)

- [ ] **#010 agent-office 마스터플랜 4인 리서치** (신규, priority high) — 다음 세션 즉시
- [ ] **#009 agent-team-manager v2 구현** (priority normal 유지) — 마스터플랜 산출물 §5 migration_plan 의 Phase 1 인프라로 위치 재조정 예정. 마스터플랜 미완 상태에서 단독 구현은 **금지** (큰 그림 위에 1층이 들어가야 어색하지 않음)

## 다음 세션 시작 지점

1. **`HANDOFF.md` Read 후 `/handoff done`** 처리 (소멸 정책 다섯 번째 검증)
2. **`.todo.md` #010 in_progress 마크** + `/checklist` 신설 (Day 17 §5 자백 재발 방지 약속 — 이번엔 반드시 지킬 것)
3. **4인 리서치 팀 빌딩** — 글로벌 CLAUDE.md Agent Preferences 준수 (TeamCreate + TaskCreate + Agent + SendMessage 4-step):
   - 팀명: `agent-office-masterplan`
   - 산출물 디렉토리: `docs/research/agent-office-masterplan/`
   - 4 teammate (specialized):
     - `architect-researcher` — 공식 docs 깊이 (PM 1인 팀 메커니즘, hooks, MCP·Skill teammate 전파, /resume 한계, Task isolation worktree)
     - `external-pattern-researcher` — 외부 사례 재리서치 (revfactory/harness Meta-factory 깊이 / barkain task-completion-verifier / oh-my-claudecode 2-runtime 최신 / Anthropic blog scaling heuristic 재조사)
     - `office-design-analyst` — Gap 분석 (v2 스펙 + /feedback 현재 + 주인님 비전 3자 비교, /feedback 단발성 vs Agent-office 영속성 분리 명시)
     - `master-architect` — Agent-office 마스터플랜 + v2 → 마스터플랜 단계별 마이그레이션
4. **task graph** (`addBlockedBy` 체인):
   - Task 1 (architect-researcher) → output: `01_official-docs-deep.md`
   - Task 2 (external-pattern-researcher) → output: `02_external-deep.md`
   - Task 3 (office-design-analyst) — blocked_by [1, 2] → output: `03_gap-analysis.md`
   - Task 4 (master-architect) — blocked_by [3] → output: `04_masterplan.md` + `05_migration_plan.md`
   - Task 5 (master-architect) — blocked_by [4] → output: `00_요약.md`
5. **4인 팀에 입력으로 전달할 결정 포인트 3개**: §결정 포인트 (D-1/D-2/D-3)

## 결정 포인트 (4인 리서치 팀이 입력으로 받을 것)

### D-1. PM 메커니즘 = Agent Teams 1인 팀

- PM 호출 시: `TeamCreate` → 1인 팀 (members = [PM]) → 메인 Claude 가 lead
- 메인 Claude ↔ PM = `SendMessage` 1:1 양방향 (= 1:1 톡)
- **R3 (응답 안 함 / 알림 중복) 회피 메커니즘**: 멀티 teammate 가 아니라 1:1 이므로 시스템 알림과 사람 지시 충돌 없음
- 일반 한계 (`/resume` 불가 / `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 필수 / experimental) 는 그대로 받음
- 4인 팀이 깊이 다룰 점: PM 1인 팀의 **검증된 외부 사례 유무** + **Anthropic 공식 문서에서 1인 팀 명시 여부** + **세션 종료 시 PM 컨텍스트 영속화 메커니즘** (Agent Teams 는 `/resume` 불가 → 어떻게 다음 세션이 동일 PM 호출하는가?)

### D-2. /feedback 통합 = 옵션 α (그대로 단발 유지)

- `/feedback` 은 Agent-office 가 호출만, **메커니즘 통합 X**
- 사유: **/feedback 단발성의 본질은 앵커링 회피** (검증 시 fresh 인스턴스 필수, 객관성 보장)
- Agent-office 워커는 영속 (D-3) — 단발성/영속 운영 충돌 방지
- **하부 헬퍼는 라이브러리화 가능**: CLI 호출 (`run-codex.ps1`, `run-gemini.ps1`) / 격리 디렉토리 / 인코딩 헬퍼 (`_encoding.ps1`) — 두 스킬이 같은 라이브러리 사용
- 4인 팀이 깊이 다룰 점: 헬퍼 라이브러리 공유 디렉토리 위치 (`~/.claude/lib/`? `~/.claude/skills/_shared/`?) + 명세 + /feedback 의 현재 격리 디렉토리 패턴이 영속 워커 워크스페이스와 어떻게 분리되는가

### D-3. Agent-office 워커 라이프사이클 = persistent (영속)

- preset YAML 에 `lifecycle: ephemeral | persistent` 필드 추가
- **persistent**: 호출 간 컨텍스트 유지 (작업류 — PM, 개발자, 디자이너, 리서처 등)
- **ephemeral**: 매 호출 fresh (검증류 — `/feedback` 식)
- 본질 차이: 검증 = **객관성 (앵커링 방지)**, 작업 = **누적 (이전 작업 기억)**
- 4인 팀이 깊이 다룰 점: persistent 워커의 **컨텍스트 영속화 구체 메커니즘** (Agent Teams 자체는 `/resume` 불가 → 어떻게 영속? 워크스페이스 파일 / status 파일 / preset YAML 의 history 필드?) + ephemeral 워커가 Agent-office 안에 존재할 필요가 있는지 (없으면 /feedback 만으로 충분)

## 컨텍스트 (배경 이해용)

### 이 작업을 하는 이유

- 9일 보류된 v2 §9 결정을 5-1 첫 후속 turn 에서 마무리 → 후속2 turn 에서 인계 → **본 후속3 turn 에서 #009 구현 들어가기 직전 주인님이 더 큰 비전 제시**
- 주인님 비전 = **Agent-office** (프로젝트 = 회사 / PM 상시 / 영속 워커 / 동적 팀 구성)
- v2 스펙은 이 비전의 부분집합 — 단순히 v2 만 짓고 나서 PM 얹으면 어색해짐. 처음부터 큰 집의 설계도 그리고 1층부터 짓는 게 깔끔
- /feedback 통합 토론에서 단발성/영속성 본질 차이 발견 → 워커 라이프사이클 분류로 일반화

### 본 turn 시행착오 (재발 방지)

- **첫 답변에서 X1~X5 5 옵션 표 던짐** (베타라도 쓰자 / Sub-agent only / 하이브리드 / 2-runtime 등) → 주인님 "더 쉽게" 요청 → 식당 비유로 길 ①/②/③ 3개로 압축 → 이해 도달
- **외부 사례 다시 펼쳐달라는 요청** → 02_community-patterns.md 9개 사례를 비유로 풀어드림 → 주인님 비전 (Agent-office) 가 거기서 추출됨
- **/feedback 단발성 이유** = 주인님이 짚으신 앵커링. 처음 답변에 못 적은 사항 — **검증 = 객관성 = 단발 / 작업 = 누적 = 영속** 본질 분리 발견
- **교훈**: 비유 + 추천 의견 + 옵션 압축 (3개 이하) 이 결정 즉답을 끌어냄. 5 옵션 표는 부담만 줌

### 주의 사항

1. **글로벌 CLAUDE.md Agent Preferences 준수** — "설계·계획·분석·구현은 무조건 팀". 4인 리서치는 진짜 Agent Teams (TeamCreate + SendMessage) 사용 필수. 단순 Sub-agent 다중 호출 금지
2. **`/checklist` 호출 본 turn 누락** — Day 17 §5 자백 재발. 다음 세션 #010 시작 전 **반드시 호출** (이번이 세 번째 검증 시그널)
3. **PM 1인 팀 자체도 Agent Teams 라 R1~R4 일반 한계는 받음** — `/resume` 불가가 가장 큰 우려 (PM 영속화 어떻게?)
4. **마스터플랜 산출물 §4 에 옵션 α/β/γ 결정 명시 필수** — α 권장 (단발성 본질) 이지만 4인 팀이 반박 검토 후 확정

## 관련 파일

### 핵심 시작 지점 (다음 세션 첫 Read 대상)
- `Harness-engineering/HANDOFF.md` — 본 파일 (확인 후 `/handoff done` 처리)
- `Harness-engineering/.todo.md` — #010 (마스터플랜) + #009 (v2 구현, normal 유지)
- `Harness-engineering/docs/history/2026-05-01.md` §8 — 본 토론 흐름 + Agent-office 비전 추출 과정
- `Harness-engineering/docs/research/agent-team-skill-redesign/02_community-patterns.md` — 외부 9 사례 (4인 팀이 깊이 다룰 입력)
- `Harness-engineering/docs/research/agent-team-skill-redesign/04_redesign-spec.md` — v2 스펙 (마스터플랜의 1층 인프라로 위치 재조정 대상)

### 신규 메모리 (다음 세션 자동 로드)
- `agent-office-vision.md` — 주인님 비전 (프로젝트별 PM YAML / 2단계 호출 / 워커 라이프사이클 / /feedback 단발 분리)
- `agent-team-skill-redesign.md` — 갱신 (마스터플랜으로 비전 확장 명시)

### 참조 (이해 보강용)
- `Harness-engineering/docs/research/agent-team-skill-redesign/01_official-docs.md` — Agent Teams 공식 docs (PM 1인 팀 명시 여부 4인 팀이 검증)
- `Harness-engineering/docs/research/agent-team-skill-redesign/03_gap-analysis.md` — v2 의 P0/P1 gap (마스터플랜이 어떻게 흡수하는지 재평가)
- `~/.claude/skills/feedback/SKILL.md` — 단발성 / 격리 디렉토리 / Validation Gate 5게이트 / 외부 훅 (라이브러리 공유 후보)
- `~/.claude/CLAUDE.md` — Agent Preferences (마스터플랜 §6 에서 갱신 대상)

### 본 turn 산출물 (커밋 예정)
- `.backups/HANDOFF.done.2026-05-01-v2.md` — 5-1 후속2 인계서 소멸 (소멸 정책 **네 번째 검증**)
- `HANDOFF.md` — 본 파일 (5-1 후속3 인계서 신설)
- `docs/history/2026-05-01.md` §8 — 본 토론 47줄 추가
- `.todo.md` — #010 신규 + #009 description 보강 (마스터플랜 후 위치 재조정)
- 메모리 신규 1건 + 갱신 1건

### Git
- 브랜치: main
- 원격: `https://github.com/CuteRyan/ryan-harness-lab.git`
- 마지막 커밋: `6f006c6` (Day 17 후속2)
- 본 turn 커밋 메시지 (예정): `docs+chore: Day 17 후속3 — agent-office 비전 토론 + 마스터플랜 4인 리서치 #010 신규`
