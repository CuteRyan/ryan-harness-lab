# 01. 공식 문서 리서치 — Claude Code Agent Teams / Subagents / Skills

- 담당: docs-researcher
- 확인 날짜: 2026-04-22
- 출처 정책: `docs.anthropic.com`, `docs.claude.com`, `code.claude.com`, `platform.claude.com` 공식만.
  - `docs.claude.com` 의 Claude Code 경로는 현재 `code.claude.com/docs/en/...` 으로 301 리다이렉트됨 (2026-04-22 실측).
  - SDK/플랫폼 경로는 `platform.claude.com/docs/en/...` 으로 302/307 리다이렉트 — 같은 Anthropic 공식 문서군.
- 분량: 실측 인용 위주로 압축. 각 사실에 출처 URL + 확인 날짜 명시. 애매한 부분은 "확인 불가" 명시.

---

## 0. 핵심 요약 (TL;DR)

1. **Agent Teams 는 실험 기능.** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 로 활성화. Claude Code **v2.1.32 이상** 필요. (출처: agent-teams)
2. **TeamCreate / TaskCreate / SendMessage 는 공식 레퍼런스 페이지에 "이름 있는 primitive" 로 명시되어 있지 않다.** 공식 문서는 "tell Claude to create an agent team" (자연어 요청) 방식만 설명. 팀/태스크 생성은 내부 구현이며 리소스 경로와 파일 포맷(`~/.claude/teams/{team-name}/config.json`, `~/.claude/tasks/{team-name}/`)만 공개됨.
3. **Agent tool 은 예전 Task tool.** v2.1.63 에서 이름 변경(Task → Agent), 기존 `Task(...)` 는 alias 로 유지.
4. **Subagent 와 Agent Team 은 다른 개념.** Subagent 는 단일 세션 내부의 분기, Agent Team 은 세션 간 coordinator+teammate 구조.
5. **Skills 의 공식 frontmatter 필드는 14개.** `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`. 이 중 `description` 만 recommended, 나머지는 전부 optional.
6. **SKILL.md 권장 길이는 500줄 이내.** 초과 시 reference 파일 분리, 중첩은 1단계까지만.

---

## 1. Agent Teams — 공식 사양

**출처**: https://code.claude.com/docs/en/agent-teams (2026-04-22 확인)

### 1.1 활성화

> "Agent teams are disabled by default. Enable them by setting the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable to `1`, either in your shell environment or through settings.json"

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

> "Agent teams require Claude Code v2.1.32 or later. Check your version with `claude --version`."

### 1.2 팀 생성 방식 — TeamCreate 는 공식 명시 없음

공식 문서는 **CLI 명령이나 MCP tool 이름을 공개하지 않는다.** 자연어로 지시하는 방식만 설명:

> "After enabling agent teams, tell Claude to create an agent team and describe the task and the team structure you want in natural language. Claude creates the team, spawns teammates, and coordinates work based on your prompt."

→ `TeamCreate` 라는 primitive 이름은 공식 레퍼런스 어디에도 등장하지 않음. 메모리/규칙에 적혀 있던 "TeamCreate → TaskCreate → Agent tool → SendMessage" 순서는 **공식 문서에서 확인 불가**. 단, 내부적으로 이런 tool 이름이 존재함은 시스템 프롬프트에서 관찰됨(실제 본 세션에서 `TaskCreate`, `TaskUpdate`, `SendMessage` 가 deferred tool 로 surfaced 되어 호출 가능).

### 1.3 생성물 (공식 문서에 나온 파일 경로)

> "Teams and tasks are stored locally:
> - **Team config**: `~/.claude/teams/{team-name}/config.json`
> - **Task list**: `~/.claude/tasks/{team-name}/`"

- **config.json 의 내용**: 공식 인용 — `"The team config contains a members array with each teammate's name, agent ID, and agent type."`
- **경고**: `"don't edit it by hand or pre-author it: your changes are overwritten on the next state update."` — 런타임 상태(세션 ID, tmux pane ID 포함)이므로 수동 편집 금지.
- **project-level 미지원**: `"There is no project-level equivalent of the team config. A file like .claude/teams/teams.json in your project directory is not recognized as configuration; Claude treats it as an ordinary file."`

### 1.4 아키텍처 컴포넌트 (공식 표)

| Component | Role |
|-----------|------|
| Team lead | The main Claude Code session that creates the team, spawns teammates, and coordinates work |
| Teammates | Separate Claude Code instances that each work on assigned tasks |
| Task list | Shared list of work items that teammates claim and complete |
| Mailbox | Messaging system for communication between agents |

### 1.5 Teammate spawn — subagent definition 재사용

> "When spawning a teammate, you can reference a subagent type from any subagent scope: project, user, plugin, or CLI-defined."
> "The teammate honors that definition's `tools` allowlist and `model`, and the definition's body is appended to the teammate's system prompt as additional instructions rather than replacing it. Team coordination tools such as `SendMessage` and the task management tools are always available to a teammate even when `tools` restricts other tools."

> 주의 (공식 Note):
> "The `skills` and `mcpServers` frontmatter fields in a subagent definition are not applied when that definition runs as a teammate. Teammates load skills and MCP servers from your project and user settings, the same as a regular session."

→ **즉, teammate 로 재사용되는 subagent 는 `tools` + `model` + 시스템 프롬프트만 상속하고, `skills`/`mcpServers` 는 무시됨.**

### 1.6 SendMessage — 라우팅 / 브로드캐스트 / lifecycle

> "message: send a message to one specific teammate"
> "broadcast: send to all teammates simultaneously. Use sparingly, as costs scale with team size."

> "The lead assigns every teammate a name when it spawns them, and any teammate can message any other by that name. To get predictable names you can reference in later prompts, tell the lead what to call each teammate in your spawn instruction."

**Auto-resume 동작** (출처: https://code.claude.com/docs/en/sub-agents, 2026-04-22):
> "If a stopped subagent receives a `SendMessage`, it auto-resumes in the background without requiring a new `Agent` invocation."
> "The `SendMessage` tool is only available when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`."

### 1.7 태스크 — blockedBy / blocks / status

공식 문서에서 확인된 사실:

> "Tasks have three states: pending, in progress, and completed. Tasks can also depend on other tasks: a pending task with unresolved dependencies cannot be claimed until those dependencies are completed."

> "Task claiming uses file locking to prevent race conditions when multiple teammates try to claim the same task simultaneously."

> "The system manages task dependencies automatically. When a teammate completes a task that other tasks depend on, blocked tasks unblock without manual intervention."

**TaskCreate/TaskUpdate/TaskList/TaskGet/TaskStop 의 파라미터 스키마는 공식 레퍼런스 페이지에 공개돼 있지 않음.** 현재 세션 런타임에서 관찰한 deferred tool 스키마 (실측, 2026-04-22):

- **TaskGet** — `taskId` 반환: subject, description, status (pending/in_progress/completed), blocks[], blockedBy[]
- **TaskUpdate** — `taskId`, `status`, `subject`, `description`, `activeForm`, `owner`, `metadata`, `addBlocks[]`, `addBlockedBy[]`

(파라미터 이름은 실제 툴 schema 에서 확인된 것이며, 공식 문서에는 이 수준의 스키마가 서술돼 있지 않다 — "확인 불가" 로 분류하지 않고 "런타임 실측" 으로 표기.)

### 1.8 Hooks — Agent Teams 전용

**출처**: https://code.claude.com/docs/en/hooks (2026-04-22)

3종의 팀 전용 hook 이벤트:

| Event | When it fires | Exit 2 동작 |
|-------|---------------|-------------|
| `TeammateIdle` | When a teammate is about to go idle | Prevents the teammate from going idle (teammate continues working) — feedback via stderr |
| `TaskCreated` | When a task is being created | Rolls back task creation |
| `TaskCompleted` | When a task is being marked as completed | Prevents task completion, sends feedback |

- 모두 matcher 미지원 (항상 fire).
- payload 공통 필드: `session_id`, `transcript_path`, `cwd`, `hook_event_name`.

### 1.9 Display modes

- `in-process` — 단일 터미널. Shift+Down 으로 teammate 순회.
- `split panes` — tmux 또는 iTerm2 (`it2` CLI) 필요. VS Code 통합 터미널/Windows Terminal/Ghostty 에서 지원 안 됨.
- 기본값 `"auto"`, 설정은 `~/.claude.json` 의 `teammateMode`.
- CLI flag: `claude --teammate-mode in-process`.

### 1.10 Limitations (공식 인용)

> "- No session resumption with in-process teammates: /resume and /rewind do not restore in-process teammates. After resuming a session, the lead may attempt to message teammates that no longer exist.
> - Task status can lag: teammates sometimes fail to mark tasks as completed, which blocks dependent tasks.
> - Shutdown can be slow: teammates finish their current request or tool call before shutting down.
> - One team per session: a lead can only manage one team at a time. Clean up the current team before starting a new one.
> - No nested teams: teammates cannot spawn their own teams or teammates. Only the lead can manage the team.
> - Lead is fixed: the session that creates the team is the lead for its lifetime.
> - Permissions set at spawn: all teammates start with the lead's permission mode.
> - Split panes require tmux or iTerm2."

---

## 2. Subagents — 공식 사양

**출처**: https://code.claude.com/docs/en/sub-agents (2026-04-22)

### 2.1 파일 위치와 우선순위

| Location | Scope | Priority |
|----------|-------|----------|
| Managed settings | Organization-wide | 1 (highest) |
| `--agents` CLI flag | Current session | 2 |
| `.claude/agents/` | Current project | 3 |
| `~/.claude/agents/` | All your projects | 4 |
| Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest) |

- Project subagents 는 현재 작업 디렉토리에서 상위로 walking 하며 탐색.
- `--add-dir` 경로는 **subagents 를 스캔하지 않음** (file access 만 grant). Skills 는 예외.

### 2.2 Frontmatter (공식 표)

필수: `name`, `description` 둘만.

| Field | Description |
|-------|-------------|
| `name` | Unique identifier using lowercase letters and hyphens |
| `description` | When Claude should delegate to this subagent |
| `tools` | Allowlist. 생략 시 모든 tool 상속 |
| `disallowedTools` | Denylist |
| `model` | `sonnet`, `opus`, `haiku`, full model ID (e.g. `claude-opus-4-7`), `inherit`. 기본 `inherit` |
| `permissionMode` | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` |
| `maxTurns` | 에이전트 중단 전 최대 turn 수 |
| `skills` | **전체 skill content 를 subagent 컨텍스트에 startup 시점에 inject** (단순 invocable 로 만드는 게 아님). 부모 대화의 skill 은 상속되지 않음 |
| `mcpServers` | 인라인 또는 참조 |
| `hooks` | Lifecycle hooks — subagent 활성 중에만 작동 |
| `memory` | `user` / `project` / `local` — persistent memory 디렉토리 |
| `background` | 기본 background 실행 |
| `effort` | `low`/`medium`/`high`/`xhigh`/`max` |
| `isolation` | `worktree` 설정 시 임시 git worktree 에서 실행 |
| `color` | transcript 표시 색 |
| `initialPrompt` | `--agent` 로 main session 으로 사용될 때 첫 turn 으로 자동 submit |

### 2.3 Built-in subagents

**출처**: 동일 페이지, Built-in subagents 섹션.

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only (denies Write/Edit) | File discovery, code search, codebase exploration. Thoroughness 지정 가능: `quick`, `medium`, `very thorough` |
| Plan | Inherits from main | Read-only | Plan mode 에서 codebase 조사 |
| general-purpose | Inherits | All tools | 복잡한 multi-step 작업 |
| statusline-setup | Sonnet | - | `/statusline` 전용 |
| Claude Code Guide | Haiku | - | Claude Code 기능 질문 전용 |

→ `subagent_type` 으로 지정 가능한 값: `Explore`, `Plan`, `general-purpose`, 그리고 커스텀 subagent 의 `name`.

### 2.4 Task tool → Agent tool 이름 변경

**출처**: 같은 페이지 & https://code.claude.com/docs/en/agent-sdk/subagents (2026-04-22):

> "The tool name was renamed from 'Task' to 'Agent' in Claude Code v2.1.63. Current SDK releases emit 'Agent' in tool_use blocks but still use 'Task' in the system:init tools list and in result.permission_denials[].tool_name. Checking both values in block.name ensures compatibility across SDK versions."

> "In version 2.1.63, the Task tool was renamed to Agent. Existing Task(...) references in settings and agent definitions still work as aliases."

### 2.5 Subagent vs Agent Team 공식 비교표

**출처**: agent-teams 페이지 비교표, 2026-04-22.

| | Subagents | Agent teams |
|---|-----------|-------------|
| Context | Own context window; results return to caller | Own context window; fully independent |
| Communication | Report results back to main agent only | Teammates message each other directly |
| Coordination | Main agent manages all work | Shared task list with self-coordination |
| Best for | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| Token cost | Lower: results summarized back | Higher: each teammate is a separate Claude instance |

### 2.6 Subagents cannot spawn subagents

> "Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation."

→ **nested team 도 금지** (`No nested teams` in limitations).

---

## 3. Agent SDK 의 subagent — AgentDefinition

**출처**: https://code.claude.com/docs/en/agent-sdk/subagents (2026-04-22)

### 3.1 프로그래매틱 정의

`query()` 옵션의 `agents` 파라미터로 전달. 빌트인 `general-purpose` 는 `Agent` 가 `allowedTools` 에 있으면 별도 정의 없이 쓸 수 있음.

### 3.2 AgentDefinition 필드 (공식 표)

| Field | Type | Required |
|-------|------|----------|
| `description` | string | Yes |
| `prompt` | string | Yes |
| `tools` | string[] | No — 생략 시 모든 tool 상속 |
| `disallowedTools` | string[] | No |
| `model` | string | No — `'sonnet'`/`'opus'`/`'haiku'`/`'inherit'`/full model ID |
| `skills` | string[] | No |
| `memory` | `'user' \| 'project' \| 'local'` | No |
| `mcpServers` | `(string \| object)[]` | No |
| `maxTurns` | number | No |
| `background` | boolean | No |
| `effort` | `'low' \| 'medium' \| 'high' \| 'xhigh' \| 'max' \| number` | No |
| `permissionMode` | PermissionMode | No |

> "Subagents cannot spawn their own subagents. Don't include `Agent` in a subagent's `tools` array."

### 3.3 CLI 정의 (subagents 와 같은 필드)

> `claude --agents '{...}'` 로 JSON 전달. 파일 기반과 동일한 frontmatter 필드를 지원: `description`, `prompt`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `isolation`, `color`.

### 3.4 CLI 정의 vs 프로그래매틱 정의 우선순위

> "Programmatically defined agents take precedence over filesystem-based agents with the same name."

### 3.5 Claude Agent SDK 와 CLI 빌트인 Agent Teams 의 관계

- **Agent Teams = Claude Code CLI 전용 실험 기능** (v2.1.32+, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
- **Subagents = CLI 와 SDK 모두 지원.** SDK 는 `agents` 파라미터로 프로그래매틱 정의 가능. 파일 기반 정의도 SDK 에서 읽힘.
- **SDK 에서 agent team 을 직접 orchestrate 하는 별도 API 는 공식 문서에서 확인 불가** — SDK 의 subagent 페이지는 "subagents run within a single session; agent teams coordinate across separate sessions" 라는 CLI 문서를 참조할 뿐이다.

---

## 4. Skills — 공식 사양

### 4.1 저장 위치 (Claude Code)

**출처**: https://code.claude.com/docs/en/skills (2026-04-22)

| Location | Path | Applies to |
|----------|------|-----------|
| Enterprise | managed settings | All users in your organization |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

- 우선순위: enterprise > personal > project. Plugin 은 `plugin-name:skill-name` 네임스페이스.
- 실시간 감지: `~/.claude/skills/` 와 프로젝트 `.claude/skills/` 의 파일 변경은 세션 재시작 없이 반영됨. 상위 디렉토리 자체를 새로 만드는 경우는 재시작 필요.
- **`--add-dir` 예외**: 일반적으로는 configuration discovery 가 아니지만, **`.claude/skills/` 만 예외적으로 로드됨.** subagents/commands/output styles 은 로드되지 않음.

### 4.2 Frontmatter 공식 필드 (14개, 전부 optional)

**출처**: 같은 페이지, "Frontmatter reference" 섹션.

> "All fields are optional. Only `description` is recommended so Claude knows when to use the skill."

| Field | Required | 핵심 |
|-------|----------|------|
| `name` | No | 생략 시 디렉토리명 사용. lowercase + 숫자 + 하이픈, 64자 max |
| `description` | Recommended | `description` + `when_to_use` 합산이 skill listing 에서 1,536자에서 절단 |
| `when_to_use` | No | trigger phrases / 예시 request |
| `argument-hint` | No | autocomplete hint |
| `arguments` | No | named positional args — `$name` 치환 |
| `disable-model-invocation` | No | `true` 시 모델이 자동 invoke 못 함, 유저 `/name` 만. 기본 false |
| `user-invocable` | No | `false` 시 `/` 메뉴에서 숨김. 기본 true |
| `allowed-tools` | No | skill 활성 중 per-use approval 없이 쓸 수 있는 tool. 제한이 아니라 pre-approve |
| `model` | No | skill 활성 중 모델 override |
| `effort` | No | `low`/`medium`/`high`/`xhigh`/`max` |
| `context` | No | `fork` 시 subagent 에서 실행 |
| `agent` | No | `context: fork` 의 subagent type |
| `hooks` | No | skill lifecycle 에 scoped hooks |
| `paths` | No | glob. 매칭 파일 작업 시만 자동 로드 |
| `shell` | No | `bash` 기본 / `powershell` (Windows, `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` 필요) |

### 4.3 API 측 YAML 요건 (추가 엄격 규칙)

**출처**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (2026-04-22)

- `name`: **max 64자**, lowercase + 숫자 + 하이픈만, XML 태그 금지, 예약어 금지 (`anthropic`, `claude`).
- `description`: **max 1,024자**, non-empty, XML 태그 금지.

> **주의**: Claude Code 의 skill listing 에서는 `description` + `when_to_use` 합산 1,536자에서 절단되나, API 측 `description` 자체의 최대치는 1,024자. 두 제한이 다름.

### 4.4 scripts/ 디렉토리 관행

**출처**: https://code.claude.com/docs/en/skills 와 https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (둘 다 2026-04-22)

공식 예시 구조:

```
my-skill/
├── SKILL.md
├── template.md
├── examples/
│   └── sample.md
└── scripts/
    └── validate.sh
```

- **scripts/ 는 실행되는 파일, context 에 로드되지 않음.** 토큰 비용은 script 출력만.
- **reference/ 는 도메인별 분리 권장.** 베스트 프랙티스 Pattern 2 (Domain-specific organization) 참고.
- **중첩 참조 1단계까지.** SKILL.md → advanced.md → details.md 형태는 피할 것. "Claude may partially read files when they're referenced from other referenced files."

### 4.5 Progressive disclosure (3단계)

**출처**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview (2026-04-22)

| Level | When Loaded | Token Cost | Content |
|-------|------------|------------|---------|
| 1. Metadata | Always (startup) | ~100 tokens/skill | `name`, `description` |
| 2. Instructions | When triggered | Under 5k tokens | SKILL.md body |
| 3+. Resources | As needed | 사실상 무제한 | bundled files, executed via bash |

### 4.6 user-invocable / 모델 invocation 동작 행렬

**출처**: https://code.claude.com/docs/en/skills (2026-04-22)

| Frontmatter | 유저 invoke | 모델 invoke | 컨텍스트 로드 |
|-------------|-----------|-----------|--------------|
| (default) | Yes | Yes | description always in context, full on invoke |
| `disable-model-invocation: true` | Yes | No | description NOT in context, full on user invoke |
| `user-invocable: false` | No | Yes | description always in context, full on invoke |

### 4.7 allowed-tools 의미

> "The `allowed-tools` field grants permission for the listed tools while the skill is active, so Claude can use them without prompting you for approval. It does not restrict which tools are available: every tool remains callable, and your permission settings still govern tools that are not listed."

→ **allowed-tools 는 pre-approve 이지 제한이 아님.** 제한은 `permissions.deny` 또는 settings 에서.

### 4.8 `context: fork` — 스킬을 subagent 에서 실행

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---
```

- subagent 에 **skill 본문 = prompt** 로 주입.
- `agent` 생략 시 `general-purpose`.
- `skill` 안의 `agent` 로 지정 가능: built-in (`Explore`/`Plan`/`general-purpose`) 또는 `.claude/agents/` 의 커스텀.

### 4.9 베스트 프랙티스 — 작성 규칙 핵심 요약

**출처**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (2026-04-22)

1. **Concise is key** — "Does Claude really need this?" 를 각 문장에 적용. Claude 가 이미 아는 설명은 삭제.
2. **500 줄 이내** — "Keep SKILL.md body under 500 lines for optimal performance." 초과 시 reference 파일 분리.
3. **Naming (gerund form 권장)** — `processing-pdfs`, `analyzing-spreadsheets`. 허용 대안: noun phrases (`pdf-processing`), action-oriented (`process-pdfs`). 금지: `helper`/`utils`/`tools` 같은 모호한 이름, 예약어 (`anthropic`, `claude`).
4. **description 은 3인칭** — "Processes Excel files and generates reports" (○) / "I can help you..." (×) / "You can use this..." (×).
5. **Degrees of freedom 3단계**:
   - High freedom — 텍스트 지시 (다양한 정답 가능)
   - Medium freedom — pseudocode or parameterized scripts
   - Low freedom — 고정 script, 파라미터 제한 (fragile ops)
6. **Reference 파일 depth 1** — SKILL.md → 바로 참조 파일들. A → B → C 금지.
7. **reference 파일 100줄 초과 시 TOC 삽입** — 부분 read 시에도 스코프 파악 가능하게.
8. **time-sensitive 금지** — "after August 2025..." 같은 표현 금지. 대신 `## Old patterns` 섹션에 deprecated 설명.
9. **MCP tool 참조는 fully qualified**: `ServerName:tool_name` 포맷.
10. **Paths 는 forward slash 만** — Windows backslash 금지.
11. **evaluation-driven development** — 평가 시나리오 3개 이상 먼저 만들고 SKILL.md 작성.

### 4.10 Skills 과 Custom commands 통합

**출처**: https://code.claude.com/docs/en/skills (2026-04-22)

> "Custom commands have been merged into skills. A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and work the same way. Your existing `.claude/commands/` files keep working."
> "if a skill and a command share the same name, the skill takes precedence."

### 4.11 Skills 의 Surface 별 차이

**출처**: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview (2026-04-22)

| Surface | Custom Skills | 제약 |
|---------|---------------|------|
| Claude Code | 지원 (filesystem) | 풀 네트워크 엑세스. 전역 패키지 설치 지양 |
| Claude API | 지원 (`/v1/skills` 업로드) | 네트워크 불가, 런타임 패키지 설치 불가, workspace-wide 공유 |
| Claude.ai | 지원 (zip 업로드) | 개인 단위, 관리자 중앙 관리 불가 |

> "Custom Skills do not sync across surfaces. Skills uploaded to one surface are not automatically available on others."

---

## 5. 리서치 시 확인한 도메인·경로 매핑

- `docs.anthropic.com/en/docs/claude-code/*` → `code.claude.com/docs/en/*` (301 Moved Permanently, 2026-04-22 실측)
- `docs.claude.com/en/docs/claude-code/*` → `code.claude.com/docs/en/*` (301)
- `docs.claude.com/en/docs/agent-sdk/*` → `platform.claude.com/docs/en/agent-sdk/*` (302) → 다시 `code.claude.com/docs/en/agent-sdk/*` (307 임의 경유)
- `docs.claude.com/en/api/agent-sdk/*` → `platform.claude.com/docs/en/agent-sdk/*` (동등)
- Skills 는 두 도메인 모두에서 레퍼런스 제공: Claude Code 측은 `code.claude.com/docs/en/skills`, API/플랫폼 측은 `platform.claude.com/docs/en/agents-and-tools/agent-skills/*`.

---

## 6. 주인님 규칙과의 대조 — 실체 확인

> 이 섹션은 참고용이며 Gap 분석(태스크 #3) 이 정식으로 수행.

- 전역 규칙 `~/.claude/CLAUDE.md` 의 "TeamCreate → TaskCreate → Agent tool (team_name 파라미터) → SendMessage" 순서:
  - `TeamCreate` 라는 명시적 primitive: **공식 문서에 이름이 존재하지 않음** (Team 생성은 자연어 요청으로 이뤄지는 것이 공식 방식).
  - `Agent tool` 의 `team_name` 파라미터: **공식 문서/SDK 타입 레퍼런스에서 확인 불가**. 공식 Agent tool 파라미터 스키마는 `subagent_type`, `description`, `prompt` 계열만 문서화됨.
  - `SendMessage` 는 존재 확정 (agent teams 활성 시). `to` 필드는 teammate name 또는 `*` broadcast.
- `subagent_type` 이 수용하는 값: built-in 3종 (`Explore`, `Plan`, `general-purpose`) + `.claude/agents/` 의 커스텀 이름.

---

## 7. 확인 불가 (명시적으로 남김)

공식 문서 (`code.claude.com`/`platform.claude.com`) 에서 **2026-04-22 기준 확인되지 않은 주장**:

1. **`TeamCreate` 라는 이름의 tool/command.** "tell Claude to create a team" 이라는 자연어 패턴만 공식화됨.
2. **Agent tool 의 `team_name` 파라미터.** teammate spawn 이 별도 파라미터로 문서화되지 않음 — 공식은 "ask the lead to spawn a teammate using <subagent-type>" 수준.
3. **TaskCreate / TaskUpdate / TaskList / TaskGet / TaskStop 의 공식 파라미터 스키마.** 런타임에서 deferred tool 로 surfaced 되지만 (실측), 공식 레퍼런스 페이지에는 파라미터 표가 없다.
4. **team config.json 의 정확한 JSON schema.** `members` 배열에 `name`, `agent ID`, `agent type` 이 들어간다는 문장만 확인. 필드명/타입은 공개 없음.
5. **Agent SDK 에서 직접 agent-team 을 생성하는 programmatic API.** 공식 SDK 문서에는 subagent 만 있고 agent team 오케스트레이션용 public API 는 서술 없음.

---

## 8. 참고: 전 리서치에서 WebFetch 로 실제 가져온 URL 목록 (2026-04-22)

- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/agent-teams
- https://code.claude.com/docs/en/agent-sdk/subagents
- https://code.claude.com/docs/en/hooks
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview

각 URL 은 WebFetch 성공 기록 있음 (best-practices 만 `code.claude.com` 경로 404 → `platform.claude.com` 경로에서 성공).

---

## 9. Gap 분석 / 스펙 설계 단계로 넘길 핵심 시드

(태스크 #3·#4 의 analyst / architect 용 입력)

1. **TeamCreate / TaskCreate / SendMessage 순서는 공식 문서가 아니라 실측 tool 이름이다.** 문서에 "왜 이 순서인가" 의 근거는 없으며 자연어 요청이 공식 방식. 스킬이 이 순서를 강제할지, 자연어 위임으로 바꿀지 결정 필요.
2. **teammate 가 subagent 정의를 재사용할 때 `skills`/`mcpServers` 는 무시된다.** `agent-team-manager` skill 이 이 제약을 사용자에게 안내해야 함.
3. **Skills frontmatter 14개 필드 중 현재 스킬이 활용하지 못하는 것 (예: `context: fork`, `paths`, `hooks`, `arguments`)** → v2 스펙에서 활용 여지.
4. **SKILL.md 500줄 룰 + reference 1단계 룰** → 현재 스킬이 이를 준수하는지 점검 필요 (Gap 분석 대상).
5. **Limitations 중 "no nested teams", "one team per session", "task status can lag"** → agent-team-manager 스크립트가 회피·감지 로직을 포함해야 함.
