[CmdletBinding()]
param(
    [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실'
)

function Get-EncodedRelativePath {
    param(
        [string]$FromDirectory,
        [string]$ToFile
    )

    $fromUri = New-Object System.Uri(($FromDirectory.TrimEnd('\') + '\'))
    $toUri = New-Object System.Uri($ToFile)
    $relative = $fromUri.MakeRelativeUri($toUri).ToString()
    $relative = [Uri]::UnescapeDataString($relative)
    $segments = $relative -split '[\\/]'
    ($segments | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'
}

function Get-Entries {
    param(
        [string]$MapPath,
        [string]$RootPath
    )

    $byOldFull = @{}
    $byNotionId = @{}
    $byNormalizedName = @{}

    foreach ($line in Get-Content -LiteralPath $MapPath) {
        if ($line -match '^\| (.+?) \| (.+?) \| ([0-9a-f]{32}) \|$') {
            $oldPath = $matches[1]
            $newPath = $matches[2]
            $notionId = $matches[3]
            $entry = [pscustomobject]@{
                OldPath  = $oldPath
                NewPath  = $newPath
                OldFull  = Join-Path $RootPath $oldPath
                NewFull  = Join-Path $RootPath $newPath
                OldLeaf  = [System.IO.Path]::GetFileName($oldPath)
                NewLeaf  = [System.IO.Path]::GetFileName($newPath)
                NewBase  = [System.IO.Path]::GetFileNameWithoutExtension($newPath)
                NotionId = $notionId
            }

            $byOldFull[$entry.OldFull] = $entry
            $byNotionId[$entry.NotionId] = $entry

            $normalized = Normalize-LinkText -Text $entry.NewBase
            if (-not $byNormalizedName.ContainsKey($normalized)) {
                $byNormalizedName[$normalized] = New-Object System.Collections.Generic.List[object]
            }
            $byNormalizedName[$normalized].Add($entry)
        }
    }

    [pscustomobject]@{
        ByOldFull = $byOldFull
        ByNotionId = $byNotionId
        ByNormalizedName = $byNormalizedName
    }
}

function Normalize-LinkText {
    param(
        [string]$Text
    )

    $normalized = $Text
    $normalized = $normalized -replace '\*\*', ''
    $normalized = $normalized -replace '__', ''
    $normalized = $normalized -replace '[*_`]', ''
    $normalized = $normalized -replace '\s*/\s*', ' '
    $normalized = $normalized -replace '\s+', ' '
    $normalized.Trim()
}

function Rewrite-MarkdownLinks {
    param(
        [string]$Content,
        [string]$DocPath,
        [hashtable]$ByOldFull,
        [hashtable]$ByNotionId
    )

    $fromDirectory = Split-Path -Parent $DocPath
    $pattern = '(?<prefix>\[[^\]]+\]\()(?<target>[^)]+)(?<suffix>\))'

    [regex]::Replace($Content, $pattern, {
        param($match)

        $target = $match.Groups['target'].Value

        if ($target -match '^https://app\.notion\.com/p/(?<id>[0-9a-f]{32})(?:\?pvs=\d+)?$') {
            $notionId = $match.Groups['id'].Value
            if ($ByNotionId.ContainsKey($notionId)) {
                $newTarget = Get-EncodedRelativePath -FromDirectory $fromDirectory -ToFile $ByNotionId[$notionId].NewFull
                return $match.Groups['prefix'].Value + $newTarget + $match.Groups['suffix'].Value
            }
            return $match.Value
        }

        if ($target -notmatch '\.md$') {
            return $match.Value
        }

        $decodedTarget = [Uri]::UnescapeDataString($target).Replace('/', '\')
        $resolved = [System.IO.Path]::GetFullPath((Join-Path $fromDirectory $decodedTarget))

        if ($ByOldFull.ContainsKey($resolved)) {
            $newTarget = Get-EncodedRelativePath -FromDirectory $fromDirectory -ToFile $ByOldFull[$resolved].NewFull
            return $match.Groups['prefix'].Value + $newTarget + $match.Groups['suffix'].Value
        }

        return $match.Value
    })
}

function Rewrite-DirectNotionUrls {
    param(
        [string]$Content,
        [string]$DocPath,
        [hashtable]$ByNotionId
    )

    $fromDirectory = Split-Path -Parent $DocPath
    [regex]::Replace($Content, 'https://app\.notion\.com/p/([0-9a-f]{32})(?:\?pvs=\d+)?', {
        param($match)

        $notionId = $match.Groups[1].Value
        if ($ByNotionId.ContainsKey($notionId)) {
            return Get-EncodedRelativePath -FromDirectory $fromDirectory -ToFile $ByNotionId[$notionId].NewFull
        }

        $match.Value
    })
}

function Rewrite-BlankLinks {
    param(
        [string]$Content,
        [string]$DocPath,
        [hashtable]$ByNormalizedName
    )

    $fromDirectory = Split-Path -Parent $DocPath
    [regex]::Replace($Content, '\[(?<text>[^\]]+)\]\(\)', {
        param($match)

        $normalized = Normalize-LinkText -Text $match.Groups['text'].Value
        if ($ByNormalizedName.ContainsKey($normalized) -and $ByNormalizedName[$normalized].Count -eq 1) {
            $target = Get-EncodedRelativePath -FromDirectory $fromDirectory -ToFile $ByNormalizedName[$normalized][0].NewFull
            return '[' + $match.Groups['text'].Value + '](' + $target + ')'
        }

        $match.Value
    })
}

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$mapPath = Join-Path $rootPath 'docs\notion-id-rename-map.md'
$unresolvedPath = Join-Path $rootPath 'docs\notion-id-unresolved-links.md'

$entries = Get-Entries -MapPath $mapPath -RootPath $rootPath
$docs = Get-ChildItem -LiteralPath (Join-Path $rootPath '룩스테라') -Recurse -File |
    Where-Object { $_.Extension -eq '.md' }

$unresolved = [System.Collections.Generic.List[string]]::new()

foreach ($doc in $docs) {
    $content = Get-Content -LiteralPath $doc.FullName -Raw
    $rewritten = Rewrite-MarkdownLinks -Content $content -DocPath $doc.FullName -ByOldFull $entries.ByOldFull -ByNotionId $entries.ByNotionId
    $rewritten = Rewrite-DirectNotionUrls -Content $rewritten -DocPath $doc.FullName -ByNotionId $entries.ByNotionId
    $rewritten = $rewritten -replace '\[\[([^\]]+?) [0-9a-f]{32}\]\]', '[[$1]]'
    $rewritten = Rewrite-BlankLinks -Content $rewritten -DocPath $doc.FullName -ByNormalizedName $entries.ByNormalizedName

    foreach ($match in [regex]::Matches($rewritten, 'https://app\.notion\.com/p/([0-9a-f]{32})(?:\?pvs=\d+)?')) {
        $unresolved.Add("- $($doc.FullName.Substring($rootPath.Length + 1)) | notion_id=$($match.Groups[1].Value)")
    }

    if ($rewritten -ne $content) {
        Set-Content -LiteralPath $doc.FullName -Value $rewritten -Encoding UTF8
    }
}

$unresolvedLines = @(
    '# Notion URL Manual Review',
    '',
    '> 링크 재작성 후에도 남아 있는 노션 URL 목록.',
    ''
)

if ($unresolved.Count -gt 0) {
    $unresolvedLines += ($unresolved | Sort-Object -Unique)
} else {
    $unresolvedLines += '- 없음'
}

Set-Content -LiteralPath $unresolvedPath -Value $unresolvedLines -Encoding UTF8
