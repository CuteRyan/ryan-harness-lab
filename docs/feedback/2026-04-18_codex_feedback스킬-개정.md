---
title: Codex 리뷰 — /feedback 커맨드 개정 (dogfood)
type: feedback
reviewer: codex
date: 2026-04-18
target: ~/.claude/commands/feedback.md (2026-04-18 재작성본)
---

# Codex 리뷰 — /feedback 커맨드 개정 (dogfood)

> 개정된 스킬로 자기 자신을 리뷰. 실측 검증 포함.

## 실측 환경
- `codex-cli 0.120.0`: `--full-auto`, `--skip-git-repo-check`, `--add-dir`, `-C`, `--output-last-message`, `--search` 확인됨
- `gemini 0.37.1`: `--yolo`, `--include-directories`, `-o text`, `--approval-mode plan` 확인됨
- **Windows PowerShell 주의**: bare `codex` / `gemini`는 `.ps1` shim으로 먼저 잡혀 실행 정책에 막힘. `.cmd` 호출은 정상

## 높음 3건

### H1. PowerShell에서 bare 명령어 실패 (실측)
- 현재 feedback.md의 `codex exec ...` / `gemini -p ...`는 PowerShell에서 실패. `.ps1` shim + 실행 정책 충돌
- **수정**: 예시를 `codex.cmd`, `gemini.cmd`로
- 근거: feedback.md:15, feedback.md:21

### H2. 읽기 전용 가드 부재 (보안/의도 일치)
- 피드백은 리뷰 용도인데 `--full-auto`(workspace-write) + `--yolo`(모든 도구 자동 승인) → **쓰기 가능 상태**
- 의도와 안 맞음. "읽기/분석만, 수정·삭제·커밋 금지" 프롬프트 고정 꼬리 필요
- 더 엄격히: Gemini `--approval-mode plan`, Codex `--sandbox read-only` 후보
- 근거: feedback.md:15, 17, 21, 23

### H3. 출력 포맷 구멍 (스킬 고정 의도 vs 실제 호출)
- 스킬이 "출력 형식 반복 서술 금지"와 Phase 5 "표준 포맷 요청"을 동시에 지시 → **실행자 혼동**
- 외부 CLI는 스킬 파일을 못 봄 → 프롬프트에 1줄 고정 꼬리 필수
- 근거: feedback.md:72, 83, 84

## 중간 3건

### M1. Codex 외부 경로 접근 지침 부재
- Gemini에는 `--include-directories` 지침 있으나 Codex에는 `-C` / `--add-dir` 안내 없음
- 대상이 cwd 밖이면 Codex도 `--add-dir <상위경로>` 반복 사용해야 함
- 근거: feedback.md:15, 24

### M2. Codex `--search` 위치 문제 + 대체 규칙
- 현 Codex 호출식에는 검색 활성화 없음. `codex exec --search`는 실패, 루트 옵션으로 `codex.cmd --search exec ...` 형태가 정상
- 공식 문서 대조가 점검 포인트면 조건부 `--search` 켜거나, **"검색 불가 시 실측/로컬 근거만 사용, 한계 명시"** 추가
- 근거: feedback.md:78

### M3. 정보 부족 대응 문장 부재
- "경로 + 점검 포인트"만 주면 장황함은 감소하나, 에이전트가 접근 실패/맥락 부족을 **추측으로 메울 수 있음**
- 고정 꼬리: "필요하면 주변 파일 직접 열람, 접근 실패/맥락 부족은 추측 금지, 명시"
- 근거: feedback.md:31, 75

## 낮음 1건

### L1. 용어 혼용 — "토큰 예산" vs "문자 수"
- feedback.md:75의 "토큰 예산: 3,000자"는 문자 수 기준이면 "**프롬프트 예산: 3,000자 이내**"가 정확
- 근거: feedback.md:75

## 추천 보강안 — 프롬프트 고정 꼬리 (2줄)

장황함을 거의 늘리지 않으면서 품질 가드 확보:

```text
제약: 읽기/분석만 하고 파일 수정·삭제·커밋 금지. 접근 실패나 맥락 부족은 추측하지 말고 명시.
출력: 중요도(치명/높음/중간/낮음), 파일:줄, 근거, 마지막 Top 3.
```

## 추천 Phase 2 명령 예시 (Windows 안전)

```powershell
codex.cmd exec --skip-git-repo-check --full-auto -C "<작업 루트>" --add-dir "<추가 루트>" --output-last-message "<저장 경로>" "<프롬프트>"

gemini.cmd -p "<프롬프트>" -o text --yolo --include-directories "<작업 루트>" --include-directories "<추가 루트>"
```

## 핵심 제안 — Phase 0 "실행 프리플라이트" 추가

> "짧아서 좋은 프롬프트"가 "짧아서 불안정한 호출"이 되지 않게 방지.

1. CLI shim 확인 (`codex.cmd --help`, `gemini.cmd --help`)
2. 플래그 help 확인 (`--sandbox`, `--approval-mode`, `--include-directories`, `--add-dir`)
3. 대상 경로 루트 산정 (공통 상위 디렉토리 계산)
4. 읽기 전용/쓰기 가능 모드 선택 (리뷰면 읽기 전용)

## Top 3 (가장 시급)
1. Windows `.cmd` 사용 명시 (현재 예시대로면 실제 실행 불가 — 높음)
2. 읽기 전용 가드 + 추측 금지 꼬리 (2줄 고정 — 높음)
3. Phase 0 프리플라이트 도입 (개정의 방향을 지키는 필수 장치 — 높음)
