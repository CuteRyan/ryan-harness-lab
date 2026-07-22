# 하네스 관리 프로젝트

이 저장소는 Claude 글로벌 하네스의 공통 원본입니다. `agents/`, `hooks/`, `rules/`, `skills/`를 여기서 수정한 뒤 `~/.claude/` 운영본에 반영합니다.

## 관리 범위

- 공통 원본: `agents/`, `hooks/`, `rules/`, `skills/`
- 글로벌 지침 원본: `settings/CLAUDE.global.md`
- 설정 기본형: `settings/settings.template.json`
- 사용자별 운영 설정: `~/.claude/settings.json` — 자동으로 덮어쓰지 않음
- 프로젝트 안내인 이 파일은 글로벌 `CLAUDE.md`와 역할이 다름

## 작업 기준

- 수정 전에 실제 파일과 활성 설정을 확인합니다.
- 공통 파일은 저장소에서 먼저 수정하고 운영본에 복사한 뒤 해시를 비교합니다.
- 운영본에만 있는 변경은 이유를 확인한 뒤 저장소에 반영하거나 제거합니다.
- 되돌리기 어려운 작업만 훅으로 막고, 나머지는 테스트와 검토로 확인합니다.
- `/checklist`는 주인님이 요청하거나 여러 파일을 크게 바꿀 때 사용합니다.
- 문서는 결론, 변경 내용, 이유, 검증만 짧게 기록합니다.

## 확인 위치

- 현재 변경 기록: `docs/HISTORY.md`
- 이전 작업 기록: `docs/history/`
- 활성 훅 설정: `settings/settings.json`
- 관련 테스트: `tests/`
