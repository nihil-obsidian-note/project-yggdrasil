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

function Convert-LuxterraSecretSettingDocumentContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $normalized = $Content -replace "`r`n", "`n"
    $lines = $normalized.Split("`n")

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
        if ($lines[$index] -notmatch '^([^:]+):\s*(.*)$') {
            throw "메타 항목 형식을 해석할 수 없습니다: $($lines[$index])"
        }

        $meta[$Matches[1].Trim()] = $Matches[2].Trim()
        $index++
    }

    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) {
        $index++
    }

    $body = ($lines[$index..($lines.Count - 1)] -join "`n").TrimEnd()

    $yamlLines = [System.Collections.Generic.List[string]]::new()
    $yamlLines.Add('---')
    $yamlLines.Add("title: $(ConvertTo-YamlQuotedString $title)")

    if ($meta.Contains('비밀 등급')) {
        $yamlLines.Add("secret_rank: $(ConvertTo-YamlQuotedString $meta['비밀 등급'])")
    }
    if ($meta.Contains('비밀 유형')) {
        $yamlLines.Add("secret_type: $(ConvertTo-YamlQuotedString $meta['비밀 유형'])")
    }
    if ($meta.Contains('상태')) {
        $yamlLines.Add("status: $(ConvertTo-YamlQuotedString $meta['상태'])")
    }
    if ($meta.Contains('생성 일시')) {
        $yamlLines.Add("created_at: $(ConvertTo-YamlQuotedString $meta['생성 일시'])")
    }
    if ($meta.Contains('최종 편집 일시')) {
        $yamlLines.Add("updated_at: $(ConvertTo-YamlQuotedString $meta['최종 편집 일시'])")
    }

    $yamlLines.Add('---')
    return (($yamlLines -join "`n") + "`n`n" + $body)
}

function Convert-LuxterraSecretSettingDocumentsInDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $files = Get-ChildItem -LiteralPath $Directory -Filter *.md -File
    foreach ($file in $files) {
        $original = Get-Content -LiteralPath $file.FullName -Raw
        $converted = Convert-LuxterraSecretSettingDocumentContent -Content $original
        Set-Content -LiteralPath $file.FullName -Value $converted -NoNewline
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $args[0]) {
        throw '변환할 디렉터리 경로를 인자로 전달해야 합니다.'
    }

    Convert-LuxterraSecretSettingDocumentsInDirectory -Directory $args[0]
}
