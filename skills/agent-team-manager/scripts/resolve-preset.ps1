<#
.NAME
    resolve-preset.ps1 — preset YAML → 팀 프로비저닝 메타(JSON) 변환 (Phase 1)

.WHY
    LLM 의 YAML 파싱 변동 차단. 본 비전 양식 (Day 20 turn 1) 결정론적 해석.
    출력 JSON 은 LLM 이 그대로 수용 (TeamCreate/TaskCreate/Agent spawn 인자).

.INPUTS
    -Preset <name>            : 단일 preset 해석 (예: review, debug, research, docs-research, harness-design)
    -List                     : 5 preset 카탈로그 표 출력
    -ValidateOnly -Path <file>: 양식 검증만 (스키마 + members + protocol + cap + output 4 요소)
    -ProjectRoot <path>       : 프로젝트 루트 (스테이징 우선 검색, 기본 = $PWD)

.OUTPUTS
    JSON stdout: {
      "preset": "review",
      "team_name_template": "review-{slug}-{timestamp}",
      "members": [{name, model, subagent_type, sequence, blocked_by, dimension, focus_areas}],
      "task_graph": [{id, owner, subject_template, blocked_by}],
      "task_template": {subject, description, output_format_required},
      "protocol_steps": [...],
      "review_cycle_cap": 3,
      "escalation_after_cap": "...",
      "variations": {...}
    }

.EXIT CODES
    0 = OK
    1 = preset 부재 또는 양식 invalid
    2 = ValidateOnly 실패

.SOURCE
    - 본 비전 preset YAML 양식 (Day 20 turn 1 #009-B PASS, D-17)
    - v2 spec `04_redesign-spec.md §1·§3.1 Phase 1` (단독 구현 금지된 spec 의 명령 양식만 차용)
    - members[].name = agents/*.md basename 1:1 매핑 (Step A 12 agent, turn 11 #009-A)
#>

[CmdletBinding(DefaultParameterSetName = 'Preset')]
param(
    [Parameter(ParameterSetName = 'Preset', Mandatory = $true)]
    [string]$Preset,

    [Parameter(ParameterSetName = 'List')]
    [switch]$List,

    [Parameter(ParameterSetName = 'Validate', Mandatory = $true)]
    [switch]$ValidateOnly,

    [Parameter(ParameterSetName = 'Validate', Mandatory = $true)]
    [string]$Path,

    [string]$ProjectRoot = $PWD.Path
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# preset 검색 경로 (스테이징 우선, 운영 fallback)
$stagingDir = Join-Path $ProjectRoot 'presets'
$opsDir = Join-Path $HOME '.claude\presets'

function Find-PresetFile {
    param([string]$Name)
    $stagingPath = Join-Path $stagingDir "$Name.yaml"
    if (Test-Path $stagingPath) { return $stagingPath }
    $opsPath = Join-Path $opsDir "$Name.yaml"
    if (Test-Path $opsPath) { return $opsPath }
    return $null
}

function Read-YamlAsJson {
    param([string]$YamlPath)
    if (-not (Test-Path $YamlPath)) {
        throw "YAML file not found: $YamlPath"
    }
    $tmpPy = New-TemporaryFile
    try {
        $script = @"
import yaml, json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
try:
    d = yaml.safe_load(open(r'$YamlPath', 'r', encoding='utf-8'))
    print(json.dumps(d, ensure_ascii=False))
except Exception as e:
    print(json.dumps({'__error__': str(e)}), file=sys.stderr)
    sys.exit(1)
"@
        Set-Content -LiteralPath $tmpPy.FullName -Value $script -Encoding UTF8
        $prevEnc = $env:PYTHONIOENCODING
        $env:PYTHONIOENCODING = 'utf-8'
        try {
            $jsonStr = & python $tmpPy.FullName 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "YAML parse failed: $YamlPath"
            }
            return ($jsonStr | ConvertFrom-Json)
        } finally {
            $env:PYTHONIOENCODING = $prevEnc
        }
    } finally {
        Remove-Item -LiteralPath $tmpPy.FullName -ErrorAction SilentlyContinue
    }
}

function Test-PresetSchema {
    param($Data, [string]$Source)
    $issues = @()
    $allowedModels = @('opus', 'sonnet', 'haiku')

    # 필수 키
    foreach ($key in @('name','description','members','task_template','protocol','review_cycle_cap')) {
        if (-not $Data.PSObject.Properties.Name.Contains($key)) {
            $issues += "missing required key: $key"
        }
    }
    if ($issues.Count -gt 0) { return $issues }

    # members 검증
    if ($Data.members.Count -lt 2) {
        $issues += "members count < 2 (got $($Data.members.Count))"
    }
    foreach ($m in $Data.members) {
        if (-not $m.name) { $issues += "member missing 'name'" }
        if (-not $m.model) { $issues += "member '$($m.name)' missing 'model'" }
        elseif ($m.model -notin $allowedModels) {
            $issues += "member '$($m.name)' model='$($m.model)' not in $allowedModels"
        }
        # Haiku 0건 정책 (메모리 feedback_no_haiku.md)
        if ($m.model -eq 'haiku') {
            $issues += "member '$($m.name)' model=haiku violates feedback_no_haiku.md policy"
        }
    }

    # protocol.steps == 4 (4-step 강제)
    if (-not $Data.protocol -or $Data.protocol.steps.Count -ne 4) {
        $issues += "protocol.steps count != 4 (got $($Data.protocol.steps.Count))"
    }

    # review_cycle_cap == 3 (aws-samples 정합)
    if ($Data.review_cycle_cap -ne 3) {
        $issues += "review_cycle_cap != 3 (got $($Data.review_cycle_cap))"
    }

    # task_template.output_format_required == 4 요소
    if (-not $Data.task_template.output_format_required -or
        $Data.task_template.output_format_required.Count -ne 4) {
        $issues += "task_template.output_format_required count != 4"
    }

    return $issues
}

function ConvertTo-TaskGraph {
    param($Members)
    $tasks = @()
    foreach ($m in $Members) {
        $blockedBy = @()
        if ($m.blocked_by) {
            # member name → task id mapping (sequence-based)
            foreach ($bn in $m.blocked_by) {
                $idx = 0
                foreach ($mm in $Members) {
                    $idx++
                    if ($mm.name -eq $bn) {
                        $blockedBy += [string]$idx
                        break
                    }
                }
            }
        }
        $idx2 = ([Array]::IndexOf(@($Members.name), $m.name)) + 1
        $tasks += [pscustomobject]@{
            id               = [string]$idx2
            owner            = $m.name
            subject_template = "[$($m.dimension)] {subject_from_user}"
            blocked_by       = $blockedBy
            sequence         = $m.sequence
        }
    }
    return ,$tasks
}

# === Mode: -List ===
if ($PSCmdlet.ParameterSetName -eq 'List') {
    if (-not (Test-Path $stagingDir)) {
        Write-Error "presets/ 디렉토리 부재: $stagingDir"
        exit 1
    }
    $presets = Get-ChildItem -Path $stagingDir -Filter '*.yaml' | Sort-Object Name
    $rows = @()
    foreach ($p in $presets) {
        try {
            $d = Read-YamlAsJson -YamlPath $p.FullName
            $memberNames = ($d.members | ForEach-Object { $_.name }) -join ', '
            $rows += [pscustomobject]@{
                preset       = $d.name
                team_size    = $d.team_size
                members      = $memberNames
                description  = $d.description
            }
        } catch {
            $rows += [pscustomobject]@{
                preset       = $p.BaseName
                team_size    = 'ERROR'
                members      = $_.Exception.Message
                description  = $null
            }
        }
    }
    $rows | ConvertTo-Json -Depth 5
    exit 0
}

# === Mode: -ValidateOnly ===
if ($PSCmdlet.ParameterSetName -eq 'Validate') {
    try {
        $data = Read-YamlAsJson -YamlPath $Path
    } catch {
        @{ valid = $false; issues = @($_.Exception.Message); path = $Path } | ConvertTo-Json -Depth 5
        exit 2
    }
    $issues = Test-PresetSchema -Data $data -Source $Path
    $result = [pscustomobject]@{
        valid  = ($issues.Count -eq 0)
        issues = $issues
        path   = $Path
    }
    $result | ConvertTo-Json -Depth 5
    exit ($(if ($issues.Count -eq 0) { 0 } else { 2 }))
}

# === Mode: -Preset ===
$presetFile = Find-PresetFile -Name $Preset
if (-not $presetFile) {
    @{ ok = $false; error = "preset not found: $Preset (searched: $stagingDir, $opsDir)" } |
        ConvertTo-Json
    exit 1
}

$data = Read-YamlAsJson -YamlPath $presetFile
$issues = Test-PresetSchema -Data $data -Source $presetFile
if ($issues.Count -gt 0) {
    @{ ok = $false; error = 'schema invalid'; issues = $issues; path = $presetFile } |
        ConvertTo-Json -Depth 5
    exit 1
}

# JSON 메타 출력 (LLM 수용 양식)
$members = @()
foreach ($m in $data.members) {
    $members += [pscustomobject]@{
        name           = $m.name
        model          = $m.model
        subagent_type  = $m.name   # frontmatter name = subagent_type 1:1 (turn 11 D-14 정합)
        sequence       = $m.sequence
        blocked_by     = @($m.blocked_by)
        dimension      = $m.dimension
        focus_areas    = @($m.focus_areas)
    }
}

$taskGraph = ConvertTo-TaskGraph -Members $data.members

$slug = ''  # LLM 이 사용자 작업 키워드로 채움
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'

$result = [pscustomobject]@{
    preset                 = $data.name
    description            = $data.description
    team_name_template     = "$($data.name)-{slug}-{timestamp}"
    team_name_example      = "$($data.name)-EXAMPLE-$timestamp"
    members                = $members
    task_graph             = $taskGraph
    task_template          = $data.task_template
    protocol_steps         = @($data.protocol.steps)
    review_cycle_cap       = $data.review_cycle_cap
    escalation_after_cap   = $data.escalation_after_cap
    variations             = $data.variations
    pm_lead                = $data.pm_lead
    display_mode           = $data.display_mode
    source_file            = $presetFile
    resolved_at            = (Get-Date -Format 'o')
}

$result | ConvertTo-Json -Depth 10
exit 0
