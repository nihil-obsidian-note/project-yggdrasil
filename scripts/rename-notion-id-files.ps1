[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실'
)

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$mapPath = Join-Path $rootPath 'docs\notion-id-rename-map.md'

if (-not (Test-Path -LiteralPath $mapPath)) {
    throw "매핑 파일 없음: $mapPath"
}

$entries = foreach ($line in Get-Content -LiteralPath $mapPath) {
    if ($line -match '^\| (.+?) \| (.+?) \| ([0-9a-f]{32}) \|$') {
        [pscustomobject]@{
            OldPath  = $matches[1]
            NewPath  = $matches[2]
            NotionId = $matches[3]
        }
    }
}

$dupes = $entries | Group-Object NewPath | Where-Object Count -gt 1
if ($dupes) {
    throw "중복 대상 발견: $($dupes.Name -join ', ')"
}

foreach ($entry in $entries) {
    $oldFull = Join-Path $rootPath $entry.OldPath
    $newFull = Join-Path $rootPath $entry.NewPath

    if (-not (Test-Path -LiteralPath $oldFull)) {
        throw "원본 파일 없음: $($entry.OldPath)"
    }

    if ((Test-Path -LiteralPath $newFull) -and ($oldFull -ne $newFull)) {
        throw "대상 파일 이미 존재: $($entry.NewPath)"
    }

    if ($PSCmdlet.ShouldProcess($entry.OldPath, "Rename to $($entry.NewPath)")) {
        Move-Item -LiteralPath $oldFull -Destination $newFull
    }
}
