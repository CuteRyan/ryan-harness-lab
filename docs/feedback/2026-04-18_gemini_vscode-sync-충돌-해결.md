---
title: Gemini 리뷰 — VS Code Settings Sync 충돌 해결 방안
type: feedback
reviewer: gemini
date: 2026-04-18
target: 방안 1(로컬 즉시 채택) / 방안 2(Sync 끄고 Git) / 방안 3(Sync 유지 SSOT 전환)
---

# Gemini 리뷰 — VS Code Settings Sync 충돌 해결 방안

## 총평
하네스 엔지니어링 관점에서 현재 구축한 **글로벌 규칙 리포지토리 체계와 일관성 유지**가 핵심. Settings Sync는 블랙박스, 방안 2(Git)가 압도적 우위.

## 6대 관점 검토

| 관점 | 방향성 | 우선순위 | 개선 제안 |
|------|-------|---------|----------|
| 1. 장기 유지보수 | 맞음 (방안 2) | 높음 | Sync는 블랙박스. Git이 규칙 파일과 버전 동기화·변경 이력 면에서 압도적 |
| 2. 빠진 방안 | 개선 필요 | 중간 | **Profiles 기능** 간과 — 'Harness 전용 Profile' 분리로 충돌 범위 축소 가능 |
| 3. dotfiles 설계 | 맞음 | 중간 | `~/.claude/` 리포 내부 `vscode/` 디렉토리가 관리 비용 낮음. chezmoi 등 전용 도구보다 **심볼릭 링크 스크립트**가 적합 |
| 4. deprecated 정리 | 순서 조정 필요 | 높음 | **충돌 해결 직전에 정리** 필수. 오염 상태로 Sync/Commit하면 이력에 노이즈 |
| 5. 멀티 기기 | 리스크 있음 | 높음 | 13개월 끊긴 상태면 타 기기 데이터는 이미 부채. **현재 기기를 SSOT로 확정**하고 타 기기는 초기화 후 새로 내려받기 |
| 6. Git 관리 비용 | 맞음 | 낮음 | `.vscode/settings.json`(워크스페이스) = 프로젝트 필수값, User settings = 개인 취향으로 엄격 분리해 상속 구조 설계 |

## 해결 방안별 리스크 및 개선점

### 방안 1: 즉시 해결 (로컬 채택)
- **리스크**: 1년 넘은 구형 키(deprecated)가 다시 클라우드로 올라가며 다른 기기에서 예기치 않은 동작 유발
- **개선**: 단순 'Show Conflicts'만 하지 말고 `jsonc` 형식으로 주석 달아 설정의 이유 기록하며 정리

### 방안 2: 근본 해결 (Git 관리 — 추천)
- **리스크**: VS Code는 `settings.json`을 UI에서 설정 변경 시 수시로 자동 수정 → Git 충돌 빈번 가능
- **개선**: 하네스의 `hooks/` 시스템에 `pre-commit-settings-check`을 추가하여 설정 파일 형식 강제 또는 민감 정보 포함 여부 린팅

### 방안 3: 중간안 (Sync 유지, SSOT)
- **리스크**: 편의성은 높으나 제어권 없음 — 왜 충돌이 났는지, 누가 언제 바꿨는지 알 수 없는 상태로 회귀
- **개선**: 이 방안 택하더라도 주기적으로 `settings.json`을 하네스 리포에 백업하는 **자동 스크립트(Hook)** 병행 필요

## 최종 권고: **방안 2 기반 'Settings as Code'**

**이유**: 주인님은 이미 규칙 기반 엄격한 개발 환경(Harness) 구축 중. 설정(Settings) 또한 규칙의 일부이므로 **클라우드 서비스에 위탁하기보다 코드화하여 명시적 관리**하는 것이 설계 철학 부합.

### 실행 로드맵
1. **[즉시] Cleanup**: 로컬 `settings.json`에서 `terminal.integrated.shell.windows` 등 deprecated 키를 최신 문법(profiles)으로 수정
2. **[선택] Profile 분리**: 전역 설정 중 'Harness 개발용'만 따로 추출하여 별도 Profile 생성 여부 결정
3. **[전환] Git 이관**: `Settings Sync: Turn Off` 수행 → `~/.claude/vscode/settings.json`으로 파일 이동 → 원래 위치(`%AppData%/Code/User/`)에 **심볼릭 링크**
4. **[확장] Extension 관리**: `extensions.json` 파일 생성하여 `code --install-extension` 리스트를 Git 관리 (진정한 근본 해결)

### 최종 이점
초기 셋업 비용 발생하나 한 번 구축 시 **기기 교체 시 하네스 리포 클론만으로 모든 개발 환경이 100% 복구되는 강력한 인프라** 확보.
