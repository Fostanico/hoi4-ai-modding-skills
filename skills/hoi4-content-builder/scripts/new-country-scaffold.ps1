[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z0-9]{3}$')]
    [string]$Tag,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 9999)]
    [int]$CapitalState,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CountryName,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [ValidateRange(0, 255)]
    [int]$Red = 128,

    [ValidateRange(0, 255)]
    [int]$Green = 128,

    [ValidateRange(0, 255)]
    [int]$Blue = 128,

    [ValidatePattern('^[a-z_]+$')]
    [string]$Language = 'english',

    [ValidatePattern('^l_[a-z_]+$')]
    [string]$LanguageHeader = 'l_english',

    [string]$LeaderName = 'Replace with leader name',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

if ($CountryName.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or
    $CountryName -ne $CountryName.Trim() -or $CountryName.EndsWith('.')) {
    throw 'CountryName must also be a valid Windows file-name segment.'
}

$root = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $root -PathType Leaf) {
    throw "OutputPath is a file: $root"
}
if ((Test-Path -LiteralPath $root) -and -not $Force) {
    $existing = @(Get-ChildItem -LiteralPath $root -Force)
    if ($existing.Count -gt 0) {
        throw "OutputPath is not empty. Use -Force to overwrite generated files: $root"
    }
}

$utf8NoBom = [Text.UTF8Encoding]::new($false)
$utf8Bom = [Text.UTF8Encoding]::new($true)

function Write-GeneratedFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][Text.Encoding]$Encoding
    )

    $path = Join-Path $root $RelativePath
    $directory = Split-Path -Parent $path
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    if ((Test-Path -LiteralPath $path) -and -not $Force) {
        throw "Generated file already exists: $path"
    }
    [IO.File]::WriteAllText($path, $Content.TrimStart("`r", "`n") + "`r`n", $Encoding)
}

$leader = "${Tag}_leader"

$countryTagContent = @"
$Tag = "countries/$Tag.txt"
"@
Write-GeneratedFile -RelativePath "common/country_tags/${Tag}_country_tags.txt" -Content $countryTagContent -Encoding $utf8NoBom

$countryContent = @"
graphical_culture = western_european_gfx
graphical_culture_2d = western_european_2d

color = { $Red $Green $Blue }
"@
Write-GeneratedFile -RelativePath "common/countries/$Tag.txt" -Content $countryContent -Encoding $utf8NoBom

$characterContent = @"
characters = {
	$leader = {
		name = $leader

		portraits = {
			civilian = {
				large = GFX_portrait_unknown
			}
		}

		country_leader = {
			ideology = despotism
			expire = "1965.1.1.1"
			id = -1
		}
	}
}
"@
Write-GeneratedFile -RelativePath "common/characters/${Tag}_characters.txt" -Content $characterContent -Encoding $utf8NoBom

$historyContent = @"
capital = $CapitalState

set_politics = {
	ruling_party = neutrality
	last_election = "1932.1.1"
	election_frequency = 48
	elections_allowed = no
}

set_popularities = {
	democratic = 10
	fascism = 10
	communism = 10
	neutrality = 70
}

recruit_character = $leader
"@
Write-GeneratedFile -RelativePath "history/countries/$Tag - $CountryName.txt" -Content $historyContent -Encoding $utf8NoBom

$localisation = [Collections.Generic.List[string]]::new()
$localisation.Add("${LanguageHeader}:")
foreach ($ideology in 'democratic', 'fascism', 'communism', 'neutrality') {
    $localisation.Add(" ${Tag}_${ideology}: `"$CountryName`"")
    $localisation.Add(" ${Tag}_${ideology}_DEF: `"$CountryName`"")
    $localisation.Add(" ${Tag}_${ideology}_ADJ: `"$CountryName`"")
}
$localisation.Add(" $Tag`: `"$CountryName`"")
$localisation.Add(" ${Tag}_DEF: `"$CountryName`"")
$localisation.Add(" ${Tag}_ADJ: `"$CountryName`"")
$localisation.Add(" $leader`: `"$LeaderName`"")
Write-GeneratedFile -RelativePath "localisation/$Language/${Tag}_l_${Language}.yml" -Content ($localisation -join "`r`n") -Encoding $utf8Bom

$checklistContent = @"
# $Tag country scaffold

- Replace the placeholder leader name and portrait.
- Verify capital state ID $CapitalState against current map files.
- Add large, medium, and small TGA flags for every required ideology under gfx/flags.
- Add state ownership/history separately; this generator does not alter the map.
- Run the repo validator, check localisation collisions, and inspect a fresh error.log.
"@
Write-GeneratedFile -RelativePath 'SCAFFOLD_CHECKLIST.md' -Content $checklistContent -Encoding $utf8NoBom

Write-Output $root
