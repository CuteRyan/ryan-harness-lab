---
title: Claude 종합 — venv 규칙 개정 피드백 분석
type: synthesis
date: 2026-04-18
target: ~/.claude/CLAUDE.md 하단 신규 섹션 + ~/.claude/rules/coding.md 전면 개정
sources:
  - 2026-04-18_codex_venv규칙-개정.md
  - 2026-04-18_gemini_venv규칙-개정.md
---

# Claude 종합 — venv 규칙 개정 피드백

## Codex 요약 (날카로운 리뷰, 공식 문서 대조)
- **방향은 맞으나 너무 단정적**, VS Code 2026 동작과 일부 어긋남
- **높음**: `python.defaultInterpreterPath` 전면 금지는 과함(폴더 경로 `${workspaceFolder}/.venv`는 공식 허용), `rg` 패턴 품질 나쁨(`.venv` 오탐+백슬래시 이스케이프+`--hidden` 잡음), 서버 배포 체크리스트 부족
- **중간**: "자동 감지 1순위" 표현 부정확(실제 우선순위: `python-envs.pythonProjects` → `defaultEnvManager` → `defaultInterpreterPath` → 자동 탐색), Windows/POSIX 분기 없음, "반드시 .venv" 단정(Conda/Docker/devcontainer/pyenv matrix 예외 압살), `.vscode/settings.json` 인터프리터 금지 구역화는 `python-envs.pythonProjects` 기록 동작과 충돌
- **rules 정합성**: coding.md가 배포 운영까지 품음 → deployment.md로 서버/CI/롤백 체크리스트 분리 권장
- **CLAUDE.md ↔ coding.md 중복**: 전역 CLAUDE.md는 포인터만, 세부는 coding.md SSOT

## Gemini 요약 (넓은 관점 리뷰)
- **방향 매우 바람직** — 현대 Python 워크플로·VS Code 설계 의도 부합
- **높음**: CLAUDE.md ↔ coding.md 중복 제거(CLAUDE.md는 포인터 역할만), `pyenv`/`conda` 사용자 안내 추가
- **중간**: Lock 파일(poetry.lock/Pipfile.lock) 재생성 리스크, IDE 캐시(`Developer: Reload Window`) Phase 4에 추가, `.env` 내 절대경로 확인 Phase 1에, `pip freeze > requirements.txt` 스냅샷 권장, systemd `Environment=PATH`·Jupyter kernel.json·VS Code Remote(SSH) 언급
- **낮음**: deployment.md와 상호 보완 — "가상환경 경로 변경 시 서비스 재시작 필수" 연동

## 공통 지적 (둘 다 언급 — 반드시 반영)
1. **CLAUDE.md ↔ coding.md 중복 제거** → CLAUDE.md는 포인터 1~2줄, coding.md가 SSOT
2. **마이그레이션 4단계 보강** — Lock 파일/IDE 캐시/systemd PATH 등 누락 보완
3. **기존 rules와 정합성** — deployment.md와 역할 분리(coding=개발환경/로컬, deployment=서버/CI/롤백)
4. **Windows/POSIX 경로 분기** — 전역 규칙이면 `Scripts/python.exe`(Win) vs `bin/python`(POSIX) 구분

## 상충 지점
| 쟁점 | Codex | Gemini | 판정 |
|------|-------|--------|------|
| `defaultInterpreterPath` 금지 강도 | **조건부 허용**(폴더 경로는 OK) | **전면 금지 타당** | Codex 채택 — 공식 문서 근거 있음 |
| `.venv` 우선순위 표현 | "자동 탐색 우선 대상"으로 완화 | "최우선 1순위" 유지 | Codex 채택 — 사실 관계 정확 |

## 반영 우선순위

| 순위 | 항목 | 반영 대상 | 중요도 |
|------|------|----------|--------|
| 1 | CLAUDE.md 섹션을 포인터 1~2줄로 축소 | `~/.claude/CLAUDE.md:42-44` | 높음 |
| 2 | `defaultInterpreterPath` 전면 금지 → "구체 실행파일 경로/User 전역 상대경로 금지"로 완화 | `coding.md:5`, `CLAUDE.md:44` | 높음 |
| 3 | `rg` 패턴 교체 (`.venv` 오탐 제거 + 제외 glob) | `coding.md:20` | 높음 |
| 4 | "자동 감지 1순위" → "기본 검색 경로·자동 탐색 우선 대상" | `coding.md:3` | 중간 |
| 5 | Windows/POSIX 경로 분기 명시 | `coding.md:3` | 중간 |
| 6 | `python -m venv .venv`가 "시스템 Python 금지"와 충돌 → 예외 명시 | `coding.md:25` | 중간 |
| 7 | 서버 배포 체크리스트를 `deployment.md`로 분리 + systemd PATH/supervisord/celery/docker-compose/k8s/daemon-reload/헬스체크/롤백 추가 | `coding.md:40-43` → `deployment.md` | 높음 |
| 8 | Phase 1에 Lock 파일 확인(`uv.lock`/`poetry.lock`/`Pipfile.lock`/`.python-version`/`.tool-versions`) 추가 | `coding.md` Phase 1 | 중간 |
| 9 | Phase 4에 VS Code `Developer: Reload Window` 또는 `Python Environments: Refresh All` 추가 | `coding.md` Phase 4 | 중간 |
| 10 | Poetry는 `poetry config virtualenvs.in-project true --local` 절차 명시 | `coding.md` Phase 2 | 중간 |
| 11 | "반드시 .venv" → "기본값 .venv, 예외는 프로젝트 CLAUDE.md 기록" | `coding.md:3` | 중간 |
| 12 | `"내부 스토리지에 저장됨"` 삭제 또는 `python-envs.pythonProjects` 기록 가능성 정정 | `coding.md:7` | 낮음 |

## 미반영 / 보류 항목
- **Gemini의 `pip freeze > requirements.txt` 스냅샷 제안**: 이미 `requirements.txt 최신 확인` 단계 있음. 중복 — 보류
- **Gemini의 Jupyter kernel.json 언급**: 대부분 프로젝트에 해당 없음 → deployment.md 체크리스트에 "프로젝트에 Jupyter 운영 있으면" 조건부로만 명시

## 다음 세션 진입점
- 주인님 승인 후 **2단계 반영**:
  - 1단계(CLAUDE.md/coding.md 본문 수정): 우선순위 1~6, 11, 12
  - 2단계(deployment.md 신설/확장): 우선순위 7
  - 3단계(세부 Phase 보강): 우선순위 8~10
- 진행 전 `.checklist.md` 생성 필요 (tiny edit 예외 아님 — 규칙 문서 대규모 개정)
