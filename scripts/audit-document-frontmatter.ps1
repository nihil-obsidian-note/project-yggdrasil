param(
    [string]$RootPath = ".",
    [string]$OutputPath = ".\docs\document-frontmatter-audit.md"
)

$ErrorActionPreference = "Stop"

function Get-FrontmatterMap {
    param([string]$Path)

    $content = Get-Content -LiteralPath $Path -Raw
    if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) {
        $content = $content.Substring(1)
    }

    $lines = $content -split "\r?\n"
    if ($lines.Count -lt 3 -or $lines[0] -ne "---") {
        return $null
    }

    $closingIndex = [Array]::IndexOf($lines, "---", 1)
    if ($closingIndex -lt 1) {
        return $null
    }

    $map = @{}
    foreach ($line in $lines[1..($closingIndex - 1)]) {
        if ($line -match "^([^:#]+):\s*(.*)$") {
            $key = $matches[1].Trim()
            if (-not $map.ContainsKey($key)) {
                $map[$key] = $matches[2]
            }
        }
    }

    return $map
}

function Get-DocTypeHint {
    param([string]$RelativePath)

    $normalized = $RelativePath -replace "\\", "/"
    if ($normalized -match "/신격/") { return "deity" }
    if ($normalized -match "/설정/") { return "setting" }
    if ($normalized -match "/비밀 설정/") { return "secret_setting" }
    if ($normalized -match "/세력 관계/") { return "relation" }
    if ($normalized -match "/스토리 설계/") { return "story_design" }
    if ($normalized -match "/설정 정비/") { return "maintenance" }
    if ($normalized -match "/템플릿/") { return "template" }
    return ""
}

function Test-ManagedDocumentPath {
    param([string]$RelativePath)

    $normalized = $RelativePath -replace "\\", "/"
    return $normalized.StartsWith("시리즈/룩스테라/") -or $normalized.StartsWith("시리즈/엘드로스/")
}

function Test-FrontmatterKey {
    param(
        [hashtable]$Map,
        [string]$Key
    )

    return [bool]($Map -and $Map.ContainsKey($Key))
}

$resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
$outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    [System.IO.Path]::GetFullPath($OutputPath)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $PWD.Path $OutputPath))
}
$outputDir = Split-Path -Parent $outputFullPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$files = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter *.md | Where-Object {
    $fullName = $_.FullName -replace "\\", "/"
    $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/") -replace "\\", "/"
    (Test-ManagedDocumentPath -RelativePath $relative) -and
    -not $relative.Contains("/템플릿/")
}

$rows = foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/") -replace "\\", "/"
    $map = Get-FrontmatterMap -Path $file.FullName
    $docTypeHint = Get-DocTypeHint -RelativePath $relativePath

    [PSCustomObject]@{
        Path = $relativePath
        DocTypeHint = $docTypeHint
        HasTitle = if (Test-FrontmatterKey -Map $map -Key "title") { "yes" } else { "no" }
        HasLegacyName = if ((Test-FrontmatterKey -Map $map -Key "이름") -or (Test-FrontmatterKey -Map $map -Key "name")) { "yes" } else { "no" }
        HasDocType = if (Test-FrontmatterKey -Map $map -Key "docType") { "yes" } else { "no" }
        HasUuid = if (Test-FrontmatterKey -Map $map -Key "uuid") { "yes" } else { "no" }
        HasThumbnail = if (Test-FrontmatterKey -Map $map -Key "thumbnail") { "yes" } else { "no" }
        HasType = if (Test-FrontmatterKey -Map $map -Key "type") { "yes" } else { "no" }
        HasSubtype = if (Test-FrontmatterKey -Map $map -Key "subtype") { "yes" } else { "no" }
        HasRegion = if (Test-FrontmatterKey -Map $map -Key "region") { "yes" } else { "no" }
        HasRank = if (Test-FrontmatterKey -Map $map -Key "rank") { "yes" } else { "no" }
        HasAlignment = if (Test-FrontmatterKey -Map $map -Key "alignment") { "yes" } else { "no" }
        HasDomain = if (Test-FrontmatterKey -Map $map -Key "domain") { "yes" } else { "no" }
        HasPortfolio = if (Test-FrontmatterKey -Map $map -Key "portfolio") { "yes" } else { "no" }
    }
}

$lines = @(
    "# Document Frontmatter Audit"
    ""
    "| Path | docTypeHint | hasTitle | hasLegacyName | hasDocType | hasUuid | hasThumbnail | hasType | hasSubtype | hasRegion | hasRank | hasAlignment | hasDomain | hasPortfolio |"
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
)

foreach ($row in $rows | Sort-Object Path) {
    $lines += "| $($row.Path) | $($row.DocTypeHint) | $($row.HasTitle) | $($row.HasLegacyName) | $($row.HasDocType) | $($row.HasUuid) | $($row.HasThumbnail) | $($row.HasType) | $($row.HasSubtype) | $($row.HasRegion) | $($row.HasRank) | $($row.HasAlignment) | $($row.HasDomain) | $($row.HasPortfolio) |"
}

[System.IO.File]::WriteAllText($outputFullPath, ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
Write-Host "WROTE $outputFullPath"
