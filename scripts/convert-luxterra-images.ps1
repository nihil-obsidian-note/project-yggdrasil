param(
  [string]$ProjectRoot = (Get-Location).Path,
  [int]$Quality = 85
)

$ErrorActionPreference = 'Stop'

function Get-RelativeMarkdownPath {
  param(
    [Parameter(Mandatory = $true)][string]$FromDirectory,
    [Parameter(Mandatory = $true)][string]$ToPath
  )

  $fromUri = [System.Uri]((Resolve-Path -LiteralPath $FromDirectory).Path + [System.IO.Path]::DirectorySeparatorChar)
  $toUri = [System.Uri](Resolve-Path -LiteralPath $ToPath).Path
  $relative = $fromUri.MakeRelativeUri($toUri).ToString()
  return $relative -replace '\\', '/'
}

function Get-TargetPath {
  param(
    [Parameter(Mandatory = $true)][System.IO.FileInfo]$SourceFile,
    [Parameter(Mandatory = $true)][string]$TargetDirectory
  )

  $baseName = $SourceFile.BaseName
  $candidate = Join-Path $TargetDirectory ($baseName + '.webp')
  $index = 2

  while (Test-Path -LiteralPath $candidate) {
    if ((Get-Item -LiteralPath $candidate).FullName -eq $SourceFile.FullName) {
      break
    }

    $candidate = Join-Path $TargetDirectory ("{0}-{1}.webp" -f $baseName, $index)
    $index++
  }

  return $candidate
}

function Convert-ToWebp {
  param(
    [Parameter(Mandatory = $true)][string]$FfmpegPath,
    [Parameter(Mandatory = $true)][string]$SourcePath,
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [Parameter(Mandatory = $true)][int]$Quality
  )

  & $FfmpegPath -y -hide_banner -loglevel error -i $SourcePath -c:v libwebp -quality $Quality $TargetPath
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $TargetPath)) {
    throw "webp 변환 실패: $SourcePath"
  }
}

function Add-Mapping {
  param(
    [Parameter(Mandatory = $true)][hashtable]$LeafMap,
    [Parameter(Mandatory = $true)][hashtable]$StemMap,
    [Parameter(Mandatory = $true)][string]$LeafName,
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [Parameter(Mandatory = $true)][string]$GroupName,
    [string]$SourcePath = $null
  )

  $entry = [pscustomobject]@{
    Source = $SourcePath
    Target = $TargetPath
    Group = $GroupName
  }

  $LeafMap[$LeafName.ToLowerInvariant()] = $entry
  $StemMap[[System.IO.Path]::GetFileNameWithoutExtension($LeafName).ToLowerInvariant()] = $entry
}

function Update-AltLabel {
  param(
    [AllowEmptyString()][string]$AltText
  )

  if ([string]::IsNullOrWhiteSpace($AltText)) {
    return $AltText
  }

  return [System.Text.RegularExpressions.Regex]::Replace(
    $AltText,
    '\.(png|jpg|jpeg|webp)$',
    '.webp',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )
}

$ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source
$luxterraRoot = Join-Path $ProjectRoot '룩스테라'
$sources = @(
  @{
    Name = '설정'
    SourceDir = Join-Path $luxterraRoot '설정'
    TargetDir = Join-Path $luxterraRoot '이미지\설정'
  },
  @{
    Name = '신격'
    SourceDir = Join-Path $luxterraRoot '신격'
    TargetDir = Join-Path $luxterraRoot '이미지\신격'
  }
)

$imageExtensions = @('.png', '.jpg', '.jpeg', '.webp')
$sourceFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
$mappingByLeaf = @{}
$mappingByStem = @{}
$convertedTargets = New-Object System.Collections.Generic.List[string]

foreach ($group in $sources) {
  New-Item -ItemType Directory -Path $group.TargetDir -Force | Out-Null

  $files = Get-ChildItem -LiteralPath $group.SourceDir -File |
    Where-Object { $imageExtensions -contains $_.Extension.ToLowerInvariant() }

  foreach ($file in $files) {
    $targetPath = Get-TargetPath -SourceFile $file -TargetDirectory $group.TargetDir
    Convert-ToWebp -FfmpegPath $ffmpeg -SourcePath $file.FullName -TargetPath $targetPath -Quality $Quality

    Add-Mapping -LeafMap $mappingByLeaf -StemMap $mappingByStem -LeafName $file.Name -TargetPath $targetPath -GroupName $group.Name -SourcePath $file.FullName

    $sourceFiles.Add($file)
    $convertedTargets.Add($targetPath)
  }

  $existingTargets = Get-ChildItem -LiteralPath $group.TargetDir -File -Filter '*.webp'
  foreach ($existingTarget in $existingTargets) {
    if (-not $mappingByStem.ContainsKey($existingTarget.BaseName.ToLowerInvariant())) {
      Add-Mapping -LeafMap $mappingByLeaf -StemMap $mappingByStem -LeafName $existingTarget.Name -TargetPath $existingTarget.FullName -GroupName $group.Name
    }
  }
}

$markdownFiles = Get-ChildItem -LiteralPath $luxterraRoot -Recurse -File -Filter '*.md'
$imagePattern = '!\[(?<alt>[^\]]*)\]\((?<url><[^>]+>|[^)]+)\)'
$unresolved = New-Object System.Collections.Generic.List[string]
$updatedFiles = 0

foreach ($markdownFile in $markdownFiles) {
  $content = Get-Content -LiteralPath $markdownFile.FullName -Raw
  $content = [System.Text.RegularExpressions.Regex]::Replace(
    $content,
    '!\[(?<alt>[^\]]+?)\.(png|jpg|jpeg|webp)\]\(',
    '![${alt}.webp](',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )
  $matches = [System.Text.RegularExpressions.Regex]::Matches($content, $imagePattern)
  if ($matches.Count -eq 0) {
    continue
  }

  $changed = $false
  $cursor = 0
  $builder = New-Object System.Text.StringBuilder

  foreach ($match in $matches) {
    [void]$builder.Append($content.Substring($cursor, $match.Index - $cursor))

    $rawUrl = $match.Groups['url'].Value.Trim()
    if ($rawUrl.StartsWith('<') -and $rawUrl.EndsWith('>')) {
      $rawUrl = $rawUrl.Substring(1, $rawUrl.Length - 2)
    }

    $decodedUrl = [System.Uri]::UnescapeDataString($rawUrl)
    $leafName = [System.IO.Path]::GetFileName($decodedUrl)
    $extension = [System.IO.Path]::GetExtension($leafName).ToLowerInvariant()

    if (-not ($imageExtensions -contains $extension)) {
      [void]$builder.Append($match.Value)
      $cursor = $match.Index + $match.Length
      continue
    }

    $targetInfo = $null
    $leafKey = $leafName.ToLowerInvariant()
    if ($mappingByLeaf.ContainsKey($leafKey)) {
      $targetInfo = $mappingByLeaf[$leafKey]
    } else {
      $stemKey = [System.IO.Path]::GetFileNameWithoutExtension($leafName).ToLowerInvariant()
      if ($mappingByStem.ContainsKey($stemKey)) {
        $targetInfo = $mappingByStem[$stemKey]
      }
    }

    if ($null -eq $targetInfo) {
      $altLeaf = [System.Uri]::UnescapeDataString($match.Groups['alt'].Value)
      $altStemKey = [System.IO.Path]::GetFileNameWithoutExtension($altLeaf).ToLowerInvariant()
      if (-not [string]::IsNullOrWhiteSpace($altStemKey) -and $mappingByStem.ContainsKey($altStemKey)) {
        $targetInfo = $mappingByStem[$altStemKey]
      }
    }

    if ($null -eq $targetInfo) {
      $unresolved.Add("{0}: {1}" -f $markdownFile.FullName, $leafName)
      $updatedAlt = Update-AltLabel -AltText $match.Groups['alt'].Value
      [void]$builder.Append(('![{0}]({1})' -f $updatedAlt, $match.Groups['url'].Value))
      if ($updatedAlt -ne $match.Groups['alt'].Value) {
        $changed = $true
      }
      $cursor = $match.Index + $match.Length
      continue
    }

    $relativePath = Get-RelativeMarkdownPath -FromDirectory $markdownFile.DirectoryName -ToPath $targetInfo.Target
    $updatedAlt = Update-AltLabel -AltText $match.Groups['alt'].Value
    [void]$builder.Append(('![{0}](<{1}>)' -f $updatedAlt, $relativePath))
    $changed = $true
    $cursor = $match.Index + $match.Length
  }

  [void]$builder.Append($content.Substring($cursor))
  $rewritten = $builder.ToString()

  if ($changed) {
    Set-Content -LiteralPath $markdownFile.FullName -Value $rewritten -NoNewline
    $updatedFiles++
  }
}

if ($unresolved.Count -gt 0) {
  Write-Host '해결되지 않은 이미지 링크가 있습니다:'
  $unresolved | Sort-Object -Unique | ForEach-Object { Write-Host $_ }
  throw "링크 미해결: $($unresolved.Count)건"
}

foreach ($sourceFile in $sourceFiles) {
  Remove-Item -LiteralPath $sourceFile.FullName -Force
}

Write-Host ("변환 완료: 원본 {0}개, 문서 {1}개 수정" -f $sourceFiles.Count, $updatedFiles)
