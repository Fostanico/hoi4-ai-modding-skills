[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [switch]$AsJson,
    [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CleanText {
    param([string]$LiteralPath)
    $text = [System.IO.File]::ReadAllText($LiteralPath)
    return [regex]::Replace($text, '(?m)#.*$', '')
}

function Get-NamedBlock {
    param([string]$Text, [string]$Name)
    $match = [regex]::Match($Text, "(?m)\b$([regex]::Escape($Name))\s*=\s*\{")
    if (-not $match.Success) { return $null }
    $open = $Text.IndexOf('{', $match.Index)
    $depth = 0
    $quoted = $false
    $escaped = $false
    for ($i = $open; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        if ($char -eq '"' -and -not $escaped) { $quoted = -not $quoted }
        if (-not $quoted) {
            if ($char -eq '{') { $depth++ }
            elseif ($char -eq '}') {
                $depth--
                if ($depth -eq 0) { return $Text.Substring($open + 1, $i - $open - 1) }
            }
        }
        $escaped = ($char -eq '\' -and -not $escaped)
        if ($char -ne '\') { $escaped = $false }
    }
    throw "Unclosed '$Name' block"
}

function Get-Numbers {
    param([string]$Text)
    if (-not $Text) { return @() }
    return @([regex]::Matches($Text, '(?<![A-Za-z0-9_])-?\d+') | ForEach-Object { [int]$_.Value })
}

function Add-Issue {
    param([string]$Code, [string]$File, [string]$Message)
    $script:issues.Add([pscustomobject]@{ code = $Code; file = $File; message = $Message })
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$definitionPath = Join-Path $rootPath 'map/definition.csv'
$statesPath = Join-Path $rootPath 'history/states'
$regionsPath = Join-Path $rootPath 'map/strategicregions'
foreach ($required in @($definitionPath, $statesPath, $regionsPath)) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing required map path: $required" }
}

$issues = [System.Collections.Generic.List[object]]::new()
$provinceIds = [System.Collections.Generic.HashSet[int]]::new()
$colors = @{}
foreach ($line in [System.IO.File]::ReadLines($definitionPath)) {
    $parts = $line.Split(';')
    if ($parts.Count -lt 4 -or $parts[0] -notmatch '^\d+$') { continue }
    $id = [int]$parts[0]
    if (-not $provinceIds.Add($id)) {
        Add-Issue 'duplicate-definition-id' $definitionPath "Province ID $id occurs more than once."
    }
    $rgb = "$($parts[1]),$($parts[2]),$($parts[3])"
    if ($colors.ContainsKey($rgb)) {
        Add-Issue 'duplicate-definition-color' $definitionPath "RGB $rgb is shared by provinces $($colors[$rgb]) and $id."
    } else { $colors[$rgb] = $id }
}

$stateIds = [System.Collections.Generic.HashSet[int]]::new()
$provinceOwners = @{}
$stateFiles = @(Get-ChildItem -LiteralPath $statesPath -Filter '*.txt' -File -Recurse)
foreach ($file in $stateFiles) {
    $text = Get-CleanText $file.FullName
    $idMatch = [regex]::Match($text, '(?m)^\s*id\s*=\s*(\d+)\b')
    if (-not $idMatch.Success) { Add-Issue 'missing-state-id' $file.FullName 'No numeric root state ID was found.'; continue }
    $stateId = [int]$idMatch.Groups[1].Value
    if (-not $stateIds.Add($stateId)) { Add-Issue 'duplicate-state-id' $file.FullName "State ID $stateId occurs more than once." }

    $stateProvinceSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($province in (Get-Numbers (Get-NamedBlock $text 'provinces'))) {
        [void]$stateProvinceSet.Add($province)
        if (-not $provinceIds.Contains($province)) { Add-Issue 'undefined-state-province' $file.FullName "State $stateId references undefined province $province." }
        if ($provinceOwners.ContainsKey($province)) { Add-Issue 'duplicate-state-province' $file.FullName "Province $province is assigned to states $($provinceOwners[$province]) and $stateId." }
        else { $provinceOwners[$province] = $stateId }
    }

    $history = Get-NamedBlock $text 'history'
    foreach ($vpMatch in [regex]::Matches([string]$history, '\bvictory_points\s*=\s*\{\s*(\d+)\s+[-+]?\d+(?:\.\d+)?\s*\}')) {
        $vp = [int]$vpMatch.Groups[1].Value
        if (-not $provinceIds.Contains($vp)) { Add-Issue 'undefined-vp-province' $file.FullName "State $stateId gives victory points to undefined province $vp." }
        elseif (-not $stateProvinceSet.Contains($vp)) { Add-Issue 'vp-outside-state' $file.FullName "Victory-point province $vp is not in state $stateId." }
    }
}

$regionIds = [System.Collections.Generic.HashSet[int]]::new()
$regionOwners = @{}
$regionFiles = @(Get-ChildItem -LiteralPath $regionsPath -Filter '*.txt' -File -Recurse)
foreach ($file in $regionFiles) {
    $text = Get-CleanText $file.FullName
    $idMatch = [regex]::Match($text, '(?m)^\s*id\s*=\s*(\d+)\b')
    if (-not $idMatch.Success) { Add-Issue 'missing-region-id' $file.FullName 'No numeric root strategic-region ID was found.'; continue }
    $regionId = [int]$idMatch.Groups[1].Value
    if (-not $regionIds.Add($regionId)) { Add-Issue 'duplicate-region-id' $file.FullName "Strategic-region ID $regionId occurs more than once." }
    foreach ($province in (Get-Numbers (Get-NamedBlock $text 'provinces'))) {
        if (-not $provinceIds.Contains($province)) { Add-Issue 'undefined-region-province' $file.FullName "Region $regionId references undefined province $province." }
        if ($regionOwners.ContainsKey($province)) { Add-Issue 'duplicate-region-province' $file.FullName "Province $province is assigned to regions $($regionOwners[$province]) and $regionId." }
        else { $regionOwners[$province] = $regionId }
    }
}

$countryPath = Join-Path $rootPath 'history/countries'
if (Test-Path -LiteralPath $countryPath) {
    foreach ($file in Get-ChildItem -LiteralPath $countryPath -Filter '*.txt' -File -Recurse) {
        $capital = [regex]::Match((Get-CleanText $file.FullName), '(?m)^\s*capital\s*=\s*(\d+)\b')
        if ($capital.Success -and -not $stateIds.Contains([int]$capital.Groups[1].Value)) {
            Add-Issue 'undefined-country-capital' $file.FullName "Capital state $($capital.Groups[1].Value) is not defined."
        }
    }
}

$orderedIssues = @($issues | Sort-Object code, file, message)
$result = [ordered]@{
    root = $rootPath
    definition_provinces = $provinceIds.Count
    state_files = $stateFiles.Count
    state_ids = $stateIds.Count
    strategic_region_files = $regionFiles.Count
    strategic_region_ids = $regionIds.Count
    issue_count = $orderedIssues.Count
    issues = $orderedIssues
}
$json = $result | ConvertTo-Json -Depth 5
if ($OutputPath) {
    $fullOutput = [System.IO.Path]::GetFullPath($OutputPath)
    if ((Test-Path -LiteralPath $fullOutput) -and -not $Force) { throw "Output already exists. Use -Force to replace it: $fullOutput" }
    $parent = Split-Path -Parent $fullOutput
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        [void](New-Item -ItemType Directory -Path $parent)
    }
    [System.IO.File]::WriteAllText($fullOutput, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}
if ($AsJson) { $json; return }
"Root: $rootPath"
"Definitions: $($provinceIds.Count) provinces; $($stateIds.Count) states; $($regionIds.Count) strategic regions"
"Issues: $($orderedIssues.Count)"
if ($orderedIssues.Count -gt 0) { $orderedIssues | Format-Table code, file, message -Wrap -AutoSize }
