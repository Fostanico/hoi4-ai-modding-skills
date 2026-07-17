[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$TextureRoot,
    [ValidateSet('generic', 'focus', 'idea')]
    [string]$Kind = 'generic',
    [string]$SpritePrefix = 'GFX_',
    [switch]$IncludeShine,
    [string]$OutputPath,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($IncludeShine -and $Kind -ne 'focus') { throw '-IncludeShine is only valid with -Kind focus.' }

$source = (Resolve-Path -LiteralPath $SourcePath).Path
if (-not (Get-Item -LiteralPath $source).PSIsContainer) { throw "SourcePath must be a directory: $source" }
$textures = @(Get-ChildItem -LiteralPath $source -File -Recurse | Where-Object Extension -in '.dds', '.png', '.tga' | Sort-Object FullName)
if ($textures.Count -eq 0) { throw "No .dds, .png, or .tga files found under $source" }

$textureRootNormalized = $TextureRoot.Trim().TrimEnd('/', '\').Replace('\', '/')
$entries = [System.Collections.Generic.List[string]]::new()
$spriteNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($texture in $textures) {
    $relative = $texture.FullName.Substring($source.TrimEnd('\').Length).TrimStart('\', '/').Replace('\', '/')
    $stem = $relative.Substring(0, $relative.Length - $texture.Extension.Length).Replace('/', '_')
    $stem = [regex]::Replace($stem, '[^A-Za-z0-9_]', '_')
    if ($Kind -eq 'focus' -and -not $stem.StartsWith('focus_', [System.StringComparison]::OrdinalIgnoreCase)) { $stem = "focus_$stem" }
    if ($Kind -eq 'idea' -and -not $stem.StartsWith('idea_', [System.StringComparison]::OrdinalIgnoreCase)) { $stem = "idea_$stem" }
    $spriteName = "$SpritePrefix$stem"
    if (-not $spriteNames.Add($spriteName)) { throw "Two texture paths normalize to the same sprite name: $spriteName" }
    $texturePath = "$textureRootNormalized/$relative"
    $entries.Add("`tSpriteType = {")
    $entries.Add("`t`tname = `"$spriteName`"")
    $entries.Add("`t`ttexturefile = `"$texturePath`"")
    $entries.Add("`t}")
    if ($IncludeShine) {
        $entries.Add('')
        $entries.Add("`tSpriteType = {")
        $entries.Add("`t`tname = `"${spriteName}_shine`"")
        $entries.Add("`t`ttexturefile = `"$texturePath`"")
        $entries.Add("`t`teffectFile = `"gfx/FX/buttonstate.lua`"")
        foreach ($rotation in @('-90.0', '90.0')) {
            $entries.Add("`t`tanimation = {")
            $entries.Add("`t`t`tanimationmaskfile = `"$texturePath`"")
            $entries.Add("`t`t`tanimationtexturefile = `"gfx/interface/goals/shine_overlay.dds`"")
            $entries.Add("`t`t`tanimationrotation = $rotation")
            $entries.Add("`t`t`tanimationlooping = no")
            $entries.Add("`t`t`tanimationtime = 0.75")
            $entries.Add("`t`t`tanimationdelay = 0")
            $entries.Add("`t`t`tanimationblendmode = `"add`"")
            $entries.Add("`t`t`tanimationtype = `"scrolling`"")
            $entries.Add("`t`t`tanimationrotationoffset = { x = 0.0 y = 0.0 }")
            $entries.Add("`t`t`tanimationtexturescale = { x = 1.0 y = 1.0 }")
            $entries.Add("`t`t}")
        }
        $entries.Add("`t`tlegacy_lazy_load = no")
        $entries.Add("`t}")
    }
    $entries.Add('')
}

$content = "spriteTypes = {`r`n$($entries -join "`r`n")`r`n}`r`n"
if (-not $OutputPath) { $content; return }
$fullOutput = [System.IO.Path]::GetFullPath($OutputPath)
if ((Test-Path -LiteralPath $fullOutput) -and -not $Force) { throw "Output already exists. Use -Force to replace it: $fullOutput" }
$parent = Split-Path -Parent $fullOutput
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    [void](New-Item -ItemType Directory -Path $parent)
}
[System.IO.File]::WriteAllText($fullOutput, $content, [System.Text.UTF8Encoding]::new($false))
$fullOutput
