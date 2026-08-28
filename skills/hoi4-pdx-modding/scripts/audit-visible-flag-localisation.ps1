[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ModRoot,
    [string[]]$AdditionalLocalisationRoot = @(),
    [string[]]$Languages = @('simp_chinese', 'english', 'japanese'),
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
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Mod root not found: $root" }

$languageSet = @{}
foreach ($language in $Languages) { $languageSet[$language.ToLowerInvariant()] = $true }

function Get-RelativePath {
    param([string]$Base, [string]$Path)
    $prefix = $Base.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $Path.Substring($prefix.Length) }
    return $Path
}

function Get-PdxTokens {
    param([string]$Text)
    $tokens = [Collections.Generic.List[object]]::new()
    $line = 1
    $i = 0
    while ($i -lt $Text.Length) {
        $char = $Text[$i]
        if ($char -eq "`n") { $line++; $i++; continue }
        if ([char]::IsWhiteSpace($char)) { $i++; continue }
        if ($char -eq '#') {
            while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ }
            continue
        }
        if ($char -eq '"') {
            $startLine = $line
            $builder = [Text.StringBuilder]::new()
            [void]$builder.Append($char)
            $i++
            $escaped = $false
            while ($i -lt $Text.Length) {
                $current = $Text[$i]
                [void]$builder.Append($current)
                if ($current -eq "`n") { $line++ }
                if ($current -eq '"' -and -not $escaped) { $i++; break }
                if ($current -eq '\' -and -not $escaped) { $escaped = $true } else { $escaped = $false }
                $i++
            }
            $tokens.Add([pscustomobject]@{ Value = $builder.ToString(); Line = $startLine })
            continue
        }
        if ($char -eq '{' -or $char -eq '}' -or $char -eq '=') {
            $tokens.Add([pscustomobject]@{ Value = [string]$char; Line = $line })
            $i++
            continue
        }
        $start = $i
        $startLine = $line
        while ($i -lt $Text.Length) {
            $current = $Text[$i]
            if ([char]::IsWhiteSpace($current) -or $current -eq '{' -or $current -eq '}' -or
                $current -eq '=' -or $current -eq '#' -or $current -eq '"') { break }
            $i++
        }
        if ($i -gt $start) {
            $tokens.Add([pscustomobject]@{ Value = $Text.Substring($start, $i - $start); Line = $startLine })
        } else { $i++ }
    }
    return $tokens.ToArray()
}

$localisationByLanguage = @{}
foreach ($language in $Languages) {
    $localisationByLanguage[$language.ToLowerInvariant()] = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
}

$locRoots = @($root) + @($AdditionalLocalisationRoot | ForEach-Object { [IO.Path]::GetFullPath($_) })
foreach ($locRoot in $locRoots | Select-Object -Unique) {
    if (-not (Test-Path -LiteralPath $locRoot -PathType Container)) { continue }
    $locFiles = Get-ChildItem -LiteralPath $locRoot -Recurse -Filter '*.yml' -File | Where-Object {
        $_.FullName -match '[\\/]localisation(?:_synced)?[\\/]'
    }
    foreach ($file in $locFiles) {
        $lines = [IO.File]::ReadAllLines($file.FullName, [Text.Encoding]::UTF8)
        $header = $lines | Where-Object { $_.Trim().Length -gt 0 } | Select-Object -First 1
        $headerMatch = [regex]::Match([string]$header, '^\ufeff?l_([a-z_]+):$')
        if (-not $headerMatch.Success) { continue }
        $language = $headerMatch.Groups[1].Value.ToLowerInvariant()
        if (-not $languageSet.ContainsKey($language)) { continue }
        foreach ($line in $lines) {
            $match = [regex]::Match($line, '^ ([^\s:#][^:]*):(?:\d+)?\s')
            if ($match.Success) { [void]$localisationByLanguage[$language].Add($match.Groups[1].Value) }
        }
    }
}

$requirementContexts = @(
    'available', 'allow', 'allowed', 'bypass', 'custom_cost_trigger',
    'cancel_trigger', 'abort_trigger', 'can_select', 'can_be_completed',
    'prerequisite', 'requirements'
)
$visibilityContexts = @('visible', 'show', 'show_if', 'potential')
$hiddenContexts = @('hidden_trigger', 'custom_trigger_tooltip')
$results = [Collections.Generic.List[object]]::new()

$scriptFiles = Get-ChildItem -LiteralPath $root -Recurse -Filter '*.txt' -File | Where-Object {
    $_.FullName -notmatch '[\\/]\.git[\\/]' -and
    $_.FullName -notmatch '[\\/]\.agents[\\/]' -and
    $_.FullName -notmatch '[\\/]\.cursor[\\/]'
} | Sort-Object FullName

foreach ($file in $scriptFiles) {
    $tokens = @(Get-PdxTokens ([IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)))
    $stack = [Collections.Generic.List[string]]::new()
    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $value = $tokens[$i].Value
        if ($value -eq '}') {
            if ($stack.Count -gt 0) { $stack.RemoveAt($stack.Count - 1) }
            continue
        }
        if ($value -eq '{') {
            $blockName = '<anonymous>'
            if ($i -ge 2 -and $tokens[$i - 1].Value -eq '=') { $blockName = $tokens[$i - 2].Value }
            $stack.Add($blockName)
            continue
        }
        if ($value -ne 'has_country_flag' -or $i + 2 -ge $tokens.Count -or $tokens[$i + 1].Value -ne '=') { continue }

        $flag = $null
        if ($tokens[$i + 2].Value -ne '{') {
            $flag = $tokens[$i + 2].Value.Trim('"')
        } else {
            $depth = 0
            for ($j = $i + 2; $j -lt $tokens.Count; $j++) {
                if ($tokens[$j].Value -eq '{') { $depth++; continue }
                if ($tokens[$j].Value -eq '}') {
                    $depth--
                    if ($depth -eq 0) { break }
                    continue
                }
                if ($depth -eq 1 -and $tokens[$j].Value -eq 'flag' -and $j + 2 -lt $tokens.Count -and
                    $tokens[$j + 1].Value -eq '=') {
                    $flag = $tokens[$j + 2].Value.Trim('"')
                    break
                }
            }
        }
        if (-not $flag -or $flag -match '^(THIS|ROOT|FROM|PREV|OWNER|CONTROLLER)$') { continue }

        $ancestors = @($stack.ToArray())
        $isHidden = @($ancestors | Where-Object { $hiddenContexts -contains $_ }).Count -gt 0
        $requirementContext = @($ancestors | Where-Object { $requirementContexts -contains $_ } | Select-Object -Last 1)
        $visibilityContext = @($ancestors | Where-Object { $visibilityContexts -contains $_ } | Select-Object -Last 1)
        $classification = if ($isHidden) {
            'hidden'
        } elseif ($requirementContext.Count -gt 0) {
            'exposed_requirement'
        } elseif ($visibilityContext.Count -gt 0) {
            'potential_visibility'
        } else { 'background' }
        if ($classification -eq 'background') { continue }

        $missing = [Collections.Generic.List[string]]::new()
        foreach ($language in $Languages) {
            $normalized = $language.ToLowerInvariant()
            if (-not $localisationByLanguage[$normalized].Contains($flag)) { $missing.Add($normalized) }
        }
        $context = if ($requirementContext.Count -gt 0) {
            [string]$requirementContext[0]
        } elseif ($visibilityContext.Count -gt 0) {
            [string]$visibilityContext[0]
        } else { [string]($ancestors | Select-Object -Last 1) }

        $results.Add([pscustomobject]@{
            File = Get-RelativePath $root $file.FullName
            Line = [int]$tokens[$i].Line
            Flag = $flag
            Context = $context
            Classification = $classification
            MissingLanguages = @($missing.ToArray())
        })
    }
}

$exposed = @($results | Where-Object Classification -eq 'exposed_requirement')
$potential = @($results | Where-Object Classification -eq 'potential_visibility')
$hidden = @($results | Where-Object Classification -eq 'hidden')
$missingExposed = @($exposed | Where-Object { $_.MissingLanguages.Count -gt 0 })
$missingPotential = @($potential | Where-Object { $_.MissingLanguages.Count -gt 0 })
$summary = [pscustomobject]@{
    ScriptFilesScanned = @($scriptFiles).Count
    LocalisationRoots = @($locRoots | Select-Object -Unique)
    Languages = @($Languages)
    ExposedRequirementOccurrences = $exposed.Count
    ExposedRequirementFlags = @($exposed.Flag | Sort-Object -Unique).Count
    MissingExposedOccurrences = $missingExposed.Count
    MissingExposedFlags = @($missingExposed.Flag | Sort-Object -Unique).Count
    PotentialVisibilityOccurrences = $potential.Count
    PotentialVisibilityFlags = @($potential.Flag | Sort-Object -Unique).Count
    MissingPotentialOccurrences = $missingPotential.Count
    MissingPotentialFlags = @($missingPotential.Flag | Sort-Object -Unique).Count
    HiddenOccurrences = $hidden.Count
}
$payload = [pscustomobject]@{
    Summary = $summary
    Findings = @($missingExposed + $missingPotential | Sort-Object File, Line, Flag)
    AllClassifiedReferences = @($results)
}

if ($AsJson) { $payload | ConvertTo-Json -Depth 8; return }
Write-Output ("Scanned {0} script file(s)." -f $summary.ScriptFilesScanned)
Write-Output ("Exposed requirement flags: {0} occurrence(s), {1} unique; missing localisation: {2} occurrence(s), {3} unique." -f `
    $summary.ExposedRequirementOccurrences, $summary.ExposedRequirementFlags,
    $summary.MissingExposedOccurrences, $summary.MissingExposedFlags)
Write-Output ("Potential visibility references: {0}; missing localisation: {1}. Hidden references: {2}." -f `
    $summary.PotentialVisibilityOccurrences, $summary.MissingPotentialOccurrences, $summary.HiddenOccurrences)
foreach ($finding in $payload.Findings) {
    Write-Output ("{0}:{1}: [{2}] {3} missing={4}" -f $finding.File, $finding.Line,
        $finding.Classification, $finding.Flag, ($finding.MissingLanguages -join ','))
}
