---
name: 공유 VPS 배포 인프라
description: Hostinger VPS 단일화(2026-07-03) — 서버 좌표 포인터 + 프로젝트별 이전 현황. 옛 AWS EC2는 폐기됨.
type: reference
---

> 2026-07-03 AWS EC2 폐기 → **Hostinger VPS 단일화**. 서버 좌표·배포 절차 SSOT = `~/.claude/rules/deployment.md` + `docs/rules-appendix/deployment-checklist.md` (중복 나열 안 함).

## 공유 서버
- Hostinger KVM4 (4코어/16GB/200GB), Ubuntu 24.04 LTS, 말레이시아 리전
- `ssh -i C:/Users/rlgns/.ssh/hostinger_vps root@187.127.123.81` (ed25519, 통과문구 없음)
- 루트 비번은 시크릿(미기재). 로그인은 SSH 키 위주.

## 프로젝트별 이전 현황
| 프로젝트 | 상태 | 비고 |
|---|---|---|
| 선창식당 (`C:/Python/restaurants_pj/`) | ✅ VPS 이전 완료 | `/opt/restaurant` systemd+nginx+SSL, `seonchang.duckdns.org`. EC2 삭제됨 |
| DealWatch · PAA · election_simulator · knowledge-platform 등 | ⬜ 미이전 | 데이터 이전 없이 **전부 새로 재구축** 방침 |

**Why:** 비용 절감 — EC2(2코어/3.7GB, 종량) → VPS($13~18/월 고정, 4코어/16GB로 스펙↑·비용↓). 주인님 명시 2026-07-03.
**How to apply:** 배포 전 대상 프로젝트가 VPS로 이전됐는지 확인. 앱 경로·서비스명·도메인·시크릿은 각 프로젝트 메모리 `deployment.md`에.
