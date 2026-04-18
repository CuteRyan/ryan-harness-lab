---
title: Codex 리뷰 — venv 규칙 개정 (CLAUDE.md + coding.md)
type: feedback
reviewer: codex
date: 2026-04-18
target: ~/.claude/CLAUDE.md 하단 신규 섹션 + ~/.claude/rules/coding.md 전면 개정
---

# Codex 리뷰 — venv 규칙 개정

> 공식 문서(VS Code Python environments, settings reference) 대조 검증 포함.

## 총평
방향은 맞으나 현재 문안은 **너무 단정적이고, VS Code 2026년 동작과 일부 어긋남**. 특히 `python.defaultInterpreterPath` 전면 금지, `Select Interpreter` 저장 위치 설명, `rg` 패턴은 수정 필요.

**공식 근거**:
- VS Code Python Environments 기본 `workspaceSearchPaths` = `["./**/.venv"]`
- 인터프리터 선택 우선순위: `python-envs.pythonProjects` → 명시적 `defaultEnvManager` → `python.defaultInterpreterPath` → 자동 탐색
- 수동 환경 지정 시 `python-envs.pythonProjects`를 `.vscode/settings.json`에 기록

## 1. `.venv` 통일 방향성 — 문제 있음 (중)
- 방향 타당. VS Code `workspaceSearchPaths` 기본값과 부합
- `coding.md:3`의 `"자동 감지 1순위"` 표현 부정확 — `.venv`는 **자동 탐색 단계의 우선 대상**이지 전체 선택 순위 1순위가 아님
- `"./.venv/Scripts/python.exe 직접 호출 방식"`은 Windows 전용 — 전역 규칙이라면 POSIX(`./.venv/bin/python`)도 분기 필요
- `"모든 프로젝트 반드시 .venv"`는 Conda/Docker-only/devcontainer/pyenv matrix/Poetry 외부 env 같은 합리적 예외 압살 → 기본값 `.venv`, 예외는 "명시적 이유+프로젝트 CLAUDE.md 기록"이 적절

## 2. `python.defaultInterpreterPath` 전면 금지 — 문제 있음 (높음)
- `coding.md:5`의 "User·프로젝트 모두 금지"는 과함
- 공식 문서: `${workspaceFolder}/.venv` 같은 **폴더 경로**는 OS별 실행파일 경로를 박지 않고 팀 공유 가능
- `coding.md:7`의 `"내부 스토리지에 저장됨"`은 위험 — 수동 프로젝트 환경 지정 시 `python-envs.pythonProjects`가 `.vscode/settings.json`에 기록됨
- `.vscode/`를 `.gitignore`로 통째 무시하는 조건부 허용 비권장 — `extensions.json`/`tasks.json`/`launch.json`/포매터·테스트 설정까지 같이 잃음

### 추천 문구
```md
- VS Code에 구체 실행파일 경로(`.venv/Scripts/python.exe`, `.venv/bin/python`)를 커밋하지 않는다.
- 기본은 자동 탐색(`.venv`)에 맡긴다.
- 팀 첫 실행 경험을 고정해야 할 때만 `${workspaceFolder}/.venv` 같은 폴더 경로 또는 `python-envs.pythonProjects`를 허용한다.
- User 전역 `python.defaultInterpreterPath`에 프로젝트 상대경로를 두는 것은 금지한다.
```

## 3. 마이그레이션 4단계 — 문제 있음 (높음)
- `coding.md:20`의 `rg "venv/Scripts|venv\\\\Scripts|venv/bin" --hidden` 검색 품질 나쁨
  - `venv/Scripts`가 `.venv/Scripts` 내부의 `venv/Scripts` 부분도 매칭 → 이미 고친 경로까지 마이그레이션 대상으로 오인
  - 백슬래시 이스케이프 케이스 불안정 → `[\\/]+`가 안전
  - `--hidden`만 쓰면 `.git`/`.venv`/기존 `venv` 내부 site-packages까지 잡음
- 대체안:
```powershell
rg -n --hidden -g '!**/.git/**' -g '!**/.venv/**' -g '!**/venv/**' '(^|[^.A-Za-z0-9_-])venv[\\/]+(Scripts|bin)'
rg -n --hidden -g '!**/.git/**' 'python\.defaultInterpreterPath|python\.pythonPath|python-envs\.pythonProjects|python\.venv(Path|Folders)'
```

### 추가 누락
- `coding.md:25` `python -m venv .venv`는 "시스템 Python 금지"와 충돌 → "생성 시에만 허용, 이후 `.venv`만 사용" 명시 필요
- `coding.md:26` `.\.venv\Scripts\pip install`보다 `.\.venv\Scripts\python.exe -m pip install ...`가 안전
- Poetry는 `poetry install`만으로 `.venv` 보장 안 됨 → `poetry config virtualenvs.in-project true --local` 절차 필요
- `requirements.txt 또는 pyproject.toml`만으로 부족 → `uv.lock`/`poetry.lock`/`Pipfile.lock`/`constraints.txt`/`environment.yml`/`.python-version`/`.tool-versions`/`runtime.txt`도 확인 대상
- VS Code 캐시 문제: `Python Environments: Refresh All Environment Managers` 또는 창 reload 절차 추가 필요

## 4. 서버 배포 주의사항 — 문제 있음 (높음)
- `coding.md:41` 시작점으로는 좋으나 부족
- 더 중요한 지점: `systemd ExecStart`, `Environment=PATH`, `EnvironmentFile`, `supervisord`, `gunicorn/uvicorn`, `celery`, `rq worker`, `apscheduler`, `Procfile`, `docker-compose`, Kubernetes manifest, GitHub Actions/Jenkins 배포 스크립트
- Docker 프로젝트는 별도 판단 필요 — 컨테이너 내부 venv 불필요 경우 다수, venv 이미지 복사는 Python minor/ABI 변경 시 깨짐
- `coding.md:36` "기존 venv/ 삭제"와 `coding.md:43` "venv.old/로 보관"은 운영 프로젝트에서 충돌 → Phase 4를 "로컬 프로젝트 vs 배포 프로젝트"로 분리해야 함
- 실효성 있는 서버 절차: `daemon-reload` + 서비스 재시작 + `systemctl status` + 로그 + 헬스체크 + 롤백 명령까지 포함

## 5. 기존 rules 정합성 — 문제 있음 (중)
- `harness-engineering.md:10` "환경 설계" 원칙과 부합 — `.venv` 표준화는 하네스 설계에 맞음
- `harness-engineering.md:12` "피드백 루프" 관점에서 약함 — 검증이 "기능 테스트"에 머물고 CI 캐시/배포 훅/헬스체크/HISTORY 갱신 연결 없음
- `deployment.md:3`은 버전/HISTORY 훅만 언급 — venv 경로 변경은 배포 리스크이므로 "런타임 경로 변경은 배포 변경, HISTORY·롤백 필수" 포인터 필요
- 구조적으로 `coding.md`에 개발환경/로컬 마이그레이션, `deployment.md`에 서버/CI/롤백 체크리스트 분리 권장

## 6. CLAUDE.md ↔ coding.md 중복 — 문제 있음 (중)
- `CLAUDE.md:42-44`는 `coding.md:3-7`과 같은 결정 반복
- 지금은 44줄이라 200줄 제한 여유 있으나, 전역 `CLAUDE.md`는 프리플라이트+원칙 포인터만 남기는 게 맞음
- `CLAUDE.md:44`의 "금지"가 나중에 조건부 허용으로 바뀌면 충돌

### 추천 구조
```md
## Python 환경
- 기본 가상환경 폴더명은 `.venv`.
- VS Code에는 구체 실행파일 경로를 커밋하지 않는다.
- 세부 절차와 예외: `~/.claude/rules/coding.md`
```

## 최우선 수정 5개
1. "자동 감지 1순위"를 "기본 검색 경로 및 자동 탐색 우선 대상"으로 낮춰 쓰기
2. `python.defaultInterpreterPath`는 "전면 금지" → "구체 실행파일 경로와 User 전역 상대경로 금지"
3. "내부 스토리지에 저장됨" 삭제 또는 `python-envs.pythonProjects`가 `.vscode/settings.json`에 기록될 수 있다고 정정
4. `rg` 패턴을 `.venv` 오탐과 JSON 이스케이프 방지하도록 교체
5. 서버 절차는 `deployment.md`로 분리하고 CI/Docker/systemd/supervisord/celery/rollback 체크리스트화
