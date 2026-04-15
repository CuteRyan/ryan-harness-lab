# 문서 안전 규칙 (강제)

> 모든 항목이 훅으로 자동 강제됨. 우회 불가.

## 문서 보호 (훅 강제)
1. **기존 문서는 Edit만** — Write 금지 (새 파일 생성만 Write 허용)
2. **Bash로 문서 수정 금지** — `sed -i`, `echo >`, `tee` 차단
3. **Edit 시 자동 백업** — `.backups/`에 자동 복사
4. **docs/rules/ 수정 시** → `.doc-checklist.md` 필수 (상세: `docs/workflows/document-work.md`)
5. **더블 체크 없이 체크리스트 삭제 불가**
6. **파일 변경 전 .bak 백업** — `.backups/` 폴더에 보관 (훅 자동)

## 발표자료/논문
- md 먼저 → HTML 반영 (역순 금지)
- generate 스크립트로 재생성 금지
