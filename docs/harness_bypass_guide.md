# 하네스 훅 우회 가이드

> 작성일: 2026-04-12 | 마지막 검증: 2026-04-12

---

## 이 문서는 무엇인가?

하네스 훅이 잘못 차단하거나 작업을 방해할 때 빠르게 우회하는 방법을 정리한 가이드.

---

## 1. 즉시 우회 (프로젝트 단위)

### .harness.yml 삭제

```bash
# 프로젝트 루트에서
rm .harness.yml
```

효과: 해당 프로젝트의 **모든 하네스 opt-in 훅**이 no-op이 됨.
글로벌 훅(체크리스트, 백업 등)은 그대로 동작.
복원: `.harness.yml`을 다시 생성하면 즉시 복구.

---

## 2. 특정 훅별 우회

### wiki-index-guard (index.md 미등록 경고)

- **방법 1**: `docs/index.md`에 해당 파일명을 추가 → 경고 해소
- **방법 2**: `.harness.yml` 삭제 → 훅 자체가 no-op

### graphify-reminder (GRAPH_REPORT.md 부재 경고)

- **방법 1**: `/graphify .`로 그래프 생성 → 경고 해소
- **방법 2**: `.harness.yml` 삭제 → 훅 자체가 no-op

---

## 3. 훅 자체 비활성화 (최후 수단)

`~/.claude/settings.json`에서 해당 훅 항목을 삭제:

```
"hooks" > "PreToolUse" > matcher별 배열에서 해당 command 줄 삭제
```

주의: JSON은 주석을 지원하지 않으므로 주석 처리 불가. 줄 자체를 삭제해야 함.
복원: `.backups/`에서 settings.json 백업 복사 또는 수동 재추가.

---

## 4. 오탐 확인 방법

```bash
# 프로젝트별 감사 로그 확인
cat {프로젝트루트}/.claude/harness-audit.log

# would-block 건수 (오탐 후보)
grep "would-block" .claude/harness-audit.log

# 훅별 분류
grep -c "wiki-index-guard" .claude/harness-audit.log
grep -c "graphify-reminder" .claude/harness-audit.log
```

로그 형식: `[날짜 시간] hook=훅명 action=동작 detail=상세`

---

## 관련 문서

- [프로젝트 하네스 설계안](project_harness_architecture.md)
- [하네스 딥다이브](harness_deep_dive.md)
