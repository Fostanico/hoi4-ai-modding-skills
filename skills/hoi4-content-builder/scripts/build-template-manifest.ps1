[CmdletBinding()]
param([string]$SkillRoot, [switch]$Force)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($SkillRoot)) { $SkillRoot = Split-Path -Parent $PSScriptRoot }
$SkillRoot = (Resolve-Path -LiteralPath $SkillRoot).Path.TrimEnd('\', '/')
$catalogPath = Join-Path $SkillRoot 'references\template-catalog.md'
$manifestPath = Join-Path $SkillRoot 'assets\template-manifest.json'
if ((Test-Path -LiteralPath $manifestPath) -and -not $Force) { throw "Manifest exists; use -Force to rebuild: $manifestPath" }

$catalog = @{}
foreach ($line in [IO.File]::ReadAllLines($catalogPath, [Text.Encoding]::UTF8)) {
    if ($line -match '^\| `([^`]+)` \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$') {
        $catalog[$Matches[1]] = [pscustomobject]@{ intendedUse = $Matches[2].Trim(); documentation = $Matches[3].Trim(); consumers = $Matches[4].Trim() }
    }
    elseif ($line -match '^\| `([^`]+)` \| ([^|]+) \|$') {
        $catalog[$Matches[1]] = [pscustomobject]@{ intendedUse = $Matches[2].Trim(); documentation = 'project engineering contract'; consumers = 'project guidance and handoff' }
    }
}

function Get-Entry {
    param([string]$CatalogKey, [string]$Kind, [IO.FileInfo[]]$Files)
    if (-not $catalog.ContainsKey($CatalogKey)) { throw "Template catalog has no row for '$CatalogKey'." }
    $record = $catalog[$CatalogKey]
    $checks = [Collections.Generic.List[string]]::new()
    foreach ($check in @('path_exists', 'placeholder_scan', 'encoding', 'cross_file_identifiers', 'current_consumer')) { $checks.Add($check) }
    if (@($Files | Where-Object { $_.Extension -eq '.yml' }).Count -gt 0) { $checks.Add('localisation_header_and_key_style') }
    if (@($Files | Where-Object { $_.Extension -in @('.gfx', '.asset') }).Count -gt 0) { $checks.Add('asset_registration_and_path_case') }
    if ($Kind -eq 'kit') { $checks.Add('whole_kit_static_validation'); $checks.Add('smallest_runtime_test') }
    return [pscustomobject]@{
        id = ($CatalogKey.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-'); kind = $Kind; catalogKey = $CatalogKey
        paths = @($Files | ForEach-Object { $_.FullName.Substring($SkillRoot.Length + 1).Replace('\', '/') } | Sort-Object)
        intendedUse = $record.intendedUse
        sourceEvidence = [pscustomobject]@{ installedDocumentation = $record.documentation; currentConsumers = $record.consumers }
        verification = [pscustomobject]@{
            targetGameVersion = '1.19.2.0'; targetBuild = 'd245'
            verifiedOn = if ($CatalogKey -eq 'kits/decision-category-cover') { '2026-08-14' } elseif ($CatalogKey -in @('kits/technology-equipment-chain', 'kits/game-rule-startup')) { '2026-08-09' } else { '2026-07-17' }
            staticStatus = 'verified_against_catalogued_sources'; runtimeStatus = 'required_after_placeholder_replacement'
        }
        requiredChecks = @($checks)
    }
}

$entries = [Collections.Generic.List[object]]::new()
$templateRoot = Join-Path $SkillRoot 'assets\templates'
foreach ($file in Get-ChildItem -LiteralPath $templateRoot -File | Sort-Object Name) { $entries.Add((Get-Entry -CatalogKey $file.Name -Kind 'template' -Files @($file))) }
$entries.Add((Get-Entry -CatalogKey 'localisation-advanced/*' -Kind 'template-set' -Files @(Get-ChildItem -LiteralPath (Join-Path $templateRoot 'localisation-advanced') -File -Recurse)))
$kitRoot = Join-Path $SkillRoot 'assets\kits'
foreach ($directory in Get-ChildItem -LiteralPath $kitRoot -Directory | Sort-Object Name) {
    $entries.Add((Get-Entry -CatalogKey ("kits/$($directory.Name)") -Kind 'kit' -Files @(Get-ChildItem -LiteralPath $directory.FullName -File -Recurse)))
}

$manifest = [pscustomobject]@{
    schemaVersion = 1
    target = [pscustomobject]@{ game = 'Hearts of Iron IV'; version = '1.19.2.0'; build = 'd245' }
    generatedFrom = 'references/template-catalog.md and assets/templates|kits'
    checkDefinitions = @(
        [pscustomobject]@{ id = 'path_exists'; meaning = 'Every listed file exists at the exact case-sensitive relative path.' },
        [pscustomobject]@{ id = 'placeholder_scan'; meaning = 'All MOD, sample tag, example ID, date, state, province, and asset placeholders are replaced deliberately.' },
        [pscustomobject]@{ id = 'encoding'; meaning = 'PDX files use UTF-8 without BOM; localisation follows its language header and project encoding policy.' },
        [pscustomobject]@{ id = 'cross_file_identifiers'; meaning = 'Definitions, callers, GFX names, asset paths, and localisation keys agree across every file in the resource.' },
        [pscustomobject]@{ id = 'current_consumer'; meaning = 'Version-sensitive fields are rechecked against the target build and exact enabled dependencies.' },
        [pscustomobject]@{ id = 'localisation_header_and_key_style'; meaning = 'Language header is correct and portable templates use key: "Text" without a numeric suffix.' },
        [pscustomobject]@{ id = 'asset_registration_and_path_case'; meaning = 'Registered names, consumer tokens, extensions, and on-disk path case match.' },
        [pscustomobject]@{ id = 'whole_kit_static_validation'; meaning = 'The copied kit passes the base validator as one cross-file unit.' },
        [pscustomobject]@{ id = 'smallest_runtime_test'; meaning = 'The customized kit receives the smallest relevant isolated in-game test after user consent.' }
    )
    resources = @($entries)
}
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 9), [Text.UTF8Encoding]::new($false))
Write-Output "Wrote $($entries.Count) resource entries to $manifestPath"
