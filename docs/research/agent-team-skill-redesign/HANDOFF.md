# 핸드오프 — agent-team-manager 스킬 디벨롭 (2026-04-22 기준)

> 팀 작업 중단 시점 상태. 내일 이어서 재개 시 이 문서부터 읽고 `04_redesign-spec.md` 로 진입.

---

## 1. 현재 상태 한 줄

외부 리서치(공식 + 커뮤니티) + Gap 분석 + v2 개편 스펙 **작성 완료**. 주인님 의사결정 3건만 내리면 별건 태스크로 구현 착수 가능한 단계.

## 2. 산출물 4종 (읽는 순서)

| # | 파일 | 담당 | 핵심 요약 |
|---|------|------|----------|
| 01 | `01_official-docs.md` | docs-researcher | 공식 사양 수집. "TeamCreate" 가 공식 문서에 없음 + 실험기능(v2.1.32+) + "확인 불가" 5건 |
| 02 | `02_community-patterns.md` | community-researcher | GitHub 9 리포 + 안티패턴 15(A1~A15) + 개편 체크리스트 10 + 특이: revfactory/harness |
| 03 | `03_gap-analysis.md` | analyst | Gap P0 11 / P1 11 / P2 12 + 실측 4건(R1~R4) 전용 섹션 |
| 04 | `04_redesign-spec.md` | architect | **v2 SKILL.md 초안** + Phase 0~8 + §9 의사결정 포인트 + 템플릿 preset 5 |

읽는 순서 추천: **04 §0 요약 → 04 §9 의사결정 → 03 Gap 표 → 02 Top 3 사례 → 01 (필요 시)**.

## 3. 주인님 결정 필요 3건 (`04 §9`)

### 결정 1. U1 충돌 — 가장 중요
주인님 `CLAUDE.md` "설계/계획/분석/구현 무조건 팀" vs Shipyard 실측 "95% task 팀 부적합".

| 옵션 | 내용 |
|------|------|
| A | 스킬에 "언제 쓰지 말것" Non-goals 추가 (주인님 룰 유지) |
| B | `CLAUDE.md` 수정 — 예외 기준 추가 (스킬은 단순) |
| **C (architect 권장)** | 둘 다 — 스킬 Non-goals + CLAUDE.md 예외 기준 보완 |

### 결정 2. Preset 팀 5개 확정
`review / debug / research / docs-research / harness-design` — 그대로 vs 빈도 기반 조정.

### 결정 3. Preset 포맷 전환
v1 markdown 프로즈 → v2 **YAML** (파싱 안정성 + `depends_on`/`blocked_by` 내장 가능).

## 4. 실측 데이터 — 이 팀 세션에서 관찰된 현재 스킬 문제

리서치 중 현재 agent-team 스킬 자체의 문제가 **실시간으로 재현**됨. 전부 v2 스펙(`04`)에 반영.

| # | 현상 | 재현율 |
|---|------|--------|
| R1 | 진행 상황 가시성 zero — 팀원이 뭐 하는지 안 보임 | 항상 |
| R2 | 타임아웃 없음 — hang 방지 메커니즘 없음 | N/A (`/feedback` 은 300초) |
| R3 | 중복 알림 스팸 — 시스템 artifact 가 재할당 지시로 위장 | **4/4 팀원 전원 재현** ⚠️ |
| R4 | 핸드오프 수동 조율 — 병렬→순차 전환을 팀 리드가 매번 spawn | 항상 |

**R3 는 100% 재현되는 치명 버그**. v2 스펙의 `instruction_prefix` 프로토콜로 차단 설계됨.

## 5. 팀 상태

- Team: `agent-team-skill-redev` (config: `~/.claude/teams/agent-team-skill-redev/config.json`)
- Task list: `~/.claude/tasks/agent-team-skill-redev/` — Task #1~#4 모두 completed
- 팀원 4명: **shutdown 처리됨** (세션 종료와 함께 정리)
- 재개 시 이 팀은 복원 불가 (Claude Code 공식 제약: `/resume` 로 teammate 복원 불가). 필요 시 새 팀 생성.

## 6. 내일 재개 흐름

1. 이 HANDOFF 읽기
2. `04_redesign-spec.md` §0 요약 + §9 읽기 → 결정 3건 내리기
3. (결정 후) 별건 태스크로 구현:
   - 새 디렉토리 `~/.claude/skills/agent-team-manager/scripts/` 생성
   - `SKILL.md` v2 교체 (현재 v1 은 `.backups/` 로)
   - preset 5개 YAML 작성
   - 테스트 — 실제 팀 1회 돌려보기
4. HISTORY 갱신

## 7. 핵심 참고

- `C:/Users/rlgns/.claude/skills/feedback/` — **벤치마크 (거의 그대로 차용)**
- `C:/Users/rlgns/.claude/skills/agent-team-manager/SKILL.md` — 교체 대상 v1 (120줄 프로즈)

---

_작성: 2026-04-22 team-lead 세션 종료 시점_
