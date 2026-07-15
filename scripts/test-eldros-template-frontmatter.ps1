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

$templateDir = ".\엘드로스\템플릿"
if (-not (Test-Path -LiteralPath $templateDir)) {
    throw "엘드로스 템플릿 폴더를 찾을 수 없습니다."
}

$files = Get-ChildItem -LiteralPath $templateDir -File -Filter *.md
if ($files.Count -eq 0) {
    throw "엘드로스 템플릿 문서가 없습니다."
}

$failures = @()
foreach ($file in $files) {
    $frontmatterLines = Get-FrontmatterLines -Path $file.FullName
    if (-not $frontmatterLines) {
        $failures += "$($file.Name): frontmatter 없음"
        continue
    }

    $titleLines = @($frontmatterLines | Where-Object { $_.TrimStart().StartsWith("title:") })
    if ($titleLines.Count -eq 0) {
        $failures += "$($file.Name): title 필드 없음"
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
    throw "엘드로스 템플릿 frontmatter 검증 실패: $($failures.Count)건"
}

Write-Host "PASS"
