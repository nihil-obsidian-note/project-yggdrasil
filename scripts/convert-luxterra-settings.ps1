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

function Convert-LuxterraSettingDocumentContent {
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

    if ($meta.Contains('타입')) {
        $yamlLines.Add("type: $(ConvertTo-YamlQuotedString $meta['타입'])")
    }
    if ($meta.Contains('서브타입')) {
        $yamlLines.Add("subtype: $(ConvertTo-YamlQuotedString $meta['서브타입'])")
    }
    if ($meta.Contains('영역')) {
        $yamlLines.Add("region: $(ConvertTo-YamlQuotedString $meta['영역'])")
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

function Convert-LuxterraSettingDocumentsInDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    $files = Get-ChildItem -LiteralPath $Directory -Filter *.md -File
    foreach ($file in $files) {
        $original = Get-Content -LiteralPath $file.FullName -Raw
        $converted = Convert-LuxterraSettingDocumentContent -Content $original
        Set-Content -LiteralPath $file.FullName -Value $converted -NoNewline
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $args[0]) {
        throw '변환할 디렉터리 경로를 인자로 전달해야 합니다.'
    }

    Convert-LuxterraSettingDocumentsInDirectory -Directory $args[0]
}
