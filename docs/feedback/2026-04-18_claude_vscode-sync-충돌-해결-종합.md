---
title: Claude 종합 — VS Code Settings Sync 충돌 해결
type: synthesis
date: 2026-04-18
target: 방안 1(로컬 즉시 채택) / 방안 2(Sync 끄고 Git) / 방안 3(Sync 유지 SSOT 전환)
sources:
  - 2026-04-18_codex_vscode-sync-충돌-해결.md
  - 2026-04-18_gemini_vscode-sync-충돌-해결.md
---

# Claude 종합 — VS Code Settings Sync 충돌 해결

## Codex 요약 (공식 문서 + VS Code 1.116.0 대조)
- **치명**: `terminal.integrated.shell.windows`는 단순 deprecated가 아니라 **VS Code 1.80에서 제거된 키** — 동기화/커밋/Reset 전에 반드시 먼저 제거
- **내 진단 단정 약함**: `sync/` 폴더 파일만 보고 "클라우드 비어있다" 단정은 약함. `Settings Sync: Show Synced Data` Remote 쪽과 `Log (Settings Sync)`로 확인 필요
- **명령명 부정확**: `Clear Data in Cloud`는 독립 명령 아님 (Turn Off 체크박스 흐름), `Replace Remote`는 공식 용어 아님(`Accept Local`이 맞음)
- **방안 3의 "pull-only" 불가**: Settings Sync는 양방향 자동. pull-only 모드 없음
- **빠진 최선안 2개**: (a) "로컬 정리 후 Accept Local", (b) **하이브리드**(Settings만 Git, 나머지는 Sync 유지)
- **dotfiles 위치**: `~/.claude/`와 **분리 권장** (수명·공개 범위·리뷰 기준 다름). Windows symlink는 개발자 모드/OneDrive 충돌 가능 → PowerShell script가 단순
- **방안 2 장기 운영 설계 빠짐**: CI/pre-commit에서 JSONC parse, 금지 키 검사(`terminal.integrated.shell.*`, `python.defaultInterpreterPath`), deprecated allowlist 필요
- **최종 권고**: **방안 2 수정판 하이브리드** — Settings만 Git SSOT, extensions/keybindings/snippets/profiles는 Sync 유지

## Gemini 요약 (하네스 관점 넓은 리뷰)
- **최종 권고: 방안 2** ('Settings as Code')
- **빠진 방안**: Profiles 분리 기능 (Harness 전용 Profile)
- **dotfiles**: `~/.claude/` 내부 `vscode/` 디렉토리 권장, **심볼릭 링크 스크립트** 적합
- **deprecated 정리**: 충돌 해결 전에 반드시
- **멀티 기기**: 13개월 끊긴 상태면 타 기기 데이터 이미 부채 → 현재 기기 SSOT 확정 후 타 기기 초기화
- **방안 2 리스크**: VS Code가 UI 변경 시 자동으로 settings.json 수정 → Git 충돌 빈번
- **개선**: 하네스 `hooks/`에 `pre-commit-settings-check` 추가
- **Extension 관리**: `extensions.json` + `code --install-extension` 리스트 Git 관리

## 공통 지적 (둘 다 언급 — 반드시 반영)
1. **방안 2 방향이 맞음** — 장기 유지보수·규칙 체계와의 일관성
2. **deprecated 키(`terminal.integrated.shell.windows`)는 충돌 해결 전 정리 필수** — 방안 무관
3. **멀티 기기 리스크**: 타 기기 데이터는 이미 부채, 현재 기기를 SSOT 확정
4. **Profile 분리** 고려 가치 있음
5. **`.vscode/settings.json` ↔ User settings 경계** 필요 (프로젝트 협업 규칙 vs 개인 취향)
6. **pre-commit/CI 린트** 병행 필요 — 방안 2 선택 시 필수

## 상충 지점
| 쟁점 | Codex | Gemini | 판정 |
|------|-------|--------|------|
| Settings Sync 완전 포기 vs 하이브리드 | **하이브리드**(Settings만 Git, 나머지 Sync 유지) | **완전 포기** + `code --install-extension` 리스트로 대체 | **Codex 채택** — extensions/keybindings 직접 재구현 비용 회피. Gemini 안은 비용이 더 큼 |
| dotfiles 저장소 위치 | **분리 권장** (수명/공개 범위 다름) | `~/.claude/vscode/` 통합 | **Codex 약하게 우세** — 원칙적으로 분리가 건전. 단, 초기 단순성을 위해 `~/.claude/vscode/`로 시작해도 허용 범위 |
| 배포 방식(Windows) | **PowerShell script** | **Symlink** | **Codex 채택** — Windows symlink는 OneDrive/권한 충돌 리스크 |
| 명령어 정확성 | 1.116.0 실측 | 일반적 명칭 | **Codex 채택** — 사실 정확 |

## 최종 권고: **Codex 하이브리드 (방안 2 수정판)**

### 왜 이 방향인가
1. **사실성**: Codex가 공식 문서·VS Code 1.116.0 실측 대조 → 명령어·동작 정확
2. **비용 효율**: Gemini 원안은 extensions/keybindings까지 Git 관리하라는 요구가 비현실적. 하이브리드는 "Settings Sync 좋은 부분은 유지, 핵심 SSOT 이점은 확보"
3. **하네스 정합성**: `settings.json`만 Git 관리해도 규칙 파일 체계(`~/.claude/rules/`)와 일관성 확보
4. **CI 린트 가능**: deprecated/금지 키 자동 차단 → 오늘의 `terminal.integrated.shell.windows` 같은 부채 재발 방지

### 실행 순서 (Codex 원안 + Gemini 보완)
1. **백업**: `%APPDATA%\Code\User` 전체 + `code --list-extensions > extensions.txt`
2. **로컬 settings 정리**:
   - `terminal.integrated.shell.windows` 제거 (대체 profiles 넣을지 결정 — cmd 기본 유지면 불필요)
   - `python.defaultInterpreterPath` 제거 (오늘 venv 규칙과 정합)
   - 기타 deprecated/금지 키 일괄 검토
3. **Git baseline 커밋** (위치: 별도 `dotfiles/` 리포 또는 `~/.claude/vscode/`. 초기 단순성 기준 후자 허용)
4. **Settings Sync 재설정**:
   - `Settings Sync: Configure`에서 **Settings 항목만 체크 해제**
   - extensions/keybindings/snippets/profiles는 Sync 유지
5. **충돌 해결**: `Accept Local` (정리된 로컬을 원격에 반영)
6. **배포 방식**:
   - Windows 단일 장비: PowerShell install script (symlink 피함 — OneDrive 충돌)
   - 멀티 OS 확장 시점: `chezmoi` 도입 검토
7. **CI 린트** (pre-commit/Git hook):
   - JSONC parse
   - 금지 키 차단 (`terminal.integrated.shell.*`, `python.defaultInterpreterPath` 등)
   - deprecated 키 allowlist
8. **멀티 기기 시나리오** (있으면):
   - 모든 기기에서 Settings Sync의 Settings 항목 제외
   - 각 기기는 dotfiles 저장소 `settings.json` 심볼릭/복사로 배포

## 주의사항 (내 초안 교정)
- 방안 3의 "pull-only" 표현 **삭제** — Settings Sync에 pull-only 모드 없음 (Codex 지적)
- "Clear Data in Cloud" 표현 **수정** — 독립 명령 아니라 Turn Off 체크박스 흐름
- 진단 근거 보강 — `Settings Sync: Show Synced Data` Remote 쪽 확인 추가

## 다음 세션 진입점
- 주인님 승인 후 실행:
  - 로컬 settings 정리 (tiny edit 불가 — deprecated 키 교체 + 재설정 포함이므로 `.checklist.md` 생성 필요)
  - dotfiles 저장소 위치 결정 (별도 repo vs `~/.claude/vscode/`)
  - PowerShell install script 설계
  - CI 린트 설계 (금지 키 allowlist)
