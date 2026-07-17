[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModRoot,
    [Parameter(Mandatory = $true)]
    [string]$VanillaRoot,
    [switch]$AsJson,
    [ValidateRange(0, 100000)]
    [int]$Limit = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelativePath {
    param([string]$BasePath, [string]$ChildPath)
    $baseFull = [System.IO.Path]::GetFullPath($BasePath).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $childFull = [System.IO.Path]::GetFullPath($ChildPath)
    if (-not $childFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside base directory: $childFull"
    }
    return $childFull.Substring($baseFull.Length).Replace('\', '/')
}

function Get-Risk {
    param([string]$RelativePath)
    if ($RelativePath -match '^(map/|history/states/|history/general/|interface/frontendmainview\.gui$|common/bookmarks/|common/frontend/|common/units/|common/defines/|common/special_projects/|common/factions/)') {
        return 'high'
    }
    if ($RelativePath -match '^(interface/|history/|common/|events/|music/|gfx/FX/)') {
        return 'medium'
    }
    return 'normal'
}

$mod = (Resolve-Path -LiteralPath $ModRoot).Path
$vanilla = (Resolve-Path -LiteralPath $VanillaRoot).Path
if (-not (Get-Item -LiteralPath $mod).PSIsContainer) { throw "ModRoot is not a directory: $mod" }
if (-not (Get-Item -LiteralPath $vanilla).PSIsContainer) { throw "VanillaRoot is not a directory: $vanilla" }

$descriptorFiles = [System.Collections.Generic.List[object]]::new()
$descriptorPath = Join-Path $mod 'descriptor.mod'
if (Test-Path -LiteralPath $descriptorPath -PathType Leaf) { $descriptorFiles.Add((Get-Item -LiteralPath $descriptorPath)) }
foreach ($candidate in Get-ChildItem -LiteralPath $mod -File -Filter '*.mod') { $descriptorFiles.Add($candidate) }

$replacePaths = [System.Collections.Generic.List[object]]::new()
foreach ($descriptor in $descriptorFiles) {
    $descriptorText = [System.IO.File]::ReadAllText($descriptor.FullName)
    foreach ($match in [regex]::Matches($descriptorText, '(?m)^\s*replace_path\s*=\s*"([^"]+)"')) {
        $replacePaths.Add([pscustomobject]@{
            descriptor = Get-RelativePath $mod $descriptor.FullName
            path = $match.Groups[1].Value.Replace('\', '/')
        })
    }
}

$excludedRoots = @('.git/', '.agents/', 'tmp/')
$overrides = [System.Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem -LiteralPath $mod -File -Recurse) {
    $relative = Get-RelativePath $mod $file.FullName
    if ($excludedRoots | Where-Object { $relative.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase) }) { continue }
    if ($relative -eq 'descriptor.mod' -or $relative.EndsWith('.mod', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
    if ($file.Extension -ieq '.md') { continue }
    $vanillaPath = Join-Path $vanilla $relative
    if (-not (Test-Path -LiteralPath $vanillaPath -PathType Leaf)) { continue }

    $missingTokens = [System.Collections.Generic.List[string]]::new()
    if ($relative -ieq 'interface/frontendmainview.gui') {
        $modText = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($token in @('change_background', 'background_selection', 'available_background')) {
            if ($modText -notmatch "\b$([regex]::Escape($token))\b") { $missingTokens.Add($token) }
        }
    }
    if ($relative -ieq 'history/general/taog_hq_template.txt') {
        $modText = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($token in @('every_possible_country', 'is_army_hq', 'Thunder at Our Gates')) {
            if ($modText -notmatch [regex]::Escape($token)) { $missingTokens.Add($token) }
        }
    }

    $modHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $vanillaHash = (Get-FileHash -LiteralPath $vanillaPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $overrides.Add([pscustomobject]@{
        path = $relative
        risk = Get-Risk $relative
        mod_bytes = $file.Length
        vanilla_bytes = (Get-Item -LiteralPath $vanillaPath).Length
        identical = $modHash -eq $vanillaHash
        mod_sha256 = $modHash
        vanilla_sha256 = $vanillaHash
        missing_migration_tokens = @($missingTokens)
    })
}

$riskOrder = @{ high = 0; medium = 1; normal = 2 }
$ordered = @($overrides | Sort-Object @{ Expression = { $riskOrder[$_.risk] } }, path)
$missingGateCount = @($ordered | Where-Object { $_.missing_migration_tokens.Count -gt 0 }).Count
$result = [ordered]@{
    mod_root = $mod
    vanilla_root = $vanilla
    descriptor_files = @($descriptorFiles | ForEach-Object { Get-RelativePath $mod $_.FullName })
    replace_paths = @($replacePaths)
    exact_override_count = $ordered.Count
    identical_override_count = @($ordered | Where-Object identical).Count
    high_risk_override_count = @($ordered | Where-Object risk -eq 'high').Count
    missing_migration_gate_count = $missingGateCount
    overrides = $ordered
}

if ($AsJson) { $result | ConvertTo-Json -Depth 6; return }
"Mod root: $mod"
"Vanilla root: $vanilla"
"replace_path entries: $($replacePaths.Count)"
if ($replacePaths.Count -gt 0) { $replacePaths | Format-Table descriptor, path -AutoSize }
"Exact overrides: $($ordered.Count); high risk: $($result.high_risk_override_count); identical: $($result.identical_override_count)"
"Known migration gates missing: $missingGateCount"
$shown = if ($Limit -gt 0) { @($ordered | Select-Object -First $Limit) } else { $ordered }
if ($shown.Count -gt 0) {
    $shown | Select-Object risk, identical, path, @{ n = 'missing_tokens'; e = { $_.missing_migration_tokens -join ', ' } } |
        Format-Table -Wrap -AutoSize
}
if ($Limit -gt 0 -and $ordered.Count -gt $shown.Count) { "... $($ordered.Count - $shown.Count) additional overrides omitted by -Limit." }
