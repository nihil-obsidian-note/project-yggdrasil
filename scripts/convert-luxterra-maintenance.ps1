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

function Convert-LuxterraMaintenanceDocumentContent {
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

    $body = if ($index -lt $lines.Count) { ($lines[$index..($lines.Count - 1)] -join "`n").TrimEnd() } else { '' }

    $yamlLines = [System.Collections.Generic.List[string]]::new()
    $yamlLines.Add('---')
    $yamlLines.Add("title: $(ConvertTo-YamlQuotedString $title)")
    if ($meta.Contains('진행 상황')) { $yamlLines.Add("progress: $(ConvertTo-YamlQuotedString $meta['진행 상황'])") }
    if ($meta.Contains('작성일자')) { $yamlLines.Add("written_on: $(ConvertTo-YamlQuotedString $meta['작성일자'])") }
    if ($meta.Contains('최종 편집 일시')) { $yamlLines.Add("updated_at: $(ConvertTo-YamlQuotedString $meta['최종 편집 일시'])") }
    $yamlLines.Add('---')

    if ($body -eq '') { return ($yamlLines -join "`n") }
    return (($yamlLines -join "`n") + "`n`n" + $body)
}

function Convert-LuxterraMaintenanceDocumentsInDirectory {
    param([Parameter(Mandatory = $true)][string]$Directory)
    Get-ChildItem -LiteralPath $Directory -Filter *.md -File | ForEach-Object {
        $original = Get-Content -LiteralPath $_.FullName -Raw
        $converted = Convert-LuxterraMaintenanceDocumentContent -Content $original
        Set-Content -LiteralPath $_.FullName -Value $converted -NoNewline
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $args[0]) { throw '변환할 디렉터리 경로를 인자로 전달해야 합니다.' }
    Convert-LuxterraMaintenanceDocumentsInDirectory -Directory $args[0]
}
