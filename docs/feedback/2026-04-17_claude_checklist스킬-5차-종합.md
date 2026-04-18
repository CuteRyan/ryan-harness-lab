---
title: /checklist 스킬 5차 — Claude 종합
type: synthesis
author: claude
date: 2026-04-17
subject: /checklist 스킬 (checklist/SKILL.md) 구조 리뷰 종합
reviewers: [codex, gemini]
---

# /checklist 스킬 5차 피드백 종합

## 배경
훅 강제(`dev-checklist-guard.sh`) → 스킬 호출(`/checklist`) 철학 전환 중.
Claude가 백업본 기반으로 **글로벌 `~/.claude/skills/checklist/SKILL.md`를 신규 생성**했으나, 확인 결과 **프로젝트 내 `하네스/skills/checklist/SKILL.md`가 이미 존재**하며 이것이 최신 진화본(`.checklist.md` 단일파일 통합). Codex/Gemini는 프로젝트 내 기존 파일을 리뷰함.

## 리뷰 대상 파일 (프로젝트 내)
- `skills/checklist/SKILL.md` (93라인, `.checklist.md` 단일파일, `approved: true` 템플릿 기본)
- 연관: `settings/settings.json`, `hooks/{dev,doc}-checklist-guard.sh`, `hooks/post-edit-verify.sh`, `CLAUDE.md`

## Codex 요약 (날카로운 구조 리뷰)

**치명 3**
1. **`approved: true`가 템플릿 기본값** → 모델이 스스로 승인 후 진행. `approved: false` + "작성 후 턴 종료" 명령형 필요
2. **스킬(`.checklist.md`) ↔ 옛 훅(`.dev-checklist.md`/`.doc-checklist.md`) 경로 불일치** → `settings.json`의 옛 훅과 `post-edit-verify.sh` 검증 모드를 정합화 필요
3. **프로젝트 `CLAUDE.md`에 프리플라이트 없음** → `rules/dev-checklist.md` 한 줄로는 모델이 매번 떠올리지 못함

**높음 3**
4. **mode 분기 부재** — 통합 스킬인데 코드 중심 템플릿만 있음. `mode: code|doc|design|mixed` 도입 + `post-edit-verify.sh`가 mode 인식해야 함
5. **tiny 의미 조건 부재** — `conftest.py`/`setup.py` blanket 예외 위험. API/스키마/보안/설정/배포는 줄 수와 무관하게 제외
6. **`git status --short` 기준선** — 작업 전/후 대조로 변경 누락 탐지 강화

**중간 1**
7. **`HISTORY.md` vs `docs/history/`** 구조 불일치 (프로젝트 `CLAUDE.md:14`도 같이 정리 필요)

## Gemini 요약 (넓은 관점)

**공통 (Codex와 겹침)**
- Phase 1 "승인 교착" 해결 필요 (단, 방향은 반대 — "선언 후 진입" 제안)
- 통합 스킬 유지 (내부 분기)
- 검증 단계 실제 도구 **로그 증명** 필수

**Gemini 고유 (반영 가치 있음)**
- **롤백 계획** 필수 섹션 (Phase 1에 "실패 시 복구" 추가)
- **Phase 6 즉시 삭제 지양** → 리포트에 내용 포함 or `.backups/` 이동
- **tiny 완화 제안** (5줄 OR 500자 + 의미 단위) — 단, Codex는 엄격 유지 주장

## 공통 지적 (둘 다 언급)
1. Phase 1 승인 프로세스 허점 — 반드시 보완
2. 통합 스킬 유지 + 내부 분기
3. Phase 3 검증을 도구 사용 로그로 증명

## 상충 지점
| 항목 | Codex | Gemini | 채택 |
|------|-------|--------|------|
| Phase 1 흐름 | "작성 후 턴 종료, 다음 턴에 승인" | "선언 후 즉시 진입 (비대화형)" | **Codex** — 이 프로젝트는 대화형 환경 |
| tiny 기준 | 3줄/240자 유지 + 의미 조건 추가 | 5줄 OR 500자 완화 | **Codex 보수적 유지** — 다만 의미 조건(AND 동작 계약) 보강 |

## 반영 우선순위

| 순위 | 항목 | 대상 파일 |
|------|------|-----------|
| 치명-1 | `approved: false` 기본 + Phase 1 "작성 후 턴 종료" 명령형 | `skills/checklist/SKILL.md` |
| 치명-2 | `.checklist.md` ↔ 옛 훅/`post-edit-verify.sh` 정합화 | `settings/settings.json` + 훅 3종 |
| 치명-3 | 프로젝트 `CLAUDE.md`에 프리플라이트 블록 실재화 | `CLAUDE.md` |
| 높음-1 | `mode: code\|doc\|design\|mixed` 분기 + 검증 로직 mode 인식 | SKILL.md + `post-edit-verify.sh` |
| 높음-2 | tiny 의미 조건 추가 (`conftest.py`/`setup.py`/API/스키마 블랭킷 예외 제거) | SKILL.md + `_harness_common.sh` |
| 높음-3 | Phase 3 검증 도구·로그 증명 명시 | SKILL.md |
| 중간-1 | `git status --short` 기준선 기록 | SKILL.md |
| 중간-2 | 롤백 계획 + 파일 보존 정책(삭제 대신 `.backups/`) | SKILL.md |
| 중간-3 | `HISTORY.md` → `docs/history/` 정정 | SKILL.md + 프로젝트 `CLAUDE.md:14` |

## 미반영/보류
- Gemini의 tiny 완화(5줄 OR 500자): Codex 보수 기준 유지 쪽이 안전하므로 **미반영**
- Gemini의 "선언 후 즉시 진입": 비대화형 환경용 제안, 대화형인 이 프로젝트에는 부적합하므로 **미반영**

## 부차 발견 — 글로벌/프로젝트 중복
- Claude가 오늘 만든 `~/.claude/skills/checklist/SKILL.md`는 백업본 기반 구식(`.dev-checklist.md` 계열)
- 프로젝트 내 파일이 최신 진화본
- **조치**: 글로벌 중복 파일을 `~/.claude/skills/.backups/checklist-SKILL-2026-04-17.md`로 이동 후 폴더 제거. 프로젝트 파일만 정식으로 유지

## 다음 단계
프로젝트 루트에 개선 작업용 `.checklist.md` 생성 후 주인님 승인 대기. 승인 시 치명 3 + 높음 3부터 순차 반영.
