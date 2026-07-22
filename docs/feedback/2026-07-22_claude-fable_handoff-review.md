# Claude(Fable) 검토: 경량화 이후 핸드오프 검증

## 결론

경량화 결과는 건전하다. 원본·운영본·설정이 일치하고 테스트 19건이 통과했다. 다만 직전 세션에서 추가한 강제 푸시 차단에 우회 1건을 재현했다. 수정은 주인님 승인 대기.

## 범위와 방법

`HANDOFF.md`의 검토 항목 6개를 실제 파일과 실행으로 확인했다. 완료 보고를 믿지 않고 해시 비교, 정규식 실행 재현, 회귀 테스트 실행으로 검증했다.

## 확인된 문제

**강제 푸시 차단 우회 1건** — `git push -f;echo hi`처럼 `-f` 뒤에 공백 없이 `;`·`&`·`|`가 붙으면 통과한다. `hooks/pre-bash-guards.sh:38`과 `hooks/doc-protection.sh:99`의 정규식이 플래그 뒤에 `=`, 공백, 문자열 끝만 허용하기 때문. `git push --force;echo`는 `[^[:space:]]*`가 `;echo`까지 삼켜서 우연히 차단된다. 후행 문자 클래스에 `;&|`를 추가하면 해결된다.

재현 결과:

| 명령 | 결과 |
|---|---|
| `git push -f` | 차단 |
| `git push origin main --force` | 차단 |
| `git push --force;echo hi` | 차단 (우연) |
| `git push -f;echo hi` | **통과** |

## 이상 없음

- **동기화**: `agents/`·`hooks/`·`rules/`·`skills/` 원본↔운영본 SHA-256 전부 일치. `settings/CLAUDE.global.md` = 운영 `CLAUDE.md`.
- **설정**: 운영 `settings.json` 훅 등록은 2종뿐, 삭제된 훅 참조 없음. 저장소 `settings/settings.json`은 gitignore된 로컬 사본으로 운영본과 동일(의도된 구조).
- **파괴 명령 차단**: `git rm/restore/clean`, `reset --hard`, `checkout --`, 문서 대상 redirect·`sed -i`·`tee`·`Set-Content` 차단 유지. 배포 검사는 VPS IP + scp/rsync에서 버전·HISTORY·CI를 fail-closed로 확인. `tests/test_doc_protection.ps1` 19/19 통과.
- **humanize**: 스킬 3종의 입출력 약속과 에이전트 6종 frontmatter 일치, 참고 파일 존재, 자동 실행 금지 유지. 실제 모델 실행은 비용 문제로 계속 보류.
- **지시 충돌**: 사전 승인 기준(되돌리기 어려움·외부 발송·해석 갈림)이 글로벌 지침·work-style·dev-checklist에서 동일. 억지 용어 없음.

## 기능 영향 없는 잔여물

- 운영본 `~/.claude/hooks/lib/__pycache__/`에 삭제된 헬퍼의 .pyc 4개
- `hooks/data/` 빈 디렉토리
- `_harness_common.sh`의 체크리스트 검증 함수 약 130줄 — 사용처가 `.backups/` 은퇴 훅뿐인 죽은 코드
- `.todo.md`의 은퇴 인프라 전제 백로그(#028 라이브 검증, #030 다이어트) — 폐기 결정 필요
- `docs/workflows/wiki-management.md`·`docs/rules-appendix/ssot-immediate-sync.md`가 삭제된 규칙을 현재형으로 참조 — 역사 기록으로 두어도 무방

## 참고

배포 검사는 IP 리터럴(187.127.123.81)이 명령에 있을 때만 발동한다. 호스트명 별칭 배포는 걸리지 않으며, 현재 설계상 수용된 범위로 판단.
