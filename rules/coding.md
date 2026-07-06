# 코딩 규칙

1. **기본 가상환경: `.venv`** — VS Code 자동 탐색 대상. 직접 호출: Windows `./.venv/Scripts/python.exe`, POSIX `./.venv/bin/python`. 시스템 Python은 **venv 생성 시에만** 허용. 예외(Conda·Docker·devcontainer·Poetry 외부 env 등)는 프로젝트 CLAUDE.md에 사유 기록.
2. **VS Code 인터프리터 경로 커밋 금지** — 구체 실행파일 경로(`.venv/Scripts/python.exe`) 커밋 ❌, User 전역 상대경로 ❌. 팀 공유 필요 시 폴더 경로(`${workspaceFolder}/.venv`)만 허용. 기본은 자동 탐색에 맡김. 수동 선택 시 `.vscode/settings.json`에 절대경로·홈·실행파일 경로 들어갔는지 커밋 전 검토.
3. **`.env` 우선 (로컬 한정)** — 로컬은 `load_dotenv(override=True)` 가능. **운영/스테이징은 시스템 env·secret manager가 `.env`보다 우선** (환경별 전략은 프로젝트 CLAUDE.md에). 시스템 env에 API 키 잔존 시 삭제.
4. **테스트는 운영 규모로** — 소규모(5건) 통과만으로 "성공" 금지. 중규모(100건+) 검증 + DB 저장 확인까지.
5. **커밋 전 관련 테스트 필수** — 수정 모듈을 import/호출하는 테스트를 로컬에서 통과 확인 후 커밋. 특히 함수 시그니처 변경·새 Phase/단계 추가·import 경로 변경 시.

> 서버/CI/컨테이너 배포는 `deployment.md` 참조.
> `venv/` → `.venv/` 마이그레이션 절차 → `Harness-engineering/docs/rules-appendix/coding-venv-migration.md`
