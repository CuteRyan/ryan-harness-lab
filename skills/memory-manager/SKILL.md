---
name: memory-manager
description: 프로젝트 메모리 목차를 처음 만들거나, 지침·메모리·문서가 현재 메모리 기준에 맞는지 점검하고 요청하면 정리한다.
trigger: /memory-manager
argument-hint: "[init|audit|clean]"
user-invocable: true
allowed-tools: Read, Write, Edit, Grep, Glob
---

# 메모리 관리

프로젝트 지침, 메모리, 문서가 각자 맡은 내용만 담도록 만들고 점검한다.

## 기준

기준은 아래 두 곳에 있다. 이 스킬은 그 내용을 따르고 옮겨 적지 않는다.

- 지침·`MEMORY.md`·`memory/*.md`·`docs/`의 역할 구분: [글로벌 지침 Documents and records](C:/Python/harness-engineering/settings/global-instructions.md#documents-and-records)
- 메모리 저장·수정·정리 권한: [에이전트 구조 Memory](C:/Python/harness-engineering/docs/agent-structure.md#memory)

메모리 위치와 frontmatter 형식은 현재 런타임의 메모리 안내를 따른다.

## init

메모리 목차가 없는 프로젝트에서 쓴다.

1. 프로젝트 지침 파일과 `docs/`가 있는지 확인한다.
2. 런타임이 정한 위치에 `MEMORY.md`를 만든다. 기억할 내용이 없으면 빈 목차로 둔다.
3. 만든 파일과 위치를 보고한다.

## audit

읽기만 한다.

1. `MEMORY.md`가 한 줄에 한 항목인 짧은 목차인지 확인한다.
2. 주제 파일마다 확인한다.
   - 지침이나 `docs/` 내용을 옮겨 적었는지
   - 링크한 파일이 실제로 있는지
   - 지금 코드·설정과 비교해 여전히 맞는지
   - 목차와 파일이 서로 빠짐없이 연결되는지
3. 규칙이 메모리에 있거나 판단 기록이 지침에 있는 등 자리가 바뀐 내용을 표시한다.
4. 문제와 고칠 방안을 보고한다.

## clean

주인님이 정리를 요청한 범위 안에서 실행한다.

1. 중복된 내용은 원래 자리에 남기고 나머지는 링크로 바꾼다.
2. 깨진 링크와 목차 줄을 고친다.
3. 틀린 것으로 확인된 메모리는 지운다. 확인이 안 되는 내용은 남기고 보고한다.
4. 바꾼 파일과 확인 결과를 보고한다. 복구는 Git이나 편집기 기록으로 한다.

## 주제 파일 예

```markdown
실시간 크롤링 대신 RSS로 뉴스를 모은다. 법적 위험을 줄이고 수집을 안정적으로 유지하기 위해서다.
상세: `docs/design/news-pipeline.md`
```

판단과 이유를 짧게 적고, 자세한 내용은 링크한 문서에 둔다.
