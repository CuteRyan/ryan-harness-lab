# HANDOFF — 2026-09-20 세션 인계서

> 생성: 2026-09-20 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 이전 인계(2026-09-14)는 `.backups/HANDOFF.done.2026-09-20.md`로 옮겼고, 아직 열린 항목은 아래에 이어 적었다.

## 마지막 상태 (어디까지 했나)
- 작업: 권한 건너뛰기 모드에서도 뜨던 삭제 확인 창 제거, 설치 스크립트의 훅 등록 형식 수정
- 진행률: 완료. 커밋·푸시했고 운영 훅에도 반영했다. 상세는 [9월 20일 기록](docs/history/2026-09-20.md)
- 운영본: `~/.claude/hooks/pretooluse-guard.ps1`이 원본과 SHA-256이 같다. 이전 훅은 `~/.claude/hooks/.backups/`에 있다
- 마지막 편집 파일: `tests/test_pretooluse_guard.ps1`

## 미완 작업 (지금 하다 멈춘 것)
- [ ] (9/14에서 이어짐) `agent-structure.md` Codex 지적 2건 — 이유: 설계 결정 대기 (아래 미결 결정)
- [ ] (9/14에서 이어짐) 메모리 주제 파일 정리 — frontmatter가 현재 Claude 형식(`metadata.type`)과 다르고, "체크리스트·피드백은 요청할 때만" 줄이 글로벌 지침과 겹친다. 이유: 보고만 함
- [ ] (9/14에서 이어짐) `.todo.md` #017(a), #016(d)는 해결됨 — 이유: 완료 처리는 `/todo done` 요청 시
- [ ] (9/14에서 이어짐) 범위 밖으로 남긴 것 — 루트·`docs/` 아래 `.backups`, 운영본 `~/.claude/skills/.backups`, `docs/history/index.md` 개요의 옛 `rules/` 언급, Claude 운영본에 빠진 `skills/feedback/scripts/g3_sample.py`
- [ ] Codex 쪽 훅 — `~/.codex/hooks/`에 옛 셸 훅(`doc-protection.sh`, `deploy-version-guard.sh` 등)이 남아 있다. 이유: 이번 범위(Claude 확인 창) 밖이라 보지 않음

## 다음 세션 시작 지점
1. 아래 미결 결정을 주인님께 여쭙는다
2. 권한 건너뛰기 모드에서 확인 창이 또 뜨면 `~/.claude/projects/*/*.jsonl`에서 `permissionDecision`을 검색해 출처가 훅인지 먼저 확인한다
3. `~/.codex/hooks.json`이 무엇을 등록하는지 읽고, Codex에서도 불필요한 확인·차단이 있는지 점검할지 여쭙는다

## 미결 결정 (다음 세션에 결정 필요)
- (9/14에서 이어짐) 공식 피드백·메모리 변경을 슬래시 명령으로만 받는 설계가 글로벌 지침 "승인된 변경은 바로 진행"과 충돌해 보인다 | 선택지: A 설계 유지하고 적용 범위 명시 / B 자연어 요청도 허용 | 현재 기울기: A
- (9/14에서 이어짐) `proposal store` 위치 미정 | 선택지: A `self-feedback.md` 색인과 연결된 기록으로 명시 / B 구현 때 정함 | 현재 기울기: A
- (9/11에서 이어짐) 글로벌 지침의 조사·배포 섹션을 더 줄일지 | 선택지: A 유지 / B 원칙 한 줄로 줄이고 문서로 분리 | 현재 기울기: A

## 컨텍스트 (배경 이해용)
- 이유: 훅이 보내는 확인 요청(`ask`)은 권한 건너뛰기 모드에서도 창을 띄운다. 삭제 확인은 정책 문서에 없고 테스트도 없었으며, 대부분 임시 폴더 정리에 뜨고 있었다
- 주의: 전역 훅은 [훅 정책](docs/hook-policy.md)대로 되돌릴 수 없는 Git 명령만 막는다. 훅을 등록할 때는 `-File` 형식을 써야 한다. `-Command` 형식은 차단 신호(종료 코드 2)를 1로 바꿔 차단이 풀린다

## 관련 파일
- `hooks/pretooluse-guard.ps1` — 전역 Git 차단 훅
- `scripts/install-global-hook.ps1` — 훅 설치 스크립트
- `tests/test_pretooluse_guard.ps1`, `tests/test_install_global_hook.ps1` — 훅·설치 테스트
- `docs/hook-policy.md` — 훅 정책
- `docs/agent-structure.md` — 미결 설계 결정 대상
