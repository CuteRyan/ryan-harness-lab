# 개발 체크리스트 (강제)

> 모든 코드 수정은 체크리스트를 먼저 만들고, 더블 체크 후 완료한다.
> `dev-checklist-guard.sh` 훅이 자동 강제. 상세 절차: `docs/workflows/dev-checklist.md`

## 필수 순서
1. **`.dev-checklist.md` 생성** → 주인님 승인 → 구현
2. **구현 대조 검증** → Read로 1:1 확인 (체크만 하고 넘어가기 금지)
3. **더블 체크** → 빠진 항목, 미반영, 일관성
4. **구조화된 리포트** → "완료했습니다"만 말하는 것 금지
5. **주인님 승인 후** `.dev-checklist.md` 삭제 — 자의적 삭제 금지

## 훅 동작
- `dev-checklist-guard.sh`가 Edit/Write 시 `.dev-checklist.md` 존재 여부 확인
- 없으면 차단. 예외: `__init__.py`, `conftest.py`, `setup.py`, 체크리스트 자체
