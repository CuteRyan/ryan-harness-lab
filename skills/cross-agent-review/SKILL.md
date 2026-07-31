---
name: cross-agent-review
description: Maintain a topic-and-date-specific Markdown relay where Claude and Codex review the same work, respond to each other's evidence, and close the discussion only when the user asks. Use when the user asks Claude and Codex to cross-review, exchange opinions through a shared file, continue an existing review relay, or complete one review record.
---

# Cross-Agent Review

Use one shared Markdown file for each review session. Treat every topic and date combination as an independent record.

## Choose the operation

- **Start**: Create a new review file when the user starts a new topic, including a repeated topic on a new date.
- **Reply**: Add the current agent's response to an open review file.
- **Complete**: Close one review file only when the user explicitly asks to complete it.

## Locate the review directory

1. Use the Git repository root when available; otherwise use the current working directory.
2. Store review files in `{project-root}/docs/cross-review/`.
3. Create the directory during the first **Start** operation only.
4. Treat each review as a sequential relay. Claude and Codex must not write the same review file at the same time.

## Start a review

1. Determine the topic, goal, materials to inspect, key questions, and constraints from the user's request and current project.
2. Read the actual listed materials before writing the first opinion.
3. Copy `assets/review-template.md` into the review directory.
4. Name the file `<topic-slug>-YYYY-MM-DD.md`.
   - Use a short slug matching `[a-z0-9]+(?:-[a-z0-9]+)*`; use `review` if no meaningful slug is available.
   - Reject Windows reserved names such as `con`, `prn`, `aux`, `nul`, `com1`–`com9`, and `lpt1`–`lpt9`.
   - Resolve the final path and confirm its parent is the review directory.
   - A repeated topic on a different date always gets a new file.
   - If the same name already exists on the same date, append `-02`, `-03`, and so on.
   - Never overwrite or silently continue an older file.
5. Replace every template placeholder and write Round 1.
6. Set `initiator` and the Round 1 author to the current agent: `Claude` or `Codex`.

## Reply to a review

1. Use the exact file named by the user.
2. If no file is named, scan the review directory for files whose frontmatter `status` is `open`. Select the only open review; if several are open, ask which one to use.
3. Read the entire review file and inspect the actual source materials relevant to the latest claims.
4. Re-read the review file immediately before writing.
5. Append the next numbered round. Never rewrite, reorder, or remove earlier rounds.
6. Identify the author as `Claude` or `Codex` and include the local timestamp.
7. Add one row to the `문서 이력` table near the top: date, author, and a one-line summary such as `Round N 작성 — <핵심 내용>`. Do not edit earlier rows.
8. Address the other agent's latest material claims with agreement, disagreement, correction, or a focused question. Cite concrete file paths, tests, or other evidence.
9. If the file changed while composing the response, reload it, recalculate the next round number, and merge the response after the new latest round.
10. Do not append to a completed review.

Use this structure for every reply:

```markdown
### Round N — Claude|Codex — YYYY-MM-DD HH:mm

#### 확인한 자료

#### 상대 의견에 대한 답변

#### 내 의견과 근거

#### 남은 질문

#### 제안
```

## Complete a review

Complete a review only after an explicit user instruction such as “완료해,” “종료해,” or “close this review.” A request to summarize or organize the discussion alone does not close the review; ask whether the user wants completion.

1. Resolve the exact open file using the same selection rules as **Reply**.
2. Read all rounds and verify important unresolved claims against the actual materials.
3. Change the frontmatter `status` from `open` to `completed`.
4. Fill `completed` and `completed_by`.
5. Add a final row to the `문서 이력` table: date, author, and `검토 완료`.
6. Append:

```markdown
## 최종 정리

### 논의 경과

### 합의한 내용

### 남은 이견

### 최종 결론

### 후속 작업
```

In `논의 경과`, summarize in a few lines how the discussion moved across rounds: which claims were raised, challenged, corrected, or dropped.

Do not force agreement. Record unresolved differences and decisions that still belong to the user.
Treat a completed file as immutable. Start a new dated review if the topic needs further discussion.

## Preserve the permission boundary

- Invoking this skill authorizes creating or updating the selected review record only.
- Inspection, review, and completion do not authorize changes to the reviewed code, documents, data, or external systems.
- Completing the review summarizes the discussion; it does not implement the conclusion.
- Modify reviewed artifacts only when the user separately and clearly requests the change.
