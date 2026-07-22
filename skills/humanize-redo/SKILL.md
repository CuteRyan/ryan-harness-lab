---
name: humanize-redo
description: 가장 최근 `/humanize` 결과에서 사용자가 지정한 부분만 다시 다듬거나 되돌립니다.
argument-hint: "[예: 번역투만 다시, 두 번째 문단만, 강도 낮춰, 이 변경 되돌려줘]"
disable-model-invocation: true
---

# /humanize-redo

## 요청

$ARGUMENTS

## 실행

1. `_workspace/YYYY-MM-DD-*/final.md`를 찾아 가장 최근 결과를 선택합니다. 없으면 먼저 `/humanize`를 실행하도록 안내합니다.
2. 사용자가 지정한 문단, 문제 유형, 강도 또는 되돌릴 변경을 확인합니다.
3. 지정 범위만 다시 다듬고 이전 결과는 `final_prev.md`로 보존합니다.
4. `03_rewrite_v2.md`부터 순서대로 새 버전을 만들고 내용 보존과 자연스러움을 다시 확인합니다.
5. 최대 세 번까지 시도하고, 해결되지 않으면 남은 문제를 그대로 보고합니다.

범위를 추측하기 어려우면 수정하기 전에 짧게 질문합니다.
