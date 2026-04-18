---
title: /checklist 스킬 5차 — Codex 리뷰
type: feedback
author: codex
date: 2026-04-17
subject: /checklist 스킬 (checklist/SKILL.md) 신규 생성본
---

# Codex 리뷰 — /checklist 스킬 5차

> 리뷰 대상: `skills/checklist/SKILL.md` (프로젝트 내 기존 파일, Codex가 실제 작업트리를 읽고 리뷰)
> 요청 배경: 훅 강제 → 스킬 호출 전환 후 백업본 기반 신규 생성, 주변 시스템과 정합성 검토 요청

## 기준 정리
질문 초안은 `.dev-checklist.md`를 말하지만, 실제 작업트리의 `skills/checklist/SKILL.md:13`은 `.checklist.md` 단일 파일을 말한다. 아래는 실제 파일과 주변 rules/settings까지 본 구조 리뷰.

## 주요 지적

### 1. 승인 절차가 사실상 무력화되어 있음
`skills/checklist/SKILL.md:26`에서는 "주인님 승인 후 진행"이라고 하는데, 템플릿이 `:63`에서 이미 `approved: true`를 넣음. 모델이 스스로 승인 마커를 작성하고 바로 구현으로 넘어갈 수 있음. **가장 큰 구멍.**

- 기본값은 `status: draft` 또는 `approved: false`여야 함
- "체크리스트 작성 후 구현 파일을 건드리지 말고 응답을 멈춘다. 다음 사용자 메시지에서 명시 승인된 경우에만 `approved: true`로 바꾼다" 필요

### 2. `.checklist.md` 통합 방향과 남아 있는 훅/설정 충돌
스킬은 `.checklist.md`를 만들라고 하지만 `settings/settings.json:57, 61, 74, 78`에는 아직 `doc-checklist-guard.sh` / `dev-checklist-guard.sh`가 남아 있음. 이 훅들은 `hooks/dev-checklist-guard.sh:77`, `hooks/doc-checklist-guard.sh:66`에서 `.dev-checklist.md`, `.doc-checklist.md`만 찾음.

→ 실제 활성 설정이 `settings/settings.json` 쪽이면 `/checklist`가 만든 `.checklist.md`는 옛 훅을 만족시키지 못함. **하나만 선택해야 함**:
- 스킬 전환이면: settings에서 옛 체크리스트 훅 제거 + 문서/테스트 정리
- 훅 유지면: 스킬이 `.dev/.doc`을 만들게 수정

### 3. CLAUDE.md(프로젝트)에 프리플라이트 블록 없음
실제 `CLAUDE.md:1`에는 질문에 적은 프리플라이트 블록이 없음. 현재 파일은 프로젝트 소개와 docs 구조만. "코드/문서 수정 전 `/checklist` 호출" 지시가 없음.

→ 훅 강제 없이 모델 자율로 돌릴 거면 `CLAUDE.md` 또는 글로벌 rule에 이 문장이 **실제로** 있어야 함. `rules/dev-checklist.md`의 한 줄 포인터만으로는 모델이 매 작업 전 스킬을 떠올릴 가능성이 낮음.

### 4. 통합 스킬인데 템플릿과 검증은 코드 작업 중심
템플릿의 `:69`에 `수정 대상 파일`은 있지만 문서 작업의 핵심인 `연관 문서`, `교차 검증`, `용어/계약 대조` 섹션이 없음. 게다가 `.checklist.md` 사후 검증도 `hooks/post-edit-verify.sh:251`에서 `.checklist.md`를 무조건 dev 체크리스트처럼 검증.

→ 통합하려면 `mode: code|doc|design|mixed`를 두고 mode별 필수 섹션을 달리 검증해야 함.

### 5. tiny edit 예외 기준 — 수치보다 의미 조건이 빠짐
3줄 AND 240자는 보수적인 기준이라 유지해도 됨. 다만:
- "한 파일의 단일 `Edit`에서 old/new 각각 3줄 이하, 각각 240자 이하"로 명확히 써야 함
- public API, 스키마, 권한/보안, 설정, 배포, 테스트 비활성화, 데이터 마이그레이션, `setup.py`, `conftest.py` 변경은 **줄 수와 무관하게** tiny 예외에서 빼야 함
- 특히 질문 초안의 `__init__.py`, `conftest.py`, `setup.py` **blanket 예외는 위험**. `conftest.py`와 `setup.py`는 작은 수정도 테스트/배포 동작을 크게 바꿈

### 6. "주인님 승인 후 구현" — 모델이 멈춰야 하는 지점이 명령형으로 박혀 있지 않음
`:23`의 Phase 1은 체크리스트 생성 단계인데, "체크리스트 작성 후 최종 응답으로 승인 요청만 하고 턴을 종료"가 없음. 훅 없는 자율 운영에서는 이 문장이 핵심.
→ "승인 요청"과 "구현 시작"을 같은 Phase 안에 두면 모델이 이어서 진행할 확률이 큼.

### 7. 변경 누락 탐지 약함
`:34`는 "추가 변경 파일 있으면 소급 추가"라고만 함. 실제로는:
- 작업 전 `git status --short` 기준선 기록
- 작업 후 `git status --short`와 `git diff -- <paths>`로 변경 파일 대조

그렇지 않으면 기존 사용자 변경과 이번 작업 변경이 섞임.

### 8. HISTORY.md 참조가 현재 구조와 어긋남
스킬은 `:56`, `:92`에서 `HISTORY.md`를 말하지만, 현재 이 프로젝트는 `docs/history/` 구조를 쓰고 있음. `CLAUDE.md:14`도 `docs/HISTORY.md`로 남아 있어 같이 정리해야 함.

## 질문별 결론

**작동성**: 지금 형태는 모델이 건너뛸 구멍이 있음. 특히 ① `approved: true` 선기입, ② 실제 `CLAUDE.md` 프리플라이트 부재, ③ `.checklist.md`와 옛 훅의 충돌이 **치명적**. 훅 없이도 따르게 하려면 "작성 후 정지", "명시 승인 전 구현 금지", "승인 마커 기본 false"가 필요.

**tiny edit**: 3줄 AND 240자는 합리적. 다만 숫자만으로 판단하지 말고 "단일 파일, 단일 Edit, 오탈자/문구/주석/포맷 수준, 동작 계약 변경 없음"을 추가해야 함. `Write`, `MultiEdit`, 다중 파일, 설정/스키마/보안/테스트/배포 변경은 tiny 예외에서 제외.

**통합 vs 분리**: `/checklist` 하나로 유지가 맞음. `/checklist-code`, `/checklist-doc`, `/checklist-design`으로 나누면 호출 회상률이 떨어지고 혼합 작업에서 다시 꼬임. 대신 **단일 스킬 안에서 `mode`를 자동 판정**하고, mode별 필수 섹션과 템플릿을 분기.

## 최소 수정안

```markdown
status: draft
approved: false
mode: code|doc|design|mixed

## 승인 규칙
- 체크리스트 생성 후 구현 파일을 수정하지 말고 사용자 승인 요청으로 턴을 종료한다.
- 사용자가 명시적으로 승인한 다음 턴에서만 `approved: true`로 변경한다.
- scope가 커지면 체크리스트에 추가하고, 중대한 범위 변경은 다시 승인받는다.
```

그리고 `.checklist.md` 통합을 유지할 거면 `settings/settings.json`, 옛 dev/doc 훅, `docs/workflows/*`, `post-edit-verify.sh`의 `.checklist.md` 검증 모드까지 **한 번에 정합화**해야 함. 지금은 스킬 문구만 바뀌고 주변 시스템이 완전히 같은 방향을 보지는 않음.
