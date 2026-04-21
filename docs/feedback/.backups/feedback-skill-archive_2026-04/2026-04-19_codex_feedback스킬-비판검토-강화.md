---
title: Codex 메타 리뷰 — 실패 기록
date: 2026-04-19
target: ~/.claude/commands/feedback.md
status: FAILED
reviewer: codex (codex-cli 0.120.0, gpt-5.4)
---

# Codex 리뷰 실패 기록

## 결과
3회 호출 모두 **자체 분석 생성 실패**.

1. **1차** (파일 경로 + `--add-dir` 방식): Codex가 PowerShell exec로 파일 읽기 시도 → Windows Constrained Language Mode가 `[Console]::OutputEncoding` 설정을 거부 → UTF-8 출력 강제 불가 → 한글 경로/파일 내용이 CP949로 깨짐 → Codex가 깨진 내용을 의미 있는 리뷰로 변환 실패. 출력 116KB 중 자체 분석 0줄.

2. **2차** (제안 본문 프롬프트 인라인, 파일 경로 불필요): Codex가 여전히 관련 파일 확인하려 PowerShell exec 반복 → 모두 `rejected: blocked by policy`. 출력 93KB 중 자체 분석 ≈0줄, 읽은 Gemini 리뷰 + `feedback.md` 원본을 인용 형태로만 담김.

3. **3차** (파일 읽기 전면 금지 명시): 2분 이상 응답 없음 → 강제 종료. CRITICAL 지시로도 툴 호출 충동을 억제 못 한 것으로 추정.

## 실패의 의미 (finding)

이 실패 자체가 `/feedback` 스킬의 **미해결 infra 이슈**:

- **한글 경로(OneDrive/문서/하네스) + PowerShell Constrained Language Mode** 조합에서 Codex가 비실용적 수준으로 동작
- 기존 Phase 2의 "UTF-8 인코딩 가드" 섹션은 "Codex가 내부에서 UTF-8 prefix를 붙여 재처리한다"고 적혀 있으나, 이번 실측은 해당 재처리가 **정책 rejection** 때문에 작동하지 않는 케이스 존재를 보여줌
- 2026-04-18 종합문서의 "Codex 실측 성공" 경험이 모든 환경·경로 조합에 일반화되지 않음을 시사

## 제안 (반영 여부는 종합문서에서 판정)

Phase 0 프리플라이트에 추가:
- Windows + 한글 경로 + Constrained Language 환경 탐지
- 해당 환경에서 Codex를 "인라인 프롬프트 + 파일 읽기 금지" 모드로 기본 전환하거나, Codex 스킵 + Gemini 단독 리뷰로 폴백

→ 종합: `2026-04-19_claude_feedback스킬-비판검토-강화-종합.md`
