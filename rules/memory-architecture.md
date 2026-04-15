# 메모리 3계층 아키텍처

## 자동 로딩 (매 세션)
| 파일 | 역할 | 제한 |
|------|------|------|
| `CLAUDE.md` | 프로젝트 소개 + 핵심 규칙 | 200줄 이내 |
| `{하위폴더}/CLAUDE.md` | 파트별 스코핑 규칙 | 해당 디렉토리 작업 시만 |
| `.claude/rules/*.md` | 세부 규칙 분리 | CLAUDE.md와 동일 우선순위 |
| `memory/MEMORY.md` | 순수 인덱스 (포인터만) | 200줄 이내 |

## on-demand 로딩
| 파일 | 역할 |
|------|------|
| `memory/*.md` (topic) | 포인터 + 핵심 판단 요약 3~5줄 |

## 역할 분리 (절대 규칙)
- **CLAUDE.md + rules/** = 강제 ("하라/하지 마라")
- **memory/** = 포인터 ("여기에 이런 게 있다" + 왜 그렇게 결정했는지 3줄)
- **docs/** = Single Source of Truth (실제 내용은 여기만)
- 내용 중복 금지 — memory에 docs/ 내용을 복사하지 않음
- topic 파일 양식: frontmatter(name, description, type) + 판단 요약 3줄 + docs/ 포인터

## 파일 컨벤션
- 파일명: 영문 kebab-case (예: `news-pipeline.md`)
- 파일 1개 = 토픽 1개
- 2개 이상 프로젝트에서 반복되는 메모리 → 글로벌로 승격
