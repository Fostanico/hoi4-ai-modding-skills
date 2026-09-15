[CmdletBinding()]
param(
    [string]$MarketplaceRoot,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
$pluginName = 'hoi4-ai-modding-skills'
$marketplaceName = 'hoi4-local-modding'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

if ([string]::IsNullOrWhiteSpace($MarketplaceRoot)) {
    $localData = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localData)) {
        throw 'Windows LocalApplicationData could not be resolved.'
    }
    $MarketplaceRoot = Join-Path $localData 'hoi4-ai-modding-marketplace'
}

$marketplaceRootPath = [IO.Path]::GetFullPath($MarketplaceRoot).TrimEnd('\', '/')
$pluginsRoot = Join-Path $marketplaceRootPath 'plugins'
$pluginRoot = Join-Path $pluginsRoot $pluginName
$expectedPluginRoot = [IO.Path]::GetFullPath($pluginRoot)
$pluginsPrefix = [IO.Path]::GetFullPath($pluginsRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if (-not $expectedPluginRoot.StartsWith($pluginsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to prepare a plugin outside the managed marketplace: $expectedPluginRoot"
}

$required = @(
    '.codex-plugin',
    '.mcp.json',
    'mcp-server',
    'skills',
    'docs',
    'README.md',
    'README_EN.md',
    'LICENSE',
    'ATTRIBUTION.md'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relative))) {
        throw "Plugin source is incomplete; missing: $relative"
    }
}

if (Test-Path -LiteralPath $expectedPluginRoot) {
    Remove-Item -LiteralPath $expectedPluginRoot -Recurse -Force
}
[void](New-Item -ItemType Directory -Path $expectedPluginRoot -Force)

foreach ($relative in $required) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $expectedPluginRoot -Recurse -Force
}
[void](New-Item -ItemType Directory -Path (Join-Path $expectedPluginRoot 'scripts') -Force)
Copy-Item -LiteralPath (Join-Path $repoRoot 'scripts/test-mcp-server.py') -Destination (Join-Path $expectedPluginRoot 'scripts/test-mcp-server.py') -Force

$pluginManifestPath = Join-Path $expectedPluginRoot '.codex-plugin/plugin.json'
$pluginManifest = Get-Content -Raw -LiteralPath $pluginManifestPath | ConvertFrom-Json
$baseVersion = ([string]$pluginManifest.version).Split('+')[0]
$cachebuster = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
$pluginManifest.version = "$baseVersion+codex.local-$cachebuster"
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText(
    $pluginManifestPath,
    ($pluginManifest | ConvertTo-Json -Depth 20) + "`n",
    $utf8NoBom
)

$marketplaceDirectory = Join-Path $marketplaceRootPath '.agents/plugins'
[void](New-Item -ItemType Directory -Path $marketplaceDirectory -Force)
$marketplacePath = Join-Path $marketplaceDirectory 'marketplace.json'
$marketplace = [ordered]@{
    name = $marketplaceName
    interface = [ordered]@{ displayName = 'HOI4 Local Modding' }
    plugins = @(
        [ordered]@{
            name = $pluginName
            source = [ordered]@{
                source = 'local'
                path = "./plugins/$pluginName"
            }
            policy = [ordered]@{
                installation = 'AVAILABLE'
                authentication = 'ON_INSTALL'
            }
            category = 'Developer Tools'
        }
    )
}
[IO.File]::WriteAllText(
    $marketplacePath,
    ($marketplace | ConvertTo-Json -Depth 20) + "`n",
    $utf8NoBom
)

"Prepared plugin: $expectedPluginRoot"
"Marketplace: $marketplacePath"
"Version: $($pluginManifest.version)"

if ($PrepareOnly) {
    'Preparation-only mode: Codex configuration was not changed.'
    return
}

$codex = Get-Command codex -ErrorAction SilentlyContinue
if ($null -eq $codex) {
    throw 'Codex CLI was not found on PATH. The plugin was prepared, but could not be installed.'
}

$configuredMarketplaces = @(& $codex.Source plugin marketplace list 2>&1)
if ($LASTEXITCODE -ne 0) {
    throw "Could not list Codex marketplaces: $($configuredMarketplaces -join [Environment]::NewLine)"
}
if (-not ($configuredMarketplaces -match ('^' + [regex]::Escape($marketplaceName) + '\s'))) {
    & $codex.Source plugin marketplace add $marketplaceRootPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Codex could not register the local HOI4 marketplace.'
    }
}

& $codex.Source plugin add "$pluginName@$marketplaceName"
if ($LASTEXITCODE -ne 0) {
    throw 'Codex could not install the HOI4 plugin.'
}

'Installation completed. Start a new Codex task to load the Skills and MCP tools.'
