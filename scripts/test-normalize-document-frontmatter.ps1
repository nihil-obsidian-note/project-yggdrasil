$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "normalize-document-frontmatter.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "yggdrasil-normalize-frontmatter-test"

if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
}

New-Item -ItemType Directory -Path (Join-Path $tempRoot "시리즈\룩스테라\설정") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $tempRoot "시리즈\룩스테라\신격") -Force | Out-Null

$settingPath = Join-Path $tempRoot "시리즈\룩스테라\설정\테스트 설정.md"
$deityPath = Join-Path $tempRoot "시리즈\룩스테라\신격\테스트 신격.md"

$settingDoc = @"
---
이름: '테스트 설정'
status: '완료'
type: '국가'
subtype: '일반'
region: '에리디안'
created_at: '2026-07-01'
updated_at: '2026-07-01'
---

![[시리즈/룩스테라/이미지/설정/테스트_설정.webp]]

## 항목

내용
"@

$deityDoc = @"
---
title: '테스트 신격'
uuid: '11111111-2222-3333-4444-555555555555'
thumbnail: 'images/deity.png'
status: '완료'
rank: '대신격'
alignment: '선신'
domain:
  - '빛'
portfolio:
  - '질서'
created_at: '2026-07-01'
updated_at: '2026-07-01'
---

# 개요

본문
"@

[System.IO.File]::WriteAllText($settingPath, $settingDoc, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($deityPath, $deityDoc, [System.Text.UTF8Encoding]::new($false))

& $scriptPath -RootPath $tempRoot

$settingContent = Get-Content -LiteralPath $settingPath -Raw
$deityContent = Get-Content -LiteralPath $deityPath -Raw

if ($settingContent -match "^이름:") {
    throw "설정 문서의 legacy title 키가 제거되지 않았습니다."
}

if ($settingContent -notmatch "(?m)^title:\s*'테스트 설정'$") {
    throw "설정 문서의 title 키가 기대값과 다릅니다."
}

if ($settingContent -notmatch "(?m)^docType:\s*'setting'$") {
    throw "설정 문서의 docType이 추가되지 않았습니다."
}

if ($settingContent -notmatch "(?m)^thumbnail:\s*'시리즈/룩스테라/이미지/설정/테스트_설정\.webp'$") {
    throw "설정 문서의 thumbnail이 본문 이미지에서 채워지지 않았습니다."
}

if ($settingContent -notmatch "(?m)^uuid:\s*'[0-9a-fA-F-]{36}'$") {
    throw "설정 문서의 uuid가 생성되지 않았습니다."
}

if ($settingContent -notmatch "## 항목") {
    throw "설정 문서 본문이 유지되지 않았습니다."
}

if ($deityContent -notmatch "(?m)^uuid:\s*'11111111-2222-3333-4444-555555555555'$") {
    throw "기존 deity uuid가 유지되지 않았습니다."
}

if ($deityContent -notmatch "(?m)^docType:\s*'deity'$") {
    throw "deity 문서의 docType이 추가되지 않았습니다."
}

if ($deityContent -notmatch "(?m)^thumbnail:\s*'images/deity\.png'$") {
    throw "기존 deity thumbnail이 유지되지 않았습니다."
}

if ($deityContent -notmatch "# 개요") {
    throw "deity 문서 본문이 유지되지 않았습니다."
}

Write-Host "PASS"
