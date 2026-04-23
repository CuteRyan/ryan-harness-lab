#Requires -Version 5.1
<#
.SYNOPSIS
    /feedback 스킬의 Validation Gate — 결과 md 파일들의 유효성을 디스크 기반으로 검증.

.DESCRIPTION
    octopus의 Validation Gate Pattern 차용. LLM 해석이 아닌 스크립트가 파일을 직접 보고 판정.

    검증 항목 (모두 만족해야 VALID):
    1. 파일 존재 (Test-Path)
    2. 크기 > 0 (빈 파일 아님)
    3. orchestrate가 쓴 실패 마커("# ... 실행 실패") 없음
    4. 중요도 태깅 접두사 `[치명]`·`[높음]`·`[중간]`·`[낮음]` 중 최소 1개가
       **줄 시작 위치**(선택적 불릿 `-`/`*`, 번호 `1.`, ATX 헤더 `#`~`######` 허용)에 존재.
       본문 설명·코드블록 안의 인용 `[치명]` 은 Finding 접두사가 아니므로 우회 차단.
       (2026-04-23 Codex/Gemini 태깅 누락 → 엄격화 1차, Gemini 본문 인용 우회 관찰 → 앵커화 2차,
        Claude Sub `### [높음]` 헤더 형식 실측 → ATX 헤더 허용 2.1차.)

.PARAMETER FilePaths
    검증할 md 파일 절대경로 배열.

.OUTPUTS
    JSON: {summary, valid_count, total, results: [{file, path, status, reason}]}
#>
param(
    [Parameter(Mandatory = $true)]
    [string[]]$FilePaths
)

$ErrorActionPreference = 'Stop'

$results = @()
foreach ($fp in $FilePaths) {
    $name = Split-Path -Leaf $fp
    $status = "INVALID"
    $reason = ""

    if (-not (Test-Path -LiteralPath $fp -PathType Leaf)) {
        $reason = "파일 없음"
    }
    else {
        $item = Get-Item -LiteralPath $fp
        if ($item.Length -eq 0) {
            $reason = "빈 파일 (0 바이트)"
        }
        else {
            $content = Get-Content -LiteralPath $fp -Raw -Encoding UTF8

            if ($content -match '^#\s+\S+\s+실행 실패') {
                $reason = "orchestrate 실패 마커 감지 (async+sync 재시도 모두 실패)"
            }
            elseif ($content -notmatch '(?m)^\s*(?:[-*]\s*|\d+\.\s*|#{1,6}\s+)?\[(치명|높음|중간|낮음)\]') {
                # 줄 시작 위치에서만 태그를 인정. 허용 prefix:
                #   - 불릿: `-` `*`
                #   - 번호: `1.` `12.` ...
                #   - 마크다운 ATX 헤더: `#` ~ `######`
                # 본문 설명·코드블록 안의 인용 `[치명]` 은 Finding 접두사가 아니므로 우회 차단.
                # (2026-04-23 Gemini dogfood 실측: "태그(`[치명]`, `[높음]` 등)" 단순 매치 통과 방지.
                #  Claude Sub 의 `### [높음] ...` ATX 헤더 형식도 허용해야 해 `#{1,6}\s+` 포함.)
                $reason = "중요도 태깅 접두사 없음 (줄 시작 [태그] 형식 필수, 본문 인용 우회 차단)"
            }
            elseif ($content -notmatch '근거|https?://|\.(md|ps1|py|json|sh|yaml|yml|toml|txt):\d+') {
                # 근거 패턴: 근거 키워드 / URL / 파일:줄 (확장자 기반) 중 하나 이상 필요
                $reason = "근거 없음 (근거 키워드·URL·파일:줄 중 1개 이상 필요)"
            }
            else {
                $status = "VALID"
            }
        }
    }

    $results += [PSCustomObject]@{
        file   = $name
        path   = $fp
        status = $status
        reason = $reason
    }
}

$validCount = @($results | Where-Object { $_.status -eq "VALID" }).Count
$total = $results.Count

@{
    summary     = "$validCount/$total 유효"
    valid_count = $validCount
    total       = $total
    results     = $results
} | ConvertTo-Json -Depth 3
