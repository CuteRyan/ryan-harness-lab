# 하네스 프로젝트 — 개발 히스토리 인덱스

## 🔄 진행 중 (다음 세션 인계)

> **단일 세션 인계는 프로젝트 루트 `HANDOFF.md` (`/handoff` 스킬) 참조 — 본 섹션은 14일 이상 장기 항목 포인터 전용** (Day 15 결정 2=C, 2026-04-30 Day 16 적용)
> **양식**: `[시작일] 상태 | 작업명 | 다음: (동사 시작) | 미결: 없음/내용`
> **선택 메타**: 대형/장기 작업에만 `(브랜치: x, 커밋: hash)` 추가
> **한계**: 7개 초과 또는 14일 초과 시 즉시 정리 (완료 → 일자별 파일로 cut & paste, 폐기 → 삭제)
> **SSOT 위치**: 단일 세션 인계 = `HANDOFF.md`. 본 섹션은 포인터 (HANDOFF.md 와 동일 정보 중복 금지)

(현재 등록된 장기 항목 없음 — 2026-04-30 Day 16 turn 에서 6건 모두 정리. 백로그성 7건은 `.todo.md` 로 이전.)

---

## 프로젝트 개요

- **목적**: 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로) 설계·개발·관리
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅
- **분리 배경**: 지식 프로젝트(리서치 문서 축적)와 역할 혼재 → 2026-04-15 독립 프로젝트로 분리

---

## 일별 인덱스

| 날짜 | Day | 요약 | 파일 |
|------|-----|------|------|
| 2026-05-01 | 17 | **`/handoff done` 첫 자연 사이클 + `/feedback` 1주 회고 (#004) + v2 §9 의사결정 (#005) + agent-office 비전 추출 (§8 후속3) + 비전 정리·마스터플랜 4인 리서치 시작 (§9 후속4)** — §8 후속3: 비전 추출 (Sub-agent + Agent Teams + 외부 CLI 동적 선택), D-1/D-2/D-3 확정, #010 마스터플랜 신규. **§9 후속4**: 비전 6라운드 토론으로 **5층 위계 + 4가지 워커 (④ 파이프라인 추가) + 모델 배분 (D-4) + 오너 컨펌 (D-5) + R-1~R-5 주인님 반박 이력** 확정. `agent-office-vision.md` (346줄) 신설 (타 프로젝트 투입 예정). 4인 리서치 진행: Task 1·2·3 완료 (Sub-agent 3명, 1461줄), Task 4 부분 완료 (master-architect Agent Teams 1인 팀, 04_masterplan.md 701줄). 잔여 (05/00/Phase E) 다음 세션. 본 turn 자체 dogfood: ① Sub-agent + ② Agent Teams + ④ 파이프라인 + 모델 배분 (워커=Sonnet, 메인=Opus). 5-1 후속3 인계서 소멸 (정책 **다섯 번째 검증**) | [상세](2026-05-01.md) |
| 2026-04-30 | 16 | **4스킬 묶음 실구현 — drift 정상화 + `/todo`·`/handoff` 신설 + `/checklist`·`/project-history` 수정 + 진행 중 옵션 C 적용** — Phase A: 운영 162줄 → 스테이징 sync (옵션 A, 일회성 역방향 sync 예외) + Day 15 변경 9 hunks 적용. Phase 1: `/todo` (결정 4=프로젝트별만) + `/handoff` (결정 2=C) 스테이징 신설. Phase 2: `/checklist` 3건 수정 (Phase 2 주석·Phase 6 미완 분류·Rules 책임 분리). Phase 3: 글로벌 동기화 4 SKILL.md SHA256 MATCH 4/4. Phase 4: 진행 중 6건 정리 (자체 종결 2 + `.todo.md` 이전 5 + 종결 메모 5건 append) + Day 16 일자 파일 신설 + index.md 진행 중 섹션 포인터 전용으로 축소 (양식·한계·SSOT 위치 보존). Phase 5: HANDOFF.md → `.backups/HANDOFF.done.2026-04-29.md` 소멸 (소멸 정책 첫 검증). `.todo.md` 신설 7건 등록 | [상세](2026-04-30.md) |
| 2026-04-29 | 15 | **4스킬 묶음 기획 — `/todo` + `/handoff` 신설 + `/checklist` + `/project-history` 수정** — `skill-quartet-planning` 4인 팀 병렬(skill-architect/workflow-ux/integration-auditor/critic), 산출물 9개(`docs/research/2026-04-29_4skills_planning/00_요약.md` + 01~08), 책임 중복 2건+Gap 3건+sycophancy 1건(05 L30) 검출, 5게이트 7/7 통과, 미결 결정 4건 주인님 확정 (1=A수동, 2=C최소유지+Gap2 deadline 보류, 3=④종결+5/5 재확인, 4=프로젝트별만 `.todo.md`). 부수 효과: [2026-04-23] ④ Gemini rubber-stamp **Day 14 흡수 종결 마킹**. 구현은 별도 turn 분리 (07_migration_plan.md Phase 0~4) | [상세](2026-04-29.md) |
| 2026-04-28 | 14 | **/feedback B방식 1·2·3단계 + 메인 Claude 5게이트 + 3단계 외부 훅** — AM: A2 검증 종결(영어 전환 38%→40% 미미, Claude Sub G2' INVALID 회귀로 롤백) + NativeCommandError fix(EAP 격리). PM 1단계: `prompts/review.md` SSOT + 격리 디렉토리 복사 + orchestrate 짧은 메타 지시 → H 실측 3/3 VALID. 2단계: SKILL.md Step 3 **5게이트** 강제(라인실측·반박최소·근거강도·통계표·자기비판). 3단계: **`feedback-sycophancy-check.sh`+`.py` 외부 검증 훅 신설** — 7 카테고리(sycophancy/환각/누락/1차전이/약한반박/충돌/약한비판), 키워드 사전 외부화(`hooks/data/sycophancy-keywords.txt`), settings.json PostToolUse Write/Edit/MultiEdit 등록, 차단형 X 표시형 O(`exit 0` 보장), dogfood 6/6 PASS, "valid" 시드 즉시 보강(VALID 마크 충돌). 게이트 6 = 외부 훅 검수 의무 SKILL.md 추가 → 두 짝 구조 완성(내부 의무 + 외부 표시) | [상세](2026-04-28.md) |
| 2026-04-25 | 12 | **Part 1: 5개 프로젝트 CLAUDE.md 옵션 B 보강** (`claude-md-batch5` 5인 teammate, 5/5 PASS — Agent-office 65, Harness 62, HSK 51, hsk_analyzer 73, PAA 65 🔴 보안 격리 unchanged). **Part 2: Day 10 이월 ①③⑤⑥ + Day 12 부산물 #8#9** (`issue-cleanup-day12` 4인 teammate — /feedback orchestrate WaitSec/Sequential + run-codex/gemini 지수 백오프 + prepare-isolation BOM 삽입 + /checklist SKILL 7건 + dev-checklist 382줄 + Agent-office .venv 마이그레이션 commit `6638d9b`) | [상세](2026-04-25.md) |
| 2026-04-24 | 11 | **CLAUDE.md 표준화 P0~P2** — PAA 위치 정상화(`7667134`), `/claude-md` 스킬+템플릿 신설(`a9cd3b3`, 헌법블록 5원칙), 9 프로젝트 전수 audit 리포트(🔴3·⚠️1·🟡5). 공식 `/init` 과 병존 관계 명시 | [상세](2026-04-24.md) |
| 2026-04-23 | 10 | **Part 1: /checklist 혼동 제거 + 5차 피드백 Q1~Q3 종결** — 글로벌 스킬 복원 SHA MATCH, SSOT 규칙 신설, dead 훅 5개 이동 (`doc-doublecheck-guard` ALIVE 실측 보존). **Part 2: /feedback 태깅 강화 + 줄 시작 앵커화** (Day 10 이월 ② 종결) — 프롬프트에 `[태그]` 접두사 강제 + Validation 정규식 앵커화 `(?m)^\s*...\[태그\]` (ATX 헤더 허용), 스모크 1/3 → 2/3 VALID 실측, Gemini 본문 인용 우회 차단. Gemini rubber-stamp 성향 자체는 이월 ④ 로 분리. **Part 3: /feedback 인코딩 3 레이어 패치** — `docs/research/feedback-encoding-fix/` 3편 근거 문서 선행 (외부 근거 10건), `_encoding.ps1` 헬퍼 + 전 CLI dot-source + Start-Job 자식 runspace 재설정. V-1 한글 정상 3/3 + mojibake 0, V-3 Claude Sub 정상 but Codex/Gemini 연속 호출 실패(이월 ⑤) | [상세](2026-04-23.md) |
| 2026-04-22 | 9 | **/feedback 스킬 구조 승격** — md 1장(135줄) → SKILL.md + scripts/ 6 PS1 분리 (octopus Validation Gate 채택) → PowerShell 5.1 BOM 이슈 실측 해결 → 3 CLI 스모크 2건 성공 → 자체 메타 리뷰 공통 지적 4건 100% 반영 | [상세](2026-04-22.md) |
| 2026-04-21 | 8 | **/feedback 스킬 v4 승격** — 과거 피드백 13개 archive + Day 7 2-Tier 제안서 폐기 → 단순 3-CLI 병렬로 재설계(77→135줄) → 3차 dogfood 3/3 성공 + 공통 지적 6건 수렴 → 플래그 2건 실측 + 6건 반영 → 217→135줄(-38%) 승격 | [상세](2026-04-21.md) |
| 2026-04-20 | 7 | **/feedback 스킬 B옵션 3차 개정 → dogfood 실패 → 제로베이스 재설계 제안** — 오전: 4축 리서치 + A+B+C 개정(217줄, 실측 V1~V4 통과). 오후: 자기 dogfood 6회 실패(Windows 고유 60%), Claude Code 서브인스턴스 1회 성공($0.20, 유효 지적 7개 중 치명 1), 2-Tier 아키텍처 재설계 제안서 작성 | [상세](2026-04-20.md) |
| 2026-04-20 | 6 | Day 4 체크리스트 실측 종결(24개 `[x]` + C3 "불필요" 판정) + `~/.claude/vscode/` git init(Q5=A 집행, 커밋 73d8b93) + 하네스 프로젝트 `venv/` → `.venv/` 실 마이그레이션(22MB 구 venv 삭제, 훅 dual-path로 무중단) + 로컬 `rules/` stale 발견(별도 세션 이월) | [상세](2026-04-20.md) |
| 2026-04-19 | 5 | /feedback 스킬 비판 검토 MVP 반영(Phase 6.3 검토 단계 + 판정 태그 + 반박·유보 사유 필수) + Codex 한글 경로 **영문 workdir + 복사본 표준 패턴** 확정(junction은 대안) + 2차 Codex 피드백 7건 반영(증거 범위 확장·1자 리뷰 폴백 등). 스킬 189줄 | [상세](2026-04-19.md) |
| 2026-04-18 | 4 | venv 규칙 개정 + VS Code Sync 하이브리드 전환 + /feedback 스킬 개정 (4차 크로스 리뷰 + dogfood, 프롬프트 1/10 압축) + 오후 hotfix 3건(프로필 null·훅 stray 폴더·VS Code 터미널 echo) | [상세](2026-04-18.md) |
| 2026-04-17 | 3 | Codex/Gemini 3라운드 크로스 리뷰(18개 수정) + 피드백 스킬 체계화 + 세션 인계 도입 + /checklist 5차 피드백(승인 대기) | [상세](2026-04-17.md) |
| 2026-04-16 | 1-2 | Codex 검증 + 훅 병목 제거 + rules 최적화 + 훅→스킬 아키텍처 전환 | [상세](2026-04-16.md) |
| 2026-04-15 | 0 | 프로젝트 분리 + P0~P2 하네스 리팩터링 + Windows 훅 안정화 | [상세](2026-04-15.md) |
