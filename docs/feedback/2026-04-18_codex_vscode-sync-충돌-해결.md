---
title: Codex 리뷰 — VS Code Settings Sync 충돌 해결 방안
type: feedback
reviewer: codex
date: 2026-04-18
target: 방안 1(로컬 즉시 채택) / 방안 2(Sync 끄고 Git) / 방안 3(Sync 유지 SSOT 전환)
---

# Codex 리뷰 — VS Code Settings Sync 충돌 해결 방안

> VS Code 1.116.0 + 공식 문서 대조 검증 포함.

## 총평
세 방안 모두 가능은 하나 **원문 그대로 실행하면 위험**. 특히 `sync/` 폴더 파일만 보고 "클라우드 비어있다" 단정하는 것도 약함. **authoritative 확인은 `Settings Sync: Show Synced Data` Remote 쪽과 `Log (Settings Sync)`로 해야 함**.

## 1. 기술적 타당성

### 방안 1 — 문제 있음 (중간)
- `"Settings Sync: Show Settings Conflicts"` 공식 표현은 `Accept Local` / `Accept Remote` / `Show Conflicts`. 정확한 팔레트 명령명은 버전/로케일에 따라 다를 수 있음
- `Accept Local` 선택은 원격을 로컬로 덮음 — 원격이 정말 빈 settings면 맞으나, deprecated 키와 의도치 않은 로컬 쓰레기까지 SSOT가 됨

### 방안 2 — 문제 있음 (높음)
- `"Clear Data in Cloud"`는 **독립 명령 아님** — Manage gear의 `Settings Sync is On`에서 Sync 끄면서 "cloud data clear" 체크박스 선택 흐름
- 1.116.0의 `workbench.actions.syncData.reset` / 내부 `resetRemote()`로 "Reset Synced Data"류는 가능하나 원문 명령명 부정확
- `settings.json` 하나만 관리하면 불완전 — keybindings/snippets/tasks/profiles/extensions 목록/profile별 settings 위치까지 설계 필요

### 방안 3 — 문제 있음 (높음)
- `"Replace Remote"` 공식 용어로는 `Accept Local`. UI/명령명 불안정
- **`"새 기기 연결 시만 pull"`은 Settings Sync 동작과 안 맞음** — Sync는 켜져 있으면 양방향 자동. pull-only 모드 없음

## 2. 빠진 방안 — 문제 있음 (높음)

### 빠진 최선의 중간안
**"로컬 정리 후 Accept Local"** — 로컬 settings.json에서 deprecated/금지 키 먼저 제거 → 정리본 백업/Git 커밋 → `Accept Local`로 충돌 종료.

### 또 다른 빠진 안: 하이브리드
**"Settings만 Git SSOT, Extensions/Keybindings/Snippets/Profiles는 Settings Sync 유지"**
- `Settings Sync: Configure`에서 Settings만 빼고 나머지는 유지
- 방안 2의 단점("extensions/keybindings 직접 관리") 회피

### Profile 분리
Python / AI-agent / 일반 개발 프로필을 나누고, 필요하면 Profiles만 Sync

### Workspace-specific settings
`.vscode/settings.json`은 프로젝트별 formatter/test/lint 규칙에만. User settings에는 개인 전역 취향만.

## 3. dotfiles 설계 — 문제 있음 (중간)
- `~/.claude/`와 **같이 두기보다 분리 권장** — Claude 규칙은 에이전트 행동 정책, VS Code settings는 툴 개인환경. 수명·공개 범위·리뷰 기준 다름
- 같은 private personal-dev-env repo 안에 `claude/`, `vscode/`, `scripts/`로 분리는 괜찮음
- **Windows symlink는 개발자 모드/권한/OneDrive와 충돌 가능** — 단일 Windows 장비면 PowerShell install script가 단순. 여러 OS/기기면 `chezmoi`가 낫고, `stow`는 Windows 주 환경에 덜 적합

## 4. deprecated 키 처리 — 문제 있음 (치명)
- `terminal.integrated.shell.windows`는 단순 deprecated 아님 — **VS Code 1.80에서 `terminal.integrated.shell.*` / `shellArgs.*`가 제거됨**
- 동기화/Git 커밋/Reset Remote **전에 반드시 먼저 제거** 필요
- 대체는 terminal profiles:
```jsonc
"terminal.integrated.profiles.windows": {
  "Command Prompt": { "path": "C:\\WINDOWS\\System32\\cmd.exe" }
},
"terminal.integrated.defaultProfile.windows": "Command Prompt"
```
- cmd가 꼭 기본일 필요 없으면 위 설정도 넣지 말고 VS Code 기본 프로필에 맡기기
- `python.defaultInterpreterPath`도 User 전역에는 넣지 말고, `.venv` 규칙은 프로젝트 구조/문서로 강제

## 5. 멀티 기기 시나리오 — 문제 있음 (높음)
- **방안 1**: 현재 기기 `Accept Local`이 원격 덮음 → 다른 노트북이 다음 sync 시 그 노트북의 고유 변경은 덮이거나 충돌
- **방안 2**: cloud clear는 가장 위험 — 원격 백업과 다른 기기 기준점 날림. 모든 기기 `%APPDATA%\Code\User` 백업 + extension list 백업 + `Show Synced Data` 확인 **이후** 실행
- **방안 3**: "1회 결단" 아님 — 다른 기기가 켜져 있고 Sync 켜져 있으면 다시 양방향. SSOT로 쓰려면 다른 기기에서 Settings Sync 끄거나 Settings 항목만 제외

## 6. Git 관리 방식의 함의 — 문제 있음 (높음)
- 방안 2는 장기 운영 설계 빠짐 — 최소한 CI/pre-commit에서:
  - JSONC parse
  - 금지 키 검사 (`terminal.integrated.shell.*`, `terminal.integrated.shellArgs.*`, `python.defaultInterpreterPath`)
  - 절대 경로 allowlist
  - deprecated 키 검사
- `.vscode/settings.json` ↔ User settings 경계 정의:
  - 프로젝트 repo: formatter/test discovery/lint 같은 협업 규칙만
  - User/dotfiles: 개인 테마/terminal shell/Git path/Jupyter 개인 설정
  - **Workspace settings가 User settings보다 우선** → 여기에 개인 취향 넣으면 팀/프로젝트 충돌 유발

## 최종 권고 — **방안 2의 수정판 (하이브리드)**
"VS Code **Settings만 Git SSOT로 전환**, Settings Sync는 완전히 버리지 말고 **Settings 항목만 제외**해서 extensions/keybindings/snippets/profiles 동기화에는 계속 사용"

### 실행 순서
1. **백업** (`%APPDATA%\Code\User` 전체 + extension list)
2. **로컬 settings 정리** (`terminal.integrated.shell.*` 제거 → profiles로 대체 or 제거)
3. **Git baseline 커밋**
4. **Settings Sync에서 Settings 제외** or Turn Off
5. 필요 시 **remote reset/clear**
6. **다른 기기 적용**

### 방안 1/3보다 나은 이유
- deprecated/금지 키를 CI로 차단 가능

### 방안 2 원안보다 나은 이유
- VS Code Sync의 유용한 영역(extensions/keybindings)을 직접 재구현하지 않아도 됨

## 공식 참고
- https://code.visualstudio.com/docs/configure/settings-sync
- https://code.visualstudio.com/docs/configure/settings
- https://code.visualstudio.com/docs/terminal/profiles
- https://code.visualstudio.com/updates/v1_80
