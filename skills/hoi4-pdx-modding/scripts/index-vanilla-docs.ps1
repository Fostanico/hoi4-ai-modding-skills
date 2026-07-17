param(
	[Parameter(Mandatory = $true)]
	[string]$GameRoot
)

$resolvedRoot = (Resolve-Path -LiteralPath $GameRoot).Path
$files = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter '*.md' |
	Sort-Object FullName

foreach ($file in $files) {
	$lines = Get-Content -LiteralPath $file.FullName
	$headings = @(
		$lines |
			Where-Object { $_ -match '^#{1,4} ' } |
			ForEach-Object { $_.Trim() }
	)

	[pscustomobject]@{
		Path = $file.FullName.Substring($resolvedRoot.Length + 1)
		Lines = $lines.Count
		Bytes = $file.Length
		Headings = $headings -join ' | '
	}
}
