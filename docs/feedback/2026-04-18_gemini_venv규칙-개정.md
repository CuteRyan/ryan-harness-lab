---
title: Gemini 리뷰 — venv 규칙 개정 (CLAUDE.md + coding.md)
type: feedback
reviewer: gemini
date: 2026-04-18
target: ~/.claude/CLAUDE.md 하단 신규 섹션 + ~/.claude/rules/coding.md 전면 개정
---

# Gemini 리뷰 — venv 규칙 개정

## 총평
제안 방향은 현대적 Python 워크플로와 VS Code 설계 의도에 부합하는 **매우 바람직한 변화**. 특히 하드코딩 경로의 "환경 오염·재현 불가능성" 해결 시도는 장기 건강성에 기여.

## 1. `.venv` 통일 방향성 — 방향: 맞음 (높음)
- VS Code Python 확장은 프로젝트 루트 `.venv`를 최우선 탐색(1순위)하도록 설계
- `poetry`/`pdm` 등 현대 패키지 매니저 기본 동작과도 일치
- `.gitignore` 템플릿에 `.venv`가 기본 포함되어 관리 용이
- **개선 제안**: "Windows(Scripts/)와 POSIX(bin/) 경로 차이 인지, 직접 호출 시 플랫폼 독립적인 방식(`python -m venv .venv`) 권장" 추가

## 2. `python.defaultInterpreterPath` 전면 금지의 부작용 — 방향: 맞음 (높음)
- CI/CD: GitHub Actions 등은 가상환경을 동적 생성하거나 `actions/setup-python`으로 주입 → 하드코딩 없어야 유연
- Docker: 컨테이너 내부는 환경 변수(`PATH`)로 제어할 영역, 에디터 설정으로 강제할 영역 아님
- 팀 공유: OS/Python 경로 차이로 하드코딩이 오히려 협업 충돌의 주범
- **결론**: 금지 조치 타당. 단 `pyenv`/`conda` 사용자를 위해 "에디터 하단 상태 표시줄 인터프리터 선택 활용" 안내 명시 중요

## 3. 마이그레이션 4단계 — 방향: 맞음 (중)
### 누락된 리스크
- **Lock 파일**: `poetry.lock`/`Pipfile.lock` 사용 시 환경 재생성에서 버전 고정 풀리지 않도록 주의
- **IDE 캐시**: VS Code가 이전 `venv` 경로를 기억하고 에러 띄울 수 있음 → `Developer: Reload Window` 단계 Phase 4에 추가 권장
- **Absolute Paths in .env**: `.env` 내 가상환경 경로 절대경로 언급 확인 단계 Phase 1에 필요

### 개선 제안
- Phase 1에 `pip freeze > requirements.txt` 스냅샷 단계 명시 → "재생성 시 패키지 누락" 방지

## 4. 서버 배포 주의사항 — 방향: 보완 필요 (중)
### 추가 고려사항
- **Systemd Unit Files**: `ExecStart` 경로뿐 아니라 `Environment="PATH=..."` 항목도 수정해야
- **Jupyter/Notebook Kernels**: 서버 Jupyter 운영 시 커널 사양(`kernel.json`) 내 Python 경로도 갱신 필요
- **VS Code Remote (SSH)**: 서버에서 직접 개발 시 서버 사이드 `.vscode/settings.json`도 동일 규칙 적용 확인

## 5. 기존 rules 정합성 — 방향: 맞음 (낮음)
- `deployment.md`의 배포 규칙과 제안한 서버 배포 주의사항은 상호 보완적
  - `deployment.md`에 "가상환경 경로 변경 시 관련 서비스 재시작(Restart) 필수" 항목 추가 연동 권장
- **Harness Engineering**: 가상환경 표준화는 "환경 설계" 업무 핵심 → 원칙을 구체적으로 실천하는 좋은 사례

## 6. CLAUDE.md ↔ coding.md 구조 최적화 — 방향: 구조 개선 제안 (높음)
- **문제점**: 동일 내용이 두 곳에 중복되면 수정 시 누락 위험
- **CLAUDE.md**: AI 초기 로드용 '요약 지침' → 짧고 강렬해야 함
- **개선 제안**:
  - CLAUDE.md: "Venv 표준: `.venv` 사용, 절대 경로 지정 금지. 상세 절차는 `rules/coding.md` 참조" 수준의 한 줄 요약
  - coding.md: 마이그레이션 절차와 기술 세부를 모두 수용하는 Single Source of Truth로 운영

## 최종 결론 및 권고
제안안은 **"명시적인 것이 암시적인 것보다 낫다"**는 Python 철학에 부합, VS Code와의 마찰을 줄이는 최선의 선택.

### 보완 적용 권고
1. **중복 제거**: CLAUDE.md는 포인터 역할만, 상세는 coding.md에 집중
2. **도구 활용**: 마이그레이션 중 하드코딩 경로를 찾기 위한 `grep`/`rg` 사용 예시 명시 (이미 포함됨)
3. **검증 단계 강화**: 가상환경 교체 후 `pytest`/기존 테스트 스위트 정상 작동을 마이그레이션 최종 승인 조건으로 명시

> 이 개정안을 적용하면 오늘 겪은 인터프리터 인식 에러와 같은 소모적 환경 문제를 원천 차단 가능.
