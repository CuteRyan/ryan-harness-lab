# Agent structure

Status: agreed design, 2026-09-10; feedback and memory approval clarified 2026-09-14. This document defines the target structure; it does not claim that existing agents implement it.

Use this reference when creating agents or changing their execution, storage, sessions, documents, memory, capabilities, or feedback structure. It applies across projects, providers, models, and platforms. Existing agents are migrated through separately authorized work.

Index: [Principles](#principles) · [Project and task boundaries](#project-and-task-boundaries) · [Ownership](#ownership) · [Documents](#documents) · [Memory](#memory) · [Index format](#index-format) · [Index examples](#index-examples) · [Reading and creation](#reading-and-creation) · [Capabilities](#capabilities) · [Human feedback](#human-feedback) · [Self-feedback](#self-feedback) · [Verification](#verification)

## Principles

### Four mandatory principles

Apply these principles to every agent design, build, and revision, including its instructions, skills, rules, and outputs, regardless of project, model, or platform:

1. **Compact:** say what is needed once, briefly.
2. **Ordinary language:** use established terms; do not invent labels.
3. **No overfitting:** write general rules rather than accumulating rules for individual cases; preserve real task differences.
4. **No overengineering:** build the structure needed now, then improve it through actual use and feedback instead of trying to perfect it upfront.

The fourth principle does not assume a particular agent framework or an existing self-improvement loop. Every agent follows the [human feedback](#human-feedback), [memory](#memory), and [self-feedback](#self-feedback) rules below: human commands authorize their requested scope; agent-originated proposals require human approval before application.

Origin: the owner's 2026-08-03 [memory record](C:/Users/rlgns/.claude/projects/C--Python-plusalpha-agency/memory/feedback-compact-general-writing.md), reaffirmed on 2026-09-11 as mandatory for all agent building. This section is the maintained source; agent guidance links here.

### Structure requirements

1. Implement and maintain shared functionality once.
2. Keep actual differences in each agent's role, permissions, tools, and task instructions.

Standing-prompt limits, current-need scope, minimal restrictions, enforcement in code, and bridge-prompt responsibilities are maintained in the [global Harness rules](../settings/global-instructions.md#harness); one authoritative location per decision is maintained in [Documents and records](../settings/global-instructions.md#documents-and-records). Both Claude and Codex receive that single source through the [instruction sync procedure](global-instruction-sync.md).

## Project and task boundaries

Separate projects before separating their agents and tasks. A shared host or database installation supplies resources; it does not merge project ownership, access, or conversation context.

```text
Host
├─ Project A root
│  ├─ Project code, documents, and shared records
│  └─ Agent workspaces, identified by agent
│     └─ Separate directories and model sessions for independent tasks
└─ Project B root
   └─ The same ownership boundaries, with its own data and permissions

Shared database server
├─ Project A database → project records and permitted agent access
└─ Project B database → project records and permitted agent access
```

**Project storage:** Each project owns its root, data, settings, and access permissions. Keep each agent's persistent workspace under its project root, using the project's existing layout. Source checkouts, installed runtimes, and work data have distinct purposes. A Python virtual environment isolates dependencies; it is not the workspace or an access boundary. Enforce permitted paths and credentials through runtime and operating-system controls. Keep concrete project names and deployment paths in project documentation.

**Database ownership:** A single database-server installation may serve several projects. Use a separate logical database and project-scoped access for each project; within it, grant agents access to the project records and their own operating state as needed. A project may own multiple databases; each database still has an explicit project owner. Agent-specific schemas are an internal project organization, not a substitute for the project boundary. Validate actual database grants and connection settings; names and schemas alone do not enforce isolation. This does not require a separate database-server installation per project or a separate database per agent.

**Persistent records:** Agents retain source material, drafts, and results in their workspaces. Project databases hold the structured records selected by that project's storage contract, including operating state where appropriate. Connect file locations and database records so results remain retrievable after a session ends. Consult project documentation before transferring data across projects.

**Task sessions:** An independent task starts with its own terminal/work directory and a fresh model session. Each new scheduled run is independent; separate jobs within that run also get separate sessions. For an agent in a conversation platform, one thread maps to one continuing task session: a new thread starts a new session, while follow-ups in that thread resume the existing session and workspace. Scope this mapping by project, agent, and platform conversation identity. Restarting a process recovers that task's mapping; it does not silently attach another task's session. Enforce duplicate-execution limits in code.

**Context:** Starting a new terminal alone does not clear an existing model session. Start fresh for independent work, and preserve continuity inside the same task. Supply role, minimal principles, the entry index, and the current personal memory index initially; retrieve only the relevant procedures, memory details, prior records, and handoffs. Treat historical task content as evidence, not as current instructions. The intent is to limit irrelevant context accumulation while preserving knowledge; verify actual output quality.

These are ownership and execution boundaries, not an extra mandatory document-index level. Continue using the compact document structure below. Shared documents and catalogs retain one source; project and agent indexes link to the applicable parts. Existing installations require an inventory and a separately authorized migration before paths, database ownership, or saved session mappings change.

## Ownership

```text
Agent system
├─ Shared runtime implementation
│  ├─ Configuration: identity, optional team, engine, model, permissions, capabilities
│  ├─ Engine adapters: execution, resume, termination
│  ├─ Sessions: participants, conversation, results, individual execution state
│  ├─ Workspaces: terminals, working directories, processes, artifacts
│  ├─ Document access: entry and memory indexes, authorized on-demand reads
│  ├─ Capability registration and invocation
│  ├─ Hooks and mandatory execution checks
│  ├─ Feedback recording, human approval, application, and verification
│  └─ Result checks, correction, verification, and termination
├─ Individual agents
│  ├─ Independent configuration and execution state
│  └─ One entry index connecting role, documents, and capabilities
└─ Platform adapters
   └─ Slack, console, Telegram, or another interface ↔ runtime sessions
```

The runtime implementation is shared; each agent owns its configuration and state. Engine and model choices are independent of role. Platform-specific handling lives in the relevant shared adapter; bot and channel values are agent settings.

Configuration is runtime data, not a second document source. Supply the agent with the effective values it needs to work.

| Scope | Applies to | Source ownership |
|---|---|---|
| Shared | The same operating standards for any agent, plus centrally registered capabilities selected by permission | One shared source |
| Team | Members of that team | One team source, referenced by its members |
| Personal | That agent | Its role and task-specific sources |

**Team membership is optional. A standalone agent uses the same structure with the team link omitted.** It needs no empty team directory or placeholder team. It can still reference shared documents.

Every agent uses the same document structure. Shared rules apply regardless of project, team, or role; team documents contain team-specific material; personal documents contain role-specific material. A company profile or a particular business workflow is not a universal rule. Shared capabilities are selectable functions, not mandatory tools for every agent. Keep one source for each item, linking it where needed.

## Documents

**Use three levels: overall index → category indexes → individual detail files.** Role is the exception: the overall index links directly to the single `role.md` body. All indexes follow [Index format](#index-format).

```text
Agent index.md                                   Level 1: overall index
├─ Role → role.md                                 Direct body, one copy
├─ Shared                                        Links to shared originals
│  ├─ rules.md                                   Level 2: rules index
│  │  ├─ → rules/essentials.md                    Level 3: operating principles
│  │  ├─ → rules/document-management.md           Document and index conventions
│  │  ├─ → rules/human-feedback.md                Human feedback application
│  │  └─ → rules/self-feedback.md                 Self-feedback recording and approval
│  ├─ skills.md → registered SKILL.md files
│  ├─ tools.md → individual tool manuals
│  └─ commands.md → invocation and connected functions
├─ Team (omit for a standalone agent)             Links to team originals
│  ├─ organization.md → membership, responsibilities, delegation, reporting
│  ├─ goals.md → individual team goals
│  ├─ decisions.md → individual agreed decisions
│  ├─ history.md → team completion records
│  └─ handoff.md → team progress, remaining work, and owners
└─ Personal                                      Role-specific sources
   ├─ memory.md → individual facts and context
   ├─ sop.md → individual task procedures
   ├─ history.md → individual work results
   ├─ handoff.md → unfinished tasks and next actions
   ├─ human-feedback.md → requests, affected sources, and application records
   └─ self-feedback.md → findings, evidence, proposals, and approval records
```

Every category file above is a level-2 index; its linked content is level 3. Shared, team, and personal are sections of the overall index, not extra index files to traverse. Shared and team owners may have an overall portal of their own, but agents link directly to the relevant category indexes. Role alone links directly to its body.

| Scope | Standard category indexes | Source ownership |
|---|---|---|
| Shared | Rules, skills, tools, commands | Shared maintainer; capabilities selected through agent settings |
| Team | Organization, goals, decisions, history, handoff | Team owner; members reference the same sources |
| Personal | Memory, SOP, history, handoff, human feedback, self-feedback | Individual agent within its authority |

The team organization describes members, responsibilities, direction, delegation, review, and final reporting. Link to each member's role rather than copying its description. Runtime permissions implement the agreed authority; the organization chart alone grants none.

Team history records shared outcomes and decisions and links to individual work. Team handoff records coordination and remaining owners; personal handoff records the agent's own unfinished work. A feedback request or discovery is recorded once at its receiving source. If it affects shared or team material, link that target and the application result rather than copying the feedback record into every scope.

Add team-specific SOPs, memory, or other category indexes when actual work needs them, using the same three levels and user-confirmed scope. Do not prebuild identical category sets for shared, team, and personal. Standalone agents omit only the Team connection; their common and personal structure stays the same.

### Example layout

This is a target layout, not an instruction to create its files. Names are illustrative. An approved skeleton may contain empty index tables until actual content is assigned or inherited.

```text
project/
├─ skills/report/SKILL.md
└─ docs/
   ├─ shared/
   │  ├─ rules.md                       Level 2
   │  ├─ skills.md                      Level 2 → ../../skills/report/SKILL.md
   │  ├─ tools.md                       Level 2 → tools/mail.md
   │  ├─ commands.md                    Level 2 → commands/status.md
   │  ├─ rules/
   │  │  ├─ essentials.md               Level 3
   │  │  ├─ document-management.md       Level 3
   │  │  ├─ human-feedback.md            Level 3
   │  │  └─ self-feedback.md             Level 3
   │  ├─ tools/mail.md                  Level 3
   │  └─ commands/status.md             Level 3
   ├─ teams/team-a/
   │  ├─ organization.md                Level 2 → organization/roles-and-reporting.md
   │  ├─ goals.md                       Level 2 → goals/current.md
   │  ├─ decisions.md                   Level 2 → decisions/report-format.md
   │  ├─ history.md                     Level 2 → history/2026-09-10.md
   │  ├─ handoff.md                     Level 2 → handoff/current-project.md
   │  └─ Matching category folders      Level 3 files named above
   └─ agents/agent-a/
      ├─ index.md                       Level 1, agent entry
      ├─ role.md                        Role body, direct link
      ├─ memory.md                      Level 2 → memory/customer-a.md
      ├─ sop.md                         Level 2 → sop/email.md
      ├─ history.md                     Level 2 → history/2026-09-10.md
      ├─ handoff.md                     Level 2 → handoff/current-task.md
      ├─ human-feedback.md              Level 2 → human-feedback/email-opening.md
      ├─ self-feedback.md               Level 2 → self-feedback/reply-matching.md
      └─ Matching category folders      Level 3 files named above
```

A file such as `memory.md` or `handoff.md` is the category index; its associated folder contains the detailed files. The overall index points to that list rather than duplicating its rows. Detail files contain actual content, not another mandatory index. A role-specific procedure stays in personal SOP; extract a shared skill when actual reuse warrants it, then link its source.

### Memory

Every agent has a persistent personal memory index. The runtime supplies its current contents when starting or resuming work. Use Date / Topic / Read when / Details; keep facts and context in linked detail files or an existing authoritative source, read only when relevant. An empty index is valid until there is something to remember.

A human memory command authorizes the requested save, update, deletion, or organization within that person's authority. Follow [human feedback](#human-feedback): read the existing source, update the relevant detail and index, and verify the saved content and links without asking for the same approval again. Ordinary conversation does not open a durable memory-change request. Agent-originated memory candidates remain in the existing [self-feedback](#self-feedback) proposal store until a human approves them; pending candidates do not enter the active memory index.

Organize memory when requested: consolidate duplicates and repair links and reading conditions within the requested scope. Preserve valid facts and unresolved items unless their removal is authorized. Keep guidance in its owning rule, role, or procedure rather than duplicating it as memory.

Use the applicable authorized write path and the owning project's persistent storage so later sessions can retrieve updates. Read access alone does not provide update capability; an update that cannot be saved remains unapplied with its reason recorded.

Runtime configuration, hooks, result checks, and approval enforcement stay outside this document hierarchy. The self-feedback index records lessons and proposals; code enforces approval before applying them.

## Index format

Use the same base fields and order across shared, team, and personal indexes, including rules, memory, SOPs, history, handoffs, skills, tools, commands, and both feedback indexes:

| Index kind | Columns |
|---|---|
| Base / records | Date · Topic · Details |
| Guidance / capabilities | Date · Topic · Read when · Details |
| Human / self-feedback | Date · Topic · Status · Details |

- Date: `YYYY-MM-DD`. For records and feedback, use the event, request, or discovery date and retain it when status changes. For guidance and capability entries, use the source's last substantive update date. Use `Unknown` when the date cannot be established; copying a document does not give it a new date.
- Topic: one short line naming one subject, change, or finding. Put the explanation in the linked detail, rather than packing a day's unrelated work into one row.
- Details: a direct link to the authoritative document, record, or section. Reuse an existing record when possible; a row does not require its own new file.
- Read when: a short condition that helps the agent select the needed guidance.
- Status: use the applicable state: `Not applied`, `Awaiting approval`, `Approved (not applied)`, `Applied`, or `Rejected`. Approval and completed application are distinct. An unsuccessful application remains not applied, with its reason in the detail.

Keep original messages, evidence, affected sources, approval references, changes, and verification in the linked detail. Update the existing row when its source or status changes; create a new row for a distinct event or proposal. New and revised indexes follow this format; existing collections are migrated within the approved scope.

## Index examples

These sample file contents follow the layout above. Dates, names, results, and approvals are illustrative. A Details link in level 1 points to a category index; in level 2 it points to the individual detail file. Role links directly to its body.

### Agent entry: `docs/agents/agent-a/index.md`

```markdown
# Agent A

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Role | Starting a session | [Role](role.md) |

## Shared

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Shared rules | Shared standards apply | [Rules](../../shared/rules.md) |
| 2026-09-10 | Skills | Selecting a permitted reusable procedure | [Skills](../../shared/skills.md) |
| 2026-09-10 | Available tools | Selecting an operation | [Tools](../../shared/tools.md) |
| 2026-09-10 | Commands | Invoking a registered function | [Commands](../../shared/commands.md) |

## Team

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Team organization | Identifying ownership, delegation, or reporting | [Organization](../../teams/team-a/organization.md) |
| 2026-09-10 | Team goals | Choosing priorities | [Goals](../../teams/team-a/goals.md) |
| 2026-09-10 | Team decisions | Checking an agreed decision | [Decisions](../../teams/team-a/decisions.md) |
| 2026-09-10 | Team history | Looking up shared results | [History](../../teams/team-a/history.md) |
| 2026-09-10 | Team handoff | Coordinating pending work | [Handoff](../../teams/team-a/handoff.md) |

## Personal

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-12 | Memory | Starting or resuming work | [Memory](memory.md) |
| 2026-09-10 | Procedures | Starting an assigned task | [SOP](sop.md) |
| 2026-09-10 | History | Looking up previous work | [History](history.md) |
| 2026-09-10 | Handoff | Resuming unfinished work | [Handoff](handoff.md) |
| 2026-09-10 | Human feedback | Receiving or checking a human request | [Human feedback](human-feedback.md) |
| 2026-09-10 | Self-feedback | Recording or reviewing a discovery | [Self-feedback](self-feedback.md) |
```

A standalone agent omits the Team section. Capability indexes are shared sources. The runtime exposes the applicable entries from those registrations and effective permissions; agent settings select capabilities without a manually maintained personal copy of the catalog.

### SOP category: `docs/agents/agent-a/sop.md`

```markdown
# SOP index

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Email drafting | Preparing a reply or draft | [Procedure](sop/email.md) |
```

### Memory category: `docs/agents/agent-a/memory.md`

```markdown
# Memory index

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Customer A's language preference | Preparing a message for Customer A | [Context](memory/customer-a.md) |
```

### Human feedback category: `docs/agents/agent-a/human-feedback.md`

```markdown
# Human feedback index

| Date | Topic | Status | Details |
|---|---|---|---|
| 2026-09-10 | Start emails with the conclusion | Applied | [Record](human-feedback/email-opening.md) |
```

The detail file links to the original request, affected source, and verification. The index does not carry the full request or duplicate the updated SOP.

### Self-feedback category: `docs/agents/agent-a/self-feedback.md`

```markdown
# Self-feedback index

| Date | Topic | Status | Details |
|---|---|---|---|
| 2026-09-10 | Improve matching when a reply subject changes | Awaiting approval | [Proposal](self-feedback/reply-matching.md) |
```

The detail file contains the observation, evidence, proposed change, and approval/application record. Awaiting approval means the target source remains unchanged.

### Team handoff category: `docs/teams/team-a/handoff.md`

```markdown
# Team handoff index

| Date | Topic | Details |
|---|---|---|
| 2026-09-10 | Current project coordination and remaining work | [Handoff](handoff/current-project.md) |
```

### Shared rules category: `docs/shared/rules.md`

```markdown
# Shared rules index

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Essential operating principles | Starting or checking work | [Principles](rules/essentials.md) |
| 2026-09-10 | Document management | Creating or updating indexes and records | [Conventions](rules/document-management.md) |
| 2026-09-10 | Human feedback | Recording and applying a human request | [Policy](rules/human-feedback.md) |
| 2026-09-10 | Self-feedback | Recording a discovery or checking approval | [Policy](rules/self-feedback.md) |
```

### Shared skills category: `docs/shared/skills.md`

```markdown
# Skills index

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Report writing | Producing a report with this permitted skill | [Procedure](../../skills/report/SKILL.md) |
```

### Team organization category: `docs/teams/team-a/organization.md`

```markdown
# Team organization index

| Date | Topic | Read when | Details |
|---|---|---|---|
| 2026-09-10 | Responsibilities and reporting | Assigning work or reporting a result | [Organization](organization/roles-and-reporting.md) |
```

The same three levels apply to shared, team, and personal material. For example: agent entry → team handoff index → current project handoff. The team owner maintains that source; every team member references it.

## Reading and creation

```text
Design or restructure agent
→ Read this agreed design and inspect the current agent
→ Show the user the proposed structure, source links, responsibilities, and change scope
→ Obtain user confirmation of that structure and scope
→ Register runtime settings, including optional team and independent engine/model choice
→ Prepare the role, overall index, category indexes, and needed detail files
→ Link existing shared sources, optional team sources, needed tasks, and permitted capabilities

Start work
→ Provide entry index + current personal memory index + role + minimal essential principles
→ Follow relevant index links to task documents
→ Execute, check, and record the result

Example: draft an email
→ Agent index.md → sop.md → sop/email.md
→ Read additional registered skill or tool details when needed
→ Produce the draft
```

Confirm the concrete structure before creating its files, moving existing material, or implementing its runtime changes. An instruction to resume work is not approval of a structure that has not been presented. Once the structure and scope are approved, proceed within them without asking again for each file; bring material changes to the agreed structure back to the user. Approval to edit this design reference does not itself approve an agent implementation.

Provide the initial documents without recursively expanding every linked source. Additional reading is driven by the task. The runtime supplies an authorized file path or document-reading tool. If repository access is restricted, permitted guidance still needs a working read path.

Required tool schemas and minimal descriptions remain available to the engine; long manuals are read on demand. Platform choice must not prevent access to the same authorized guidance. Mandatory execution limits are enforced independently of whether the agent reads their documentation.

## Capabilities

| Component | Purpose | Example |
|---|---|---|
| Skill | Task procedure and related resources | Registered email-writing `SKILL.md` |
| Tool | An executable operation | `mail.read`, `mail.save_draft` |
| Command | An entry point to a task or runtime function | `/email-draft`, `/status` |
| Hook | A code check before or after execution | Approval or permission enforcement |

Definitions, procedures, usage documentation, and capability indexes are maintained in the shared catalog. Each agent's runtime settings select its allowed skills, tools, and commands. The runtime checks those permissions on invocation. Common catalog ownership does not imply identical access for every agent.

These identifiers are illustrative. Registration and effective permissions supply the actual entries, targets, and valid documentation locations. Skill, tool, and command category indexes use the guidance columns defined in [Index format](#index-format).

```text
Capability registration + effective agent permissions
├─ Skills category index: procedure source and usage condition
├─ Tools category index: available operation and usage documentation
├─ Commands category index: syntax and connected task or function
├─ Console menus and platform invocation routes
└─ Execution-time permission checks

/email-draft → existing email SOP or skill → permitted tools → draft
/status → runtime status query
```

Generate or expose these views from the registered sources rather than manually maintaining independent platform catalogs. A command connects to an existing procedure or function; it does not need its own copy of the prompt. Mandatory checks apply to every invocation path, including direct model tool calls.

## Human feedback

The `human-feedback.md` category index lists human requests and their application using Date / Topic / Status / Details. The shared rules index links to `rules/human-feedback.md`, the common recording and application policy in the example layout. The linked record identifies the original message, common/team/personal scope, affected source, application or unresolved result, and verification.

Accept formal human feedback and memory changes through their explicit slash commands. The runtime recognizes the invocation and checks the requester, permitted scope, persistence, and duplicate processing; the model interprets the content and appropriate target. Register command names and syntax in the existing shared command catalog when implementing them; this design does not choose those names. Ordinary task conversation can direct corrections to the current output without being treated as a standing-guidance or memory update.

Record feedback received by command, then apply the requested changes to the appropriate SOP, rule, memory, role, or code within the human-authorized scope. The command itself supplies authorization for that scope; do not ask for the same approval again. Ask when the intended change or authority is unclear. Structure changes also follow the confirmation step in [Reading and creation](#reading-and-creation).

The original request stays in the conversation. The index tracks its disposition; the affected source holds the current guidance. Read feedback history when relevant, not automatically on every start or resume. Apply the corrected source in later work, without duplicating the feedback as standing instructions or memory. If an existing rule already covers the issue, correct the work rather than adding a case-specific rule.

| Request | Target |
|---|---|
| Make this email shorter | Current output |
| Start future emails with the conclusion | Email writing guidance in the applicable scope |
| Use this report format for the team | Team reporting procedure |
| This customer prefers English replies | Memory in the applicable scope |
| Take responsibility for this additional task | Role document |
| Require approval before sending | Runtime approval check |

```text
Receive human feedback command → index the request and source → determine authorized scope
→ update the authoritative source → verify → update the index with the result
```

Change the SOP when the workflow changes; change a linked detail document when only that detail changes. Update an index when an item, location, or reading condition changes. A corrected source does not automatically require a new appendix.

When asked to organize feedback, consolidate duplicate records and repair links and statuses while preserving original requests, approval evidence, and unresolved items.

Record the changed source and verification before reporting a durable request as applied. Unapplied requests retain their unresolved state and reason; link them from the relevant handoff when crossing sessions. Code, deployment, and other operational changes remain subject to the authorized scope and applicable execution boundaries.

## Self-feedback

Self-feedback covers problems encountered while working, their causes, useful methods, proposed improvements, and memory candidates. Use the existing proposal store and `self-feedback.md` category index, with Date / Topic / Status / Details; distinguish feedback proposals from memory candidates in the record rather than adding a separate self-memory document hierarchy. The shared rules index links to `rules/self-feedback.md` for the common recording and approval policy. The linked record contains the kind, observation, task or evidence reference, proposed target and scope, and human approval/application references. Distinguish a verified method from an untested hypothesis.

The agent may record its findings and proposals. Applying them to an SOP, rule, memory, role, code, or another authoritative source requires human approval of that change. Pending proposals are evidence for review, not active instructions for later tasks. The runtime checks human approval and its scope before a source write, across every write path; a model-written status alone is not approval.

```text
Discover an improvement or memory candidate → record evidence, kind, target, and scope
→ Await human approval
   ├─ Approved → route to human feedback or memory → apply → verify → link the result
   ├─ Rejected → record the decision; source unchanged
   └─ Pending → retain the proposal; source unchanged
```

Approval must identify the proposal and scope. An approved feedback proposal enters the human-feedback record and updates its owning source; an approved memory candidate enters the memory source and index. Link the original proposal, human approval, changed source, and verification instead of creating another active copy. Mark it applied only after successful verification; approval alone is not completion. Pending or rejected candidates remain review records, not active guidance or memory.

Task-result checking is a related runtime operation. Its evaluation criteria belong in the existing SOP, skill, or validation code. The runtime ensures that the check is executed and its result recorded.

```text
Execute task → check its completion criteria
               ├─ Pass → record verification → complete
               └─ Fail → correct → verify again
                          └─ Cannot resolve or repetition limit reached
                             → record unresolved state and reason
```

Successful completion requires a recorded check result. Use task-appropriate termination conditions rather than an unbounded correction loop. Automate objectively checkable criteria and use model or human review where judgment is required. Running a review does not guarantee that its judgment is correct.

Correcting the current output within the assigned task is distinct from changing standing guidance. Complete and check the current task, then record reusable lessons as proposals. Even a recurring, verified improvement needs human approval before it changes an authoritative source. After an approved change, check its effect in subsequent work.

## Verification

Revision, 2026-09-14 (structure requirements): removed requirements that repeated the global Harness and Documents and records rules; this section now keeps only agent-specific requirements and links to the global source.

Revision, 2026-09-14: human feedback and memory commands authorize their requested scope; self-feedback and memory candidates use the existing proposal store and require human approval before application. The changed source holds the effective content; feedback history records disposition and is read on demand. The current memory index remains mandatory at start and resume. This revision updates the design only; command names, runtime implementation, and deployment remain separate work.

Verified for this revision: 20 internal anchor references resolve, code fences are balanced, the four mandatory principles remain intact, and the memory/feedback loading and proposal-promotion rules agree. Runtime behavior was not changed or tested.

Revision, 2026-09-12 (memory): the owner requested that basic memory be available at the start of work and confirmed indexed memory and human-requested updates. Initial and resumed context now explicitly includes the current personal memory index; details remain on demand. The Memory section connects updates to the existing human-feedback and self-feedback policies. Checked the affected startup descriptions, index example, and verification criteria for consistency. This design change does not deploy an agent or grant a runtime memory-write capability.

Revision, 2026-09-12: added the owner-confirmed host → project → agent → task boundaries, project databases on shared installations, persistent file/DB responsibilities, and fresh-task versus same-thread session behavior. Global instructions link to this section; project documentation keeps application details and observed state. Source/active instruction equality, section links, and whitespace were checked. No runtime, database, or filesystem migration is implied.

Revision, 2026-09-11: recovered the four principles from the original memory and made them mandatory for every agent design and build. Global instructions and PA shared guidance reference this source. Documentation linkage does not establish that existing agent runtimes already load it.

Verified for this revision: the four-item section and shared guidance links resolve; both active global instruction files match their source SHA-256 hashes. Existing runtime adoption remains unverified.

Revision, 2026-09-10: the final diagram defines shared rules and capability catalogs; team organization, goals, decisions, history, and handoff; and personal memory, SOP, history, handoff, and both feedback indexes. This replaces the earlier duplicated category sets and personal capability catalogs. Shared feedback policies are rules, not a separate shared SOP collection.

The overall-index → category-index → detail-file structure, common index fields, role exception, human approval for self-feedback application, and structure confirmation before implementation remain in force. This revision updates documents and examples only. Global Codex and Claude instructions continue to reference this source; runtime implementation and agent migration are separate work.

Verified: nine sample indexes, twelve tables, and 27 relative links match the final category sets and level transitions. Dates, section anchors, Markdown fences, and whitespace checks pass. Both active global instruction files link here and match their source hashes.

When implementing this design, verify:

- The design and agent guidance apply all four mandatory principles; the agent has a working read path to this source.
- Project roots, database connections, and effective access grants preserve project boundaries; each agent has its own workspace inside the project layout.
- Independent scheduled tasks use distinct model sessions and work directories; same-thread follow-ups resume their own session, including after process recovery.
- Retained files and project DB records remain retrievable after task completion; new sessions load only needed guidance and records.
- A standalone agent works with no team setting or team document link.
- Each populated category follows overall index → category index → detail file; role links directly to its single body.
- Shared, team, and personal records retain distinct owners and single sources; scope grouping adds no required navigation level.
- All index rows follow the common date, one-line topic, and detail-link format, with reading conditions or feedback status where applicable.
- A task can resolve the required guidance through working index links and read permissions.
- Initial and resumed context includes the entry point, current personal memory index, role, and minimal principles rather than every linked document.
- Memory details remain readable on demand; a missing required memory index is reported rather than silently omitted.
- A human memory command changes the saved source and needed index entries within its authorized scope, is verified, and is visible to later sessions; ordinary conversation and pending memory candidates do not open or apply durable changes.
- Skills, tools, and commands come from shared registrations; individual settings select allowed entries and code checks every invocation.
- Team organization includes assignment and reporting relationships; role descriptions and individual work records remain at their original sources.
- The user confirmed the proposed agent structure and implementation scope before files or runtime changes were made.
- Human feedback is indexed with its original request, affected source, and application result.
- Formal feedback and memory changes require the registered command or approval of an identified proposal; the runtime checks authorization and duplicates on every write path.
- Later work uses the changed source; feedback history is read on demand and does not become a second set of instructions.
- Self-feedback is indexed with evidence, proposed target, and approval/application status.
- Approved feedback proposals and memory candidates link to their human approval and verified target; failed application remains unresolved rather than being reported as applied.
- A pending or rejected self-feedback proposal cannot change authoritative sources through any write path; approval permits only its recorded scope.
- Completion records include the task check, with bounded correction and explicit unresolved results.
