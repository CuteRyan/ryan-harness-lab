---
name: project-structure
description: 프로젝트 하네스 구조 진단(audit), 초기화(init), 위키 린트(lint), 역색인 생성(reindex)
trigger: /project-structure
---

# /project-structure

프로젝트의 하네스 구조를 관리하는 스킬.

## Usage

```
/project-structure audit              # 현재 프로젝트 구조 진단
/project-structure init               # 하네스 기본 구조 초기화
/project-structure lint               # 위키 린트 (고아 문서, 깨진 링크, 메타데이터 누락 등)
/project-structure reindex            # 코드↔문서 역색인 생성/갱신
```

## Commands

### audit — 프로젝트 구조 진단

현재 프로젝트 루트에서 하네스 최소 필수 구조가 갖춰졌는지 검사한다.

검사 항목:
1. `.harness.yml` 존재 여부
2. `CLAUDE.md` 존재 여부 (루트 또는 .claude/)
3. `docs/index.md` 존재 여부
4. `docs/log.md` 존재 여부
5. `docs/templates/` 존재 여부 + 5종 템플릿 확인
6. `graphify-out/GRAPH_REPORT.md` 존재 여부
7. `pyproject.toml` 또는 `package.json` 존재 여부
8. 루트에 산재한 코드 파일 수 (src/ 밖의 .py/.js/.ts)
9. `.gitignore`에 `.backups/`, `__pycache__/` 등 포함 여부

출력 형식:
```
✅ 항목명 — 있음 (상세)
❌ 항목명 — 없음 (권장 조치)
⚠️  항목명 — 주의 (상세)
```

마지막에 점수 요약: `N/M 항목 충족`.

### init — 하네스 기본 구조 초기화

다음 파일을 생성한다 (이미 존재하면 건너뜀):

1. `.harness.yml` — 기본 opt-in 설정
2. `docs/index.md` — 빈 인덱스 (카테고리 골격)
3. `docs/log.md` — 빈 변경 기록
4. `docs/templates/` — 5종 템플릿 (design, decision, ops, audit, research)
5. `CLAUDE.md` — 프로젝트 소개 스켈레톤

템플릿 원본 위치: 이 스킬이 직접 생성 (PAA/docs/templates/와 동일한 내용).

init 후 자동으로 `audit`을 실행하여 결과를 보여준다.

### lint — 위키 린트

docs/ 폴더를 검사하여 위키 품질 문제를 찾는다.

검사 항목:
1. **고아 문서** — docs/ 내 .md 파일 중 index.md에 등록되지 않은 것
2. **깨진 링크** — 프론트매터 `related_docs`에 적힌 파일이 실제로 존재하지 않는 것
3. **구식 문서** — 프론트매터 `updated`가 3개월 이상 지난 문서
4. **메타데이터 누락** — YAML 프론트매터가 없는 .md 파일 (index.md, log.md, HISTORY.md, templates/ 제외)
5. **중복 주제** — 비슷한 제목의 문서가 2개 이상

출력: 항목별 건수 + 파일 목록.

### reindex — 역색인 생성/갱신

docs/ 내 모든 .md 파일의 YAML 프론트매터에서 `related_code` 필드를 추출하여 양방향 매핑을 생성한다.

출력 파일: `docs/.harness-index.json`

```json
{
  "code_to_docs": {
    "src/auth.py": ["docs/design/auth-flow.md"]
  },
  "doc_to_code": {
    "docs/design/auth-flow.md": {
      "code": ["src/auth.py"],
      "mtime": 1712928000
    }
  },
  "last_indexed": "2026-04-12T10:00:00"
}
```

파싱 방식:
- Python stdlib 기반 (PyYAML 의존성 없음)
- `---` 사이의 프론트매터에서 `related_code:` 아래 `- path` 추출
- 경로를 repo-relative로 정규화 (\ → /, ../ 해석)

## Scope

- `.harness.yml`이 있는 프로젝트에서만 동작 (없으면 "opt-in 필요" 안내)
- `init`은 예외: .harness.yml이 없어도 실행 가능 (생성하는 명령이므로)
- 지식 폴더(`문서/지식/`)에는 적용하지 않음 (코드가 없으므로)

## Implementation Notes

- audit/lint/reindex는 **읽기 전용** — 파일을 수정하지 않고 결과만 출력
- init만 파일을 생성 — 주인님 확인 후 실행
- reindex의 프론트매터 파서는 `code-doc-sync.sh` 훅과 동일한 로직 사용
