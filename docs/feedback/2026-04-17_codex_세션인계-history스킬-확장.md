---
title: Codex 피드백 — 세션 인계 / project-history 스킬 확장 설계
author: codex
date: 2026-04-17
target: 세션-인계-history-스킬-확장
---

# Codex 피드백 — 세션 인계 / project-history 스킬 확장 설계

## 검토 대상
- project-history 스킬에 세션 간 핸드오프 기능 통합 설계안
- 핵심: 마이그레이션 → index.md 최상단 진행 중 섹션 → 일별 동기화 → SessionStart 훅

## 원문

가장 큰 약점은 "index가 거울"이면 결국 신뢰할 수 없는 두 번째 원본이 된다는 점이다. 동기화 실패, 수동 편집, 충돌 시 무엇을 믿을지 규칙이 없다. index에는 진행 중 내용을 저장하지 말고, 최신 일별 파일의 `## 다음 작업`을 추출해 렌더링하거나 `project-history status`가 생성한 캐시로만 두는 편이 낫다.

SessionStart 훅은 필요하되 아주 얇게: handoff 5줄 + `git status --short` + `git log -5` 정도만 조건부 주입. 깊은 탐색은 수동 `/project-history`가 맞다.

순서는 마이그레이션 선행보다 단일 `HISTORY.md` 상단에 인계 섹션을 먼저 붙여 1~2주 검증하는 게 안전하다. 포맷과 습관이 안정된 뒤 폴더 구조로 옮겨라.

## 핵심 지적
1. **이중 기록 = 신뢰 붕괴**: index를 "거울"로 두면 결국 두 개의 원본이 됨 → index는 SSOT가 아닌 추출 결과/캐시여야 함
2. **SessionStart 훅 얇게 + 조건부**: handoff 5줄 + git status/log만, 깊은 탐색은 수동
3. **마이그레이션은 후순위**: 단일 HISTORY.md 상단 섹션으로 1~2주 검증 후 폴더 이전
