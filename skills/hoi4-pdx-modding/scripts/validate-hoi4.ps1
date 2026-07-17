[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$Paths,

    [switch]$All,

    [string]$ModRoot,

    # Retained so older validation commands remain callable. Suffixes are
    # rejected unconditionally.
    [switch]$ForbidLocalisationVersionSuffix
)

$ErrorActionPreference = 'Stop'
$repo = if ($ModRoot) {
    [IO.Path]::GetFullPath($ModRoot)
} else {
    $gitRoot = (git rev-parse --show-toplevel 2>$null)
    if (-not $gitRoot) { throw 'Pass -ModRoot or run inside a Git repository.' }
    [IO.Path]::GetFullPath($gitRoot.Trim())
}

function Get-CandidateFiles {
    if ($All) {
        return Get-ChildItem -LiteralPath $repo -Recurse -File | Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]' -and
            $_.Extension -in '.txt', '.gui', '.gfx', '.yml'
        } | ForEach-Object FullName
    }

    if ($Paths) {
        return $Paths | ForEach-Object {
            $candidate = if ([IO.Path]::IsPathRooted($_)) { $_ } else { Join-Path $repo $_ }
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                [IO.Path]::GetFullPath($candidate)
            } elseif (Test-Path -LiteralPath $candidate -PathType Container) {
                Get-ChildItem -LiteralPath $candidate -Recurse -File | Where-Object {
                    $_.Extension -in '.txt', '.gui', '.gfx', '.yml'
                } | ForEach-Object FullName
            } else {
                Write-Warning "Path not found: $_"
            }
        }
    }

    if ($ModRoot) {
        return Get-ChildItem -LiteralPath $repo -Recurse -File | Where-Object {
            $_.Extension -in '.txt', '.gui', '.gfx', '.yml'
        } | ForEach-Object FullName
    }

    $changed = @(
        git diff --name-only --diff-filter=ACMR HEAD --
        git ls-files --others --exclude-standard
    ) | Where-Object { $_ -match '\.(txt|gui|gfx|yml)$' }
    return $changed | ForEach-Object { Join-Path $repo $_ }
}

function Get-BraceDelta {
    param([string]$Text)

    $depth = 0
    $inQuote = $false
    $escaped = $false
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $char = $Text[$i]
        if ($escaped) {
            $escaped = $false
            continue
        }
        if ($inQuote -and $char -eq '\') {
            $escaped = $true
            continue
        }
        if ($char -eq '"') {
            $inQuote = -not $inQuote
            continue
        }
        if (-not $inQuote -and $char -eq '#') {
            while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ }
            continue
        }
        if (-not $inQuote) {
            if ($char -eq '{') { $depth++ }
            elseif ($char -eq '}') { $depth-- }
        }
    }
    return $depth
}

function Remove-PdxComments {
    param([string]$Text)

    return (($Text -split "`r?`n") | ForEach-Object {
        $line = $_
        $inQuote = $false
        for ($i = 0; $i -lt $line.Length; $i++) {
            if ($line[$i] -eq '"') { $inQuote = -not $inQuote }
            if (-not $inQuote -and $line[$i] -eq '#') {
                $line = $line.Substring(0, $i)
                break
            }
        }
        $line
    }) -join "`n"
}

$files = @(Get-CandidateFiles | Sort-Object -Unique)
if ($files.Count -eq 0) {
    Write-Host 'No changed HOI4 script or localisation files to validate.'
    exit 0
}

$errors = [Collections.Generic.List[string]]::new()
$warnings = [Collections.Generic.List[string]]::new()
$allLocKeys = @{}

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
    $fullFile = [IO.Path]::GetFullPath($file)
    $repoPrefix = $repo.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $relative = if ($fullFile.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $fullFile.Substring($repoPrefix.Length)
    } else {
        $fullFile
    }
    $bytes = [IO.File]::ReadAllBytes($file)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ($hasBom) { $text = $text.Substring(1) }

    if ($text -match '(?m)^(<<<<<<<|=======|>>>>>>>)') {
        $errors.Add("${relative}: contains a merge-conflict marker")
    }

    $extension = [IO.Path]::GetExtension($file).ToLowerInvariant()
    if ($extension -in '.txt', '.gui', '.gfx') {
        if ($hasBom) {
            $errors.Add("${relative}: PDX script file has a UTF-8 BOM")
        }
        $delta = Get-BraceDelta -Text $text
        if ($delta -ne 0) {
            $errors.Add("${relative}: brace balance is $delta")
        }
        $scriptText = Remove-PdxComments -Text $text
        if ($scriptText -match '(?im)^\s*NOR\s*=\s*\{') {
            $warnings.Add("${relative}: contains NOR; HOI4 trigger logic normally needs NOT = { OR = { ... } }")
        }
        if ($scriptText -match '(?is)check_variable\s*=\s*\{[^}]*?(?:>=|<=)') {
            $warnings.Add("${relative}: check_variable uses >= or <=; verify with explicit current-vanilla comparisons")
        }
        if ($scriptText -match '(?im)^\s*dirty\s*=\s*(?:global\.)?(?:date|num_days)\b') {
            $warnings.Add("${relative}: scripted GUI dirty value appears date-driven and may force frequent redraws")
        }
        continue
    }

    if (-not $hasBom) {
        $errors.Add("${relative}: localisation file is missing UTF-8 BOM")
    }
    $lines = $text -split "`r?`n"
    $firstContent = $lines | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 1
    $languageMatch = [regex]::Match($relative, '(?i)[\\/]localisation[\\/]([^\\/]+)[\\/]')
    $headerMatch = [regex]::Match($firstContent, '^l_([a-z_]+):$')
    $languageId = if ($languageMatch.Success) {
        $languageMatch.Groups[1].Value.ToLowerInvariant()
    } elseif ($headerMatch.Success) {
        $headerMatch.Groups[1].Value.ToLowerInvariant()
    } else {
        '<unknown>'
    }
    if ($languageId -ne '<unknown>') {
        $expectedHeader = 'l_' + $languageMatch.Groups[1].Value + ':'
        if (-not $languageMatch.Success) { $expectedHeader = 'l_' + $languageId + ':' }
        if ($firstContent -ne $expectedHeader) {
            $errors.Add("${relative}: expected ${expectedHeader} as the language header")
        }
    }

    $fileKeys = @{}
    for ($lineNumber = 0; $lineNumber -lt $lines.Count; $lineNumber++) {
        $line = $lines[$lineNumber]
        if ($line -match '^\s+([^\s:#]+):(\d+)\s*"') {
            $errors.Add("${relative}:$($lineNumber + 1): key '$($Matches[1])' uses forbidden version suffix :$($Matches[2]); use an unversioned key")
        }
        if ($line -notmatch '^\s+([^\s:#]+):\s*"(.*)"\s*(?:#.*)?$') { continue }
        $key = $Matches[1]
        $value = $Matches[2]
        $entry = [pscustomobject]@{ File = $relative; Line = $lineNumber + 1; Value = $value }
        if ($fileKeys.ContainsKey($key)) {
            $previous = $fileKeys[$key]
            $kind = if ($previous.Value -ceq $value) { 'exact duplicate' } else { 'conflicting duplicate' }
            $errors.Add("${relative}:$($lineNumber + 1): $kind key '$key' (first at line $($previous.Line))")
        } else {
            $fileKeys[$key] = $entry
        }
        $globalKey = "${languageId}|${key}"
        if ($allLocKeys.ContainsKey($globalKey)) {
            $previous = $allLocKeys[$globalKey]
            $kind = if ($previous.Value -ceq $value) { 'exact duplicate' } else { 'same-key/different-value collision' }
            $warnings.Add("${relative}:$($lineNumber + 1): $kind '$key' (also $($previous.File):$($previous.Line))")
        } else {
            $allLocKeys[$globalKey] = $entry
        }
    }
}

foreach ($warning in $warnings) { Write-Warning $warning }
foreach ($error in $errors) { Write-Error $error -ErrorAction Continue }

Write-Host "Validated $($files.Count) file(s): $($errors.Count) error(s), $($warnings.Count) warning(s)."
if ($errors.Count -gt 0) { exit 1 }
$global:LASTEXITCODE = 0
