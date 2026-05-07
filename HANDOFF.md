# HANDOFF — 2026-05-07 Day 21 turn 1 인계서 (#028 a PASS, 잔여 b·c·d·e·f + #029)

> 생성: 2026-05-07 turn 1 종료 시점 | 소멸 조건: 다음 세션 확인 후 `/handoff done`
> 양식 v2 간소 모드 (R-16) + dogfood 22건째

---

## 🚨 다음 세션 진입 전 사용자 결정 (있음)

**결정 1 — 다음 turn 진입 작업 우선순위**:
- (A) #028 (d) + (f) + #029 R-15 후속 = 잔여 묶음 처리 (R-24 의무 적용 = 1시간 이내 목표)
- (B) 다른 프로젝트 우선 (Harness-engineering 잠시 휴식)
- **현재 기울기 = A** (잔여 작아짐 = b·c·e 完 후 d 만 큰 작업)

## 마지막 상태

- commit `[turn 1 commit]` (working tree clean)
- **#028 (a) 라이브 검증 全 PASS** = 4 검증 全 PASS (PM hook 차단/통과 + DAST hook 차단/통과)
- **신설 자산**: `hooks/lib/subagent_lookup.py` (~70줄, agent_id+name+fallback 3차 매칭)
- **누적 정책**: D-30 (옵션 E Team config 매칭) + R-23 잠정 (subagent_lookup 의무) + #029 (R-15 후속 = CP949 fix)

## 미완 작업 (#028 잔여 2건 + #029 신설 + R 정책)

- [x] #028 (a) 라이브 검증 = Day 21 turn 1 PASS
- [x] #028 (b) 키워드 외부 파일화 = `hooks/data/pm-research-guard-keywords.txt` 신설 + py fallback 로직 (Day 21 turn 1 PASS)
- [x] #028 (c) agent_type 라이브 검증 결과 = DAST hook docstring 갱신 (Day 21 turn 1 PASS 사실 박음)
- [x] #028 (e) namesilo CI/CD URL 특정 + 직접 인용 = security.yaml + DAST hook docstring (Day 21 turn 1)
- [ ] **#028 (d) Bash matcher 확장** (옵션 B + R-22 helper 추출 = `hooks/lib/dast_url_check.py` + `pretooluse-dast-prod-guard-bash.{sh,py}` 신설, 큰 작업 ≈ 30~45분)
- [ ] **#028 (f) R-21 정식 등록** (현재 dogfood 4회차 누적, 1회 더 dogfood 후 등록 = 결정 1=B 정합)
- [ ] #029 R-15 후속 = 양 hook 한글 메시지 UTF-8 강제 (PYTHONIOENCODING + io.TextIOWrapper)
- [ ] R-23 정식 등록 (옵션 E + name 매칭 fallback 정책, dogfood 1회차 누적)
- [ ] **R-24 신설 의무** (다음 turn 진입 즉시 강제) = "신설 hook/스킬 = 공식 docs 사전 fetch + 라이브 형식 단위 테스트 의무. 미준수 시 작업 진입 금지"

## 다음 세션 시작 지점

### Quick Start (메인 Claude 새 세션 진입 직후)
1. PowerShell `Get-ChildItem Env:CLAUDE_CODE_SUBAGENT_MODEL` 부재 확인
2. `git status --short` clean + 마지막 commit 본 turn 확인
3. settings.json `hooks.PreToolUse` 7 matcher 확인 (Bash·Edit·Write·MultiEdit·Task\|Agent·WebSearch\|WebFetch·WebFetch)
4. 본 HANDOFF Read → `/handoff done` (소멸 정책 19회차 검증)

### 정식 절차 (사용자 결정 1 컨펌 후)
1. `.todo.md` Read → #028 (b)·(d)·(c)·(e)·(f) 진입 + #029 R-15 후속 묶음 결정
2. `/checklist mode=mixed` 작성 (Step 별 분할)
3. (결정 1=A 시) PM 협의 dogfood 5회차 → R-21 정식 등록 후보 (5회차 누적 시)

## 컨텍스트

- 본 turn = 라이브 검증 진단 5 라운드 + 옵션 E v2 적용 = critical 결함 (hook silent pass) 결정적 해결
- 옵션 E (사용자 안) > 추천 B+A (내 안) 우월 입증
- 사용자 시간 우려 표명 → 진척도 1/6 = critical 결함 발견의 자연 결과 = 결과적 가치 高 (회귀 잠복 차단)

## 관련 파일

- `hooks/lib/subagent_lookup.py` (신설, ~70줄)
- `hooks/pretooluse-pm-research-guard.py` + `hooks/pretooluse-dast-prod-guard.py` (subagent_lookup 호출 추가, 디버그 라인 cycle 후 제거)
- `~/.claude/hooks/lib/subagent_lookup.py` + `~/.claude/hooks/pretooluse-{pm,dast}-*.py` 운영 sync (3쌍 SHA256 MATCH)
- `docs/history/2026-05-07.md` (본 turn 상세)
- `.todo.md` (#028 a 完, b·c·d·e·f 잔여, #029 신설)
