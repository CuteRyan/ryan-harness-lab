# [부록] 배포 규칙 — 상세 체크리스트

> 글로벌 규칙 `~/.claude/rules/deployment.md`에서 분리한 상세 절차.
> 규칙 본문은 짧게(매 세션 로드), 이 체크리스트는 실제 배포 시에만 열람.
> 부록 분리: 2026-07-06 (하네스 다이어트)

---

## 인프라 진행 현황 (2026-07-03, EC2 → Hostinger VPS 단일화)

- ✅ **선창식당**: VPS 이전 완료 (2026-07-03 오전). `/opt/restaurant` systemd+nginx+SSL, `seonchang.duckdns.org` repoint. EC2 삭제됨.
- ⬜ 나머지(DealWatch·PAA·knowledge-platform·election_simulator·trading/moving alert 등): 데이터 이전 안 하고 **전부 새로 재구축** 방침.
- Hermes Agent(nexos.ai/Nous Research, MIT) 구동 예정 — 여러 프로젝트 재구축.
- 공용 VPS 상세: `root@187.127.123.81` (Hostinger KVM4, Ubuntu 24.04 LTS, 말레이시아). SSH `ssh -i C:/Users/rlgns/.ssh/hostinger_vps root@187.127.123.81` (ed25519, 통과문구 없음). 루트 비번은 시크릿(미기재).

## 서버/CI 배포 체크리스트

### 1. 경로 하드코딩 지점 사전 파악
- [ ] **systemd unit**: `ExecStart`, `ExecStartPre/Post`, `WorkingDirectory`, `Environment="PATH=..."`, `EnvironmentFile`, **drop-in(`/etc/systemd/system/<svc>.service.d/*.conf`)**. 확인: `systemctl cat <service>`
- [ ] **systemd timer**: `OnCalendar` 트리거의 `.service` 파일도 검토
- [ ] **프로세스 매니저**: supervisord, gunicorn/uvicorn, celery/rq, apscheduler, PM2 ecosystem.config.js
- [ ] **컨테이너**: Dockerfile `COPY/RUN/CMD` venv 경로, docker-compose `command:`/`entrypoint:`, K8s manifest (Deployment/StatefulSet/CronJob/Job)
- [ ] **스케줄러**: cron (시스템+유저), Procfile
- [ ] **CI**: GitHub Actions/Jenkins/GitLab CI venv 경로 + `actions/cache` key + Python setup version
- [ ] **웹 서버**: nginx/apache uwsgi/fastcgi socket 경로
- [ ] **개발 서버**: VS Code Remote(SSH) 서버 사이드 `.vscode/settings.json`
- [ ] **비 Linux**: Windows Service/Task Scheduler/IIS, macOS `launchd` plist
- [ ] **Secrets**: AWS Secrets Manager/Parameter Store/Vault/.env 참조 스크립트의 Python 경로

### 2. 배포 리허설
- [ ] 스테이징/백업 인스턴스에서 새 `.venv` 생성 + 의존성 복원
- [ ] 스테이징 전체 재시작 + 헬스체크
- [ ] 프로덕션 반영 시간창 결정 (트래픽 낮은 시간대 + 롤백 여유)

### 3. 프로덕션 적용 (안전 순서 — auto-restart 고려)
> **원칙**: 서비스가 참조하는 경로를 **변경하기 전**에 새 환경이 **이미 준비**돼 있어야 함. auto-restart/watchdog 켜진 상태에서 old path 먼저 지우면 장애.

- [ ] (A) 새 `.venv` 생성 + 의존성 복원 (Lock 기준) — 기존 `venv/`는 그대로
- [ ] (B) Smoke test: 새 `.venv`로 엔트리포인트 import·실행
- [ ] (C) 서비스 중지 (`systemctl stop <service>`)
- [ ] (D) 경로 스왑: `venv/` → `venv.old/` 리네이밍 + unit/env 파일 경로를 `.venv`로
- [ ] (E) `systemctl daemon-reload` (unit 변경 시 필수)
- [ ] (F) 재시작 (`systemctl start`) + `status` + 로그 tail
- [ ] (G) 헬스체크 (HTTP 200, DB 연결, 큐 연결)
- [ ] (H) 로그 모니터링 (최소 30분, 에러율 급증 없음)

### 4. 롤백 트리거
헬스체크 3회 연속 실패 / 에러율 평소 5배↑ / 메모리·CPU 이상 급증 / 큐 적체·처리 지연 → 즉시 롤백.

### 5. 롤백 절차
- [ ] 서비스 중지 → `venv.old/` → `venv/` 복원 → unit 파일도 이전 버전 복원 → `daemon-reload` + 재시작 → 헬스체크 → 롤백 사유 HISTORY 기록
> `venv.old/`는 최소 1~2주 보존 (삭제 금지)

### 6. 사후 정리
- 1~2주 안정 운영 확인 후 `venv.old/` 제거
- Docker: 이전 이미지 태그 registry에서 수동 제거 (자동 GC 주의)

## Blue-Green / Atomic Swap (무중단 선호 시)
1. `/opt/app/releases/<timestamp>/.venv` 생성
2. `/opt/app/current` 심볼릭 링크(POSIX): `ln -sfn <new> current.tmp && mv -T current.tmp current`
3. `ExecReload` 설계 서비스면 `systemctl reload`로 무재시작 전환
4. 이전 release는 롤백 창(예: 3개)만 보존
> 서비스가 **경로 간접 참조(symlink)** 허용해야 함. 직접 참조(absolute)만 쓰는 unit은 위 (A)~(H) 필수.

## 특수 케이스
- **Docker**: 컨테이너 내부는 venv 불필요 多 (시스템 Python 격리 사용). venv 이미지 복사 시 Python minor/ABI 변경으로 깨짐 — base image 변경 시 venv 재생성.
- **CI 캐시**: `actions/cache` key에 `hashFiles('**/poetry.lock','**/requirements.txt')` 포함. Python 버전 변경 시 key에 버전 포함.
- **Jupyter**: 서버 커널 사양(`kernel.json`) Python 경로 갱신. 기존 커널 제거 후 `python -m ipykernel install --user --name <new>` 재등록.
