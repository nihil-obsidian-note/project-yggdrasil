$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $PSScriptRoot "audit-document-frontmatter.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "yggdrasil-frontmatter-audit-test"
$reportPath = Join-Path $tempRoot "frontmatter-audit.md"

if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path (Join-Path $tempRoot "시리즈\룩스테라\설정") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempRoot "시리즈\룩스테라\신격") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempRoot "시리즈\룩스테라\템플릿") -Force | Out-Null

$settingDoc = @"
---
title: '테스트 설정'
status: '완료'
type: '국가'
subtype: '일반'
region: '에리디안'
thumbnail: ''
---

본문
"@

$deityDoc = @"
---
title: '테스트 신격'
docType: 'deity'
status: '완료'
rank: '대신격'
alignment: '선신'
domain:
  - '빛'
portfolio:
  - '질서'
---

# 개요

본문
"@

$templateDoc = @"
---
title: '템플릿'
---
"@

[System.IO.File]::WriteAllText((Join-Path $tempRoot "시리즈\룩스테라\설정\테스트 설정.md"), $settingDoc, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tempRoot "시리즈\룩스테라\신격\테스트 신격.md"), $deityDoc, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $tempRoot "시리즈\룩스테라\템플릿\설정_기본 템플릿.md"), $templateDoc, [System.Text.UTF8Encoding]::new($false))

& $scriptPath -RootPath $tempRoot -OutputPath $reportPath

if (-not (Test-Path -LiteralPath $reportPath)) {
    throw "감사 보고서가 생성되지 않았습니다."
}

$report = Get-Content -LiteralPath $reportPath -Raw

if ($report -notmatch "테스트 설정\.md") {
    throw "설정 문서 행이 보고서에 없습니다."
}

if ($report -notmatch "테스트 신격\.md") {
    throw "신격 문서 행이 보고서에 없습니다."
}

if ($report -match "설정_기본 템플릿\.md") {
    throw "템플릿 문서는 감사 대상에서 제외되어야 합니다."
}

if ($report -notmatch "\| 시리즈/룩스테라/설정/테스트 설정\.md \| setting \| yes \| no \| no \| no \| yes \| yes \| yes \| yes \| no \| no \| no \| no \|") {
    throw "설정 문서 감사 결과가 기대값과 다릅니다."
}

if ($report -notmatch "\| 시리즈/룩스테라/신격/테스트 신격\.md \| deity \| yes \| no \| yes \| no \| no \| no \| no \| no \| yes \| yes \| yes \| yes \|") {
    throw "신격 문서 감사 결과가 기대값과 다릅니다."
}

Write-Host "PASS"
