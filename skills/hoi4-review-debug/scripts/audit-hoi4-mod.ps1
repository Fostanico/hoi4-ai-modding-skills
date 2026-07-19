[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ModRoot,

    [string[]]$DependencyRoots = @(),

    [string]$GameRoot,

    [switch]$AsJson,

    [string]$OutputPath,

    [switch]$Force,

    [ValidateSet('None', 'Error', 'Warning')]
    [string]$FailOn = 'None',

    [ValidateRange(1, 10000)]
    [int]$MaxFindings = 500
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingDirectory {
    param([string]$Path, [string]$Label)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $resolved -or -not (Test-Path -LiteralPath $resolved.Path -PathType Container)) {
        throw "$Label directory does not exist: $Path"
    }

    return $resolved.Path.TrimEnd('\', '/')
}

function Get-DefaultModRoot {
    $gitRoot = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($gitRoot)) {
        return $gitRoot.Trim()
    }
    return (Get-Location).Path
}

function Get-RelativePath {
    param([string]$Root, [string]$Path)

    $rootUri = [Uri]($Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar)
    $pathUri = [Uri]$Path
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('/', '\')
}

function Get-CommentlessLine {
    param([string]$Line)

    $quoted = $false
    $escaped = $false
    for ($index = 0; $index -lt $Line.Length; $index++) {
        $character = $Line[$index]
        if ($escaped) {
            $escaped = $false
            continue
        }
        if ($character -eq '\') {
            $escaped = $true
            continue
        }
        if ($character -eq '"') {
            $quoted = -not $quoted
            continue
        }
        if ($character -eq '#' -and -not $quoted) {
            return $Line.Substring(0, $index)
        }
    }
    return $Line
}

function Get-BraceDelta {
    param([string]$Line)

    $delta = 0
    $quoted = $false
    $escaped = $false
    foreach ($character in $Line.ToCharArray()) {
        if ($escaped) {
            $escaped = $false
            continue
        }
        if ($character -eq '\') {
            $escaped = $true
            continue
        }
        if ($character -eq '"') {
            $quoted = -not $quoted
            continue
        }
        if (-not $quoted) {
            if ($character -eq '{') { $delta++ }
            if ($character -eq '}') { $delta-- }
        }
    }
    return $delta
}

function New-StringMap {
    return @{}
}

function Add-MapEntry {
    param([hashtable]$Map, [string]$Key, [object]$Value)

    if ([string]::IsNullOrWhiteSpace($Key)) { return }
    if (-not $Map.ContainsKey($Key)) {
        $Map[$Key] = [Collections.Generic.List[object]]::new()
    }
    $Map[$Key].Add($Value)
}

function New-Location {
    param([object]$File, [int]$Line)
    return [pscustomobject]@{
        root = $File.RootKind
        file = $File.RelativePath
        line = $Line
    }
}

$script:Findings = [Collections.Generic.List[object]]::new()
$script:SuppressedFindings = 0

function Add-Finding {
    param(
        [ValidateSet('Error', 'Warning', 'Info')][string]$Severity,
        [string]$Code,
        [string]$Message,
        [object]$Location,
        [string]$Evidence,
        [bool]$Heuristic = $false
    )

    $script:Findings.Add([pscustomobject]@{
        severity = $Severity
        code = $Code
        message = $Message
        location = $Location
        evidence = $Evidence
        heuristic = $Heuristic
    })
}

function Get-PrimaryFiles {
    param([string]$Root)

    $extensions = @('.txt', '.gui', '.gfx', '.asset', '.mod', '.yml')
    $excludedSegments = @('.git', '.agents', 'dist', 'tmp', 'logs', 'crashes')
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $extensionMatch = $extensions -contains $_.Extension.ToLowerInvariant()
        if (-not $extensionMatch) { return $false }
        $relative = Get-RelativePath -Root $Root -Path $_.FullName
        $segments = $relative.Split(@('\', '/'), [StringSplitOptions]::RemoveEmptyEntries)
        return -not (@($segments | Where-Object { $excludedSegments -contains $_ }).Count -gt 0)
    })
}

function Get-ExternalFiles {
    param([string]$Root, [switch]$ExcludeLocalisation)

    $candidateDirectories = [Collections.Generic.List[string]]::new()
    foreach ($directory in @(
        'events',
        'common\scripted_effects',
        'common\scripted_triggers',
        'interface'
    )) { $candidateDirectories.Add($directory) }
    if (-not $ExcludeLocalisation) {
        $candidateDirectories.Add('localisation')
        $candidateDirectories.Add('localization')
    }
    $files = [Collections.Generic.List[object]]::new()
    foreach ($relativeDirectory in $candidateDirectories) {
        $directory = Join-Path $Root $relativeDirectory
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File -ErrorAction SilentlyContinue) {
            if (@('.txt', '.gui', '.gfx', '.yml') -contains $file.Extension.ToLowerInvariant()) {
                $files.Add($file)
            }
        }
    }
    return @($files)
}

function Read-IndexedFile {
    param([IO.FileInfo]$File, [string]$Root, [string]$RootKind)

    try {
        $content = [IO.File]::ReadAllText($File.FullName, [Text.Encoding]::UTF8)
        return [pscustomobject]@{
            FullName = $File.FullName
            RelativePath = Get-RelativePath -Root $Root -Path $File.FullName
            Root = $Root
            RootKind = $RootKind
            Extension = $File.Extension.ToLowerInvariant()
            Content = $content
            Lines = @($content -split "`r?`n")
        }
    }
    catch {
        Add-Finding -Severity Error -Code 'FILE_READ_FAILED' -Message "Could not read $($File.FullName)." -Location $null -Evidence $_.Exception.Message
        return $null
    }
}

function Get-LanguageName {
    param([object]$File)

    foreach ($line in $File.Lines) {
        if ($line -match '^\s*(l_[A-Za-z0-9_]+)\s*:\s*$') {
            return $Matches[1]
        }
    }
    if ($File.RelativePath -match '_l_([A-Za-z0-9_]+)\.yml$') {
        return ('l_' + $Matches[1])
    }
    return 'unknown'
}

function Test-AssetPath {
    param([string]$Reference, [object]$SourceFile, [string[]]$Roots)

    $normalized = $Reference.Replace('/', [IO.Path]::DirectorySeparatorChar).Replace('\', [IO.Path]::DirectorySeparatorChar)
    $candidates = [Collections.Generic.List[string]]::new()
    $candidates.Add((Join-Path ([IO.Path]::GetDirectoryName($SourceFile.FullName)) $normalized))
    foreach ($root in $Roots) {
        if (-not [string]::IsNullOrWhiteSpace($root)) {
            $candidates.Add((Join-Path $root $normalized))
        }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $true }
    }
    return $false
}

function Get-GfxTextureSignature {
    param([object]$Location, [object[]]$IndexedFiles)

    $file = $IndexedFiles | Where-Object {
        $_.RootKind -eq $Location.root -and $_.RelativePath -eq $Location.file
    } | Select-Object -First 1
    if ($null -eq $file) { return '' }

    $start = [Math]::Max(0, $Location.line - 1)
    $end = [Math]::Min($file.Lines.Count - 1, $start + 8)
    for ($index = $start; $index -le $end; $index++) {
        $code = Get-CommentlessLine -Line $file.Lines[$index]
        if ($index -gt $start -and $code -match '(?<![A-Za-z0-9_])name\s*=') { break }
        if ($code -match '(?<![A-Za-z0-9_])texturefile\s*=\s*"?([^"\s}]+)') {
            return $Matches[1].Replace('\', '/').ToLowerInvariant()
        }
    }
    return ''
}

if ([string]::IsNullOrWhiteSpace($ModRoot)) {
    $ModRoot = Get-DefaultModRoot
}
$ModRoot = Resolve-ExistingDirectory -Path $ModRoot -Label 'Mod root'

$resolvedDependencies = [Collections.Generic.List[string]]::new()
foreach ($dependency in $DependencyRoots) {
    $resolvedDependencies.Add((Resolve-ExistingDirectory -Path $dependency -Label 'Dependency root'))
}
$GameRoot = Resolve-ExistingDirectory -Path $GameRoot -Label 'Game root'

$allFiles = [Collections.Generic.List[object]]::new()
foreach ($file in Get-PrimaryFiles -Root $ModRoot) {
    $record = Read-IndexedFile -File $file -Root $ModRoot -RootKind 'mod'
    if ($null -ne $record) { $allFiles.Add($record) }
}
foreach ($dependency in $resolvedDependencies) {
    foreach ($file in Get-ExternalFiles -Root $dependency) {
        $record = Read-IndexedFile -File $file -Root $dependency -RootKind 'dependency'
        if ($null -ne $record) { $allFiles.Add($record) }
    }
}
if (-not [string]::IsNullOrWhiteSpace($GameRoot)) {
    foreach ($file in Get-ExternalFiles -Root $GameRoot -ExcludeLocalisation) {
        $record = Read-IndexedFile -File $file -Root $GameRoot -RootKind 'game'
        if ($null -ne $record) { $allFiles.Add($record) }
    }
}

$primaryFiles = @($allFiles | Where-Object { $_.RootKind -eq 'mod' })
$eventDefinitions = New-StringMap
$eventReferences = New-StringMap
$effectDefinitions = New-StringMap
$triggerDefinitions = New-StringMap
$assignmentReferences = New-StringMap
$localisationDefinitions = New-StringMap
$localisationReferences = New-StringMap
$gfxDefinitions = New-StringMap
$gfxReferences = New-StringMap
$assetReferences = New-StringMap
$performanceSignals = [Collections.Generic.List[object]]::new()
$commentStats = [Collections.Generic.List[object]]::new()
$eventKinds = 'country_event|news_event|state_event|unit_leader_event|operative_leader_event'

foreach ($file in $allFiles) {
    $relativeForward = $file.RelativePath.Replace('\', '/')
    $isEventFile = $relativeForward -match '(^|/)events/'
    $isEffectFile = $relativeForward -match '(^|/)common/scripted_effects/'
    $isTriggerFile = $relativeForward -match '(^|/)common/scripted_triggers/'
    $isLocalisationFile = $file.Extension -eq '.yml'
    $depth = 0
    $eventDefinitionBlockDepth = -1
    $eventDefinitionLocation = $null
    $eventDefinitionFound = $false
    $pendingEventCallDepth = -1
    $pendingEventCallLocation = $null
    $codeLines = 0
    $commentLines = 0
    $hasDaily = $false
    $hasBroadIteration = $false
    $hasDirtyZero = $false
    $hasWhileLoop = $false

    if ($isLocalisationFile) {
        $language = Get-LanguageName -File $file
        for ($lineIndex = 0; $lineIndex -lt $file.Lines.Count; $lineIndex++) {
            $line = $file.Lines[$lineIndex]
            if ($line -match '^\s*([^#\s][^:]*?):(\d+)?\s*"') {
                $key = $Matches[1].Trim()
                $version = $Matches[2]
                Add-MapEntry -Map $localisationDefinitions -Key ($language + '|' + $key) -Value (New-Location -File $file -Line ($lineIndex + 1))
                if (-not [string]::IsNullOrWhiteSpace($version)) {
                    Add-Finding -Severity Warning -Code 'LOC_VERSION_SUFFIX' -Message "Localisation key '$key' uses a numeric version suffix." -Location (New-Location -File $file -Line ($lineIndex + 1)) -Evidence "Use key: \"Text\" in this skill's portable templates." -Heuristic $false
                }
            }
        }
        continue
    }

    # Dependencies and vanilla only provide an effective-definition index. Full
    # reference, readability, and hot-path analysis belongs to the target mod.
    if ($file.RootKind -ne 'mod') {
        $externalLocation = New-Location -File $file -Line 1
        if ($isEffectFile -or $isTriggerFile) {
            $definitionMap = if ($isEffectFile) { $effectDefinitions } else { $triggerDefinitions }
            foreach ($match in [regex]::Matches($file.Content, '(?m)^([A-Za-z_][A-Za-z0-9_.-]*)\s*=\s*\{')) {
                Add-MapEntry -Map $definitionMap -Key $match.Groups[1].Value -Value $externalLocation
            }
        }
        if ($isEventFile) {
            $awaitingEventId = $false
            for ($externalLineIndex = 0; $externalLineIndex -lt $file.Lines.Count; $externalLineIndex++) {
                $externalLine = $file.Lines[$externalLineIndex]
                if ($externalLine -match ("^[ \t]*(?:$eventKinds)[ \t]*=[ \t]*\{")) {
                    $awaitingEventId = $true
                    if ($externalLine -match '\bid\s*=\s*([A-Za-z0-9_.:-]+)') {
                        Add-MapEntry -Map $eventDefinitions -Key $Matches[1] -Value (New-Location -File $file -Line ($externalLineIndex + 1))
                        $awaitingEventId = $false
                    }
                    continue
                }
                if ($awaitingEventId -and $externalLine -match '^[ \t]*id\s*=\s*([A-Za-z0-9_.:-]+)') {
                    Add-MapEntry -Map $eventDefinitions -Key $Matches[1] -Value (New-Location -File $file -Line ($externalLineIndex + 1))
                    $awaitingEventId = $false
                }
            }
        }
        if ($file.Extension -eq '.gfx' -or $file.Extension -eq '.gui') {
            foreach ($match in [regex]::Matches($file.Content, '(?<![A-Za-z0-9_])name\s*=\s*"?(GFX_[A-Za-z0-9_.:-]+)"?')) {
                Add-MapEntry -Map $gfxDefinitions -Key $match.Groups[1].Value -Value $externalLocation
            }
        }
        continue
    }

    for ($lineIndex = 0; $lineIndex -lt $file.Lines.Count; $lineIndex++) {
        $rawLine = $file.Lines[$lineIndex]
        $lineNumber = $lineIndex + 1
        $code = Get-CommentlessLine -Line $rawLine
        $trimmed = $code.Trim()
        if ($rawLine -match '^\s*#') { $commentLines++ }
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) { $codeLines++ }

        if ($file.RootKind -eq 'mod' -and $rawLine -match '^(<<<<<<< .+|={7}|>>>>>>> .+)$') {
            Add-Finding -Severity Error -Code 'CONFLICT_MARKER' -Message 'Unresolved merge conflict marker.' -Location (New-Location -File $file -Line $lineNumber) -Evidence $rawLine.Trim()
        }

        if ($file.RootKind -eq 'mod') {
            if ($code -match '(?<![A-Za-z0-9_])on_daily\s*=') { $hasDaily = $true }
            if ($code -match '(?<![A-Za-z0-9_])(every_country|every_state|every_owned_state|every_controlled_state|every_army_leader|every_navy_leader|every_unit_leader)\s*=') { $hasBroadIteration = $true }
            if ($code -match '(?<![A-Za-z0-9_])dirty\s*=\s*0(?:\.0+)?(?=\s|$)') { $hasDirtyZero = $true }
            if ($code -match '(?<![A-Za-z0-9_])while_loop_effect\s*=') { $hasWhileLoop = $true }
        }

        if (($isEffectFile -or $isTriggerFile) -and $depth -eq 0 -and $code -match '^\s*([A-Za-z_][A-Za-z0-9_.-]*)\s*=\s*\{') {
            $definitionMap = if ($isEffectFile) { $effectDefinitions } else { $triggerDefinitions }
            Add-MapEntry -Map $definitionMap -Key $Matches[1] -Value (New-Location -File $file -Line $lineNumber)
        }

        if ($isEventFile -and $depth -eq 0 -and $code -match ("^\s*(?:$eventKinds)\s*=\s*\{")) {
            $eventDefinitionBlockDepth = $depth + [Math]::Max(1, (Get-BraceDelta -Line $code))
            $eventDefinitionLocation = New-Location -File $file -Line $lineNumber
            $eventDefinitionFound = $false
            if ($code -match '\bid\s*=\s*([A-Za-z0-9_.:-]+)') {
                Add-MapEntry -Map $eventDefinitions -Key $Matches[1] -Value $eventDefinitionLocation
                $eventDefinitionFound = $true
            }
        }
        elseif ($eventDefinitionBlockDepth -ge 0 -and -not $eventDefinitionFound -and $code -match '^\s*id\s*=\s*([A-Za-z0-9_.:-]+)') {
            Add-MapEntry -Map $eventDefinitions -Key $Matches[1] -Value $eventDefinitionLocation
            $eventDefinitionFound = $true
        }

        if ($code -match '(?<![A-Za-z0-9_])name\s*=\s*"?(GFX_[A-Za-z0-9_.:-]+)"?') {
            Add-MapEntry -Map $gfxDefinitions -Key $Matches[1] -Value (New-Location -File $file -Line $lineNumber)
        }

        if ($file.RootKind -eq 'mod') {
            if ($code -match ("(?:^|\s)(?:$eventKinds)\s*=\s*([A-Za-z0-9_.:-]+)")) {
                Add-MapEntry -Map $eventReferences -Key $Matches[1] -Value (New-Location -File $file -Line $lineNumber)
            }
            if ($code -match ("(?:^|\s)(?:$eventKinds)\s*=\s*\{[^}]*\bid\s*=\s*([A-Za-z0-9_.:-]+)")) {
                if (-not ($isEventFile -and $depth -eq 0)) {
                    Add-MapEntry -Map $eventReferences -Key $Matches[1] -Value (New-Location -File $file -Line $lineNumber)
                }
            }
            elseif ($code -match ("(?:^|\s)(?:$eventKinds)\s*=\s*\{") -and -not ($isEventFile -and $depth -eq 0)) {
                $pendingEventCallDepth = $depth + [Math]::Max(1, (Get-BraceDelta -Line $code))
                $pendingEventCallLocation = New-Location -File $file -Line $lineNumber
            }
            elseif ($pendingEventCallDepth -ge 0 -and $code -match '^\s*id\s*=\s*([A-Za-z0-9_.:-]+)') {
                Add-MapEntry -Map $eventReferences -Key $Matches[1] -Value $pendingEventCallLocation
                $pendingEventCallDepth = -1
                $pendingEventCallLocation = $null
            }

            foreach ($match in [regex]::Matches($code, '(?<![A-Za-z0-9_.-])([A-Za-z_][A-Za-z0-9_.-]*)\s*=')) {
                Add-MapEntry -Map $assignmentReferences -Key $match.Groups[1].Value -Value (New-Location -File $file -Line $lineNumber)
            }

            foreach ($match in [regex]::Matches($code, '(?<![A-Za-z0-9_])(title|desc|tooltip|custom_effect_tooltip|custom_trigger_tooltip|localization_key)\s*=\s*([A-Za-z0-9_.:-]+)')) {
                Add-MapEntry -Map $localisationReferences -Key $match.Groups[2].Value -Value (New-Location -File $file -Line $lineNumber)
            }
            foreach ($match in [regex]::Matches($code, '\b(GFX_[A-Za-z0-9_.:-]+)\b')) {
                Add-MapEntry -Map $gfxReferences -Key $match.Groups[1].Value -Value (New-Location -File $file -Line $lineNumber)
            }
            foreach ($match in [regex]::Matches($code, '"([^"\r\n]+\.(?:dds|png|tga|mesh|anim|asset|wav|ogg|mp3))"', [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                Add-MapEntry -Map $assetReferences -Key $match.Groups[1].Value -Value (New-Location -File $file -Line $lineNumber)
            }
        }

        $delta = Get-BraceDelta -Line $code
        $depth += $delta
        if ($depth -lt 0 -and $file.RootKind -eq 'mod') {
            Add-Finding -Severity Error -Code 'BRACE_UNDERFLOW' -Message 'A closing brace appears before a matching opening brace.' -Location (New-Location -File $file -Line $lineNumber) -Evidence $trimmed
            $depth = 0
        }
        if ($eventDefinitionBlockDepth -ge 0 -and $depth -lt $eventDefinitionBlockDepth) {
            $eventDefinitionBlockDepth = -1
            $eventDefinitionLocation = $null
            $eventDefinitionFound = $false
        }
        if ($pendingEventCallDepth -ge 0 -and $depth -lt $pendingEventCallDepth) {
            $pendingEventCallDepth = -1
            $pendingEventCallLocation = $null
        }
    }

    if ($depth -ne 0 -and $file.RootKind -eq 'mod') {
        Add-Finding -Severity Error -Code 'BRACE_IMBALANCE' -Message "File ends with brace depth $depth." -Location (New-Location -File $file -Line $file.Lines.Count) -Evidence 'Quoted strings and comments were excluded from the count.'
    }

    if ($file.RootKind -eq 'mod') {
        $commentStats.Add([pscustomobject]@{
            file = $file.RelativePath
            codeLines = $codeLines
            commentLines = $commentLines
        })
        if ($codeLines -ge 150 -and $commentLines -eq 0) {
            Add-Finding -Severity Warning -Code 'LARGE_FILE_NO_COMMENTS' -Message 'Large script file has no full-line comments.' -Location (New-Location -File $file -Line 1) -Evidence "$codeLines non-empty code lines; review readability and handoff contracts." -Heuristic $true
        }
        if ($hasDaily -and $hasBroadIteration) {
            Add-Finding -Severity Warning -Code 'DAILY_BROAD_ITERATION' -Message 'File combines on_daily with broad scope iteration.' -Location (New-Location -File $file -Line 1) -Evidence 'Measure actual hook scope and consider event-driven, weekly, or monthly batching where semantics allow.' -Heuristic $true
        }
        elseif ($hasDaily) {
            Add-Finding -Severity Info -Code 'DAILY_HOOK' -Message 'File contains an on_daily hook.' -Location (New-Location -File $file -Line 1) -Evidence 'Review frequency, country scope, persistent state, and required cadence before changing it.' -Heuristic $true
        }
        if ($hasDirtyZero) {
            Add-Finding -Severity Warning -Code 'GUI_DIRTY_ZERO' -Message 'GUI script contains dirty = 0.' -Location (New-Location -File $file -Line 1) -Evidence 'This can force frequent UI reevaluation; confirm the current engine consumer and use a less frequent refresh when possible.' -Heuristic $true
        }
        if ($hasWhileLoop) {
            Add-Finding -Severity Info -Code 'WHILE_LOOP' -Message 'Script uses while_loop_effect.' -Location (New-Location -File $file -Line 1) -Evidence 'Confirm a bounded termination condition and expected worst-case iterations.' -Heuristic $true
        }
        $performanceSignals.Add([pscustomobject]@{
            file = $file.RelativePath
            onDaily = $hasDaily
            broadIteration = $hasBroadIteration
            dirtyZero = $hasDirtyZero
            whileLoop = $hasWhileLoop
        })
    }
}

foreach ($mapSpec in @(
    [pscustomobject]@{ Map = $eventDefinitions; Type = 'event'; Code = 'DUPLICATE_EVENT' },
    [pscustomobject]@{ Map = $effectDefinitions; Type = 'scripted effect'; Code = 'DUPLICATE_SCRIPTED_EFFECT' },
    [pscustomobject]@{ Map = $triggerDefinitions; Type = 'scripted trigger'; Code = 'DUPLICATE_SCRIPTED_TRIGGER' }
)) {
    foreach ($key in $mapSpec.Map.Keys) {
        $modLocations = @($mapSpec.Map[$key] | Where-Object { $_.root -eq 'mod' })
        if ($modLocations.Count -gt 1) {
            Add-Finding -Severity Error -Code $mapSpec.Code -Message "Duplicate $($mapSpec.Type) definition '$key'." -Location $modLocations[0] -Evidence (($modLocations | ForEach-Object { "$($_.file):$($_.line)" }) -join ', ')
        }
    }
}

$redundantGfxKeys = [Collections.Generic.List[string]]::new()
foreach ($key in $gfxDefinitions.Keys) {
    $modLocations = @($gfxDefinitions[$key] | Where-Object { $_.root -eq 'mod' })
    if ($modLocations.Count -le 1) { continue }

    $signatures = @($modLocations | ForEach-Object { Get-GfxTextureSignature -Location $_ -IndexedFiles $allFiles } | Sort-Object -Unique)
    $evidence = ($modLocations | ForEach-Object { "$($_.file):$($_.line)" }) -join ', '
    if ($signatures.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($signatures[0])) {
        $redundantGfxKeys.Add($key)
    }
    else {
        Add-Finding -Severity Warning -Code 'CONFLICTING_GFX' -Message "GFX object '$key' has multiple definitions whose texture could not be proven identical." -Location $modLocations[0] -Evidence $evidence -Heuristic $false
    }
}
if ($redundantGfxKeys.Count -gt 0) {
    Add-Finding -Severity Info -Code 'REDUNDANT_GFX_SUMMARY' -Message "$($redundantGfxKeys.Count) GFX objects are defined repeatedly with the same texture." -Location $null -Evidence ("Examples: " + ((@($redundantGfxKeys | Sort-Object | Select-Object -First 12)) -join ', ')) -Heuristic $false
}

foreach ($compoundKey in $localisationDefinitions.Keys) {
    $locations = @($localisationDefinitions[$compoundKey] | Where-Object { $_.root -eq 'mod' })
    if ($locations.Count -gt 1) {
        $parts = $compoundKey.Split('|', 2)
        Add-Finding -Severity Warning -Code 'DUPLICATE_LOCALISATION' -Message "Duplicate localisation key '$($parts[1])' in $($parts[0])." -Location $locations[0] -Evidence (($locations | ForEach-Object { "$($_.file):$($_.line)" }) -join ', ')
    }
}

$hasExternalDefinitions = ($resolvedDependencies.Count -gt 0 -or -not [string]::IsNullOrWhiteSpace($GameRoot))
$missingEvidence = 'Not found in the target mod, supplied dependencies, or supplied game root.'

function Publish-MissingReferences {
    param(
        [string[]]$Keys,
        [hashtable]$ReferenceMap,
        [string]$Code,
        [string]$Noun
    )

    if ($Keys.Count -eq 0) { return }
    if ($hasExternalDefinitions) {
        foreach ($key in $Keys) {
            Add-Finding -Severity Warning -Code $Code -Message "$Noun '$key' has no indexed definition." -Location $ReferenceMap[$key][0] -Evidence $missingEvidence -Heuristic $false
        }
        return
    }

    Add-Finding -Severity Info -Code ($Code + '_UNVERIFIED') -Message "$($Keys.Count) $Noun references are absent from the mod-only index." -Location $ReferenceMap[$Keys[0]][0] -Evidence ("Supply dependency and game roots before treating these as defects. Examples: " + ((@($Keys | Sort-Object | Select-Object -First 12)) -join ', ')) -Heuristic $true
}

$missingEventIds = @($eventReferences.Keys | Where-Object { -not $eventDefinitions.ContainsKey($_) })
Publish-MissingReferences -Keys $missingEventIds -ReferenceMap $eventReferences -Code 'MISSING_EVENT_TARGET' -Noun 'event target'

$allLocalisationKeys = @{}
foreach ($compoundKey in $localisationDefinitions.Keys) {
    $key = $compoundKey.Substring($compoundKey.IndexOf('|') + 1)
    $allLocalisationKeys[$key] = $true
}
$gameLocalisationCandidates = @($localisationReferences.Keys | Where-Object { -not $allLocalisationKeys.ContainsKey($_) })
if (-not [string]::IsNullOrWhiteSpace($GameRoot) -and $gameLocalisationCandidates.Count -gt 0) {
    $escapedCandidates = @($gameLocalisationCandidates | ForEach-Object { [regex]::Escape($_) })
    $candidatePattern = [regex]::new(('(?m)^[ \t]*(' + ($escapedCandidates -join '|') + '):(?:\d+)?[ \t]*"'), [Text.RegularExpressions.RegexOptions]::Compiled)
    $gameLocalisationRoot = Join-Path $GameRoot 'localisation'
    if (Test-Path -LiteralPath $gameLocalisationRoot -PathType Container) {
        foreach ($localisationFile in Get-ChildItem -LiteralPath $gameLocalisationRoot -Recurse -File -Filter '*.yml' -ErrorAction SilentlyContinue) {
            try {
                $localisationContent = [IO.File]::ReadAllText($localisationFile.FullName, [Text.Encoding]::UTF8)
                foreach ($match in $candidatePattern.Matches($localisationContent)) {
                    Add-MapEntry -Map $localisationDefinitions -Key ('external|' + $match.Groups[1].Value) -Value ([pscustomobject]@{ root = 'game'; file = Get-RelativePath -Root $GameRoot -Path $localisationFile.FullName; line = 1 })
                    $allLocalisationKeys[$match.Groups[1].Value] = $true
                }
            }
            catch {
                Add-Finding -Severity Warning -Code 'GAME_LOCALISATION_READ_FAILED' -Message "Could not inspect game localisation file '$($localisationFile.FullName)'." -Location $null -Evidence $_.Exception.Message -Heuristic $false
            }
        }
    }
}
$missingLocalisationKeys = @($localisationReferences.Keys | Where-Object { -not $allLocalisationKeys.ContainsKey($_) })
Publish-MissingReferences -Keys $missingLocalisationKeys -ReferenceMap $localisationReferences -Code 'MISSING_LOCALISATION' -Noun 'strong localisation key'

$missingGfxKeys = @($gfxReferences.Keys | Where-Object { -not $gfxDefinitions.ContainsKey($_) })
Publish-MissingReferences -Keys $missingGfxKeys -ReferenceMap $gfxReferences -Code 'MISSING_GFX' -Noun 'GFX object'

$assetSearchRoots = [Collections.Generic.List[string]]::new()
$assetSearchRoots.Add($ModRoot)
foreach ($dependency in $resolvedDependencies) { $assetSearchRoots.Add($dependency) }
if (-not [string]::IsNullOrWhiteSpace($GameRoot)) { $assetSearchRoots.Add($GameRoot) }
$missingAssetPaths = [Collections.Generic.List[string]]::new()
foreach ($assetPath in $assetReferences.Keys) {
    $firstReference = $assetReferences[$assetPath][0]
    $sourceFile = $primaryFiles | Where-Object { $_.RelativePath -eq $firstReference.file } | Select-Object -First 1
    if ($null -ne $sourceFile -and -not (Test-AssetPath -Reference $assetPath -SourceFile $sourceFile -Roots @($assetSearchRoots))) {
        $missingAssetPaths.Add($assetPath)
    }
}
Publish-MissingReferences -Keys @($missingAssetPaths) -ReferenceMap $assetReferences -Code 'MISSING_ASSET' -Noun 'asset path'

foreach ($definitionSpec in @(
    [pscustomobject]@{ Definitions = $effectDefinitions; Type = 'scripted effect'; Code = 'ORPHAN_SCRIPTED_EFFECT' },
    [pscustomobject]@{ Definitions = $triggerDefinitions; Type = 'scripted trigger'; Code = 'ORPHAN_SCRIPTED_TRIGGER' }
)) {
    foreach ($key in $definitionSpec.Definitions.Keys) {
        $modDefinitions = @($definitionSpec.Definitions[$key] | Where-Object { $_.root -eq 'mod' })
        if ($modDefinitions.Count -eq 0) { continue }
        $assignmentCount = if ($assignmentReferences.ContainsKey($key)) { $assignmentReferences[$key].Count } else { 0 }
        if ($assignmentCount -le $definitionSpec.Definitions[$key].Count) {
            Add-Finding -Severity Info -Code $definitionSpec.Code -Message "Possibly unused $($definitionSpec.Type) '$key'." -Location $modDefinitions[0] -Evidence 'No assignment-shaped call was found. Dynamic or engine-driven consumers may not be visible to this audit.' -Heuristic $true
        }
    }
}
foreach ($key in $eventDefinitions.Keys) {
    $modDefinitions = @($eventDefinitions[$key] | Where-Object { $_.root -eq 'mod' })
    if ($modDefinitions.Count -gt 0 -and -not $eventReferences.ContainsKey($key)) {
        Add-Finding -Severity Info -Code 'ORPHAN_EVENT' -Message "Possibly unreachable event '$key'." -Location $modDefinitions[0] -Evidence 'No explicit event call was found. On-actions, console use, hidden engine hooks, or dependency consumers may still reach it.' -Heuristic $true
    }
}
$orphanGfxKeys = [Collections.Generic.List[string]]::new()
foreach ($key in $gfxDefinitions.Keys) {
    $modDefinitions = @($gfxDefinitions[$key] | Where-Object { $_.root -eq 'mod' })
    $referenceCount = if ($gfxReferences.ContainsKey($key)) { $gfxReferences[$key].Count } else { 0 }
    if ($modDefinitions.Count -gt 0 -and $referenceCount -le $gfxDefinitions[$key].Count) {
        $orphanGfxKeys.Add($key)
    }
}
if ($orphanGfxKeys.Count -gt 0) {
    Add-Finding -Severity Info -Code 'ORPHAN_GFX_SUMMARY' -Message "$($orphanGfxKeys.Count) GFX objects have no additional token reference." -Location $null -Evidence ("Dynamic or pattern-generated GUI consumers may exist. Examples: " + ((@($orphanGfxKeys | Sort-Object | Select-Object -First 12)) -join ', ')) -Heuristic $true
}

$allOrderedFindings = @($script:Findings | Sort-Object @{ Expression = { switch ($_.severity) { 'Error' { 0 } 'Warning' { 1 } default { 2 } } } }, code, @{ Expression = { if ($null -ne $_.location) { $_.location.file } else { '' } } }, @{ Expression = { if ($null -ne $_.location) { $_.location.line } else { 0 } } })
$errorCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Error' }).Count
$warningCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Warning' }).Count
$infoCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Info' }).Count
$script:SuppressedFindings = [Math]::Max(0, $allOrderedFindings.Count - $MaxFindings)
$orderedFindings = @($allOrderedFindings | Select-Object -First $MaxFindings)
$modLocalisationCompoundKeys = @($localisationDefinitions.Keys | Where-Object {
    @($localisationDefinitions[$_] | Where-Object { $_.root -eq 'mod' }).Count -gt 0
})
$languages = @($modLocalisationCompoundKeys | ForEach-Object { $_.Split('|', 2)[0] } | Sort-Object -Unique)

$result = [pscustomobject]@{
    tool = 'HOI4 Mod Doctor'
    schemaVersion = 1
    generatedAt = (Get-Date).ToString('o')
    roots = [pscustomobject]@{
        mod = $ModRoot
        dependencies = @($resolvedDependencies)
        game = $GameRoot
    }
    summary = [pscustomobject]@{
        filesScanned = $allFiles.Count
        modFilesScanned = $primaryFiles.Count
        errors = $errorCount
        warnings = $warningCount
        info = $infoCount
        suppressed = $script:SuppressedFindings
    }
    inventory = [pscustomobject]@{
        events = $eventDefinitions.Count
        scriptedEffects = $effectDefinitions.Count
        scriptedTriggers = $triggerDefinitions.Count
        localisationKeys = $modLocalisationCompoundKeys.Count
        localisationLanguages = $languages
        gfxObjects = $gfxDefinitions.Count
        assetPaths = $assetReferences.Count
    }
    performance = [pscustomobject]@{
        dailyHookFiles = @($performanceSignals | Where-Object { $_.onDaily }).Count
        dailyBroadIterationFiles = @($performanceSignals | Where-Object { $_.onDaily -and $_.broadIteration }).Count
        dirtyZeroFiles = @($performanceSignals | Where-Object { $_.dirtyZero }).Count
        whileLoopFiles = @($performanceSignals | Where-Object { $_.whileLoop }).Count
    }
    referenceGraph = [pscustomobject]@{
        eventTargets = $eventReferences.Count
        unresolvedEventTargets = $missingEventIds.Count
        strongLocalisationKeys = $localisationReferences.Count
        unresolvedStrongLocalisationKeys = $missingLocalisationKeys.Count
        gfxTokens = $gfxReferences.Count
        unresolvedGfxTokens = $missingGfxKeys.Count
        assetPaths = $assetReferences.Count
        unresolvedAssetPaths = $missingAssetPaths.Count
    }
    commentCoverage = @($commentStats | Sort-Object file)
    findings = $orderedFindings
    limitations = @(
        'This is a static, read-only audit. It does not prove runtime correctness or balance.',
        'Missing and orphan results are heuristic unless all enabled dependencies and the matching game root were supplied.',
        'Dynamic identifiers, generated GUI names, scripted localisation, and engine-owned consumers can evade static indexing.',
        'Gameplay design, balance, and UX judgments require the documented player promise plus playtest evidence.'
    )
}

if ($AsJson) {
    $rendered = $result | ConvertTo-Json -Depth 8
}
else {
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('HOI4 Mod Doctor')
    $lines.Add("Root: $ModRoot")
    $lines.Add("Scanned: $($result.summary.modFilesScanned) mod files / $($result.summary.filesScanned) effective files")
    $lines.Add("Definitions: $($result.inventory.events) events, $($result.inventory.scriptedEffects) scripted effects, $($result.inventory.scriptedTriggers) scripted triggers, $($result.inventory.gfxObjects) GFX objects")
    $lines.Add("Localisation: $($result.inventory.localisationKeys) keys across $($languages.Count) languages")
    $lines.Add("Findings: $errorCount errors, $warningCount warnings, $infoCount info, $($script:SuppressedFindings) suppressed")
    $lines.Add('')
    foreach ($finding in $orderedFindings) {
        $locationText = ''
        if ($null -ne $finding.location) {
            $locationText = " [$($finding.location.file):$($finding.location.line)]"
        }
        $heuristicText = if ($finding.heuristic) { ' (heuristic)' } else { '' }
        $lines.Add("[$($finding.severity)] $($finding.code)$locationText$heuristicText - $($finding.message)")
        if (-not [string]::IsNullOrWhiteSpace($finding.evidence)) {
            $lines.Add("  $($finding.evidence)")
        }
    }
    $lines.Add('')
    $lines.Add('Static findings are a baseline, not runtime proof or permission to make subjective design changes.')
    $rendered = $lines -join [Environment]::NewLine
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $fullOutputPath = [IO.Path]::GetFullPath($OutputPath)
    if ((Test-Path -LiteralPath $fullOutputPath) -and -not $Force) {
        throw "Output file already exists. Use -Force to overwrite: $fullOutputPath"
    }
    $parent = [IO.Path]::GetDirectoryName($fullOutputPath)
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        [IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    $utf8NoBom = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($fullOutputPath, $rendered, $utf8NoBom)
}
else {
    Write-Output $rendered
}

if ($FailOn -eq 'Error' -and $errorCount -gt 0) { exit 2 }
if ($FailOn -eq 'Warning' -and ($errorCount -gt 0 -or $warningCount -gt 0)) { exit 3 }
