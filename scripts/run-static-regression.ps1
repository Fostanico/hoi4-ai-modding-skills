[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$doctor = Join-Path $repo 'skills\hoi4-review-debug\scripts\audit-hoi4-mod.ps1'
$mediaDoctor = Join-Path $repo 'skills\hoi4-review-debug\scripts\audit-media-footprint.ps1'
$fixture = Join-Path $repo '.validation-fixture\mod-doctor'
$suppressions = Join-Path $repo '.validation-fixture\mod-doctor-suppressions.json'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("hoi4-skills-regression-" + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($tempRoot)

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "Regression assertion failed: $Message" }
}

try {
    & python (Join-Path $repo 'scripts\validate-evals.py')
    if ($LASTEXITCODE -ne 0) { throw 'Eval dataset validation failed.' }
    & python (Join-Path $repo 'scripts\validate-skills.py')
    if ($LASTEXITCODE -ne 0) { throw 'Skill tree validation failed.' }
    & (Join-Path $repo 'skills\hoi4-content-builder\scripts\validate-template-manifest.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Template manifest validation failed.' }

    foreach ($script in Get-ChildItem -LiteralPath $repo -Recurse -File -Filter '*.ps1' | Where-Object { $_.FullName -notmatch '[\\/]dist[\\/]' }) {
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { throw "PowerShell parse failure in $($script.FullName): $($parseErrors[0].Message)" }
    }

    $validator = Join-Path $repo 'skills\hoi4-pdx-modding\scripts\validate-hoi4.ps1'
    & $validator -ModRoot $repo -Paths @(
        'skills\hoi4-content-builder\assets\kits\technology-equipment-chain',
        'skills\hoi4-content-builder\assets\kits\game-rule-startup'
    )
    if ($LASTEXITCODE -ne 0) { throw 'New multi-file kit validation failed.' }

    $baselinePath = Join-Path $tempRoot 'baseline.json'
    & $doctor -ModRoot $fixture -AuditMedia -Format Json -OutputPath $baselinePath
    $baseline = [IO.File]::ReadAllText($baselinePath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    Assert-True ($baseline.schemaVersion -eq 2) 'Doctor JSON schema must be 2.'
    Assert-True (@($baseline.findings | Where-Object { $_.code -eq 'MISSING_EVENT_TARGET_UNVERIFIED' }).Count -eq 1) 'Fixture must expose one missing event target.'
    Assert-True ($baseline.media.exactDuplicateGroups.Count -eq 1) 'Fixture must expose one exact media duplicate group.'
    Assert-True (@($baseline.findings | Where-Object { $_.certainty -notin @('confirmed', 'lead') }).Count -eq 0) 'Every finding needs a certainty class.'

    $delta = (& $doctor -ModRoot $fixture -BaselinePath $baselinePath -Format Json | ConvertFrom-Json)
    Assert-True ($delta.summary.baselineSuppressed -gt 0) 'Baseline comparison must suppress existing findings.'
    Assert-True ($delta.findings.Count -eq 0) 'An unchanged fixture should have no new findings against its own baseline.'

    $policy = (& $doctor -ModRoot $fixture -SuppressionsPath $suppressions -Format Json | ConvertFrom-Json)
    Assert-True ($policy.summary.policySuppressed -eq 1) 'Suppression policy must filter the missing event finding.'
    Assert-True (@($policy.findings | Where-Object { $_.code -eq 'MISSING_EVENT_TARGET_UNVERIFIED' }).Count -eq 0) 'Suppressed finding must not remain in output.'

    $userData = Join-Path $tempRoot 'user-data'
    $descriptorDirectory = Join-Path $userData 'mod'
    $dependencyRoot = Join-Path $tempRoot 'dependency'
    [void][IO.Directory]::CreateDirectory($descriptorDirectory)
    [void][IO.Directory]::CreateDirectory((Join-Path $dependencyRoot 'events'))
    [IO.File]::WriteAllText((Join-Path $userData 'dlc_load.json'), '{"enabled_mods":["mod/fixture-dependency.mod"],"disabled_dlcs":[]}', [Text.UTF8Encoding]::new($false))
    $descriptorText = 'name="Fixture dependency"' + [Environment]::NewLine + 'path="' + $dependencyRoot.Replace('\', '/') + '"'
    [IO.File]::WriteAllText((Join-Path $descriptorDirectory 'fixture-dependency.mod'), $descriptorText, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $dependencyRoot 'events\FIX_dependency.txt'), "add_namespace = FIX`ncountry_event = { id = FIX.missing is_triggered_only = yes }", [Text.UTF8Encoding]::new($false))
    $playset = (& $doctor -ModRoot $fixture -AutoResolvePlayset -UserDataRoot $userData -Format Json | ConvertFrom-Json)
    Assert-True ($playset.roots.dependencies.Count -eq 1) 'Playset resolution must add the enabled dependency.'
    Assert-True ($playset.roots.playsetDescriptors.Count -eq 1) 'Playset resolution must record the descriptor.'
    Assert-True (@($playset.findings | Where-Object { $_.code -like 'MISSING_EVENT_TARGET*' }).Count -eq 0) 'Resolved dependency must satisfy the event target.'

    $changedRoot = Join-Path $tempRoot 'changed-mod'
    Copy-Item -LiteralPath $fixture -Destination $changedRoot -Recurse
    & git -C $changedRoot init --quiet
    & git -C $changedRoot config user.email 'fixture@example.invalid'
    & git -C $changedRoot config user.name 'Regression Fixture'
    & git -C $changedRoot config core.autocrlf false
    & git -C $changedRoot config core.safecrlf false
    & git -C $changedRoot add .
    & git -C $changedRoot commit --quiet -m baseline
    [IO.File]::AppendAllText((Join-Path $changedRoot 'events\FIX_events.txt'), "`n# changed-only fixture`n", [Text.UTF8Encoding]::new($false))
    $changed = (& $doctor -ModRoot $changedRoot -ChangedOnly -GitBase HEAD -Format Json | ConvertFrom-Json)
    Assert-True ($changed.mode.changedOnly) 'Changed-only mode must be recorded.'
    Assert-True ($changed.findings.Count -gt 0) 'Changed-only audit must retain findings attached to a changed file.'

    $sarif = (& $doctor -ModRoot $fixture -Format Sarif | ConvertFrom-Json)
    Assert-True ($sarif.version -eq '2.1.0') 'SARIF version must be 2.1.0.'
    Assert-True ($sarif.runs[0].results.Count -gt 0) 'SARIF must contain results.'

    $media = (& $mediaDoctor -ModRoot $fixture -Format Json | ConvertFrom-Json)
    Assert-True ($media.summary.exactDuplicateGroups -eq 1) 'Media audit must find the duplicate fixture files.'
    Assert-True ($media.summary.signatureMismatches -eq 2) 'Fixture pseudo-PNG files must be reported as signature mismatches.'

    Write-Output 'All static regression checks passed.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
