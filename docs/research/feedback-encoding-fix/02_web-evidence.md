---
title: "/feedback 인코딩 깨짐 — 웹 근거 수집"
owner: analyst
date: 2026-04-23
scope: L1/L2/L3 각 레이어를 외부 근거로 교차검증
sources:
  - hy2k.dev 2025-11-20 블로그
  - Microsoft Learn CJK garbled 공식 troubleshooting
  - google-gemini/gemini-cli#20186 (한글 직접 케이스)
  - openai/codex#4498 (stdio mojibake)
  - OpenAI Developer Community — Cyrillic on PS 5.1
  - codegenes.net — Permanent UTF-8 프로필
  - PowerShell/PowerShell#7233, #4681, #14945 (공식 레포)
  - Delft Stack — CHCP 65001 vs $OutputEncoding
---

# /feedback 인코딩 깨짐 — 웹 근거 수집

> [01_root-cause.md](01_root-cause.md)의 3 레이어 진단을 외부 기술 문서·이슈·공식 레포 근거로 교차검증.

---

## L1 — stdout 디코딩 근거

### 근거 1. hy2k.dev — PowerShell mojibake 공식 레시피 (2025-11-20)
**핵심 인용**:
> `[Console]::OutputEncoding` controls how the .NET Console APIs decode bytes received from child processes (that is, how bytes are turned into .NET string objects).
> `$OutputEncoding` controls how PowerShell converts .NET strings into bytes when PowerShell writes to external processes.
> **By itself `$OutputEncoding` will not repair text that was already decoded incorrectly.**

**의의**: L1과 L2는 **별개 변수**이며 **둘 다** 설정해야 양방향 안전. 1차 대응이 한쪽만 커버했을 가능성.

**URL**: https://hy2k.dev/en/blog/2025/11-20-fix-powershell-mojibake-on-windows/

### 근거 2. Microsoft Learn — CJK garbled 공식 troubleshooting
**핵심**: Windows Server 2022 PowerShell에서 CJK 문자가 깨지는 문제의 공식 해결책으로 `[Console]::OutputEncoding` 변경 제시.

**의의**: Microsoft 스스로 이것이 **설정 이슈**(버그 아님)로 인정한 공식 문서.

**URL**: https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/powershell-console-characters-garbled-for-cjk-languages

### 근거 3. OpenAI Developer Community — Cyrillic on PS 5.1
**핵심**: "Incorrect Cyrillic rendering in Codex Agent on Windows due to PowerShell 5.1 default ANSI encoding." PS 5.1이 ANSI 기본값이라는 점을 명시적으로 원인으로 지목.

**의의**: PS 5.1 vs PS 7의 기본값 차이가 공개 커뮤니티에서 반복 제기. 근본 회피책은 PS 7 이주.

**URL**: https://community.openai.com/t/incorrect-cyrillic-rendering-in-codex-agent-on-windows-due-to-powershell-5-1-default-ansi-encoding/1356123

---

## L2 — 인자 인코딩 근거

### 근거 4. gemini-cli #20186 — 한글 직접 케이스 (2026-02)
**실측 증상**:
> git commit -m 'feat : SecurityConfig CORS AllowedOrigins ngrok URL 추가'
> Results in: feat : SecurityConfig CORS AllowedOrigins ngrok URL 異媛

**핵심**:
- Windows 10/11 PowerShell에서 gemini-cli 0.29.7 (보고 시점) **한글 argv 손상 재현**.
- 유일하게 확인된 우회책: **파일 기반 전달** (`git commit -F msg.txt`, `gh pr create --body-file body.md` 류).
- 이슈 시점 미해결.

**의의**: 현재 `/feedback` `run-gemini.ps1:40`의 `gemini.cmd -p $Prompt` 패턴이 **정확히 이 버그 조건**. L2가 실제로 Gemini에서 재현될 가능성 매우 높음.

**URL**: https://github.com/google-gemini/gemini-cli/issues/20186

### 근거 5. openai/codex #4498 — stdio mojibake
**핵심**:
> The `-NoProfile` parameter prevents PowerShell from loading user profiles that contain UTF-8 encoding configurations. Windows PowerShell defaults to GB2312 encoding (code page 936), while the application expects UTF-8.
> 문제 코드: `codex-rs/core/src/shell.rs`의 `format_default_shell_invocation()`가 `-NoProfile`을 하드코딩.

**제안 해결책 3가지**:
1. `use_profile = true`일 때 `-NoProfile` 제거
2. 도구 전용 인코딩 설정 추가
3. `encoding_rs` 기반 감지·변환

**의의**: Codex CLI 자체가 PS subprocess 호출 시 인코딩 버그를 가짐. 이슈 2025-09-30 오픈, 0.43.0-alpha.5까지 미해결. 우리 `run-codex.ps1`은 CLI를 직접 호출하므로 이 내부 버그의 직접 영향은 덜하지만, **CLI가 내부에서 또 다른 PS를 spawn할 경우** 간접 영향 가능.

**URL**: https://github.com/openai/codex/issues/4498

---

## L3 — Start-Job runspace 근거

### 근거 6. PowerShell/PowerShell#4681 — $OutputEncoding과 코드페이지 준비
**핵심**: `$OutputEncoding`이 세션/스코프 단위라는 점, 그리고 자식 프로세스/잡에 자동 상속되지 않음을 공식 이슈에서 논의.

**URL**: https://github.com/PowerShell/PowerShell/issues/4681

### 근거 7. PowerShell/PowerShell#14945 — Input/Output 인코딩 비정렬
**핵심**: `$OutputEncoding`과 `[System.Console]::InputEncoding`이 Windows에서만 비일관. 프로필 로드 타이밍·runspace 별로 달라짐.

**URL**: https://github.com/PowerShell/PowerShell/issues/14945

**의의**: L3의 근본 원인 — PS 5.1 runspace 모델이 인코딩 설정을 자동 전파하지 않음을 공식 레포가 인정.

---

## 보조 — 영구 설정 / 대안

### 근거 8. codegenes.net — 영구 UTF-8 프로필
**레시피**:
```powershell
# $PROFILE 에 추가
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
```

**URL**: https://www.codegenes.net/blog/changing-powershell-s-default-output-encoding-to-utf-8/

### 근거 9. Delft Stack — CHCP 65001 의 한계
**핵심**:
- `chcp 65001`은 콘솔 코드페이지만 바꿈 → `$OutputEncoding`은 여전히 레거시 유지 → 파이프/리다이렉트 불일치.
- **임시 밴드에이드**. 영구 해결책 아님.

**의의**: `chcp` 방식은 기각. PS API 기반 설정이 표준.

**URL**: https://www.delftstack.com/howto/powershell/powershell-utf-8-encoding-chcp-65001/

### 근거 10. PowerShell/PowerShell#7233 — UTF-8 기본화 장기 과제
**핵심**: "Make console windows fully UTF-8 by default on Windows." 2018년부터 논의 중. PS 7에서 일부 진전, PS 5.1은 여전히 ANSI.

**URL**: https://github.com/PowerShell/PowerShell/issues/7233

**의의**: 근본 해결책은 **PS 7 이주**. 단 하네스 프로젝트는 Windows 서버 배포도 고려해야 하므로 PS 5.1 호환성을 당분간 유지하는 게 안전 (연관 메모리: `project_deployment_target.md`).

---

## 근거 → 레이어 매핑

| 근거 | L1 | L2 | L3 | 행동 시사점 |
|---|---|---|---|---|
| 1. hy2k.dev | ✅ | ✅ | — | 두 변수 모두 필수 |
| 2. MS Learn | ✅ | — | — | 공식 해결책 확정 |
| 3. OpenAI 커뮤니티 | ✅ | — | — | PS 5.1 근본 한계 |
| 4. gemini-cli #20186 | — | ✅ | — | 파일 기반 프롬프트 전달 |
| 5. codex #4498 | — | ✅ | — | 간접 영향 주시 |
| 6. PS #4681 | — | ✅ | ✅ | runspace 별 재설정 |
| 7. PS #14945 | — | ✅ | ✅ | Input/Output 비정렬 |
| 8. codegenes.net | ✅ | ✅ | — | `$PSDefaultParameterValues` 추가 |
| 9. Delft Stack | ❌ | ❌ | ❌ | CHCP 기각 |
| 10. PS #7233 | — | — | — | 장기: PS 7 이주 |

---

## 종합

- **L1**은 근거 1,2,3로 확정 — `[Console]::OutputEncoding = UTF8` 설정이 표준 해결책.
- **L2**는 근거 4가 가장 결정적 — **Gemini에만** 파일 기반 우회 필요. Codex/Claude는 `$OutputEncoding`으로 충분할 가능성 높음(추가 실측 필요).
- **L3**는 근거 6,7로 확정 — Start-Job ScriptBlock 내부에서 재설정.
- **근본 이주**(근거 10)는 MVP 범위 밖. 단기는 PS 5.1에서 3 레이어 방어.

---

## 연관 문서
- [01_root-cause.md](01_root-cause.md) — 3 레이어 원인 분석
- [03_fix-plan.md](03_fix-plan.md) — 수정안 + 검증
