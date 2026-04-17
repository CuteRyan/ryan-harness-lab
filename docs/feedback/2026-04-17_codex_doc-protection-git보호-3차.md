# Codex 3차 재검토: doc-protection git 보호 로직

> 모델: GPT-5.4 (Codex v0.120.0) | 날짜: 2026-04-17

## 총평
아직 "우회 불가능" 상태로 보기 어렵다. 특히 git 보호 로직에 치명적 구멍이 남아있다.

## Findings (6개)

### 치명 (2개)
1. **BLOCKED=false 재초기화로 git 파괴 명령 차단 무효화**
   - 106행에서 BLOCKED=true → 126행에서 BLOCKED=false로 덮어씀
   - git restore docs/, git reset --hard 등 통과

2. **newline/command substitution 우회**
   - [;|&>]만 금지, \n과 $() 백틱 미차단
   - `git status\npython -c "open('docs/guide.md','w').write('x')"` 통과

### 높음 (2개)
3. **git --output 옵션 우회**
   - `git diff --output=docs/guide.md`가 redirect 없이 파일 쓰기

4. **branch/tag/remote prefix 매치**
   - 끝 앵커 없음, `git branch -r -D origin/main` 등 매치
   - `[[:space:]$]`는 리터럴 $ 문자

### 중간 (1개)
5. **.backups cp 의도 충돌**
   - 문서 확장자 포함 시 .backups 예외 무효화
   - cp to .backups\guide.md가 mv/cp 차단에 걸림

### 낮음 (1개)
6. **unknown 메시지 부정확**
   - jq 없음/파싱 실패/gh 인증 실패 미구분

## 정상 부분
- MultiEdit 배선 일관성 확인
- settings.template.json JSON 파싱 OK
