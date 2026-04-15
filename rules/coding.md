# 코딩 규칙

1. **모든 프로젝트는 반드시 venv를 생성하고, 해당 venv 안에서만 작업할 것** — 시스템 Python 사용 금지. `./venv/Scripts/python.exe` 직접 호출 방식
2. **venv 생성 시 `.vscode/settings.json` 자동 설정**
   ```json
   {"python.defaultInterpreterPath": "./venv/Scripts/python.exe", "python.terminal.activateEnvironment": true}
   ```
3. **`.env` 파일이 항상 우선** — `load_dotenv(override=True)` 필수 사용. 시스템/사용자 환경변수가 `.env`를 덮어쓰는 문제 방지. 시스템 환경변수에 API 키 등이 남아있으면 반드시 삭제할 것
4. **테스트는 운영 규모로 검증** — 소규모(5건) 통과만으로 "성공" 보고 금지. 중규모(100건+) 검증 + DB 저장 확인까지가 테스트
5. **코드 수정 후 커밋 전 관련 테스트 필수 실행** — 수정한 모듈을 import/호출하는 테스트를 반드시 로컬에서 돌려서 통과 확인 후 커밋. CI에서 실패가 발견되는 것은 늦은 것이다. 특히 함수 시그니처 변경, 새 Phase/단계 추가, import 경로 변경 시 반드시 확인
