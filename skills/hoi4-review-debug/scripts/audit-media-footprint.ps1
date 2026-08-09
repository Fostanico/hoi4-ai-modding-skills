[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$ModRoot,
    [ValidateSet('Text', 'Json', 'Markdown')][string]$Format = 'Text',
    [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelativePath {
    param([string]$Root, [string]$Path)
    $rootUri = [Uri]($Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar)
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri([Uri]$Path).ToString()).Replace('/', '\')
}

function Test-ExcludedPath {
    param([string]$Root, [string]$Path)
    $segments = (Get-RelativePath -Root $Root -Path $Path).Split(@('\', '/'), [StringSplitOptions]::RemoveEmptyEntries)
    return @($segments | Where-Object { $_ -in @('.git', '.agents', 'dist', 'tmp', 'logs', 'crashes') }).Count -gt 0
}

function Get-UInt32LE {
    param([byte[]]$Bytes, [int]$Offset)
    if ($Bytes.Length -lt ($Offset + 4)) { return $null }
    return [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Get-Signature {
    param([IO.FileInfo]$File)
    $stream = [IO.File]::OpenRead($File.FullName)
    try {
        $bytes = [byte[]]::new([int][Math]::Min(148L, $stream.Length))
        [void]$stream.Read($bytes, 0, $bytes.Length)
    }
    finally { $stream.Dispose() }
    $kind = 'unknown'
    if ($bytes.Length -ge 4 -and [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq 'DDS ') { $kind = 'dds' }
    elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x89 -and [Text.Encoding]::ASCII.GetString($bytes, 1, 3) -eq 'PNG') { $kind = 'png' }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xD8 -and $bytes[2] -eq 0xFF) { $kind = 'jpeg' }
    elseif ($bytes.Length -ge 4 -and [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq 'OggS') { $kind = 'ogg' }
    elseif ($bytes.Length -ge 4 -and [Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq 'RIFF') { $kind = 'riff' }
    return [pscustomobject]@{ kind = $kind; bytes = $bytes }
}

function Get-DdsMetadata {
    param([byte[]]$Header)
    if ($Header.Length -lt 128 -or [Text.Encoding]::ASCII.GetString($Header, 0, 4) -ne 'DDS ') { return $null }
    $fourCC = [Text.Encoding]::ASCII.GetString($Header, 84, 4).Trim([char]0)
    $caps2 = Get-UInt32LE -Bytes $Header -Offset 112
    return [pscustomobject]@{
        width = Get-UInt32LE -Bytes $Header -Offset 16
        height = Get-UInt32LE -Bytes $Header -Offset 12
        mipmaps = Get-UInt32LE -Bytes $Header -Offset 28
        fourCC = $fourCC
        cubemap = (($caps2 -band 0x00000200) -ne 0)
        dx10 = ($fourCC -eq 'DX10')
    }
}

if ([string]::IsNullOrWhiteSpace($ModRoot)) {
    $gitRoot = & git rev-parse --show-toplevel 2>$null
    $ModRoot = if ($LASTEXITCODE -eq 0) { $gitRoot.Trim() } else { (Get-Location).Path }
}
$resolved = Resolve-Path -LiteralPath $ModRoot -ErrorAction SilentlyContinue
if ($null -eq $resolved -or -not (Test-Path -LiteralPath $resolved.Path -PathType Container)) { throw "Mod root does not exist: $ModRoot" }
$ModRoot = $resolved.Path.TrimEnd('\', '/')

$literalReferences = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$sourceFiles = @(Get-ChildItem -LiteralPath $ModRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension.ToLowerInvariant() -in @('.txt', '.gui', '.gfx', '.asset') -and -not (Test-ExcludedPath -Root $ModRoot -Path $_.FullName)
})
foreach ($source in $sourceFiles) {
    $content = [IO.File]::ReadAllText($source.FullName, [Text.Encoding]::UTF8)
    foreach ($match in [regex]::Matches($content, '"([^"\r\n]+\.(?:dds|png|tga|jpg|jpeg|wav|ogg|mp3))"', [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $candidate = Join-Path $ModRoot $match.Groups[1].Value.Replace('/', '\')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { [void]$literalReferences.Add((Resolve-Path -LiteralPath $candidate).Path) }
    }
}

$mediaFiles = @(Get-ChildItem -LiteralPath $ModRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Extension.ToLowerInvariant() -in @('.dds', '.png', '.tga', '.jpg', '.jpeg', '.wav', '.ogg', '.mp3') -and -not (Test-ExcludedPath -Root $ModRoot -Path $_.FullName)
})
$records = [Collections.Generic.List[object]]::new()
$hashGroups = @{}
foreach ($file in $mediaFiles) {
    $relative = Get-RelativePath -Root $ModRoot -Path $file.FullName
    $path = $relative.Replace('\', '/').ToLowerInvariant()
    $extension = $file.Extension.ToLowerInvariant()
    $signature = Get-Signature -File $file
    $dds = if ($extension -eq '.dds') { Get-DdsMetadata -Header $signature.bytes } else { $null }
    $engineDiscovered = $path -eq 'thumbnail.png' -or $path.StartsWith('gfx/flags/') -or $path.StartsWith('gfx/achievements/') -or $path -match '^music/hoi4maintheme[^/]*\.ogg$'
    $preserveReason = $null
    if ($path.StartsWith('gfx/loadingscreens/')) { $preserveReason = 'loading screens are runtime-verified DDS consumers' }
    elseif ($path.StartsWith('gfx/models/')) { $preserveReason = 'model/material consumer' }
    elseif ($null -ne $dds -and $dds.cubemap) { $preserveReason = 'DDS cubemap' }
    elseif ($null -ne $dds -and $dds.mipmaps -gt 1) { $preserveReason = 'DDS contains mipmaps' }
    $classification = if ($null -ne $preserveReason) { 'retain_dds' } elseif ($extension -eq '.dds' -and $literalReferences.Contains($file.FullName)) { 'png_comparison_candidate' } elseif (-not $literalReferences.Contains($file.FullName) -and -not $engineDiscovered) { 'investigate_consumer' } else { 'retain_current' }
    $expectedSignatures = switch ($extension) { '.dds' { @('dds') } '.png' { @('png') } '.jpg' { @('jpeg') } '.jpeg' { @('jpeg') } '.ogg' { @('ogg') } '.wav' { @('riff') } default { @('unknown') } }
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not $hashGroups.ContainsKey($hash)) { $hashGroups[$hash] = [Collections.Generic.List[string]]::new() }
    $hashGroups[$hash].Add($relative)
    $records.Add([pscustomobject]@{
        path = $relative; bytes = [long]$file.Length; extension = $extension
        actualSignature = $signature.kind; extensionMatchesSignature = ($expectedSignatures -contains $signature.kind)
        explicitlyReferenced = $literalReferences.Contains($file.FullName); engineDiscovered = $engineDiscovered
        classification = $classification; preserveReason = $preserveReason; dds = $dds; sha256 = $hash
    })
}

$duplicates = @($hashGroups.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 } | ForEach-Object {
    $hash = $_.Key
    $first = $records | Where-Object { $_.sha256 -eq $hash } | Select-Object -First 1
    [pscustomobject]@{ sha256 = $hash; bytesEach = $first.bytes; count = $_.Value.Count; potentialSavingsBytes = [long]$first.bytes * ($_.Value.Count - 1); paths = @($_.Value | Sort-Object) }
})
$totalMeasure = $records | Measure-Object bytes -Sum
$savingMeasure = $duplicates | Measure-Object potentialSavingsBytes -Sum
$result = [pscustomobject]@{
    tool = 'HOI4 Media Footprint Audit'; schemaVersion = 1; generatedAt = (Get-Date).ToString('o'); root = $ModRoot
    summary = [pscustomobject]@{
        files = $records.Count; bytes = if ($null -ne $totalMeasure) { [long]$totalMeasure.Sum } else { [long]0 }
        exactDuplicateGroups = $duplicates.Count; potentialDuplicateSavingsBytes = if ($null -ne $savingMeasure) { [long]$savingMeasure.Sum } else { [long]0 }
        pngComparisonCandidates = @($records | Where-Object { $_.classification -eq 'png_comparison_candidate' }).Count
        consumerInvestigationCandidates = @($records | Where-Object { $_.classification -eq 'investigate_consumer' }).Count
        signatureMismatches = @($records | Where-Object { -not $_.extensionMatchesSignature }).Count
    }
    byExtension = @($records | Group-Object extension | ForEach-Object { [pscustomobject]@{ extension = $_.Name; files = $_.Count; bytes = [long](($_.Group | Measure-Object bytes -Sum).Sum) } } | Sort-Object bytes -Descending)
    exactDuplicates = $duplicates; files = @($records | Sort-Object bytes -Descending)
    limitations = @('Literal references do not cover every engine-discovered or generated consumer.', 'A PNG comparison candidate still requires pixel-equivalence, size, registration, and runtime tests.', 'No file is converted or deleted by this audit.')
}

if ($Format -eq 'Json') { $rendered = $result | ConvertTo-Json -Depth 9 }
else {
    $lines = [Collections.Generic.List[string]]::new()
    if ($Format -eq 'Markdown') { $lines.Add('# HOI4 Media Footprint Audit'); $lines.Add('') } else { $lines.Add('HOI4 Media Footprint Audit') }
    $lines.Add("Root: $ModRoot")
    $lines.Add("Files: $($result.summary.files); bytes: $($result.summary.bytes)")
    $lines.Add("Exact duplicate groups: $($result.summary.exactDuplicateGroups); potential savings: $($result.summary.potentialDuplicateSavingsBytes) bytes")
    $lines.Add("PNG comparison candidates: $($result.summary.pngComparisonCandidates); consumer investigations: $($result.summary.consumerInvestigationCandidates)")
    $lines.Add("Signature mismatches: $($result.summary.signatureMismatches)")
    $lines.Add(''); $lines.Add('Largest candidates:')
    foreach ($record in @($records | Where-Object { $_.classification -in @('png_comparison_candidate', 'investigate_consumer') } | Sort-Object bytes -Descending | Select-Object -First 30)) { $lines.Add("- $($record.path) [$($record.classification)] $($record.bytes) bytes") }
    $rendered = $lines -join [Environment]::NewLine
}

if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $full = [IO.Path]::GetFullPath($OutputPath)
    if ((Test-Path -LiteralPath $full) -and -not $Force) { throw "Output file exists; use -Force: $full" }
    $parent = [IO.Path]::GetDirectoryName($full)
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) { [void][IO.Directory]::CreateDirectory($parent) }
    [IO.File]::WriteAllText($full, $rendered, [Text.UTF8Encoding]::new($false))
}
else { Write-Output $rendered }
