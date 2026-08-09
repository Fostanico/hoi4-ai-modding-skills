[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ModRoot,

    [string[]]$DependencyRoots = @(),

    [string]$GameRoot,

    [switch]$AsJson,

    [ValidateSet('Text', 'Json', 'Markdown', 'Sarif')]
    [string]$Format = 'Text',

    [switch]$ChangedOnly,

    [string]$GitBase = 'HEAD',

    [string]$BaselinePath,

    [string]$SuppressionsPath,

    [switch]$AutoResolvePlayset,

    [string]$UserDataRoot,

    [switch]$AuditMedia,

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
$script:BaselineSuppressedFindings = 0
$script:PolicySuppressedFindings = 0

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
        certainty = if ($Heuristic) { 'lead' } else { 'confirmed' }
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

function Find-AssetAlternatives {
    param([string]$Reference, [object]$SourceFile, [string[]]$Roots)

    $normalized = $Reference.Replace('/', [IO.Path]::DirectorySeparatorChar).Replace('\', [IO.Path]::DirectorySeparatorChar)
    $relativeDirectory = [IO.Path]::GetDirectoryName($normalized)
    if ($null -eq $relativeDirectory) { $relativeDirectory = '' }
    $baseName = [IO.Path]::GetFileNameWithoutExtension($normalized)
    $expectedExtension = [IO.Path]::GetExtension($normalized)
    if ([string]::IsNullOrWhiteSpace($baseName)) { return @() }

    $directories = [Collections.Generic.List[string]]::new()
    $sourceDirectory = [IO.Path]::GetDirectoryName($SourceFile.FullName)
    if (-not [string]::IsNullOrWhiteSpace($sourceDirectory)) {
        $directories.Add((Join-Path $sourceDirectory $relativeDirectory))
    }
    foreach ($root in $Roots) {
        if (-not [string]::IsNullOrWhiteSpace($root)) {
            $directories.Add((Join-Path $root $relativeDirectory))
        }
    }

    $alternatives = [Collections.Generic.List[string]]::new()
    foreach ($directory in @($directories | Sort-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { continue }
        foreach ($candidate in Get-ChildItem -LiteralPath $directory -File -ErrorAction SilentlyContinue) {
            if ($candidate.BaseName -ne $baseName -or $candidate.Extension -eq $expectedExtension) { continue }
            if (@('.dds', '.png', '.tga') -notcontains $candidate.Extension.ToLowerInvariant()) { continue }
            $alternatives.Add($candidate.FullName)
        }
    }
    return @($alternatives | Sort-Object -Unique)
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

function Read-JsonFile {
    param([string]$Path, [string]$Label)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $resolved -or -not (Test-Path -LiteralPath $resolved.Path -PathType Leaf)) {
        throw "$Label file does not exist: $Path"
    }
    try {
        return [IO.File]::ReadAllText($resolved.Path, [Text.Encoding]::UTF8) | ConvertFrom-Json
    }
    catch {
        throw "$Label is not valid JSON: $Path`n$($_.Exception.Message)"
    }
}

function Get-DefaultUserDataRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
        return Join-Path $env:USERPROFILE 'Documents\Paradox Interactive\Hearts of Iron IV'
    }
    return $null
}

function Get-PlaysetDependencyRoots {
    param([string]$DataRoot, [string]$TargetModRoot)

    $loadFile = Join-Path $DataRoot 'dlc_load.json'
    if (-not (Test-Path -LiteralPath $loadFile -PathType Leaf)) {
        throw "Active playset file does not exist: $loadFile"
    }
    $load = Read-JsonFile -Path $loadFile -Label 'Active playset'
    $resolved = [Collections.Generic.List[object]]::new()
    foreach ($descriptorEntry in @($load.enabled_mods)) {
        if ([string]::IsNullOrWhiteSpace([string]$descriptorEntry)) { continue }
        $descriptorPath = Join-Path $DataRoot ([string]$descriptorEntry).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $descriptorPath -PathType Leaf)) {
            Add-Finding -Severity Warning -Code 'PLAYSET_DESCRIPTOR_MISSING' -Message "Enabled playset descriptor is missing: $descriptorEntry" -Location $null -Evidence $descriptorPath
            continue
        }
        $descriptorText = [IO.File]::ReadAllText($descriptorPath, [Text.Encoding]::UTF8)
        $pathMatch = [regex]::Match($descriptorText, '(?m)^\s*path\s*=\s*"([^"]+)"')
        if (-not $pathMatch.Success) {
            Add-Finding -Severity Warning -Code 'PLAYSET_PATH_MISSING' -Message "Enabled descriptor has no path field: $descriptorEntry" -Location $null -Evidence $descriptorPath
            continue
        }
        $candidate = $pathMatch.Groups[1].Value.Replace('/', '\')
        if (-not [IO.Path]::IsPathRooted($candidate)) { $candidate = Join-Path $DataRoot $candidate }
        $candidatePath = Resolve-Path -LiteralPath $candidate -ErrorAction SilentlyContinue
        if ($null -eq $candidatePath -or -not (Test-Path -LiteralPath $candidatePath.Path -PathType Container)) {
            Add-Finding -Severity Warning -Code 'PLAYSET_MOD_ROOT_MISSING' -Message "Enabled descriptor points to a missing mod root: $descriptorEntry" -Location $null -Evidence $candidate
            continue
        }
        $root = $candidatePath.Path.TrimEnd('\', '/')
        if ([string]::Equals($root, $TargetModRoot, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $resolved.Add([pscustomobject]@{
            descriptor = $descriptorPath
            root = $root
        })
    }
    return @($resolved)
}

function Get-GitChangedFiles {
    param([string]$Root, [string]$Base)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        & git -C $Root rev-parse --is-inside-work-tree 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) { throw '-ChangedOnly requires ModRoot to be inside a Git worktree.' }
        $changed = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $tracked = @(& git -C $Root diff --name-only --diff-filter=ACMR $Base -- 2>$null)
        if ($LASTEXITCODE -ne 0) { throw "Could not compare Git changes against '$Base'." }
        $untracked = @(& git -C $Root ls-files --others --exclude-standard 2>$null)
    }
    finally { $ErrorActionPreference = $previousErrorAction }
    foreach ($path in @($tracked) + @($untracked)) {
        if (-not [string]::IsNullOrWhiteSpace($path)) { [void]$changed.Add($path.Trim().Replace('/', '\')) }
    }
    return $changed
}

function Get-FindingFingerprint {
    param([object]$Finding)

    $file = if ($null -ne $Finding.location) { ([string]$Finding.location.file).Replace('/', '\').ToLowerInvariant() } else { '' }
    $payload = "$($Finding.code)|$file|$($Finding.message)"
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $hash = [Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return ([BitConverter]::ToString($hash)).Replace('-', '').ToLowerInvariant()
}

function Resolve-AssetFile {
    param([string]$Reference, [object]$SourceFile, [string[]]$Roots)

    $normalized = $Reference.Replace('/', [IO.Path]::DirectorySeparatorChar).Replace('\', [IO.Path]::DirectorySeparatorChar)
    $candidates = [Collections.Generic.List[string]]::new()
    $sourceDirectory = [IO.Path]::GetDirectoryName($SourceFile.FullName)
    if (-not [string]::IsNullOrWhiteSpace($sourceDirectory)) { $candidates.Add((Join-Path $sourceDirectory $normalized)) }
    foreach ($root in $Roots) {
        if (-not [string]::IsNullOrWhiteSpace($root)) { $candidates.Add((Join-Path $root $normalized)) }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

function Test-AutoDiscoveredMedia {
    param([string]$RelativePath)

    $path = $RelativePath.Replace('\', '/').ToLowerInvariant()
    return (
        $path -eq 'thumbnail.png' -or
        $path.StartsWith('gfx/flags/') -or
        $path.StartsWith('gfx/achievements/') -or
        $path -match '^music/hoi4maintheme[^/]*\.ogg$'
    )
}

function Get-MediaInventory {
    param([string]$Root, [object[]]$IndexedFiles, [hashtable]$ReferenceMap, [string[]]$SearchRoots)

    $extensions = @('.dds', '.png', '.tga', '.jpg', '.jpeg', '.wav', '.ogg', '.mp3')
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $extensions -contains $_.Extension.ToLowerInvariant() -and
        -not ((Get-RelativePath -Root $Root -Path $_.FullName).Split(@('\', '/'), [StringSplitOptions]::RemoveEmptyEntries) | Where-Object { $_ -in @('.git', '.agents', 'dist', 'tmp') })
    })

    $referenced = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($reference in $ReferenceMap.Keys) {
        $location = $ReferenceMap[$reference] | Select-Object -First 1
        $source = $IndexedFiles | Where-Object { $_.RootKind -eq $location.root -and $_.RelativePath -eq $location.file } | Select-Object -First 1
        if ($null -eq $source) { continue }
        $resolved = Resolve-AssetFile -Reference $reference -SourceFile $source -Roots $SearchRoots
        if (-not [string]::IsNullOrWhiteSpace($resolved) -and $resolved.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)) {
            [void]$referenced.Add($resolved)
        }
    }

    $records = [Collections.Generic.List[object]]::new()
    $hashGroups = @{}
    foreach ($file in $files) {
        $relative = Get-RelativePath -Root $Root -Path $file.FullName
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if (-not $hashGroups.ContainsKey($hash)) { $hashGroups[$hash] = [Collections.Generic.List[object]]::new() }
        $hashGroups[$hash].Add($file)
        $records.Add([pscustomobject]@{
            path = $relative
            extension = $file.Extension.ToLowerInvariant()
            bytes = $file.Length
            referenced = $referenced.Contains($file.FullName)
            autoDiscovered = Test-AutoDiscoveredMedia -RelativePath $relative
            sha256 = $hash
        })
    }

    $duplicateGroups = [Collections.Generic.List[object]]::new()
    [long]$potentialSavings = 0
    foreach ($hash in $hashGroups.Keys) {
        $group = @($hashGroups[$hash])
        if ($group.Count -lt 2) { continue }
        $saving = [long]$group[0].Length * ($group.Count - 1)
        $potentialSavings += $saving
        $duplicateGroups.Add([pscustomobject]@{
            sha256 = $hash
            bytesEach = [long]$group[0].Length
            potentialSavingsBytes = $saving
            paths = @($group | ForEach-Object { Get-RelativePath -Root $Root -Path $_.FullName } | Sort-Object)
        })
    }
    $unreferenced = @($records | Where-Object { -not $_.referenced -and -not $_.autoDiscovered })
    $totalMeasure = $records | Measure-Object bytes -Sum
    $unreferencedMeasure = $unreferenced | Measure-Object bytes -Sum
    $totalBytes = if ($null -ne $totalMeasure -and $null -ne $totalMeasure.Sum) { [long]$totalMeasure.Sum } else { [long]0 }
    $unreferencedBytes = if ($null -ne $unreferencedMeasure -and $null -ne $unreferencedMeasure.Sum) { [long]$unreferencedMeasure.Sum } else { [long]0 }
    $byExtension = @($records | Group-Object extension | ForEach-Object {
        [pscustomobject]@{
            extension = $_.Name
            files = $_.Count
            bytes = [long](($_.Group | Measure-Object bytes -Sum).Sum)
        }
    } | Sort-Object bytes -Descending)

    return [pscustomobject]@{
        files = $records.Count
        bytes = $totalBytes
        byExtension = $byExtension
        exactDuplicateGroups = @($duplicateGroups | Sort-Object potentialSavingsBytes -Descending)
        potentialDuplicateSavingsBytes = $potentialSavings
        unreferencedCandidates = $unreferenced.Count
        unreferencedCandidateBytes = $unreferencedBytes
        unreferencedExamples = @($unreferenced | Sort-Object bytes -Descending | Select-Object -First 20 path, bytes, extension)
    }
}

if ([string]::IsNullOrWhiteSpace($ModRoot)) {
    $ModRoot = Get-DefaultModRoot
}
$ModRoot = Resolve-ExistingDirectory -Path $ModRoot -Label 'Mod root'
if ($AsJson) { $Format = 'Json' }
$changedFiles = if ($ChangedOnly) { Get-GitChangedFiles -Root $ModRoot -Base $GitBase } else { $null }
$playsetDescriptors = [Collections.Generic.List[string]]::new()

$resolvedDependencies = [Collections.Generic.List[string]]::new()
foreach ($dependency in $DependencyRoots) {
    $resolvedDependencies.Add((Resolve-ExistingDirectory -Path $dependency -Label 'Dependency root'))
}
if ($AutoResolvePlayset) {
    if ([string]::IsNullOrWhiteSpace($UserDataRoot)) { $UserDataRoot = Get-DefaultUserDataRoot }
    $UserDataRoot = Resolve-ExistingDirectory -Path $UserDataRoot -Label 'HOI4 user data root'
    foreach ($entry in Get-PlaysetDependencyRoots -DataRoot $UserDataRoot -TargetModRoot $ModRoot) {
        $playsetDescriptors.Add($entry.descriptor)
        if (-not ($resolvedDependencies | Where-Object { [string]::Equals($_, $entry.root, [StringComparison]::OrdinalIgnoreCase) })) {
            $resolvedDependencies.Add($entry.root)
        }
    }
}
$GameRoot = Resolve-ExistingDirectory -Path $GameRoot -Label 'Game root'
$gameDlcRoots = [Collections.Generic.List[string]]::new()
if (-not [string]::IsNullOrWhiteSpace($GameRoot)) {
    $gameDlcDirectory = Join-Path $GameRoot 'dlc'
    if (Test-Path -LiteralPath $gameDlcDirectory -PathType Container) {
        foreach ($directory in Get-ChildItem -LiteralPath $gameDlcDirectory -Directory -ErrorAction SilentlyContinue) {
            $gameDlcRoots.Add($directory.FullName)
        }
    }
}

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

$gameDlcGfxCandidates = @($gfxReferences.Keys | Where-Object { -not $gfxDefinitions.ContainsKey($_) })
if ($gameDlcRoots.Count -gt 0 -and $gameDlcGfxCandidates.Count -gt 0) {
    $escapedGfxCandidates = @($gameDlcGfxCandidates | ForEach-Object { [regex]::Escape($_) })
    $gameDlcGfxPattern = [regex]::new(
        ('(?<![A-Za-z0-9_])name\s*=\s*"?(' + ($escapedGfxCandidates -join '|') + ')"?'),
        [Text.RegularExpressions.RegexOptions]::Compiled
    )
    foreach ($gameDlcRoot in $gameDlcRoots) {
        $gameDlcInterface = Join-Path $gameDlcRoot 'interface'
        if (-not (Test-Path -LiteralPath $gameDlcInterface -PathType Container)) { continue }
        foreach ($gameDlcFile in Get-ChildItem -LiteralPath $gameDlcInterface -Recurse -File -ErrorAction SilentlyContinue | Where-Object { @('.gfx', '.gui') -contains $_.Extension.ToLowerInvariant() }) {
            try {
                $gameDlcContent = [IO.File]::ReadAllText($gameDlcFile.FullName, [Text.Encoding]::UTF8)
                foreach ($match in $gameDlcGfxPattern.Matches($gameDlcContent)) {
                    Add-MapEntry -Map $gfxDefinitions -Key $match.Groups[1].Value -Value ([pscustomobject]@{
                        root = 'game-dlc'
                        file = Get-RelativePath -Root $gameDlcRoot -Path $gameDlcFile.FullName
                        line = 1
                    })
                }
            }
            catch {
                Add-Finding -Severity Warning -Code 'GAME_DLC_GFX_READ_FAILED' -Message "Could not inspect DLC GFX file '$($gameDlcFile.FullName)'." -Location $null -Evidence $_.Exception.Message -Heuristic $false
            }
        }
    }
}
$missingGfxKeys = @($gfxReferences.Keys | Where-Object { -not $gfxDefinitions.ContainsKey($_) })
Publish-MissingReferences -Keys $missingGfxKeys -ReferenceMap $gfxReferences -Code 'MISSING_GFX' -Noun 'GFX object'

$assetSearchRoots = [Collections.Generic.List[string]]::new()
$assetSearchRoots.Add($ModRoot)
foreach ($dependency in $resolvedDependencies) { $assetSearchRoots.Add($dependency) }
if (-not [string]::IsNullOrWhiteSpace($GameRoot)) { $assetSearchRoots.Add($GameRoot) }
foreach ($gameDlcRoot in $gameDlcRoots) { $assetSearchRoots.Add($gameDlcRoot) }
$missingAssetPaths = [Collections.Generic.List[string]]::new()
$extensionMismatchAssetPaths = [Collections.Generic.List[string]]::new()
foreach ($assetPath in $assetReferences.Keys) {
    $firstReference = $assetReferences[$assetPath][0]
    $sourceFile = $primaryFiles | Where-Object { $_.RelativePath -eq $firstReference.file } | Select-Object -First 1
    if ($null -ne $sourceFile -and -not (Test-AssetPath -Reference $assetPath -SourceFile $sourceFile -Roots @($assetSearchRoots))) {
        $alternatives = @(Find-AssetAlternatives -Reference $assetPath -SourceFile $sourceFile -Roots @($assetSearchRoots))
        if ($alternatives.Count -gt 0) {
            $extensionMismatchAssetPaths.Add($assetPath)
            Add-Finding -Severity Warning -Code 'ASSET_EXTENSION_MISMATCH' -Message "Asset path '$assetPath' is missing, but the same basename exists with another texture extension." -Location $firstReference -Evidence (($alternatives | Select-Object -First 6) -join ', ') -Heuristic $false
        }
        else {
            $missingAssetPaths.Add($assetPath)
        }
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

$mediaInventory = $null
if ($AuditMedia) {
    $mediaInventory = Get-MediaInventory -Root $ModRoot -IndexedFiles $primaryFiles -ReferenceMap $assetReferences -SearchRoots @($assetSearchRoots)
    if ($mediaInventory.exactDuplicateGroups.Count -gt 0) {
        Add-Finding -Severity Info -Code 'DUPLICATE_MEDIA_SUMMARY' -Message "$($mediaInventory.exactDuplicateGroups.Count) groups of byte-identical media were found." -Location $null -Evidence "Potential deduplication savings: $($mediaInventory.potentialDuplicateSavingsBytes) bytes. Review consumer paths before removing copies."
    }
    if ($mediaInventory.unreferencedCandidates -gt 0) {
        Add-Finding -Severity Info -Code 'UNREFERENCED_MEDIA_SUMMARY' -Message "$($mediaInventory.unreferencedCandidates) media files have no explicit reference in the indexed mod files." -Location $null -Evidence 'This is a lead only: engine-discovered, generated, dependency, and pattern-based consumers can evade static indexing.' -Heuristic $true
    }
}

$candidateFindings = @($script:Findings)
if ($ChangedOnly) {
    $candidateFindings = @($candidateFindings | Where-Object {
        if ($null -ne $_.location -and $changedFiles.Contains(([string]$_.location.file).Replace('/', '\'))) { return $true }
        foreach ($changedPath in $changedFiles) {
            if (-not [string]::IsNullOrWhiteSpace($_.evidence) -and $_.evidence.IndexOf($changedPath, [StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
        }
        return $false
    })
}

$suppressionPolicy = Read-JsonFile -Path $SuppressionsPath -Label 'Suppression policy'
if ($null -ne $suppressionPolicy) {
    if ($suppressionPolicy.schemaVersion -ne 1 -or $null -eq $suppressionPolicy.suppressions) {
        throw 'Suppression policy must use schemaVersion 1 and contain suppressions.'
    }
    $activeSuppressions = [Collections.Generic.List[object]]::new()
    foreach ($rule in @($suppressionPolicy.suppressions)) {
        if ([string]::IsNullOrWhiteSpace([string]$rule.code) -or [string]::IsNullOrWhiteSpace([string]$rule.reason)) {
            throw 'Every suppression requires code and reason.'
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$rule.expires)) {
            $expiry = [DateTime]::MinValue
            if (-not [DateTime]::TryParseExact([string]$rule.expires, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$expiry)) {
                throw "Invalid suppression expiry '$($rule.expires)'; use YYYY-MM-DD."
            }
            if ($expiry.Date -lt (Get-Date).Date) {
                Add-Finding -Severity Warning -Code 'EXPIRED_SUPPRESSION' -Message "Suppression for '$($rule.code)' expired on $($rule.expires)." -Location $null -Evidence ([string]$rule.reason)
                continue
            }
        }
        $activeSuppressions.Add($rule)
    }
    $candidateFindings = @($candidateFindings | Where-Object {
        $finding = $_
        $matched = $false
        foreach ($rule in $activeSuppressions) {
            if ($finding.code -ne [string]$rule.code) { continue }
            $file = if ($null -ne $finding.location) { [string]$finding.location.file } else { '' }
            $filePattern = if ($null -ne $rule.PSObject.Properties['filePattern']) { [string]$rule.filePattern } else { '' }
            $messagePattern = if ($null -ne $rule.PSObject.Properties['messagePattern']) { [string]$rule.messagePattern } else { '' }
            if (-not [string]::IsNullOrWhiteSpace($filePattern) -and $file -notmatch $filePattern) { continue }
            if (-not [string]::IsNullOrWhiteSpace($messagePattern) -and $finding.message -notmatch $messagePattern) { continue }
            $matched = $true
            break
        }
        if ($matched) { $script:PolicySuppressedFindings++ }
        return -not $matched
    })
    $expiredFindings = @($script:Findings | Where-Object { $_.code -eq 'EXPIRED_SUPPRESSION' })
    $candidateFindings = @($candidateFindings) + $expiredFindings
}

$baseline = Read-JsonFile -Path $BaselinePath -Label 'Baseline report'
if ($null -ne $baseline) {
    $baselineFingerprints = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($finding in @($baseline.findings)) { [void]$baselineFingerprints.Add((Get-FindingFingerprint -Finding $finding)) }
    $candidateFindings = @($candidateFindings | Where-Object {
        $exists = $baselineFingerprints.Contains((Get-FindingFingerprint -Finding $_))
        if ($exists) { $script:BaselineSuppressedFindings++ }
        return -not $exists
    })
}

$allOrderedFindings = @($candidateFindings | Sort-Object @{ Expression = { switch ($_.severity) { 'Error' { 0 } 'Warning' { 1 } default { 2 } } } }, code, @{ Expression = { if ($null -ne $_.location) { $_.location.file } else { '' } } }, @{ Expression = { if ($null -ne $_.location) { $_.location.line } else { 0 } } })
$errorCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Error' }).Count
$warningCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Warning' }).Count
$infoCount = @($allOrderedFindings | Where-Object { $_.severity -eq 'Info' }).Count
$confirmedCount = @($allOrderedFindings | Where-Object { $_.certainty -eq 'confirmed' }).Count
$leadCount = @($allOrderedFindings | Where-Object { $_.certainty -eq 'lead' }).Count
$script:SuppressedFindings = [Math]::Max(0, $allOrderedFindings.Count - $MaxFindings)
$orderedFindings = @($allOrderedFindings | Select-Object -First $MaxFindings)
$modLocalisationCompoundKeys = @($localisationDefinitions.Keys | Where-Object {
    @($localisationDefinitions[$_] | Where-Object { $_.root -eq 'mod' }).Count -gt 0
})
$languages = @($modLocalisationCompoundKeys | ForEach-Object { $_.Split('|', 2)[0] } | Sort-Object -Unique)

$result = [pscustomobject]@{
    tool = 'HOI4 Mod Doctor'
    schemaVersion = 2
    generatedAt = (Get-Date).ToString('o')
    mode = [pscustomobject]@{
        format = $Format
        changedOnly = [bool]$ChangedOnly
        gitBase = if ($ChangedOnly) { $GitBase } else { $null }
        baseline = $BaselinePath
        suppressionPolicy = $SuppressionsPath
        mediaAudit = [bool]$AuditMedia
    }
    roots = [pscustomobject]@{
        mod = $ModRoot
        dependencies = @($resolvedDependencies)
        playsetDescriptors = @($playsetDescriptors)
        game = $GameRoot
        gameDlcRoots = @($gameDlcRoots)
    }
    summary = [pscustomobject]@{
        filesScanned = $allFiles.Count
        modFilesScanned = $primaryFiles.Count
        errors = $errorCount
        warnings = $warningCount
        info = $infoCount
        confirmed = $confirmedCount
        heuristicLeads = $leadCount
        outputTruncated = $script:SuppressedFindings
        baselineSuppressed = $script:BaselineSuppressedFindings
        policySuppressed = $script:PolicySuppressedFindings
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
        extensionMismatchAssetPaths = $extensionMismatchAssetPaths.Count
    }
    commentCoverage = @($commentStats | Sort-Object file)
    media = $mediaInventory
    findings = $orderedFindings
    limitations = @(
        'This is a static, read-only audit. It does not prove runtime correctness or balance.',
        'Missing and orphan results are heuristic unless all enabled dependencies and the matching game root were supplied.',
        'Dynamic identifiers, generated GUI names, scripted localisation, and engine-owned consumers can evade static indexing.',
        'Gameplay design, balance, and UX judgments require the documented player promise plus playtest evidence.'
    )
}

switch ($Format) {
    'Json' {
        $rendered = $result | ConvertTo-Json -Depth 10
    }
    'Markdown' {
        $lines = [Collections.Generic.List[string]]::new()
        $lines.Add('# HOI4 Mod Doctor')
        $lines.Add('')
        $lines.Add('## Summary')
        $lines.Add('')
        $lines.Add("- Root: ``$ModRoot``")
        $lines.Add("- Scanned: $($result.summary.modFilesScanned) mod files / $($result.summary.filesScanned) effective files")
        $lines.Add("- Findings: $errorCount errors, $warningCount warnings, $infoCount info")
        $lines.Add("- Certainty: $confirmedCount confirmed findings, $leadCount heuristic leads")
        $lines.Add("- Filtered: $($script:BaselineSuppressedFindings) baseline, $($script:PolicySuppressedFindings) policy, $($script:SuppressedFindings) output cap")
        foreach ($section in @(
            [pscustomobject]@{ Heading = 'Confirmed findings'; Findings = @($orderedFindings | Where-Object { $_.certainty -eq 'confirmed' }) },
            [pscustomobject]@{ Heading = 'Heuristic leads'; Findings = @($orderedFindings | Where-Object { $_.certainty -eq 'lead' }) }
        )) {
            $lines.Add('')
            $lines.Add("## $($section.Heading)")
            $lines.Add('')
            if ($section.Findings.Count -eq 0) { $lines.Add('_None._') }
            foreach ($finding in $section.Findings) {
                $locationText = if ($null -ne $finding.location) { " (``$($finding.location.file):$($finding.location.line)``)" } else { '' }
                $lines.Add("- **$($finding.severity) $($finding.code)**${locationText}: $($finding.message)")
                if (-not [string]::IsNullOrWhiteSpace($finding.evidence)) { $lines.Add("  Evidence: $($finding.evidence)") }
            }
        }
        if ($null -ne $mediaInventory) {
            $lines.Add('')
            $lines.Add('## Media')
            $lines.Add('')
            $lines.Add("- Files: $($mediaInventory.files)")
            $lines.Add("- Bytes: $($mediaInventory.bytes)")
            $lines.Add("- Exact duplicate groups: $($mediaInventory.exactDuplicateGroups.Count)")
            $lines.Add("- Potential duplicate savings: $($mediaInventory.potentialDuplicateSavingsBytes) bytes")
            $lines.Add("- Unreferenced candidates: $($mediaInventory.unreferencedCandidates) ($($mediaInventory.unreferencedCandidateBytes) bytes)")
        }
        $lines.Add('')
        $lines.Add('Static findings are a baseline, not runtime proof or permission to make subjective design changes.')
        $rendered = $lines -join [Environment]::NewLine
    }
    'Sarif' {
        $rules = @($orderedFindings | Group-Object code | ForEach-Object {
            [pscustomobject]@{
                id = $_.Name
                name = $_.Name
                shortDescription = [pscustomobject]@{ text = $_.Group[0].message }
                properties = [pscustomobject]@{ certainty = $_.Group[0].certainty }
            }
        })
        $sarifResults = @($orderedFindings | ForEach-Object {
            $level = switch ($_.severity) { 'Error' { 'error' } 'Warning' { 'warning' } default { 'note' } }
            $locations = @()
            if ($null -ne $_.location) {
                $locations = @([pscustomobject]@{
                    physicalLocation = [pscustomobject]@{
                        artifactLocation = [pscustomobject]@{ uri = ([string]$_.location.file).Replace('\', '/') }
                        region = [pscustomobject]@{ startLine = [int]$_.location.line }
                    }
                })
            }
            [pscustomobject]@{
                ruleId = $_.code
                level = $level
                message = [pscustomobject]@{ text = $_.message }
                locations = $locations
                properties = [pscustomobject]@{ certainty = $_.certainty; evidence = $_.evidence }
            }
        })
        $sarif = [pscustomobject]@{
            version = '2.1.0'
            '$schema' = 'https://json.schemastore.org/sarif-2.1.0.json'
            runs = @([pscustomobject]@{
                tool = [pscustomobject]@{ driver = [pscustomobject]@{ name = 'HOI4 Mod Doctor'; informationUri = 'https://github.com/Fostanico/hoi4-ai-modding-skills'; rules = $rules } }
                results = $sarifResults
            })
        }
        $rendered = $sarif | ConvertTo-Json -Depth 12
    }
    default {
        $lines = [Collections.Generic.List[string]]::new()
        $lines.Add('HOI4 Mod Doctor')
        $lines.Add("Root: $ModRoot")
        $lines.Add("Scanned: $($result.summary.modFilesScanned) mod files / $($result.summary.filesScanned) effective files")
        $lines.Add("Definitions: $($result.inventory.events) events, $($result.inventory.scriptedEffects) scripted effects, $($result.inventory.scriptedTriggers) scripted triggers, $($result.inventory.gfxObjects) GFX objects")
        $lines.Add("Localisation: $($result.inventory.localisationKeys) keys across $($languages.Count) languages")
        $lines.Add("Findings: $errorCount errors, $warningCount warnings, $infoCount info; $confirmedCount confirmed, $leadCount heuristic")
        $lines.Add("Filtered: $($script:BaselineSuppressedFindings) baseline, $($script:PolicySuppressedFindings) policy, $($script:SuppressedFindings) output cap")
        $lines.Add('')
        foreach ($finding in $orderedFindings) {
            $locationText = if ($null -ne $finding.location) { " [$($finding.location.file):$($finding.location.line)]" } else { '' }
            $lines.Add("[$($finding.severity)] $($finding.code)$locationText [$($finding.certainty)] - $($finding.message)")
            if (-not [string]::IsNullOrWhiteSpace($finding.evidence)) { $lines.Add("  $($finding.evidence)") }
        }
        if ($null -ne $mediaInventory) {
            $lines.Add('')
            $lines.Add("Media: $($mediaInventory.files) files / $($mediaInventory.bytes) bytes; $($mediaInventory.exactDuplicateGroups.Count) exact duplicate groups; $($mediaInventory.unreferencedCandidates) unreferenced candidates")
        }
        $lines.Add('')
        $lines.Add('Static findings are a baseline, not runtime proof or permission to make subjective design changes.')
        $rendered = $lines -join [Environment]::NewLine
    }
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
