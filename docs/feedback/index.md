---
title: 피드백 인덱스
type: index
status: active
created: 2026-04-17
---

# 피드백 인덱스

## /feedback 스킬 관련 피드백 (archive)

> 2026-04-18 ~ 2026-04-20 동안 /feedback 스킬 자체에 대한 피드백이 3단계 누적(4차 개정 → 비판 검토 강화 → MVP 반영 검증 → B옵션 3차 개정). 2026-04-21 수렴 시점에 전부 `drafts/2026-04-20_proposal_feedback-skill-rewrite.md`(v4)로 흡수됨 (~85% 직접 반영, 나머지 9건 중 4건은 v4 패치 예정·5건은 후속/폐기).
>
> **원문 13개 파일**: `.backups/feedback-skill-archive_2026-04/` (2026-04-18 feedback 개정 종합·Codex·Gemini / 2026-04-19 비판검토 종합·Codex·Gemini·MVP 종합·Codex·Gemini / 2026-04-20 B옵션 3차 종합·Codex·Gemini·Claude-Sub).
>
> **다음 세션 진입점**: 이 index가 아니라 제안서 v4 + `docs/history/2026-04-20.md`를 먼저 읽을 것.

## 2026-04-23

### /checklist 혼동 제거 체크리스트 v2 리뷰
- 대상: `.checklist.md` (v2, 혼동 제거 + 5차 피드백 Q1~Q3 종결)
- Validation: **1/3 VALID** (Claude Sub 태깅 완비 / Codex·Gemini 태깅 누락으로 rubber-stamp 의심)
- [Claude Sub](2026-04-23_claude-sub_.checklist_20260423-084406.md) — H-1 venv-guard 이동 모순, H-2 frontmatter 구분자 누락, M-1 롤백경로 실측 누락, M-2 workflows 갱신 누락, M-3 4번 항목 혼재, L-1/L-2
- [Codex](2026-04-23_codex_.checklist_20260423-084406.md) — (태깅 누락, 실질 5건) **치명급: `.checklist.md` 자체가 `git stash --include-untracked` 로 사라질 위험** + 글로벌 파일 롤백 백업 누락 + venv-guard 이중 지시 + 기존 변경 3건과 최종 1:1 검증 충돌
- [Gemini](2026-04-23_gemini_.checklist_20260423-084406.md) — (태깅 누락, rubber-stamp 경향) 장점 나열 + Win32 경로 원론
- [종합](2026-04-23_claude_.checklist_20260423-084406-종합.md) — Top 3: ①stash 위험 ②글로벌 사전 백업 ③venv-guard 선제 실측. v3 작성 9개 항목 정리

## 2026-04-18

### 3차: Phase A/B/C 구현 결과 리뷰
- [Codex](2026-04-18_codex_구현결과-리뷰.md) — 치명 0, 높음 2(deployment.md 순서 위험, B5 미완 상태의 Accept 방향 주의) + 중간 7. 공식 문서 대조 + 실측 검증. 이전 피드백 10/10 중 8반영/1부분/1미반영(B7 연기)
- [Gemini](2026-04-18_gemini_구현결과-리뷰.md) — 4계층 아키텍처 확립 평가. Settings Drift(UI→repo 역전파 자동화 빠짐) + Git repo 파편화 리스크 + B7 훅 필수
- 공통 시급: B7 allowlint 훅, B5 수동 검증, 5차 피드백 복원

### 2차: VS Code Settings Sync 충돌 해결
- [Codex](2026-04-18_codex_vscode-sync-충돌-해결.md) — 공식 문서+1.116.0 대조, 치명 1(`terminal.integrated.shell.windows`는 제거된 키) + 높음 3(방안 2/3 명령명 부정확, 멀티 기기, CI 린트 설계 빠짐), 최종 권고 **하이브리드(Settings만 Git, 나머지 Sync 유지)**
- [Gemini](2026-04-18_gemini_vscode-sync-충돌-해결.md) — 'Settings as Code' 방향 추천, Profile 분리·`extensions.json` 관리·pre-commit-settings-check 제안
- [종합](2026-04-18_claude_vscode-sync-충돌-해결-종합.md) — Codex 하이브리드 채택, 실행 8단계 정리

### 1차: venv 규칙 개정 (CLAUDE.md + coding.md)
- [Codex](2026-04-18_codex_venv규칙-개정.md) — 높음 3 (defaultInterpreterPath 전면 금지 과도, rg 패턴 품질, 서버 배포 체크리스트 부족) + 중간 3 (우선순위 표현/Windows·POSIX 분기/.vscode 금지 구역화 충돌)
- [Gemini](2026-04-18_gemini_venv규칙-개정.md) — 방향 바람직, 중복 제거·Lock 파일·IDE 캐시·systemd PATH 보완 제안
- [종합](2026-04-18_claude_venv규칙-개정-종합.md) — Codex 근거 강함, 반영 우선순위 12개 정리 (CLAUDE.md 포인터화 + 금지 완화 + rg 교체 + deployment.md 분리)

## 2026-04-17

### 5차: /checklist 스킬 구조 리뷰
- [Codex](2026-04-17_codex_checklist스킬-5차.md) — 치명 3 (approved: true 선기입, 훅-스킬 경로 충돌, 프리플라이트 부재) + 높음 3 + 중간 1
- [Gemini](2026-04-17_gemini_checklist스킬-5차.md) — 승인 교착/롤백 계획/도구 로그 증명/삭제 정책
- [종합](2026-04-17_claude_checklist스킬-5차-종합.md) — 치명 3 + 높음 3 순차 반영 예정, Gemini 완화안은 보류

### 4차: 세션 인계 / project-history 스킬 확장 설계
- 1차: [Codex](2026-04-17_codex_세션인계-history스킬-확장.md) | [Gemini](2026-04-17_gemini_세션인계-history스킬-확장.md) — SSOT 위치 논쟁 (일별 vs index)
- 2차: [Codex](2026-04-17_codex_세션인계-history스킬-확장-2차.md) | [Gemini](2026-04-17_gemini_세션인계-history스킬-확장-2차.md) — 누적 방지 + 형식 + 전환 기준
- [종합](2026-04-17_claude_세션인계-history스킬-확장-종합.md) — 역방향 SSOT 채택 + 7개/14일 한계 + 단계별 적용

### 3차: doc-protection git 보호 로직
- [Codex](2026-04-17_codex_doc-protection-git보호-3차.md) — 치명 2(BLOCKED 재초기화, newline 우회) + 높음 2 + 중간 1 + 낮음 1
- [Gemini](2026-04-17_gemini_하네스-최종상태-3차.md) — Production Ready, 전 컴포넌트 Pass
- [종합](2026-04-17_claude_doc-protection-git보호-3차-종합.md) — Codex 6개 지적 전부 즉시 수정 반영

### 2차: 하네스 피드백 반영 재검토
- [Codex](2026-04-17_codex_하네스-피드백반영-재검토.md) — 8개 문제 (MultiEdit 반쪽, git 우회, .backups Windows)
- [Gemini](2026-04-17_gemini_하네스-피드백반영-재검토.md) — 긍정, 4개 추가 제언
- [종합](2026-04-17_claude_하네스-피드백반영-재검토-종합.md) — 치명 3 + 중간 3 즉시 수정
