$ErrorActionPreference = 'Stop'

function ConvertTo-YamlQuotedString {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    $escaped = $Value.Replace("'", "''")
    return "'$escaped'"
}

function ConvertTo-ObsidianWikiLink {
    param([Parameter(Mandatory = $true)][string]$Value)
    $trimmed = $Value.Trim()
    if ($trimmed -match '^(.*?)\s+\(https?://.+\)$') {
        $label = $Matches[1].Trim()
        return "[[$label]]"
    }
    return "[[$trimmed]]"
}

function Convert-LuxterraRelationDocumentContent {
    param([Parameter(Mandatory = $true)][string]$Content)

    $normalized = $Content -replace "`r`n", "`n"
    $lines = $normalized.Split("`n")

    if ($lines[0] -notmatch '^#\s+(.+)$') { throw '첫 줄이 제목 헤더 형식이 아닙니다.' }
    $title = $Matches[1].Trim()
    $index = 1
    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) { $index++ }

    $meta = [ordered]@{}
    while ($index -lt $lines.Count -and -not [string]::IsNullOrWhiteSpace($lines[$index])) {
        if ($lines[$index] -notmatch '^([^:]+):\s*(.*)$') { throw "메타 항목 형식을 해석할 수 없습니다: $($lines[$index])" }
        $meta[$Matches[1].Trim()] = $Matches[2].Trim()
        $index++
    }

    while ($index -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$index])) { $index++ }
    $body = if ($index -lt $lines.Count) { ($lines[$index..($lines.Count - 1)] -join "`n").TrimEnd() } else { '' }

    $yamlLines = [System.Collections.Generic.List[string]]::new()
    $yamlLines.Add('---')
    $yamlLines.Add("title: $(ConvertTo-YamlQuotedString $title)")

    $mapping = [ordered]@{
        'A(세력)' = 'a_setting'
        'A(신격)' = 'a_god'
        'B(세력)' = 'b_setting'
        'B(신격)' = 'b_god'
        '공개 수준' = 'visibility'
        '관계' = 'relation'
        '세션 징후' = 'session_signs'
        '쟁점(한 줄)' = 'issue'
    }

    foreach ($entry in $mapping.GetEnumerator()) {
        if (-not $meta.Contains($entry.Key)) { continue }
        $value = $meta[$entry.Key]
        if ($entry.Key -like '?(*)') { }
        if ($entry.Key -in @('A(세력)', 'A(신격)', 'B(세력)', 'B(신격)')) {
            $yamlLines.Add("$($entry.Value): $(ConvertTo-YamlQuotedString (ConvertTo-ObsidianWikiLink $value))")
        } else {
            $yamlLines.Add("$($entry.Value): $(ConvertTo-YamlQuotedString $value)")
        }
    }

    $yamlLines.Add('---')
    if ($body -eq '') { return ($yamlLines -join "`n") }
    return (($yamlLines -join "`n") + "`n`n" + $body)
}

function Convert-LuxterraRelationDocumentsInDirectory {
    param([Parameter(Mandatory = $true)][string]$Directory)
    Get-ChildItem -LiteralPath $Directory -Filter *.md -File | ForEach-Object {
        $original = Get-Content -LiteralPath $_.FullName -Raw
        $converted = Convert-LuxterraRelationDocumentContent -Content $original
        Set-Content -LiteralPath $_.FullName -Value $converted -NoNewline
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $args[0]) { throw '변환할 디렉터리 경로를 인자로 전달해야 합니다.' }
    Convert-LuxterraRelationDocumentsInDirectory -Directory $args[0]
}
