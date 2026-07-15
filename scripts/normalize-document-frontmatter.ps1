param(
    [string]$RootPath = "."
)

$ErrorActionPreference = "Stop"

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

function Get-FrontmatterDocument {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
        $raw = $raw.Substring(1)
    }

    $lines = [regex]::Split($raw, "\r?\n")
    if ($lines.Count -lt 3 -or $lines[0] -ne "---") {
        return $null
    }

    $closingIndex = [Array]::IndexOf($lines, "---", 1)
    if ($closingIndex -lt 1) {
        return $null
    }

    $frontmatter = New-Object System.Collections.Generic.List[string]
    $frontmatter.AddRange([string[]]$lines[1..($closingIndex - 1)])

    return [PSCustomObject]@{
        Raw = $raw
        Lines = $lines
        Frontmatter = $frontmatter
        BodyLines = if ($closingIndex + 1 -lt $lines.Count) { [string[]]$lines[($closingIndex + 1)..($lines.Count - 1)] } else { @() }
    }
}

function Find-FrontmatterKeyIndex {
    param(
        [System.Collections.Generic.List[string]]$Frontmatter,
        [string]$Key
    )

    for ($i = 0; $i -lt $Frontmatter.Count; $i++) {
        if ($Frontmatter[$i] -match ("^{0}:\s*" -f [regex]::Escape($Key))) {
            return $i
        }
    }

    return -1
}

function Set-OrInsertFrontmatterValue {
    param(
        [System.Collections.Generic.List[string]]$Frontmatter,
        [string]$Key,
        [string]$Value,
        [int]$InsertIndex
    )

    $line = "{0}: '{1}'" -f $Key, ($Value -replace "'", "''")
    $index = Find-FrontmatterKeyIndex -Frontmatter $Frontmatter -Key $Key
    if ($index -ge 0) {
        $Frontmatter[$index] = $line
        return
    }

    if ($InsertIndex -lt 0) {
        $InsertIndex = 0
    }

    if ($InsertIndex -gt $Frontmatter.Count) {
        $InsertIndex = $Frontmatter.Count
    }

    $Frontmatter.Insert($InsertIndex, $line)
}

function Get-ThumbnailFromBody {
    param([string[]]$BodyLines)

    foreach ($line in $BodyLines) {
        if ($line -match "!\[\[([^\]]+)\]\]") {
            return $matches[1].Trim()
        }

        if ($line -match "!\[[^\]]*\]\(([^)]+)\)") {
            return $matches[1].Trim()
        }
    }

    return $null
}

function Normalize-DocumentFrontmatter {
    param(
        [string]$Path,
        [string]$RelativePath
    )

    $doc = Get-FrontmatterDocument -Path $Path
    if ($null -eq $doc) {
        return $false
    }

    $frontmatter = $doc.Frontmatter
    $docType = Get-DocTypeHint -RelativePath $RelativePath
    if ([string]::IsNullOrWhiteSpace($docType) -or $docType -eq "template") {
        return $false
    }

    $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $title = $null

    for ($i = $frontmatter.Count - 1; $i -ge 0; $i--) {
        $line = $frontmatter[$i]
        if ($line -match "^title:\s*'(.*)'$") {
            $title = $matches[1]
        } elseif ($line -match '^title:\s*"(.*)"$') {
            $title = $matches[1]
        } elseif ($line -match "^title:\s*(.+)$") {
            $title = $matches[1].Trim()
        } elseif ($line -match "^이름:\s*'(.*)'$") {
            if (-not $title) { $title = $matches[1] }
            $frontmatter.RemoveAt($i)
        } elseif ($line -match '^이름:\s*"(.*)"$') {
            if (-not $title) { $title = $matches[1] }
            $frontmatter.RemoveAt($i)
        } elseif ($line -match "^이름:\s*(.+)$") {
            if (-not $title) { $title = $matches[1].Trim() }
            $frontmatter.RemoveAt($i)
        } elseif ($line -match "^name:\s*'(.*)'$") {
            if (-not $title) { $title = $matches[1] }
            $frontmatter.RemoveAt($i)
        } elseif ($line -match '^name:\s*"(.*)"$') {
            if (-not $title) { $title = $matches[1] }
            $frontmatter.RemoveAt($i)
        } elseif ($line -match "^name:\s*(.+)$") {
            if (-not $title) { $title = $matches[1].Trim() }
            $frontmatter.RemoveAt($i)
        }
    }

    if (-not $title) {
        $title = $fileBaseName
    }

    $uuidIndex = Find-FrontmatterKeyIndex -Frontmatter $frontmatter -Key "uuid"
    $uuidValue = $null
    if ($uuidIndex -ge 0 -and $frontmatter[$uuidIndex] -match "^[^:]+:\s*'?(.*?)'?$") {
        $uuidValue = $matches[1].Trim()
    }
    if ([string]::IsNullOrWhiteSpace($uuidValue)) {
        $uuidValue = [guid]::NewGuid().Guid
    }

    $thumbnailIndex = Find-FrontmatterKeyIndex -Frontmatter $frontmatter -Key "thumbnail"
    $thumbnailValue = $null
    if ($thumbnailIndex -ge 0 -and $frontmatter[$thumbnailIndex] -match "^[^:]+:\s*'?(.*?)'?$") {
        $thumbnailValue = $matches[1]
    }
    if ([string]::IsNullOrWhiteSpace($thumbnailValue)) {
        $thumbnailValue = Get-ThumbnailFromBody -BodyLines $doc.BodyLines
    }
    if ($null -eq $thumbnailValue) {
        $thumbnailValue = ""
    }

    Set-OrInsertFrontmatterValue -Frontmatter $frontmatter -Key "title" -Value $title -InsertIndex 0
    Set-OrInsertFrontmatterValue -Frontmatter $frontmatter -Key "uuid" -Value $uuidValue -InsertIndex 1
    Set-OrInsertFrontmatterValue -Frontmatter $frontmatter -Key "docType" -Value $docType -InsertIndex 2
    Set-OrInsertFrontmatterValue -Frontmatter $frontmatter -Key "thumbnail" -Value $thumbnailValue -InsertIndex 3

    $newLines = @("---") + @($frontmatter.ToArray()) + @("---")
    if ($doc.BodyLines.Count -gt 0) {
        $newLines += $doc.BodyLines
    }

    $newContent = ($newLines -join "`n").TrimEnd("`n") + "`n"
    if ($newContent -eq $doc.Raw) {
        return $false
    }

    [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $Path), $newContent, [System.Text.UTF8Encoding]::new($false))
    return $true
}

$resolvedRoot = (Resolve-Path -LiteralPath $RootPath).Path
$targets = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File -Filter *.md | Where-Object {
    $fullName = $_.FullName -replace "\\", "/"
    $relative = $_.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/") -replace "\\", "/"
    (Test-ManagedDocumentPath -RelativePath $relative) -and
    -not $relative.Contains("/템플릿/")
}

$updated = 0
foreach ($file in $targets) {
    $relativePath = $file.FullName.Substring($resolvedRoot.Length).TrimStart("\", "/") -replace "\\", "/"
    if (Normalize-DocumentFrontmatter -Path $file.FullName -RelativePath $relativePath) {
        $updated += 1
    }
}

Write-Host "UPDATED $updated"
