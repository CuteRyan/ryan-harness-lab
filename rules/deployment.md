# 배포 규칙 (훅 강제)

> `deploy-version-guard.sh` 훅이 버전업/HISTORY 확인. 접속정보는 프로젝트 메모리 `deployment.md` 참조.

## 인프라 (2026-07-03, 전 프로젝트)
- **AWS EC2 폐기 → Hostinger VPS 단일화.** 모든 프로젝트를 1대 VPS로 통합, 신규 배포는 VPS 기준. EC2 신규 투자 금지.
- 공용 VPS: `root@187.127.123.81` (Hostinger KVM4, Ubuntu 24.04). SSH: `ssh -i C:/Users/rlgns/.ssh/hostinger_vps root@187.127.123.81`.
- **앱 경로·서비스명·도메인·시크릿은 각 프로젝트 메모리 `deployment.md`에.** 배포 전 대상 프로젝트가 VPS로 이전됐는지 프로젝트 메모리 확인.

## 핵심 원칙
- **런타임 경로 변경(venv·Python 버전·실행 유저)은 배포 변경**으로 간주 — HISTORY 기록(무엇을·왜·이전 값) + 롤백 플랜 + 서비스 재시작·헬스체크 필수.
- **경로를 바꾸기 전에** 새 환경이 이미 준비돼 있을 것 (auto-restart 장애 방지).
- 배포 전 **경로 하드코딩 지점 전수 확인** (systemd·컨테이너·cron·CI·nginx).
- 문제 발생 시 즉시 롤백 (`venv.old/` 최소 1~2주 보존).

---
> 상세 체크리스트 (경로 하드코딩 전수 · 프로덕션 적용 A~H · 롤백 절차 · Blue-Green · Docker/CI/Jupyter 특수 케이스 · VPS 진행 현황) → `Harness-engineering/docs/rules-appendix/deployment-checklist.md`
