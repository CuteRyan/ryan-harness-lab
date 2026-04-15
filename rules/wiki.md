# docs/ 위키 체계 (강제)

> 상세 절차: `docs/workflows/wiki-management.md`

## 필수 규칙
- **문서 생성/삭제 시** → `index.md` 반드시 업데이트
- **문서 생성/수정 시** → `log.md`에 항목 추가 (append-only, 역순)
- **교차 참조** → 새 문서에 관련 문서 링크 + 기존 문서에 역참조 추가
- **중복 금지** → index.md에서 같은 주제 확인 후, 있으면 업데이트
