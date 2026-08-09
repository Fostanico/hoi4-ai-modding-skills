[CmdletBinding()]
param([string]$SkillRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SkillRoot)) { $SkillRoot = Split-Path -Parent $PSScriptRoot }
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path.TrimEnd('\', '/')
$manifestPath = Join-Path $SkillRoot 'assets\template-manifest.json'
$manifest = [IO.File]::ReadAllText($manifestPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
$errors = [Collections.Generic.List[string]]::new()
if ($manifest.schemaVersion -ne 1) { $errors.Add('schemaVersion must be 1.') }
if ($manifest.target.version -ne '1.19.2.0' -or $manifest.target.build -ne 'd245') { $errors.Add('Target version/build must be explicit and current for this catalog.') }
$checkIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($check in @($manifest.checkDefinitions)) {
    if ([string]::IsNullOrWhiteSpace([string]$check.id) -or [string]::IsNullOrWhiteSpace([string]$check.meaning)) { $errors.Add('Every check definition requires id and meaning.'); continue }
    if (-not $checkIds.Add([string]$check.id)) { $errors.Add("Duplicate check id: $($check.id)") }
}
$ids = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$listedPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($resource in @($manifest.resources)) {
    if (-not $ids.Add([string]$resource.id)) { $errors.Add("Duplicate resource id: $($resource.id)") }
    foreach ($field in @('kind', 'catalogKey', 'intendedUse')) { if ([string]::IsNullOrWhiteSpace([string]$resource.$field)) { $errors.Add("Resource '$($resource.id)' is missing $field.") } }
    if ($resource.verification.staticStatus -ne 'verified_against_catalogued_sources') { $errors.Add("Resource '$($resource.id)' has an invalid static status.") }
    if ([string]::IsNullOrWhiteSpace([string]$resource.verification.verifiedOn)) { $errors.Add("Resource '$($resource.id)' has no verification date.") }
    foreach ($check in @($resource.requiredChecks)) { if (-not $checkIds.Contains([string]$check)) { $errors.Add("Resource '$($resource.id)' uses unknown check '$check'.") } }
    foreach ($path in @($resource.paths)) {
        $normalized = ([string]$path).Replace('\', '/')
        if (-not $listedPaths.Add($normalized)) { $errors.Add("Manifest path is listed more than once: $normalized") }
        if (-not (Test-Path -LiteralPath (Join-Path $SkillRoot $normalized.Replace('/', '\')) -PathType Leaf)) { $errors.Add("Manifest path does not exist: $normalized") }
    }
}
$actualPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($directory in @('assets\templates', 'assets\kits')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $SkillRoot $directory) -File -Recurse) { [void]$actualPaths.Add($file.FullName.Substring($SkillRoot.Length + 1).Replace('\', '/')) }
}
foreach ($path in $actualPaths) { if (-not $listedPaths.Contains($path)) { $errors.Add("File is missing from manifest: $path") } }
foreach ($path in $listedPaths) { if (-not $actualPaths.Contains($path)) { $errors.Add("Manifest contains a non-template path: $path") } }
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "Validated $($manifest.resources.Count) resources and $($listedPaths.Count) template files."
