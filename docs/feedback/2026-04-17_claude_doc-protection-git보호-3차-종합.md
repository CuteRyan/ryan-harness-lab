# 종합 정리: doc-protection git 보호 3차 리뷰 + 수정

> 작성: Claude Opus 4.6 | 날짜: 2026-04-17
> 원본: `2026-04-17_codex_doc-protection-git보호-3차.md`, `2026-04-17_gemini_하네스-최종상태-3차.md`

## 리뷰 결과
- **Gemini**: Production Ready, 전 컴포넌트 Pass
- **Codex**: 치명 2개 + 높음 2개 + 중간 1개 + 낮음 1개

## Codex 지적 → 즉시 수정 반영

### 1. BLOCKED=false 재초기화 (치명)
- **문제**: 106행 BLOCKED=true → 126행 BLOCKED=false로 덮어씀
- **수정**: 파괴적 git 감지 시 즉시 `block()` 호출 (exit 1). BLOCKED 플래그 불필요

### 2. newline/command substitution 우회 (치명)
- **문제**: `[;|&>]`만 금지, `\n`, `$()`, 백틱 미차단
- **수정**: 금지 문자에 `$'\n'`, `$(``, 백틱 추가

### 3. git --output 옵션 우회 (높음)
- **문제**: `git diff --output=docs/guide.md` 통과
- **수정**: `--output`, `--ext-diff` 포함 시 허용 안 함

### 4. branch/tag/remote prefix 매치 (높음)
- **문제**: 끝 앵커 없어 뒤에 파괴 옵션 붙여도 매치
- **수정**: 파괴 옵션(-D/-d/-m, add/remove 등) 포함 여부를 별도 체크

### 5. .backups cp 의도 충돌 (중간)
- **문제**: cp to .backups\guide.md가 mv/cp 차단에 걸림
- **수정**: .backups 경로 포함 cp/mv 명령은 백업 목적으로 허용

### 6. unknown 메시지 부정확 (낮음)
- **문제**: jq 없음/gh 없음/파싱 실패 구분 안 됨
- **수정**: CI_DETAIL에 상황별 메시지 세분화
