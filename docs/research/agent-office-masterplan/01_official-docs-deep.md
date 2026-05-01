---
title: "공식 docs 깊이 리서치 — Agent Teams API 한계 + 모델 배분 검증"
owner: architect-researcher
date: 2026-05-01
scope: Task 1 of agent-office-masterplan
parent_doc: agent-office-vision.md
model: sonnet
---

# 공식 docs 깊이 리서치 — Agent Teams API 한계 + 모델 배분 검증

## 0. Executive Summary

- **`/resume` 불가는 영속화 문제와 무관** — 주인님 R-1 반박 확인. `pm.yaml` + 외부 자산 패턴(메인 Claude와 동일)으로 완전히 해소됨.
- **teammates는 main session보다 5개 도구 적음 (20개 vs 25개)** — Agent(spawner), TeamCreate, TeamDelete, CronCreate/Delete/List 없음. 즉 teammate가 PM 역할 불가 — D-1 (PM = main Claude가 lead) 강하게 지지.
- **subagent의 `skills`/`mcpServers` frontmatter는 teammate로 쓸 때 미적용** — 공식 docs 명시. teammate는 project/user settings에서 로드. `/feedback` 스킬 호출은 별도 메커니즘 필요.
- **`isolation: worktree`는 subagent frontmatter 공식 지원 필드** — ④ 파이프라인 패턴에 직접 활용 가능. 자동 생성·자동 정리.
- **TeammateIdle/TaskCreated/TaskCompleted 훅은 공식 docs에 명시** — D-3 워커 lifecycle 강제 및 자동 `/feedback` 트리거 구현 기반.
- **모델 지정은 4단계 우선순위** — CLAUDE_CODE_SUBAGENT_MODEL env > 호출 시 model 파라미터 > frontmatter model > 메인 대화 모델. 단, Opus main이 Sonnet worker를 spawn할 때 호출 파라미터가 frontmatter를 덮어쓸 수 있어 주의 필요 (issue#32732).
- **Windows + psmux split-pane은 경로 인용 버그 존재** (issue#42848, v2.1.90 기준 미해결) — 주인님 환경에서는 in-process 모드 사용 권장.

---

## 1. Agent Teams API 한계

### 1.1 환경 요건

| 요건 | 내용 | 출처 |
|------|------|------|
| 환경변수 | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (settings.json env 또는 shell) | [공식 docs](https://code.claude.com/docs/en/agent-teams) |
| 최소 버전 | Claude Code v2.1.32+ | [공식 docs](https://code.claude.com/docs/en/agent-teams) |
| 확인 방법 | `claude --version` | [공식 docs](https://code.claude.com/docs/en/agent-teams) |

```json
// settings.json에서 활성화
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### 1.2 `/resume` 불가 — 비전 영향 분석

**공식 docs 명시 한계:**

> `/resume` and `/rewind` do not restore in-process teammates. After resuming a session, the lead may attempt to message teammates that no longer exist. If this happens, tell the lead to spawn new teammates.

**비전(D-1)과의 관계:**
이는 "세션 컨텍스트 복원 불가"이지, "PM이 역할을 기억 못 한다"는 뜻이 아님. 주인님 R-1 반박이 정확함:

- 메인 Claude도 매 세션 새로 시작 → CLAUDE.md 읽고 역할 인지
- PM도 똑같음 → `pm.yaml` 읽고 "내 역할 = PM" 인지 → 필요 시 history/결정 log 읽음
- `/resume` 불가 = 진행 중인 teammate 프로세스 복원 불가 (런타임 상태 소멸)
- `/resume` 불가 ≠ 역할/지식 영속화 불가 (외부 자산은 그대로)

**결론**: R-1 해소 패턴이 공식 아키텍처와 완전히 일관함. 영속화는 `pm.yaml` + `docs/history/` + `memory/`로 충분.

### 1.3 한 세션당 1 team 한계

**공식 docs 명시:**

> One team per session: a lead can only manage one team at a time. Clean up the current team before starting a new one.

**비전과의 관계:**
- D-1: PM = Agent Teams 1인 팀 → 메인 Claude가 lead
- 이 한계는 메인 Claude(lead)가 동시에 PM 팀 + 워커 팀을 운영할 수 없다는 의미
- **비전 설계 재확인 필요**: "PM = 1인 팀" 이후 PM이 ② 회의실(멀티 워커 팀)을 다시 TeamCreate로 spawn하면 오류 → **PM 팀 teardown 후 워커 팀 생성** 또는 **PM을 1인 팀이 아닌 subagent로 대체** 검토 필요
- 현실적 대안: PM은 `SendMessage` 기반 1인 팀이 아니라 단순 `Agent` 도구 호출(subagent) + 커스텀 system prompt로 구현 가능. 팀 슬롯을 워커 팀에 온전히 양보.

### 1.4 nested team 불가 (issue#32723, #32731)

**공식 docs 명시:**

> No nested teams: teammates cannot spawn their own teams or teammates. Only the lead can manage the team.

**issue#32731 발견 (2026-05-01 확인):**
공식 docs가 축소하여 표현. 실제 teammate 제한은 더 광범위함:

| 도구 | Main Session | Subagent (25개) | Teammate (20개) |
|------|--------------|-----------------|-----------------|
| Agent (spawner) | ✅ | ✅ | ❌ |
| TeamCreate | ✅ | ✅ | ❌ |
| TeamDelete | ✅ | ✅ | ❌ |
| CronCreate/Delete/List | ✅ | ✅ | ❌ |
| SendMessage | ✅ | ✅ | ✅ |

**비전과의 관계:**
- teammate(회의실 워커)는 subagent를 spawn 불가 → ④ 파이프라인 재귀 호출 불가
- teammate는 팀 관리 불가 → 비전의 "PM = teammate" 구조는 근본적으로 불가
- **D-1 검증**: PM = main Claude가 lead 되어야 함이 아키텍처적으로 강제됨

**issue#32723 역설적 사실:**
standalone subagent는 TeamCreate를 호출할 수 있지만 Agent 도구가 없어 빈 팀 shell만 생성. 고아 `~/.claude/teams/<name>/config.json` 생성 주의. subagent에서 TeamCreate 사용 시 `disallowedTools: ["TeamCreate", "TeamDelete"]`로 차단 권장.

### 1.5 기타 한계

| 한계 | 공식 docs 명시 | 비전 영향 |
|------|--------------|----------|
| Lead 교체 불가 | "Lead is fixed: the session that creates the team is the lead for its lifetime." | D-1 확정 — 메인 Claude = lead 고정 |
| Split-pane Windows 미지원 | "Split-pane mode isn't supported in VS Code's integrated terminal, Windows Terminal, or Ghostty." | 주인님 환경: **in-process 모드 사용** |
| Task 상태 지연 | "Teammates sometimes fail to mark tasks as completed" | TaskCompleted 훅으로 보완 가능 |
| Shutdown 느림 | "Teammates finish their current request or tool call before shutting down" | lifecycle 설계 시 grace period 고려 |
| Spawn 시 permission 고정 | "All teammates start with the lead's permission mode" | 스킬 entry에서 lead permission 미리 설정 |

---

## 2. TeamCreate / Agent / SendMessage / TaskCreate 권한 차이

### 2.1 컨텍스트별 도구 가용성

| 도구 | Main Session | Skill-fork | Subagent | Teammate |
|------|--------------|------------|----------|----------|
| TeamCreate | ✅ | ✅ | ✅ (빈 shell만 — 비권장) | ❌ |
| TeamDelete | ✅ | ✅ | ✅ (비권장) | ❌ |
| SendMessage | ✅ | ✅ | ✅ | ✅ |
| Agent (spawner) | ✅ | ✅ | ❌ | ❌ |
| TaskCreate | ✅ | ✅ | 미확인 | ✅ |

**출처:** [issue#32723](https://github.com/anthropics/claude-code/issues/32723), [issue#32731](https://github.com/anthropics/claude-code/issues/32731), [공식 docs](https://code.claude.com/docs/en/agent-teams)

### 2.2 PM 메커니즘 선택 함의

**D-1 "PM = Agent Teams 1인 팀"의 숨은 한계:**
PM이 1인 팀의 teammate로 spawn되는 순간 Agent 도구와 TeamCreate를 잃음. PM이 ②③④ 워커를 spawn하려면 반드시 메인 Claude(lead)를 통해야 함.

두 가지 구현 경로:

**경로 A (현행 D-1 유지):** PM = 1인 팀 teammate. PM이 워커 spawn 요청 → SendMessage로 lead에게 전달 → lead가 대신 spawn. 간접 경로지만 비판자 역할 격리 효과는 유지.

**경로 B (대안):** PM = subagent (팀 없이). `Agent(model="opus", system_prompt="PM 역할...")` 직접 호출. Agent 도구 있어 이론적 spawn 가능하지만 실제 subagent는 다른 subagent spawn 불가. 동일 한계.

**결론:** D-1 구조 (메인 Claude = lead, PM = 1인 팀 teammate) 유지 시, PM은 "분석·반박·추천"만 하고 실제 spawn은 lead가 함. 이 분리가 오히려 역할 명확성을 높임. **D-1 비전 검증됨**, 단 "PM이 직접 spawn"이라는 착각은 수정 필요.

---

## 3. Skill / MCP teammate 전파

### 3.1 공식 docs 명시 (critical)

> The `skills` and `mcpServers` frontmatter fields in a subagent definition are not applied when that definition runs as a teammate. Teammates load skills and MCP servers from your project and user settings, the same as a regular session.

**출처:** [공식 docs - agent teams: Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)

### 3.2 teammate에서 적용되는 것 vs 적용 안 되는 것

| 필드 | teammate로 쓸 때 적용 여부 | 비고 |
|------|--------------------------|------|
| `tools` | ✅ 적용 | 허용 목록 적용됨 |
| `model` | ✅ 적용 | 해당 teammate 모델 지정 |
| body (system prompt) | ✅ 일부 적용 | 팀 coordination 지시에 추가(append)됨 |
| `skills` frontmatter | ❌ 미적용 | project/user settings에서 로드 |
| `mcpServers` frontmatter | ❌ 미적용 | project/user settings에서 로드 |

### 3.3 비전(D-2) 영향 — `/feedback` 단발 호출

D-2: `/feedback` 단발 유지 + 헬퍼 라이브러리 공유

**teammate에서 `/feedback` 스킬 호출 가능 여부:**
- teammate는 project/user settings의 skills를 로드 → `~/.claude/skills/feedback/SKILL.md`가 있으면 teammate도 인식 가능
- 단, `/feedback`이 PowerShell 스크립트(`run-codex.ps1`, `_encoding.ps1` 등)를 `Bash`/`PowerShell` 도구로 직접 호출하는 구조면 teammate도 실행 가능 (tools 허용 시)
- **핵심 제약**: teammate가 외부 프로세스(Codex, Gemini)를 직접 spawn하는 것은 Bash 도구 허용이면 가능. `mcpServers` frontmatter만 미적용.

**결론:** `/feedback` 호출은 teammate에서도 가능하지만, skills frontmatter로 강제 주입은 안 됨 — project/user settings에 등록된 스킬을 teammate가 자연스럽게 invoke하는 방식으로 사용. D-2 큰 영향 없음.

---

## 4. Task isolation worktree

### 4.1 공식 docs 명시

**subagent frontmatter 지원 필드로 공식 등재:**

| 필드 | 필수 여부 | 설명 |
|------|---------|------|
| `isolation` | No | `worktree` 설정 시 subagent에 repository 격리 복사본 제공. subagent가 변경사항 없으면 자동 정리 |

**출처:** [공식 docs - sub-agents: supported frontmatter fields](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

```yaml
---
name: safe-refactoring-worker
description: 파일 리팩터링 전담 워커
isolation: worktree
model: sonnet
---
```

### 4.2 동작 메커니즘

- **자동 생성**: subagent 실행 시 git worktree 자동 생성 (`.claude/worktrees/[name]/` + 브랜치 `worktree-[name]`)
- **자동 정리**: subagent 종료 시 변경사항 없으면 worktree + 브랜치 자동 삭제
- **변경사항 있으면 유지**: 검토 후 수동 처리 또는 merge
- **충돌 방지**: 멀티 워커 병렬 실행 시 각자 격리된 복사본에서 작업 → 파일 충돌 원천 차단
- **고아 worktree 자동 정리**: 크래시 후 `cleanupPeriodDays` 설정 기준 초과 시 시작 시 자동 제거

**출처:** 공식 docs + [issue#27023: isolation worktree 문서 추가 요청 → 반영됨](https://github.com/anthropics/claude-code/issues/27023)

### 4.3 aws-samples 언급 vs 공식 docs

`02_community-patterns.md` §7에서 "aws-samples 언급, 공식 docs 명시 여부 미확인"으로 기록됨. **현재 공식 docs에 명시됨 (미확인 해소).**

### 4.4 비전(④ 파이프라인) 활용 가능성

④ 파이프라인 패턴(zircote 7패턴) 중 **Multi-File Refactoring** / **Swarm** 패턴에서 직접 활용 가능:

```yaml
# 예: Multi-File Refactoring 워커
---
name: refactor-worker
isolation: worktree
model: sonnet
---
```

각 워커가 독립 브랜치에서 작업 → fan-in 시 merge 전략 필요. **⑤ 파이프라인 패턴 설계 시 이 흐름을 표준화해야 함.**

---

## 5. Hooks (TeammateIdle / TaskCreated / TaskCompleted)

### 5.1 공식 docs 명시

공식 docs [agent-teams: Enforce quality gates with hooks](https://code.claude.com/docs/en/agent-teams#enforce-quality-gates-with-hooks) 섹션에 명시:

| 훅 | 트리거 시점 | exit 2 동작 | 비고 |
|----|-----------|------------|------|
| `TeammateIdle` | teammate가 idle 상태로 전환 직전 | teammate가 계속 작업 | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 필요 |
| `TaskCreated` | TaskCreate 호출 시 | 태스크 생성 롤백 | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 필요 |
| `TaskCompleted` | 태스크 완료 마킹 시 | 완료 차단 | CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 필요 |

**Matcher 지원 여부:** 세 훅 모두 matcher 미지원 — 모든 발생에 실행됨.

### 5.2 settings.json 등록 방법

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "type": "command",
        "command": "path/to/idle-check.sh"
      }
    ],
    "TaskCompleted": [
      {
        "type": "command",
        "command": "path/to/quality-gate.sh"
      }
    ],
    "TaskCreated": [
      {
        "type": "command",
        "command": "path/to/validate-task.sh"
      }
    ]
  }
}
```

### 5.3 비전(D-3) lifecycle 강제 활용 방안

D-3: `lifecycle: ephemeral | persistent` 필드로 워커 타입 구분

**훅 기반 lifecycle 강제 구현:**

1. **TeammateIdle → persistent 워커 재활성**: idle 직전에 "다음 태스크 있나?" 체크 → exit 2로 계속 작업 지시 가능
2. **TaskCompleted → 품질 게이트**: 태스크 완료 전 테스트/린팅 자동 실행. 실패 시 exit 2로 완료 차단
3. **TaskCreated → 태스크 유효성 검증**: PM이 만든 태스크가 조건 미충족 시 롤백 (예: 너무 모호한 task 차단)

**`/feedback` 자동 호출 트리거:**
```bash
# TaskCompleted 훅 예시
#!/bin/bash
# 태스크 완료 시 /feedback 호출
# 완료된 산출물 파일 경로를 피드백 대상으로
TASK_FILE=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.taskFile // empty')
if [ -n "$TASK_FILE" ]; then
  # 메인 Claude에게 /feedback 호출 신호 전송
  echo "feedback_trigger: $TASK_FILE" >> /tmp/pending-feedback.log
fi
exit 0  # 완료 차단 아님, 트리거만
```

**주의:** 훅에서 exit 2는 "차단 + 피드백 전달"이므로, `/feedback` 자동 호출용으로는 exit 0 유지하고 별도 로그 파일 기반 비동기 트리거를 권장. (exit 2로 무한 루프 방지)

---

## 6. 한글 경로 안정성

### 6.1 Agent Teams config 저장 경로

Agent Teams 구성 요소는 모두 홈 디렉토리 하위 영문 경로에 저장됨:

| 구성요소 | 저장 경로 | 한글 영향 |
|---------|---------|---------|
| Team config | `~/.claude/teams/{team-name}/config.json` | 영향 없음 |
| Task list | `~/.claude/tasks/{team-name}/` | 영향 없음 |
| Mailbox | 내부 처리 | 영향 없음 |
| Subagent definitions | `~/.claude/agents/` or `.claude/agents/` | 프로젝트 경로 영향 |

**Agent Teams 메타 구조 자체는 한글 경로 무관.** `~/.claude/`는 영문 홈 경로이므로 안전.

### 6.2 실제 위험 지점

**팀 워커가 한글 경로 파일 직접 처리할 때:**

- `C:\Users\rlgns\OneDrive\문서\Harness-engineering\...` 경로의 파일 Read/Write
- Windows PowerShell에서 한글 경로 인수 전달 시 인코딩 이슈 가능성
- psmux split-pane 모드에서 경로 관련 추가 이슈 (issue#42848)

### 6.3 기존 시행착오와 연계 (2026-04-19 실측)

`~/.claude/CLAUDE.md` codex_workdir 섹션 기록:
- Codex: 한글 경로 CP949 깨짐 / UTF-8 재시도 정책 차단 / 재귀 스캔 폭주
- Gemini: 영향 없음

**Agent Teams + 한글 경로 권장 대응:**
1. **in-process 모드 사용** (psmux split-pane 회피) — Windows Terminal/VS Code에서는 split-pane 미지원이므로 자동으로 in-process
2. **teammate spawn prompt에 절대 경로 명시** 시 영문 단축 경로 또는 UNC 대신 한글 경로 그대로 사용 가능 (Claude Code 자체는 한글 경로 처리 가능, Codex/Gemini 혼용 시에만 주의)
3. **외부 CLI (③ Codex) 호출 시**: 기존 `codex_workdir` 패턴 (영문 경로 복사본) 그대로 유지

### 6.4 OneDrive + agent teams config 경로 관련 주의

issue#35513: Explore agent가 scoped 경로 외부 파일 접근 → OneDrive cloud-only 파일 강제 다운로드 관측됨. Agent Teams 워커의 파일 탐색 범위도 동일 위험. **spawn prompt에 "이 경로 외 탐색 금지" 명시 권장.**

---

## 7. 모델 지정 메커니즘

### 7.1 모델 해석 우선순위 (공식 docs)

```
1. CLAUDE_CODE_SUBAGENT_MODEL 환경변수 (설정 시)
2. Agent 도구 호출 시 model 파라미터
3. subagent 정의의 model frontmatter
4. 메인 대화 모델 (inherit 또는 미지정 시 기본값)
```

**출처:** [공식 docs - sub-agents: Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)

### 7.2 frontmatter model 필드 지원값

```yaml
model: sonnet          # Sonnet 별칭
model: opus            # Opus 별칭
model: haiku           # Haiku 별칭
model: claude-opus-4-7  # 전체 모델 ID
model: claude-sonnet-4-6
model: inherit          # 메인 대화 모델 그대로 (기본값)
```

### 7.3 teammate에서의 모델 지정

teammate를 spawn할 때 subagent 정의를 참조하면 해당 정의의 `tools`와 `model`이 적용됨:

```text
Spawn a teammate using the worker-sonnet agent type to handle file refactoring.
```

이때 `worker-sonnet.md`의 `model: sonnet`이 teammate 모델로 적용됨.

### 7.4 알려진 이슈 (issue#32732)

**Agent 도구 model 파라미터가 frontmatter를 덮어씀:**

Opus main session이 subagent를 spawn할 때 호출 파라미터로 모델을 지정하면 frontmatter `model: sonnet`보다 우선함. 실제 사례: 16개 커스텀 에이전트 중 `model: sonnet` 명시한 에이전트도 27세션 중 9세션이 Opus로 실행됨 (issue#173, everything-claude-code).

**이유:** 메인 Claude(Opus)가 Agent 도구 호출 시 명시적 model 파라미터를 자동 추가하는 동작.

**feature request**: issue#32732 — model 필드를 non-overridable(hard enforcement)로 만들어 달라는 요청 → **미해결 (2026-05-01 기준)**.

**회피책:** `CLAUDE_CODE_SUBAGENT_MODEL` 환경변수로 전체 subagent 기본 모델을 Sonnet으로 고정:
```json
{
  "env": {
    "CLAUDE_CODE_SUBAGENT_MODEL": "sonnet"
  }
}
```

### 7.5 D-4 모델 배분 구현 방법 검증

D-4: Opus = 사장(메인 Claude), PM(부장), /feedback 호출·해석 / Sonnet = ①인턴, ②회의실, ④파이프라인

**구현 방법:**

| 역할 | 모델 지정 방법 | 신뢰도 |
|------|-------------|--------|
| 사장 (메인 Claude) | `claude --model opus` 또는 settings.json `model: opus` | 높음 |
| PM (1인 팀 teammate) | subagent 정의 `model: opus` → spawn 시 참조 | 중간 (issue#32732 우회 가능성 있음) |
| ①②④ 워커 | `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` + frontmatter `model: sonnet` 이중 보장 | 중간~높음 |
| ③ 외부 CLI | `run-codex.ps1`, `run-gemini.ps1` 직접 호출 (Claude Code 모델 시스템 외부) | 높음 |

**권장 구현:** `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` 전역 설정 + PM 정의에만 `model: opus` 명시. PM은 팀 spawn으로 생성되므로 subagent와 다른 경로이나 실험 필요.

---

## 8. 비전 (D-1~D-5) 검증 결과

### D-1 PM = Agent Teams 1인 팀 + 비판자·선택자 두 역할

**검증 결과: 조건부 지지 — 구조적 한계 1건 확인**

- 1인 팀 teammate로 spawn된 PM은 Agent 도구, TeamCreate 없음 → PM이 직접 워커 spawn 불가
- 실제 패턴: PM이 SendMessage로 lead에게 spawn 요청 → lead가 대신 실행 (간접 위임)
- "PM = 동적 선택자" 역할은 "분석·추천"으로 한정, 실행은 lead에게 위임하는 명확한 역할 분리
- 이 구조가 오히려 hub-and-spoke 아키텍처와 일관되고 책임이 명확함
- **권고:** SKILL.md에 "PM은 추천하고 lead(메인 Claude)가 spawn한다"는 역할 분리 명시 필요

**한 세션당 1 team 한계 → 대안 필요:**
- PM 1인 팀(SendMessage 기반) + 나중에 워커 팀이 동시에 존재 불가
- **해결안**: 작업 순서 = (1) PM 팀 생성 → 토론 → 합의 → PM 팀 cleanup → (2) 워커 팀 생성 → 실행

### D-2 /feedback 단발 유지 + 헬퍼 라이브러리 공유

**검증 결과: 지지**

- teammate에서 project/user settings 기반 스킬 로드 → `/feedback` 스킬 호출 가능
- skills frontmatter는 teammate에 미적용이지만, user settings에 등록된 스킬은 teammate도 사용
- 헬퍼 라이브러리(`run-codex.ps1` 등)는 Bash 도구 허용 시 teammate에서 직접 실행 가능
- 단발성(앵커링 회피) = fresh 인스턴스 원칙이 공식 docs의 subagent 격리 설계와 일관

### D-3 워커 lifecycle = persistent/ephemeral

**검증 결과: 지지 + 구현 경로 확인**

- `TeammateIdle` 훅으로 persistent 워커 재활성 강제 가능 (exit 2 = 계속 작업)
- `TaskCompleted` 훅으로 품질 게이트 + 완료 차단 가능
- ephemeral 패턴 = `isolation: worktree` + 1회 실행 후 종료 (subagent)
- persistent 패턴 = 팀 teammate로 spawn + TeammateIdle 훅 유지

### D-4 모델 배분 (Opus/Sonnet/외부 CLI)

**검증 결과: 지지 + 이슈 1건 확인 (issue#32732)**

- `model: sonnet` frontmatter + `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` env 이중 보장으로 대부분 해소 가능
- PM(Opus) 지정은 subagent 정의 `model: opus`로 가능하나 lead의 호출 파라미터 덮어쓰기 가능성 → 테스트 필요
- 외부 CLI 모델 지정은 Claude Code 시스템 외부이므로 영향 없음
- 비용 효과는 공식 docs "토큰 비용 선형 증가" + aws-samples/wshobson 3개 출처로 Sonnet 워커 정당성 지지

### D-5 최종 의사결정권자 = 주인님

**검증 결과: 지지 (별도 공식 메커니즘 불필요)**

- 공식 docs: "In both cases, you stay in control. Claude won't create a team without your approval."
- Agent-office 비전의 "컨펌 대기" = 메인 Claude가 합의안 보고 후 사용자 응답 대기 = 기본 Claude Code 대화 흐름과 일관
- 별도 구현 불필요, 운영 규칙으로 충분

---

## 9. R-1~R-5 가드 검증

### R-1 영속화 우려 해소 → yaml + 외부 자산 패턴 공식 일관성

**검증 결과: 완전 일관**

공식 docs 아키텍처:
- Teams/tasks: `~/.claude/teams/`, `~/.claude/tasks/` — 런타임 상태
- Subagent memory: `~/.claude/agent-memory/<name>/` — 영속 지식 (memory 필드 활성 시)
- CLAUDE.md, project docs: 파일시스템 영속

주인님 정리 "yaml + 외부 자산으로 영속화"는 공식 docs가 "CLAUDE.md works normally: teammates read CLAUDE.md files from their working directory"라고 명시한 패턴과 완전히 일치.

`pm.yaml` = teammate가 읽는 역할 명세 = CLAUDE.md 확장 패턴. 공식 지원됨.

**추가 발견:** subagent `memory` 필드 활성 시 `~/.claude/agent-memory/<name>/MEMORY.md` 자동 관리 → PM 워커에 `memory: user` 설정하면 cross-session 지식 누적 가능 (선택적 강화).

### R-4 ④ 파이프라인 공식 호환성

**검증 결과: 완전 지지**

zircote 7패턴의 핵심 메커니즘 (`TaskCreate` + `TaskUpdate addBlockedBy` 체인)은 공식 docs의 태스크 시스템과 100% 호환:

> "Tasks can also depend on other tasks: a pending task with unresolved dependencies cannot be claimed until those dependencies are completed."

> "Task claiming uses file locking to prevent race conditions when multiple teammates try to claim the same task simultaneously."

`addBlockedBy`는 공식 태스크 의존성 메커니즘. zircote 패턴은 이를 코드화한 것. **④ 파이프라인 = 공식 기능 활용, 외부 해킹 아님.**

### R-3 Sonnet 워커 충분 여부

**검증 결과: 공식 + 3개 외부 출처 지지**

공식 docs: "For routine tasks, a single session is more cost-effective." + 토큰 비용 선형 증가 명시 → 적절한 모델 배분 중요성 인정.

---

## 10. 미확인 / 후속 조사 필요

1. **한 세션당 1 team 한계 해소 방법 실증** — "PM 팀 cleanup → 워커 팀 생성" 순서가 실제로 원활하게 동작하는지 로컬 테스트 필요. 특히 메인 Claude의 PM 팀 대화 맥락이 cleanup 후에도 유지되는지.

2. **`CLAUDE_CODE_SUBAGENT_MODEL` env와 팀 teammate 관계** — 공식 docs가 subagent 모델 해석 순위는 설명하지만, 팀 teammate(subagent와 다른 컨텍스트)에 동일하게 적용되는지 명시 없음. issue#32732와 연계 실험 필요.

3. **PM `memory: user` 실효성** — PM subagent에 `memory: user` 설정 시 cross-session 지식 누적이 `pm.yaml`의 역할 명세와 어떻게 결합하는지. HANDOFF.md 패턴과의 역할 중복 여부.

4. **psmux Windows 경로 버그 (issue#42848) 해소 시점** — 2026-05-01 기준 미해결. 주인님 환경에서 split-pane 사용 가능 시점 확인 필요.

5. **TaskCompleted 훅 input 스키마 세부** — 공식 docs가 공통 input 필드는 명시하지만, TaskCompleted 훅이 어떤 태스크 메타데이터(태스크 ID, 담당 teammate, 결과물 경로 등)를 제공하는지 상세 스펙 미확인. `/feedback` 자동 연계에 필요.

6. **`isolation: worktree` + 팀 teammate 조합** — `isolation` 필드는 subagent 정의 frontmatter 필드로 공식 지원됨. 이 정의를 참조해 팀 teammate로 spawn 시 worktree 격리가 teammate에도 적용되는지 (subagent와 teammate는 다른 컨텍스트) 실험 필요.

---

**Task 1 상태**: completed
**다음**: Task 3 (gap-analysis) 입력으로 활용

---

## 참고 출처

- [공식 docs - Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [공식 docs - Sub-agents](https://code.claude.com/docs/en/sub-agents)
- [issue#32723: TeamCreate/TeamDelete available to standalone subagents — undocumented](https://github.com/anthropics/claude-code/issues/32723)
- [issue#32731: Teammates have fewer tools than subagents](https://github.com/anthropics/claude-code/issues/32731)
- [issue#32732: Allow agent config model field to be non-overridable](https://github.com/anthropics/claude-code/issues/32732)
- [issue#42848: Agent Teams on Windows with psmux unix-style path bug](https://github.com/anthropics/claude-code/issues/42848)
- [issue#35513: Explore agent triggers unscoped file access in OneDrive](https://github.com/anthropics/claude-code/issues/35513)
- [issue#27023: isolation:worktree 문서 추가 요청 → 반영됨](https://github.com/anthropics/claude-code/issues/27023)
- [Anthropic engineering blog - How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)
