[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [string]$BaselinePath,
    [ValidateRange(1, 200)]
    [int]$Top = 25,
    [switch]$AsJson,
    [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-InputFile {
    param([string]$LiteralPath)
    $resolved = Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop
    if ((Get-Item -LiteralPath $resolved.Path).PSIsContainer) {
        throw "Expected a file, got a directory: $LiteralPath"
    }
    return $resolved.Path
}

function Get-NormalizedLogLines {
    param([string]$LiteralPath)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($line in [System.IO.File]::ReadLines($LiteralPath)) {
        $normalized = $line.Trim()
        if ($normalized.Length -gt 0) { [void]$seen.Add($normalized) }
    }
    return $seen
}

function Get-LogClassification {
    param([string]$Line)
    $rules = @(
        @{ Priority = 0; Bucket = 'likely-crash'; Pattern = 'This will likely crash the game|assertion failed|fatal error' },
        @{ Priority = 1; Bucket = 'parser-scope-trigger'; Pattern = 'Parser error|Unexpected token|Invalid trigger|Invalid effect|Invalid scope|scope mismatch|Error: "Unexpected' },
        @{ Priority = 1; Bucket = 'ideology'; Pattern = 'Invalid ideology|unknown ideology' },
        @{ Priority = 1; Bucket = 'equipment-mio'; Pattern = 'equipment|military industrial organization|\bMIO\b|industrial manufacturer' },
        @{ Priority = 1; Bucket = 'localisation'; Pattern = 'locali[sz]ation|Duplicate loc|Missing loc|Malformed token' },
        @{ Priority = 2; Bucket = 'gui-gfx'; Pattern = '\.gui|\.gfx|sprite|texture|pdx_tooltip|scripted gui' },
        @{ Priority = 3; Bucket = 'optional-media'; Pattern = '\.ogg|\.wav|music|sound|entity|mesh|animation' }
    )
    foreach ($rule in $rules) {
        if ($Line -match $rule.Pattern) {
            return [pscustomobject]@{ Priority = $rule.Priority; Bucket = $rule.Bucket }
        }
    }
    return [pscustomobject]@{ Priority = 2; Bucket = 'other' }
}

$logPath = Resolve-InputFile -LiteralPath $Path
$current = Get-NormalizedLogLines -LiteralPath $logPath
$baseline = $null
if ($BaselinePath) {
    $baselineFile = Resolve-InputFile -LiteralPath $BaselinePath
    $baseline = Get-NormalizedLogLines -LiteralPath $baselineFile
}

$records = [System.Collections.Generic.List[object]]::new()
foreach ($line in $current) {
    $state = if ($null -ne $baseline -and $baseline.Contains($line)) { 'unchanged' } else { 'new' }
    $class = Get-LogClassification -Line $line
    $records.Add([pscustomobject]@{
        priority = $class.Priority
        bucket = $class.Bucket
        state = $state
        text = $line
    })
}

$removed = [System.Collections.Generic.List[string]]::new()
if ($null -ne $baseline) {
    foreach ($line in $baseline) {
        if (-not $current.Contains($line)) { $removed.Add($line) }
    }
}

$ordered = @($records | Sort-Object priority, bucket, text)
$bucketCounts = @(
    $records | Group-Object bucket | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ bucket = $_.Name; count = $_.Count }
    }
)
$result = [ordered]@{
    source = $logPath
    baseline = if ($BaselinePath) { $baselineFile } else { $null }
    unique_entries = $current.Count
    new_entries = @($records | Where-Object state -eq 'new').Count
    unchanged_entries = @($records | Where-Object state -eq 'unchanged').Count
    removed_entries = $removed.Count
    buckets = $bucketCounts
    top_entries = @($ordered | Select-Object -First $Top)
}

$json = $result | ConvertTo-Json -Depth 6
if ($OutputPath) {
    $fullOutput = [System.IO.Path]::GetFullPath($OutputPath)
    if ((Test-Path -LiteralPath $fullOutput) -and -not $Force) {
        throw "Output already exists. Use -Force to replace it: $fullOutput"
    }
    $parent = Split-Path -Parent $fullOutput
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent)
    }
    [System.IO.File]::WriteAllText($fullOutput, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

if ($AsJson) { $json; return }
"Source: $logPath"
if ($BaselinePath) { "Baseline: $baselineFile" }
"Entries: $($result.unique_entries) unique; $($result.new_entries) new; $($result.removed_entries) removed"
""
"Buckets:"
$bucketCounts | Format-Table bucket, count -AutoSize
"Top entries:"
$ordered | Select-Object -First $Top priority, bucket, state, text | Format-Table -Wrap -AutoSize
