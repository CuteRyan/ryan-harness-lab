---
title: 피드백 인덱스
type: index
status: active
created: 2026-04-17
---

# 피드백 인덱스

## 2026-04-18

### 4차: /feedback 커맨드 개정 (dogfood — 개정본으로 자기 리뷰)
- [Codex](2026-04-18_codex_feedback스킬-개정.md) — 실측 검증(codex-cli 0.120.0 / gemini 0.37.1), 높음 3(PS bare 실패, 읽기 전용 가드 부재, 출력 포맷 모순) + 중간 3 + 낮음 1. Phase 0 프리플라이트 제안
- [Gemini](2026-04-18_gemini_feedback스킬-개정.md) — "바로 적용 무방", 높음 2(경로 해석, 읽기 실패 폴백) + 중간 1 + 낮음 1. Pre-check·Diff 기반 리뷰 아이디어
- [종합](2026-04-18_claude_feedback스킬-개정-종합.md) — dogfood 검증 성공(프롬프트 600자로 1/10 감축, 품질 유지). 공통 3 + 주인님 한글 인코딩 지적 반영, 11개 개선안 정리

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
