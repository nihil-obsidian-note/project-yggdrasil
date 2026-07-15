$ErrorActionPreference = "Stop"

function Normalize-FrontmatterTitle {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
        $raw = $raw.Substring(1)
    }

    $lines = [regex]::Split($raw, "\r?\n")
    if ($lines.Count -lt 3 -or $lines[0] -ne "---") {
        return $false
    }

    $closingIndex = [Array]::IndexOf($lines, "---", 1)
    if ($closingIndex -lt 1) {
        return $false
    }

    $frontmatter = New-Object System.Collections.Generic.List[string]
    $frontmatter.AddRange([string[]]$lines[1..($closingIndex - 1)])

    $titleIndex = -1
    $legacyTitleIndex = -1
    $nameIndex = -1

    for ($i = 0; $i -lt $frontmatter.Count; $i++) {
        $line = $frontmatter[$i]
        if ($line -match "^title:\s*") {
            $titleIndex = $i
        } elseif ($line -match "^이름:\s*") {
            $legacyTitleIndex = $i
        } elseif ($line -match "^name:\s*") {
            $nameIndex = $i
        }
    }

    if ($titleIndex -lt 0) {
        if ($legacyTitleIndex -ge 0) {
            $frontmatter[$legacyTitleIndex] = $frontmatter[$legacyTitleIndex] -replace "^이름:", "title:"
            $titleIndex = $legacyTitleIndex
            $legacyTitleIndex = -1
        } else {
            $fileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
            $frontmatter.Insert(0, "title: '$fileBaseName'")
            $titleIndex = 0
            if ($legacyTitleIndex -ge 0) { $legacyTitleIndex += 1 }
            if ($nameIndex -ge 0) { $nameIndex += 1 }
        }
    }

    for ($i = $frontmatter.Count - 1; $i -ge 0; $i--) {
        if ($frontmatter[$i] -match "^(name|이름):\s*") {
            $frontmatter.RemoveAt($i)
        }
    }

    $newLines = @("---") + $frontmatter + @("---")
    if ($closingIndex + 1 -lt $lines.Count) {
        $newLines += $lines[($closingIndex + 1)..($lines.Count - 1)]
    }

    $newContent = ($newLines -join "`n").TrimEnd("`n") + "`n"
    if ($newContent -ne $raw) {
        [System.IO.File]::WriteAllText((Resolve-Path -LiteralPath $Path), $newContent, [System.Text.UTF8Encoding]::new($false))
        return $true
    }

    return $false
}

$targets = @()
foreach ($baseDir in @(".\룩스테라\설정", ".\룩스테라\신격", ".\엘드로스\설정", ".\엘드로스\신격", ".\엘드로스\템플릿")) {
    if (Test-Path -LiteralPath $baseDir) {
        $targets += Get-ChildItem -LiteralPath $baseDir -File -Filter *.md
    }
}

$updated = 0
foreach ($file in $targets) {
    if (Normalize-FrontmatterTitle -Path $file.FullName) {
        $updated += 1
    }
}

Write-Host "UPDATED $updated"
