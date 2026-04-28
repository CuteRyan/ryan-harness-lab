# 하네스 프로젝트 — 개발 히스토리 인덱스

## 🔄 진행 중 (다음 세션 인계)

> **양식**: `[시작일] 상태 | 작업명 | 다음: (동사 시작) | 미결: 없음/내용`
> **선택 메타**: 대형/장기 작업에만 `(브랜치: x, 커밋: hash)` 추가
> **한계**: 7개 초과 또는 14일 초과 시 즉시 정리 (완료 → 일자별 파일로 cut & paste, 폐기 → 삭제)
> **SSOT**: 이 섹션이 진행 중 정보의 유일한 원본. 다른 파일에 동일 정보 두지 않음.

- [2026-04-17] 진행 중 | 세션 인계 + 폴더 마이그레이션(Phase 2 직행) | 다음: 1주 운영 후 회고 (양식/한계 규칙이 실제로 작동하는지) | 미결: 없음
- [2026-04-18] 부분 종결 (Day 6에 체크리스트 종결) | venv 규칙 개정 + VS Code Sync 하이브리드 + /feedback 스킬 개정 | 다음: **B5 Settings Sync UI 재설정(주인님 수작업)** + **B7 금지 키 allowlint 훅 설계(별도 세션)** | 미결: 없음 (Day 6 완료분 — vscode git init 73d8b93, 하네스 프로젝트 venv 마이그레이션, C3 "불필요" 종결)
- [2026-04-22] 종결 | /feedback 스킬 **구조 승격** (Day 9) — md 1장 → SKILL.md + scripts/ 6 PS1 구조 (octopus Validation Gate Pattern 채택), 3 CLI 스모크 2건 실측 성공, 자체 메타 리뷰로 4건 공통 지적 100% 반영 | 다음: **/todo 스킬 제작** (/checklist는 Day 10에 혼동 제거 + Q1~3 종결 완료) | 미결: 없음 (Phase 2 항목은 별도 세션)
- [2026-04-23] 부분 종결 (Day 12 Part 2 에서 ①③⑤⑥ 종결) | **Day 10 이월**: ④ **Gemini rubber-stamp 성향 근본 해결** — 주인님 ①+② 조합 채택(2026-04-26), 체크리스트 작성 완료 후 내일 이어가기 | 다음: `.checklist.md` 승인 + A~F 항목(orchestrate 자동 재호출 + few-shot + 동기화 + dogfood) 진행 | 미결: ④ 근거 `docs/feedback/2026-04-23_gemini_SKILL_20260423-100623.md`, 체크리스트 `Harness-engineering/.checklist.md` (approved: false)
- [2026-04-24] 종결 (Day 13 에서 주인님 자체 해결) | **9 프로젝트 CLAUDE.md 보강** (Day 11 🔴 긴급 2/3 + Day 12 🟡 5/5 종결, 잔여 Knowledge-platform 축약 + candidate_orchestra 처리 방침은 주인님이 직접 해결/불필요 판정) | 다음: 없음 | 미결: 없음
- [2026-04-27] 종결 (Day 14에 종결) | /feedback 스킬 A2 (GEMINI_SYSTEM_MD + few-shot) | 다음: 없음 | 미결: 없음 — **A2 영어 전환 효과 미미 (38% → 40%) + 부작용 발생으로 롤백 결정**, B 방식(prompt 파일 분리)으로 재설계 (Day 14)
- [2026-04-28] 종결 | /feedback B 방식 1·2·3단계 모두 완료 — 3단계 훅(`feedback-sycophancy-check.sh`+`.py`) 신설, 7 카테고리 검출(sycophancy/환각/누락/1차전이/약한반박/충돌/약한비판), 외부 장치+SKILL.md 게이트 6 두 짝 구조, dogfood 6/6 PASS, valid 시드 즉시 보강 | 다음: 1주 사용 후 false positive 비율 관찰·키워드 사전 보강 결정 | 미결: 없음

---

## 프로젝트 개요

- **목적**: 글로벌 하네스 인프라(훅, 스킬, rules, 워크플로) 설계·개발·관리
- **관리 대상**: `~/.claude/rules/`, `~/.claude/skills/`, `settings.json` 훅
- **분리 배경**: 지식 프로젝트(리서치 문서 축적)와 역할 혼재 → 2026-04-15 독립 프로젝트로 분리

---

## 일별 인덱스

| 날짜 | Day | 요약 | 파일 |
|------|-----|------|------|
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
