# HANDOFF — 2026-09-14 세션 인계서

> 생성: 2026-09-14 | 소멸 조건: 다음 세션 확인 후 `/handoff done`

## 마지막 상태 (어디까지 했나)
- 작업: 네 가지 원칙 기준 하네스 셀프 점검과 정리
- 진행률: 완료. 커밋 2개를 `main`에 올리고 푸시했다 (`git log -2`로 확인)
- 결과: 옛 `rules/` 구조를 가르치던 `memory-manager` 재작성, `handoff`·`todo`·`project-history` 용어 정리, 스킬 설명 축소, 중복 문장 정리, 추적되지 않는 백업 폴더 삭제. 상세는 [9월 14일 기록](docs/history/2026-09-14.md)
- 운영본: 바꾼 스킬 6개를 `~/.claude/skills`, `~/.agents/skills`에 복사했고 해시가 같다. Codex도 새 설명을 불러오는 것을 확인했다

## 미완 작업 (지금 하다 멈춘 것)
- [ ] `agent-structure.md` Codex 지적 2건 — 이유: 설계 결정 대기 (아래 미결 결정)
- [ ] 메모리 주제 파일 정리 — frontmatter가 현재 Claude 형식(`metadata.type`)과 다르고, "체크리스트·피드백은 요청할 때만" 줄이 글로벌 지침과 겹친다. 이유: 보고만 함
- [ ] `.todo.md` #017(a) SSOT 표기, #016(d) Day 번호 추출은 이번 정리로 해결됨 — 이유: 완료 처리는 `/todo done` 요청 시
- [ ] 범위 밖으로 남긴 것 — 루트·`docs/` 아래 `.backups`, 운영본 `~/.claude/skills/.backups`, `docs/history/index.md` 개요의 옛 `rules/` 언급, Claude 운영본에 빠진 `skills/feedback/scripts/g3_sample.py`

## 다음 세션 시작 지점
1. 아래 미결 결정 두 가지를 주인님께 여쭙는다
2. `agent-reach`가 줄인 설명으로도 필요할 때만 실행되는지 실제 조사 작업에서 살핀다

## 미결 결정 (다음 세션에 결정 필요)
- 공식 피드백·메모리 변경을 슬래시 명령으로만 받는 설계(`docs/agent-structure.md` Human feedback 절)가 글로벌 지침 "승인된 변경은 바로 진행"과 충돌해 보인다 | 선택지: A 설계 유지하고 적용 범위(에이전트 런타임 한정)를 명시 / B 자연어 요청도 허용 | 현재 기울기: A
- `proposal store` 위치가 정의되지 않았다 | 선택지: A `self-feedback.md` 색인과 연결된 기록으로 명시 / B 구현 때 정함 | 현재 기울기: A
- 9월 11일 인계에서 넘어온 항목: 글로벌 지침의 조사·배포 섹션을 더 줄일지 | 선택지: A 유지 / B 원칙 한 줄로 줄이고 문서로 분리 (Codex는 분리 문서를 따로 읽지 못함) | 현재 기울기: A

## 컨텍스트 (배경 이해용)
- 이 작업을 하는 이유: 네 가지 원칙(간결, 평범한 말, 과적합 금지, 과잉 설계 금지)이 스킬과 문서에도 적용되게 하려는 것
- 주의 사항: humanize 계열은 외부 원본을 그대로 유지하는 결정(`skills/humanize-korean/.upstream.lock.json`)이라 손대지 않았다. 스킬 원본은 런타임 경로를 쓰지 않으므로 Claude·Codex 운영본에 같은 파일을 복사한다

## 관련 파일
- `docs/history/2026-09-14.md` — 이번 작업 기록
- `docs/agent-structure.md` — 미결 설계 결정 대상
- `skills/memory-manager/SKILL.md`, `skills/handoff/SKILL.md` — 이번에 다시 쓴 스킬
- `settings/global-instructions.md` — 충돌 여부를 비교할 글로벌 기준
