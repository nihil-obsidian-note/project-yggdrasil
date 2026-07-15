$ErrorActionPreference = "Stop"

function Get-FrontmatterLines {
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

    return $lines[1..($closingIndex - 1)]
}

$targets = @()

foreach ($baseDir in @(".\룩스테라\설정", ".\룩스테라\신격", ".\엘드로스\설정", ".\엘드로스\신격")) {
    if (Test-Path -LiteralPath $baseDir) {
        $targets += Get-ChildItem -LiteralPath $baseDir -File -Filter *.md
    }
}

if ($targets.Count -eq 0) {
    throw "검사 대상 문서가 없습니다."
}

$failures = @()
foreach ($file in $targets) {
    $frontmatterLines = Get-FrontmatterLines -Path $file.FullName
    if (-not $frontmatterLines) {
        $failures += "$($file.Name): frontmatter 없음"
        continue
    }

    $expected = $file.BaseName
    $titleLine = $frontmatterLines | Where-Object { $_.TrimStart().StartsWith("title:") } | Select-Object -First 1
    if (-not $titleLine) {
        $failures += "$($file.Name): title 필드 없음"
        continue
    }

    if ($titleLine -notmatch "^title:\s*['""]?(.*?)['""]?\s*$") {
        $failures += "$($file.Name): title 파싱 실패"
        continue
    }

    $titleValue = $matches[1]
    if ([string]::IsNullOrWhiteSpace($titleValue)) {
        $failures += "$($file.Name): title 값 비어 있음"
    }

    $nameLines = @($frontmatterLines | Where-Object { $_.TrimStart().StartsWith("name:") })
    if ($nameLines.Count -gt 0) {
        $failures += "$($file.Name): name 필드 제거 필요"
    }

    $legacyNameLines = @($frontmatterLines | Where-Object { $_.TrimStart().StartsWith("이름:") })
    if ($legacyNameLines.Count -gt 0) {
        $failures += "$($file.Name): 이름 필드 제거 필요"
    }
}

if ($failures.Count -gt 0) {
    $failures | Select-Object -First 20 | ForEach-Object { Write-Host $_ }
    throw "title 프론트매터 검증 실패: $($failures.Count)건"
}

Write-Host "PASS"
