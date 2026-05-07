# HANDOFF — 2026-05-07 Day 21 turn 2 인계서

> **주제**: 하네스 엔지니어링 간소화 회고 + 다음 정리 방향
> 생성: 2026-05-07 turn 2 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`

---

## 본 세션 핵심

**주인님 핵심 피드백**: *"하네스 엔지니어링을 할수록 너 성능이 떨어지는듯한데"* — 이게 본 세션 전부의 도화선. 단순한 30분 작업을 10 step 체크리스트로 부풀린 게 발화점.

**진단 후 처리**:
1. **메모리 박음** — `memory/feedback_harness_inflation.md` (4가지 근본 원인 + 해결 방향)
2. **1차 정리 (#030)** — history/index.md 92.5% 압축 + 글로벌 룰 "무조건 팀" 완화 + /checklist 간소 모드 명시
3. **본 작업 (#028 d + #029)** — 간소 모드 적용해서 단위 테스트 8/8 PASS, 운영 sync 5쌍 MATCH

---

## 🚨 다음 세션 진입 시 토론 주제 (간소화 후속)

본 세션 1차 정리는 **"눈에 보이는 비대"** 만 손댔습니다. 진짜 뿌리는 더 있습니다.

### 추가 정리 후보 (주인님 컨펌 받고 진입)

#### 1) **R/D 번호 체계 자체 폐기 검토**
- 현재 R-1 ~ R-24, D-1 ~ D-31 누적 = 본질적으로 **자기 강화 메타데이터**
- 메모리 `feedback_harness_inflation.md` 의 *"체계화 = 안전 잘못된 전제"* 직격
- 옵션 A: 신규 등록 중지 + 기존 번호 자연 소멸
- 옵션 B: 한 번에 다 폐기 (마스터플랜·SKILL.md·history 전수 제거)
- 옵션 C: 유지하되 "주인님 명시 요청 시만 등록" 강제

#### 2) **`agent-team-manager` SKILL.md 다이어트**
- 현재 v3.4 = ~390줄. R-1~R-20 가드레일 표 + 7 preset 카탈로그 + Phase 0~8 흐름표
- 진짜 사용 시나리오 = "PM 협의" 한 패턴이 90%
- 옵션 A: 핵심 5 가드레일만 남기고 나머지 reference/ 로 이전 (~150줄로 압축)
- 옵션 B: 현재 유지

#### 3) **마스터플랜 04·06 문서 압축**
- `04_masterplan.md` 814줄, `06_issue32732_experiment.md` 600+줄
- 본 issue#32732 종결 후에도 §갱신 의무 누적
- 옵션 A: "결론 + 출처" 만 남기고 본문 .archived/ 이동
- 옵션 B: 현재 유지

#### 4) **/feedback 스킬 자동 호출 의무 재검토**
- 현재 매 큰 작업 후 /feedback 검수 = 평균 ~10분 + 환각 위험
- R-21 잠정 (PM 협의 외부 출처 N건 시 /feedback 생략) 도 같은 방향성
- 옵션 A: /feedback 자동 호출 의무 폐기, 사용자 명시 요청 시만
- 옵션 B: 유지

#### 5) **글로벌 룰 추가 완화 (`~/.claude/rules/*.md` 11개)**
- 현재 자동 로드 ~600줄. `agent-spawn-model.md`·`research-mandatory.md`·`bot-deploy.md` 등
- 일부는 이미 hook으로 자동화됨 = rule 텍스트 중복
- 옵션 A: hook으로 자동화된 영역은 rule 본문 제거 + 1줄 포인터로
- 옵션 B: 유지

---

## 미완 작업 (잔손질)

- [ ] **라이브 검증** — Bash hook + 한글 fix (settings.json hot-reload 미작동 → 메인 재시작 의존). dast-analyzer agent spawn 후 `curl https://api.example.com/` 차단 PASS 확인. 단위 테스트 8/8 PASS는 이미 끝남.
- [ ] **#028 (f) R-21 정식 등록 처리** — #030 정리 결과에 따라 자연 폐기 가능 (옵션 1=B 일관)

---

## 다음 세션 시작 지점

### Quick Start
1. `git status --short` clean 확인
2. settings.json `hooks.PreToolUse` Bash matcher hook 4개 (마지막 = `pretooluse-dast-prod-guard-bash.sh`) 확인
3. 본 HANDOFF Read → 토론 주제 1~5 中 어느 것 진입할지 주인님 결정
4. `/handoff done` (소멸 정책 20회차 검증)

### 라이브 검증부터 우선 처리하려면
- `python hooks/pretooluse-dast-prod-guard-bash.py` 직접 호출 후 stdin JSON 주입으로 단위 테스트 재현 가능
- 또는 dast-analyzer agent spawn 으로 라이브 차단 확인

---

## 컨텍스트

- 본 세션 = 인플레이션 진단 → 1차 다이어트 → 본 작업 (간소 모드 적용) 3 단계
- 다이어트 효과 검증 = 본 세션 후반부 자체 = 글로벌 룰 완화 후 단순 코드 작업 30분 내 완료 PASS
- 메모리 `feedback_harness_inflation.md` 가 다음 세션 자동 로드 → 부풀림 자동 차단

## 관련 파일

- `memory/feedback_harness_inflation.md` (인플레이션 진단)
- `docs/history/.backups/index.md.before-compress-2026-05-07.md` (압축 전 원본)
- `hooks/lib/dast_url_check.py` (helper 신설)
- `hooks/pretooluse-dast-prod-guard-bash.{sh,py}` (Bash hook 신설)
- `~/.claude/settings.json` Bash matcher 4 hook
- `.todo.md` #028 (d)·#030 完, #028 (f) 잔여 변경
