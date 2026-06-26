[CmdletBinding()]
param(
    [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실',
    [string]$OutFile = 'C:\Users\nihil\coding\note\프로젝트 위그드라실\docs\notion-id-rename-map.md',
    [string]$UnresolvedFile = 'C:\Users\nihil\coding\note\프로젝트 위그드라실\docs\notion-id-unresolved-links.md'
)

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$luxterraRoot = Join-Path $rootPath '룩스테라'

$targets = Get-ChildItem -LiteralPath $luxterraRoot -Recurse -File |
    Where-Object {
        $_.Extension -eq '.md' -and
        $_.Name -match ' [0-9a-f]{32}\.md$'
    } |
    Sort-Object FullName

$rows = foreach ($file in $targets) {
    $newName = $file.Name -replace ' [0-9a-f]{32}(?=\.md$)', ''
    [pscustomobject]@{
        OldPath  = $file.FullName.Substring($rootPath.Length + 1)
        NewPath  = (Join-Path $file.DirectoryName $newName).Substring($rootPath.Length + 1)
        OldName  = $file.Name
        NewName  = $newName
        NotionId = ([regex]::Match($file.Name, '([0-9a-f]{32})(?=\.md$)')).Value
    }
}

$dupes = $rows | Group-Object NewPath | Where-Object Count -gt 1
if ($dupes) {
    throw "중복 대상 발견: $($dupes.Name -join ', ')"
}

$mapLines = @(
    '# Notion ID Rename Map',
    '',
    '> 자동 생성. 실행 전에 충돌 검토 필수.',
    '',
    '| OldPath | NewPath | NotionId |',
    '| --- | --- | --- |'
)
$mapLines += $rows | ForEach-Object { "| $($_.OldPath) | $($_.NewPath) | $($_.NotionId) |" }
Set-Content -LiteralPath $OutFile -Value $mapLines -Encoding UTF8

$knownIds = @{}
foreach ($row in $rows) {
    $knownIds[$row.NotionId] = $row.NewPath
}

$unresolved = [System.Collections.Generic.List[string]]::new()
$pattern = 'https://app\.notion\.com/p/([0-9a-f]{32})(?:\?pvs=\d+)?'

Get-ChildItem -LiteralPath $luxterraRoot -Recurse -File |
    Where-Object { $_.Extension -eq '.md' } |
    ForEach-Object {
        $relativeDoc = $_.FullName.Substring($rootPath.Length + 1)
        foreach ($match in [regex]::Matches((Get-Content -LiteralPath $_.FullName -Raw), $pattern)) {
            $id = $match.Groups[1].Value
            if (-not $knownIds.ContainsKey($id)) {
                $unresolved.Add("- $relativeDoc | notion_id=$id")
            }
        }
    }

$unresolvedLines = @(
    '# Notion URL Manual Review',
    '',
    '> 자동 생성. 파일명 매핑만으로 치환되지 않는 노션 URL 검토용 목록.',
    ''
)
if ($unresolved.Count -gt 0) {
    $unresolvedLines += $unresolved
} else {
    $unresolvedLines += '- 없음'
}

Set-Content -LiteralPath $UnresolvedFile -Value $unresolvedLines -Encoding UTF8
