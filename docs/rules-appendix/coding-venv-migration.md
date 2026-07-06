# [부록] `venv/` → `.venv/` 마이그레이션 절차

> 글로벌 규칙 `~/.claude/rules/coding.md`에서 분리한 상세 절차.
> 규칙 본문은 짧게(매 세션 로드), 이 이전 절차는 실제 마이그레이션 시에만 열람.
> 부록 분리: 2026-07-06 (하네스 다이어트)

---

운영 중인 프로젝트는 배포/크론 중단 시점 잡고 점진 적용.

## Phase 1: 사전 확인
- [ ] `.gitignore`에 `.venv/` 추가 확인
- [ ] 하드코딩 경로 검색 (`.venv`/`venv`/`.git` 내부 제외):
  ```bash
  rg -n --hidden -g '!**/.git/**' -g '!**/.venv/**' -g '!**/venv/**' '(^|[^.A-Za-z0-9_-])venv[\\/]+(Scripts|bin)'
  rg -n --hidden -g '!**/.git/**' 'python\.defaultInterpreterPath|python\.pythonPath|python-envs\.pythonProjects|python\.venv(Path|Folders)'
  ```
- [ ] CI·배포 스크립트(deploy.sh, systemd unit, Dockerfile 등) 경로 하드코딩 확인
- [ ] Lock/버전 고정 파일 최신 확인: `requirements.txt`, `pyproject.toml`, `poetry.lock`, `Pipfile.lock`, `uv.lock`, `constraints.txt`, `environment.yml`, `.python-version`, `.tool-versions`, `runtime.txt`

## Phase 2: 재생성
1. 새 `.venv` 생성: `python -m venv .venv` (베이스 Python 허용 — 생성 시에만)
2. 의존성 복원 (안전 패턴: `python -m pip` 직접 호출):
   - Windows: `./.venv/Scripts/python.exe -m pip install -r requirements.txt`
   - POSIX: `./.venv/bin/python -m pip install -r requirements.txt`
   - Poetry: `poetry config virtualenvs.in-project true --local` 후 `poetry install`
3. 동작 확인: 주요 엔트리포인트 import·실행 테스트

## Phase 3: 경로 치환
- 스크립트·문서·배포 파일의 `venv/Scripts/` → `.venv/Scripts/` (Windows) / `venv/bin/` → `.venv/bin/` (POSIX)
- `.vscode/settings.json`의 `python.defaultInterpreterPath`에 **구체 실행파일 경로**가 있으면 삭제 (폴더 경로 `${workspaceFolder}/.venv`는 팀 공유 필요 시 허용)
- `CLAUDE.md`/`README.md`의 venv 경로 언급 갱신

## Phase 4: 검증 후 정리
1. 기능 테스트 (운영 규모 검증 원칙 준수)
2. VS Code 캐시 refresh: `Ctrl+Shift+P` → `Python Environments: Refresh All Environment Managers` 또는 `Developer: Reload Window`
3. VS Code 재선택: `Python: Select Interpreter` → `.venv`
4. 기존 `venv/` 폴더 정리 (로컬 프로젝트: 삭제 / 배포 프로젝트: 별도 절차 — `deployment.md`)
5. 커밋: `chore: venv/ → .venv/ 전환`

> **운영 프로젝트(서버/CI 배포 있음)는 Phase 4 "정리"가 다름** → `deployment.md` 및 그 부록 체크리스트 따를 것
