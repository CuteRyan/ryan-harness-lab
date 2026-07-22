---
name: feedback
description: 파일을 다른 모델로 검토하고, 확인된 문제만 짧게 정리한다.
trigger: /feedback
argument-hint: "<파일 경로> [--full]"
user-invocable: true
---

# Feedback

사용자가 `/feedback`을 요청했을 때만 실행한다. 일반 작업에 자동으로 붙이지 않는다.

## 실행 방식

- 기본 `Quick`: Codex 한 번만 호출한다.
- `Full`: 사용자가 `--full`, “여러 모델”, “정밀 검토”를 요청했을 때만 Claude Sub, Codex, Gemini를 함께 호출한다.
- 모델 호출 전에 별도 승인이나 중간 보고를 요구하지 않는다.

```powershell
# 기본
& "$HOME\.claude\skills\feedback\scripts\orchestrate.ps1" `
  -SourceFile "<대상 파일 절대경로>"

# 정밀 검토
& "$HOME\.claude\skills\feedback\scripts\orchestrate.ps1" `
  -SourceFile "<대상 파일 절대경로>" -Mode Full
```

기본 저장 위치는 현재 프로젝트의 `docs/feedback/`이다. 필요하면 `-FeedbackDir`로 바꾼다.

## 결과 확인

스크립트가 실행과 결과 검사를 한 번에 처리하고 JSON을 반환한다.

- `outputs`: 실행한 모델의 결과 파일 경로
- `validation`: 결과 파일의 유효 여부와 실패 사유
- `validation.valid_count = 0`: 자동 종합을 중단하고 실패 사유만 알린다.
- `validation.valid_count >= 1`: 원본 파일과 지적 내용을 대조한다.

## 정리 원칙

1. 원본에서 확인되지 않는 지적은 제외한다.
2. 같은 문제는 하나로 합친다.
3. 실제 영향이 큰 문제부터 최대 5개만 제시한다.
4. 각 항목에는 파일 위치, 문제, 이유를 짧게 쓴다.
5. 반박이나 자기비판 항목을 수량 맞추기 위해 만들지 않는다.
6. 문제가 없으면 “확인된 문제 없음”이라고 쓴다.

사용자가 문서 저장을 요청하지 않았다면 채팅으로만 보고한다. 저장 요청이 있으면 `docs/feedback/`에 짧은 종합 문서 하나를 만든다.

## 제약

- 리뷰 모델은 격리된 복사본만 읽는다.
- 원본 파일의 줄 번호와 내용은 메인 세션이 다시 확인한다.
- 삭제된 훅이나 별도 사후 검사에 의존하지 않는다.
- 과거 피드백, 히스토리, 할 일 문서를 자동으로 갱신하지 않는다.

## 관리 위치

- 작업본: `Harness-engineering/skills/feedback/`
- Claude 사용본: `~/.claude/skills/feedback/`
