# 하네스 프로젝트 — 개발 히스토리

## 프로젝트 개요
- **목적**: 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로) 설계·개발·관리
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅
- **분리 배경**: 지식 프로젝트(리서치 문서 축적)와 역할 혼재 → 2026-04-15 독립 프로젝트로 분리

---

## Day 0 (2026-04-15)

### 프로젝트 초기화
- **지식 프로젝트에서 분리**: 하네스 인프라 관련 문서를 독립 프로젝트로 이동
- **이동 파일**:
  - `project_harness_architecture.md` — 하네스 아키텍처 설계안 (Phase 0~4)
  - `harness_bypass_guide.md` — 훅 우회 가이드
  - `workflows/dev-checklist.md` — 개발 체크리스트 워크플로
  - `workflows/document-work.md` — 문서 작업 워크플로
  - `workflows/wiki-management.md` — 위키 관리 워크플로
  - `workflows/graphify-guide.md` — Graphify 가이드
- **프로젝트 구조**: git init, venv, .vscode, CLAUDE.md, docs/
- 왜: 지식 프로젝트는 "리서치 → 문서화"가 역할인데, 훅/스킬/rules 개발까지 섞이면 역할이 불분명해짐
