$ErrorActionPreference = 'Stop'

function ConvertTo-YamlQuotedString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    $escaped = $Value.Replace("'", "''")
    return "'$escaped'"
}

function ConvertTo-YamlBool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    switch ($Value.Trim().ToLowerInvariant()) {
        'yes' { return 'true' }
        'true' { return 'true' }
        'no' { return 'false' }
        'false' { return 'false' }
        default { throw "지원하지 않는 불리언 값입니다: $Value" }
    }
}

function Split-CommaList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return @(
        $Value.Split(',') |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' }
    )
}

function Convert-LuxterraGodDocumentContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $normalized = $Content -replace "`r`n", "`n"
    $lines = $normalized.Split("`n")

    if ($lines.Count -lt 3) {
        throw '문서가 너무 짧아 신격 문서 형식으로 해석할 수 없습니다.'
    }

    if ($lines[0] -notmatch '^#\s+(.+)$') {
        throw '첫 줄이 제목 헤더 형식이 아닙니다.'
    }

    $title = $Matches[1].Trim()
    $index = 1

    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }

    $meta = [ordered]@{}
    while ($index -lt $lines.Count -and -not [string]::IsNullOrWhiteSpace($lines[$index])) {
        $line = $lines[$index]
        if ($line -notmatch '^([^:]+):\s*(.*)$') {
            throw "메타 항목 형식을 해석할 수 없습니다: $line"
        }

        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim()
        $meta[$key] = $value
        $index++
    }

    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }

    $body = ($lines[$index..($lines.Count - 1)] -join "`n").TrimEnd()

    $yamlLines = [System.Collections.Generic.List[string]]::new()
    $yamlLines.Add('---')
    $yamlLines.Add("title: $(ConvertTo-YamlQuotedString $title)")

    $keyOrder = @(
        '상태',
        '등급',
        '성향',
        '도메인',
        '포트폴리오',
        '생성 일시',
        '최종 편집 일시',
        '대표',
        '청연 만신전'
    )

    foreach ($key in $keyOrder) {
        if (-not $meta.Contains($key)) {
            continue
        }

        $value = $meta[$key]
        switch ($key) {
            '상태' {
                $yamlLines.Add("status: $(ConvertTo-YamlQuotedString $value)")
            }
            '등급' {
                $yamlLines.Add("rank: $(ConvertTo-YamlQuotedString $value)")
            }
            '성향' {
                $yamlLines.Add("alignment: $(ConvertTo-YamlQuotedString $value)")
            }
            '도메인' {
                $yamlLines.Add('domain:')
                foreach ($item in (Split-CommaList $value)) {
                    $yamlLines.Add("  - $(ConvertTo-YamlQuotedString $item)")
                }
            }
            '포트폴리오' {
                $yamlLines.Add('portfolio:')
                foreach ($item in (Split-CommaList $value)) {
                    $yamlLines.Add("  - $(ConvertTo-YamlQuotedString $item)")
                }
            }
            '생성 일시' {
                $yamlLines.Add("created_at: $(ConvertTo-YamlQuotedString $value)")
            }
            '최종 편집 일시' {
                $yamlLines.Add("updated_at: $(ConvertTo-YamlQuotedString $value)")
            }
            '대표' {
                $yamlLines.Add("pantheon: $(ConvertTo-YamlBool $value)")
            }
            '청연 만신전' {
                $yamlLines.Add("cheongyeon_pantheon: $(ConvertTo-YamlBool $value)")
            }
        }
    }

    $yamlLines.Add('---')

    return (($yamlLines -join "`n") + "`n`n" + $body)
}

function Convert-LuxterraGodDocumentsInDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $files = Get-ChildItem -LiteralPath $Directory -Filter *.md -File
    foreach ($file in $files) {
        $original = Get-Content -LiteralPath $file.FullName -Raw
        $converted = Convert-LuxterraGodDocumentContent -Content $original
        Set-Content -LiteralPath $file.FullName -Value $converted -NoNewline
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $args[0]) {
        throw '변환할 디렉터리 경로를 인자로 전달해야 합니다.'
    }

    Convert-LuxterraGodDocumentsInDirectory -Directory $args[0]
}
