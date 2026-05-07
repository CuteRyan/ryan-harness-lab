# -*- coding: utf-8 -*-
"""
Subagent identity lookup helper for PreToolUse hooks.

Why:
  Claude Code 의 PreToolUse hook stdin JSON 의 `agent_type` 필드는
  spawn 시 `name` 파라미터 (= 임의값, 예: "dast-verifier-3") 가 들어옴.
  frontmatter `name` (실제 subagent_type, 예: "dast-analyzer") 이 아니다.
  → hook 검사 분기 `agent_type in (...)` 가 의도대로 작동 안 함.

Solution:
  Active team config (`~/.claude/teams/*/config.json`) 에서 `members[].agentId`
  매칭 → `agentType` (frontmatter name) 추출. 매칭 실패 시 stdin agent_type fallback.

Source:
  - 본 프로젝트 2026-05-07 Day 21 turn 1 #028 (a) 진단 라운드 3 PASS
    (stdin JSON 캡처 결과 = "agent_type": "dast-verifier-3" 결정적 재현)
  - Anthropic Claude Code Hooks Reference 의 "agent_type" 의미 = subagent 일 때
    spawn name 우선 (Team 컨텍스트 한정, frontmatter name 아님)
"""

import glob
import json
import os


def lookup_subagent_type(agent_id="", spawn_name="", fallback=""):
    """Active team config 에서 frontmatter agentType 추출.

    매칭 순위:
      1. agentId 정확 매칭 (Claude Code 내부 식별자가 일치하는 경우)
      2. name 매칭 (spawn 시 `name` 파라미터, stdin 의 agent_type 과 동일)
      3. 매칭 실패 시 fallback

    Why 매칭 2개 필요:
      stdin `agent_id` 형식 (예: "ab8f82bb6690ef214" hex) ≠ team config `agentId`
      형식 (예: "dast-verifier-4@team_name" long form). 둘은 별도 식별자.
      그러나 stdin `agent_type` == team config `name` 정확 일치.
      → 두 매칭 시도하면 robust (Day 21 turn 1 #028 a 라이브 검증 PASS 보장).

    Args:
      agent_id: stdin JSON 의 `agent_id` 필드 (Claude Code 내부 short id)
      spawn_name: stdin JSON 의 `agent_type` 필드 (= spawn 시 name 파라미터)
      fallback: 매칭 실패 시 반환값 (보통 spawn_name 자체 = 메인 호출 시 빈 값)

    Returns:
      frontmatter `name` (실제 subagent_type) 또는 fallback.
      메인 호출 (agent_id + spawn_name 모두 부재) = 즉시 fallback.

    Side effects:
      ~/.claude/teams/*/config.json 파일 순회 (active team 만, .archived 제외).
    """
    if not agent_id and not spawn_name:
        return fallback

    teams_dir = os.path.expanduser("~/.claude/teams/")
    if not os.path.isdir(teams_dir):
        return fallback

    pattern = os.path.join(teams_dir, "*", "config.json")
    for cfg_path in glob.glob(pattern):
        # archived team 폴더 (`.archived/...`) 우회
        if os.sep + ".archived" + os.sep in cfg_path:
            continue
        try:
            with open(cfg_path, encoding="utf-8") as f:
                cfg = json.load(f)
        except (OSError, json.JSONDecodeError, ValueError):
            continue

        for member in cfg.get("members", []):
            if agent_id and member.get("agentId") == agent_id:
                return member.get("agentType") or fallback
            if spawn_name and member.get("name") == spawn_name:
                return member.get("agentType") or fallback

    return fallback
