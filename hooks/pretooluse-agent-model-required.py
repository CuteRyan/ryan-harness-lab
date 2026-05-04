#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Claude Code PreToolUse hook 본체 — Agent/Task spawn 시 model 파라미터 강제.

검사 순위:
1. tool_name in ("Task", "Agent") 가 아니면 즉시 통과 (방어적 — settings.json matcher 가 1차 거름)
2. tool_input.model 이 opus|sonnet|haiku 중 하나면 통과
3. tool_input.subagent_type 의 ~/.claude/agents/{name}.md frontmatter 에 model: 명시 → 통과
   (rules/agent-spawn-model.md section3 예외 — 공식 agent frontmatter 명시는 model 파라미터 생략 허용)
4. 위 모두 아니면 → permissionDecision: deny + exit 0 + stderr 가시화

근거 룰:
- ~/.claude/rules/agent-spawn-model.md section2 (의무 형식: PM=opus / 워커=sonnet)
- ~/.claude/rules/research-mandatory.md section1 (외부 리서치 의무)

알려진 외부 버그 (rules/research-mandatory.md section3 인용 형식):
- Issue #26923 (CLOSED, 2026-02-19~03-03): exit 2 가 Task 서브에이전트 호출 차단 못함
- Issue #40580 (OPEN, 2026-03-29): subagent PreToolUse 훅 exit code 무시
→ 본 훅은 permissionDecision: deny + exit 0 우회 패턴 (Issue #26923 reporter 미검증 가설)
   = 세계 1호 검증 시도. 작동 시 fallback C+ 변형, 실패 시 D-plan (env=sonnet 보존) 후퇴.
"""

import sys
import json
import os
import re

VALID_MODELS = {"opus", "sonnet", "haiku"}
WATCHED_TOOLS = ("Task", "Agent")
AGENTS_DIR = os.path.expanduser("~/.claude/agents")


def get_frontmatter_model(subagent_type):
    """공식 agent frontmatter `model:` 필드 값 반환. 없으면 None."""
    if not subagent_type:
        return None
    agent_file = os.path.join(AGENTS_DIR, "{}.md".format(subagent_type))
    if not os.path.isfile(agent_file):
        return None
    try:
        with open(agent_file, "r", encoding="utf-8") as f:
            head = f.read(4096)
    except (OSError, UnicodeDecodeError):
        return None
    m = re.search(r"^---\s*\n(.*?)\n---", head, re.DOTALL | re.MULTILINE)
    if not m:
        return None
    mm = re.search(r"^model:\s*([\w-]+)\s*$", m.group(1), re.MULTILINE)
    if not mm:
        return None
    return mm.group(1).lower()


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # 입력 파싱 실패 = silent pass (다른 훅 영향 없음)

    tool_name = data.get("tool_name", "") or ""
    tool_input = data.get("tool_input") or {}

    # (1) Task/Agent 가 아니면 즉시 통과
    if tool_name not in WATCHED_TOOLS:
        return 0

    # (2) model 명시 검사
    model_raw = tool_input.get("model")
    model = (model_raw or "").strip().lower() if isinstance(model_raw, str) else ""
    if model in VALID_MODELS:
        sys.stderr.write(
            "[pretooluse-agent-model-required] PASS via model={} "
            "(tool={}, subagent_type={})\n".format(
                model, tool_name, tool_input.get("subagent_type", "")
            )
        )
        return 0

    # (3) frontmatter 예외 검사 (rules section3)
    subagent_type = tool_input.get("subagent_type", "") or ""
    fm_model = get_frontmatter_model(subagent_type)
    if fm_model in VALID_MODELS:
        sys.stderr.write(
            "[pretooluse-agent-model-required] PASS via frontmatter "
            "(subagent_type={}, model={})\n".format(subagent_type, fm_model)
        )
        return 0

    # (4) 차단 — permissionDecision: deny + exit 0 우회 (Issue #26923)
    reason = (
        "[BLOCKED] Agent spawn requires model parameter. "
        "got: tool_name={}, model={!r}, subagent_type={!r}. "
        "Per ~/.claude/rules/agent-spawn-model.md section 2: "
        "PM uses model=\"opus\", workers use model=\"sonnet\". "
        "Frontmatter agents (e.g., pm) are exempt via rules section 3."
    ).format(tool_name, model_raw, subagent_type)

    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    sys.stdout.write(json.dumps(response, ensure_ascii=False))
    sys.stdout.write("\n")
    sys.stderr.write(reason + "\n")
    sys.stderr.write(
        "[pretooluse-agent-model-required] Workaround: permissionDecision:deny + exit 0 "
        "(Issue #26923 reporter's untested hypothesis). "
        "If spawn proceeds despite this output, the workaround failed = D-plan fallback.\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
