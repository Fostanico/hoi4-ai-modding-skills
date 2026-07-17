[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ModRoot,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$root = if ($ModRoot) {
    [IO.Path]::GetFullPath($ModRoot)
} else {
    $gitRoot = (git rev-parse --show-toplevel 2>$null)
    if (-not $gitRoot) { throw 'Pass -ModRoot or run inside a Git repository.' }
    [IO.Path]::GetFullPath($gitRoot.Trim())
}

if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Mod root not found: $root"
}

$issues = [Collections.Generic.List[object]]::new()
$entriesByLanguage = @{}
$functionCounts = @{}
$variableCounts = @{}
$iconCounts = @{}
$sectionSign = [char]0x00A7
$poundSign = [char]0x00A3
$validColorChars = '!CLWBGRbgYHTO0123456789t'
$colorPattern = [regex]::Escape([string]$sectionSign) + '(.)'

function Add-Issue {
    param(
        [string]$Severity,
        [string]$File,
        [int]$Line,
        [string]$Code,
        [string]$Message
    )

    $issues.Add([pscustomobject]@{
        Severity = $Severity
        File = $File
        Line = $Line
        Code = $Code
        Message = $Message
    })
}

function Add-Count {
    param([hashtable]$Table, [string]$Token)
    if ($Table.ContainsKey($Token)) { $Table[$Token]++ } else { $Table[$Token] = 1 }
}

$files = @(Get-ChildItem -LiteralPath $root -Recurse -Filter '*.yml' -File | Where-Object {
    $_.FullName -notmatch '[\\/]\.git[\\/]'
} | Sort-Object FullName)

foreach ($file in $files) {
    $rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    $relative = if ($file.FullName.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        $file.FullName.Substring($rootPrefix.Length)
    } else {
        $file.FullName
    }
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $hasBom = $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if (-not $hasBom) {
        Add-Issue Error $relative 1 'missing-bom' 'Localisation must be UTF-8 with BOM.'
    }

    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ($hasBom -and $text.Length -gt 0) { $text = $text.Substring(1) }
    $lines = $text -split "`r?`n"
    $firstContent = $lines | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 1
    $headerMatch = [regex]::Match([string]$firstContent, '^l_([a-z_]+):$')
    $pathMatch = [regex]::Match($relative, '(?i)[\\/]localisation[\\/]([^\\/]+)[\\/]')
    $suffixMatch = [regex]::Match($file.Name, '(?i)_l_([a-z_]+)\.yml$')

    if (-not $headerMatch.Success) {
        Add-Issue Error $relative 1 'invalid-header' 'First content line must be l_<language>:.'
        $language = '<unknown>'
    } else {
        $language = $headerMatch.Groups[1].Value.ToLowerInvariant()
    }

    if (-not $suffixMatch.Success) {
        Add-Issue Warning $relative 1 'nonstandard-suffix' 'Filename does not end in _l_<language>.yml.'
    } elseif ($language -ne '<unknown>' -and
        $suffixMatch.Groups[1].Value.ToLowerInvariant() -ne $language) {
        Add-Issue Error $relative 1 'suffix-header-mismatch' 'Filename language and header language differ.'
    }

    if ($pathMatch.Success -and $language -ne '<unknown>' -and
        $pathMatch.Groups[1].Value.ToLowerInvariant() -ne $language) {
        Add-Issue Error $relative 1 'path-header-mismatch' 'Directory language and header language differ.'
    }

    if (-not $entriesByLanguage.ContainsKey($language)) {
        $entriesByLanguage[$language] = @{}
    }
    $globalEntries = $entriesByLanguage[$language]
    $fileEntries = @{}

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineNumber = $index + 1
        $line = $lines[$index]
        if ($line -notmatch '^\s+([^\s:#]+):(?:\d+)?\s*"(.*)"\s*(?:#.*)?$') { continue }

        $key = $Matches[1]
        $value = $Matches[2]
        $entry = [pscustomobject]@{ File = $relative; Line = $lineNumber; Value = $value }

        if ($fileEntries.ContainsKey($key)) {
            $previous = $fileEntries[$key]
            $kind = if ($previous.Value -ceq $value) { 'exact duplicate' } else { 'conflicting duplicate' }
            Add-Issue Error $relative $lineNumber 'duplicate-in-file' "$kind key '$key'; first at line $($previous.Line)."
        } else {
            $fileEntries[$key] = $entry
        }

        if ($globalEntries.ContainsKey($key)) {
            $previous = $globalEntries[$key]
            $kind = if ($previous.Value -ceq $value) { 'exact duplicate' } else { 'same-key/different-value collision' }
            Add-Issue Warning $relative $lineNumber 'duplicate-across-files' "$kind '$key'; also $($previous.File):$($previous.Line)."
        } else {
            $globalEntries[$key] = $entry
        }

        foreach ($match in [regex]::Matches($value, $colorPattern)) {
            $code = $match.Groups[1].Value
            if (-not $validColorChars.Contains($code)) {
                Add-Issue Error $relative $lineNumber 'unknown-colour' "Unknown colour marker after section sign: '$code'."
                continue
            }
            if ($code -ne '!' -and
                $value.IndexOf(([string]$sectionSign + '!'), $match.Index + 2, [StringComparison]::Ordinal) -lt 0) {
                Add-Issue Warning $relative $lineNumber 'colour-not-reset' "Colour marker '$code' has no later reset in this value."
            }
        }
        if ($value.EndsWith([string]$sectionSign, [StringComparison]::Ordinal)) {
            Add-Issue Error $relative $lineNumber 'bare-section-sign' 'Value ends with a bare section sign.'
        }

        $bracketText = $value.Replace('[[', '')
        $opens = ([regex]::Matches($bracketText, '\[')).Count
        $closes = ([regex]::Matches($bracketText, '\]')).Count
        if ($opens -ne $closes) {
            Add-Issue Warning $relative $lineNumber 'unbalanced-brackets' "Dynamic-localisation brackets differ: $opens opening, $closes closing."
        }

        $dollarText = $value.Replace('$$', '')
        $dollarCount = ([regex]::Matches($dollarText, '\$')).Count
        if (($dollarCount % 2) -ne 0) {
            Add-Issue Warning $relative $lineNumber 'unbalanced-dollar' 'Nested key or bound parameter has an unmatched dollar sign.'
        }

        foreach ($match in [regex]::Matches($value, '\[(?:\?)?[^\]\s]+\.(Get[A-Za-z0-9_]+)\]')) {
            Add-Count $functionCounts $match.Groups[1].Value
        }
        foreach ($match in [regex]::Matches($value, '\[\?([^\]]+)\]')) {
            Add-Count $variableCounts $match.Groups[1].Value
        }
        $iconPattern = [regex]::Escape([string]$poundSign) + '([A-Za-z0-9_]+(?:\|\d+)?)'
        foreach ($match in [regex]::Matches($value, $iconPattern)) {
            Add-Count $iconCounts $match.Groups[1].Value
        }
    }
}

$errors = @($issues | Where-Object Severity -eq 'Error')
$warnings = @($issues | Where-Object Severity -eq 'Warning')
$result = [pscustomobject]@{
    Root = $root
    Files = $files.Count
    Languages = @($entriesByLanguage.Keys | Sort-Object)
    Errors = $errors.Count
    Warnings = $warnings.Count
    Issues = @($issues)
    Functions = @($functionCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ Token = $_.Name; Count = $_.Value }
    })
    Variables = @($variableCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ Token = $_.Name; Count = $_.Value }
    })
    Icons = @($iconCounts.GetEnumerator() | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ Token = $_.Name; Count = $_.Value }
    })
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 6
} else {
    foreach ($issue in $issues | Sort-Object Severity, File, Line, Code) {
        $location = if ($issue.Line -gt 0) { "$($issue.File):$($issue.Line)" } else { $issue.File }
        Write-Host "[$($issue.Severity)] $location [$($issue.Code)] $($issue.Message)"
    }
    Write-Host "Audited $($files.Count) localisation file(s): $($errors.Count) error(s), $($warnings.Count) warning(s)."
    if ($functionCounts.Count) { Write-Host "Functions found: $($functionCounts.Count) unique." }
    if ($variableCounts.Count) { Write-Host "Formatted variables found: $($variableCounts.Count) unique." }
    if ($iconCounts.Count) { Write-Host "Text icons found: $($iconCounts.Count) unique." }
}

if ($errors.Count -gt 0) { exit 1 }
$global:LASTEXITCODE = 0
