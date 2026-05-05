# patterns.md — 7 오케스트레이션 패턴 (zircote 7패턴)

> **Why on-demand 로드**: SKILL.md 가 항상 읽지 않음. LLM 이 preset 외 즉흥 설계 시 또는 패턴 선택 모호 시 본 파일 Read.
> **출처**: zircote/spec-driven-agent-orchestration HEAD 차용 (마스터플랜 §3 + `02_external-deep.md §3·§5`).
> **본 비전 매핑**: ④ 파이프라인 = 본 7패턴 中 5종 + 본 비전 추가 (Multi-File Refactoring + RLM).

## 목차

1. [Pipeline](#1-pipeline) — 순차 의존성
2. [Parallel Specialists](#2-parallel-specialists) — 독립 병렬
3. [Swarm](#3-swarm) — 동일 작업 N개 병렬
4. [Research+Implementation](#4-researchimplementation) — 탐색 후 구현
5. [Plan-Approval](#5-plan-approval) — 고위험 변경 승인 게이트
6. [Multi-File Refactoring](#6-multi-file-refactoring) — 대규모 리팩터링
7. [RLM (Recursive Language Model)](#7-rlm-recursive-language-model) — 청크 병렬 분석
8. [패턴 선택 매트릭스](#8-패턴-선택-매트릭스)

---

## 1. Pipeline

### 트리거 조건
- 단계 의존성 명시적 (A → B → C, 각 단계 출력 = 다음 단계 입력)
- `addBlockedBy` 체인 자연스러움
- 단계별 산출물 검증 가능

### 멤버 구성 예시
- 3 단계: 가설 → 재현 → 해결 (debug preset)
- 4 단계: docs/community 병렬 → analyst 종합 → architect ADR (docs-research preset)

### preset 매핑
- **debug** (가설→재현→해결) — 3단계 직선 Pipeline
- **harness-design** (researcher→architect→auditor) — 3단계 직선 Pipeline
- **docs-research** (research 3 + architect) — Parallel + Pipeline 혼합

### 비용 추정
- 단계 N개 → 토큰 ≈ N × 단일 멤버 비용 (병렬 절감 없음)
- 실패 회복 비용 = N단계 中 K단계 실패 시 K부터 재시작

---

## 2. Parallel Specialists

### 트리거 조건
- 독립 차원 동시 검토 (보안·성능·정확성처럼 차원 분리)
- 단계 의존성 없음
- 각 멤버 결과는 lead (PM) 가 종합

### 멤버 구성 예시
- 3 차원 병렬: review preset (security/performance/correctness-reviewer)
- 2 차원 병렬: review.security_focused variation (security + correctness)

### preset 매핑
- **review** — 3 차원 병렬 (보안/성능/정확성)
- (research preset 의 docs/community 단계 = 부분 Parallel + analyst 종합)

### 비용 추정
- 동시 실행 → 시간 절약 (1× 단일 멤버 시간)
- 토큰 = N × 단일 멤버 비용 (절감 없음)
- Echo chamber 위험 = R-2 보호 (외부 ③ CLI 검증 권장)

---

## 3. Swarm

### 트리거 조건
- 동일 작업 N개 병렬 (예: 100개 파일에 동일 검증)
- 공유 task pool (먼저 끝난 워커가 다음 task 가져감)
- Anthropic +90.2% 일반화 한계 (#012 R-9): 코딩 태스크는 multi-agent 부적합 가능성

### 멤버 구성 예시
- N명 워커 = 동일 subagent_type, 동일 prompt template
- task pool = `~/.claude/tasks/<team>/*.json` 各 task 의 `owner` 미할당 상태

### preset 매핑
- 본 비전 = 미정 (Phase 2 후 패턴 적용 검토)

### 비용 추정
- 토큰 = N × 단일 비용
- 시간 절감 ≈ 1/N (병렬도 비례)
- 부적합 사례: 코드 리뷰 = task 마다 컨텍스트 다름 → Swarm 비효율

---

## 4. Research+Implementation

### 트리거 조건
- 탐색 (조사·리서치) 완료 후 구현 (코딩·설계)
- Phase gate 명시: 탐색 결과 검토 → 구현 진입 결정 (R-5 정합)
- 두 단계의 멤버 구성 다름

### 멤버 구성 예시
- 탐색: docs-researcher + community-researcher (research preset)
- 구현: architect + (Phase 2 후 신설 코더)

### preset 매핑
- **research** + (별도 turn 구현) — 본 비전은 분리 turn 권장
- **docs-research** = research + architect ADR (구현 전 단계까지 통합)

### 비용 추정
- 토큰 = research 비용 + 구현 비용
- Phase gate 사용자 컨펌 = 시간 비용 추가 (R-5 정합)

---

## 5. Plan-Approval

### 트리거 조건
- 고위험 변경 (배포·마이그레이션·DB 스키마)
- 사용자 승인 게이트 의무
- D-5 오너 컨펌 정합 (마스터플랜 §6 R-5)

### 멤버 구성 예시
- 1 단계: architect (설계안 작성)
- 2 단계: 사용자 승인 (Plan mode + ExitPlanMode)
- 3 단계: 워커 (실행)

### preset 매핑
- 본 비전 = preset 외 즉흥 설계 (1 회성, 사용자 컨펌 게이트 직접 박음)
- ExitPlanMode 도구 호출 의무 (Claude Code 내장)

### 비용 추정
- 토큰 = 설계 + 승인 대기 + 실행
- 승인 대기 시간 = 사용자 응답 시간 (변동)

---

## 6. Multi-File Refactoring

### 트리거 조건
- 대규모 파일 N개 동시 수정 (코드 마이그레이션·리네이밍)
- 각 파일 독립적 (의존성 없음)
- Swarm 변형 + 결과 통합 단계 추가

### 멤버 구성 예시
- N명 워커 = 각 파일 1개 담당 (Swarm 패턴)
- 1명 통합자 = N개 결과 검증 + 통합 보고

### preset 매핑
- 본 비전 = 미정 (Phase 2 후 패턴 적용)
- 외부 사례: aws-samples spec-workflow (HEAD `67840be3`)

### 비용 추정
- 토큰 = N × 단일 파일 + 통합 비용
- 시간 절감 = 1/N (병렬도)

---

## 7. RLM (Recursive Language Model)

### 트리거 조건
- 컨텍스트 초과 분석 (대용량 파일·로그)
- 청크 단위 병렬 + 재귀 종합
- mikeyobrien/Ralph Wiggum 패턴 (마스터플랜 §3 인용)

### 멤버 구성 예시
- N개 청크 분석자 (Swarm 변형, 각 청크 1명)
- 1 종합자 (분석 결과 → 메타 분석)
- 재귀 단계 (대용량 = 종합자 결과 다시 분석자에게)

### preset 매핑
- 본 비전 = 미정 (Phase 2 후 패턴 적용 검토)
- Ralph 자율 루프 제한 = `max_iterations: 5` (마스터플랜 §9.1 가드, R-5 정합)

### 비용 추정
- 토큰 = N × 청크 비용 + 종합 비용 × 재귀 깊이
- 무한 루프 위험 = R-5 cap (max_iterations 강제)

---

## 8. 패턴 선택 매트릭스

> 작업 분석 → 본 매트릭스 → preset 매핑 → SKILL.md §6 명령어.

| 작업 특성 | 추천 패턴 | 매핑 preset |
|---------|---------|-----------|
| 단계 의존성 명시 (A→B→C) | Pipeline | debug · harness-design · docs-research (3·4단계) |
| 독립 차원 동시 검토 (보안·성능·정확성) | Parallel Specialists | review |
| 동일 작업 N개 (배치 검증) | Swarm | (Phase 2 후) |
| 탐색 후 구현 (Phase gate) | Research+Implementation | research + 별도 turn 구현 |
| 고위험 변경 (사용자 승인 의무) | Plan-Approval | (preset 외 즉흥, ExitPlanMode 게이트) |
| 대규모 파일 N개 동시 수정 | Multi-File Refactoring | (Phase 2 후) |
| 컨텍스트 초과 분석 (대용량) | RLM | (Phase 2 후, max_iterations 강제) |

**보수적 default**: 작업 분류 모호 시 → ① 인턴 (Sub-agent) 단독 + 결과 보고 후 재판단 (마스터플랜 §3, SKILL.md §2.1).

**Echo chamber 회피 (R-2)**: 모든 패턴에서 ③ 외부 CLI (`/feedback`) 호출 권장 — 다른 모델 시각 = Codex / Gemini / Claude Sub.
