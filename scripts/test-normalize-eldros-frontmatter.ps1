$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tmpRoot = Join-Path $env:TEMP ("eldros-frontmatter-test-" + [guid]::NewGuid().ToString("N"))
$inputRoot = Join-Path $tmpRoot "vault"
$settingDir = Join-Path $inputRoot "엘드로스\\설정"
$templateDir = Join-Path $inputRoot "엘드로스\\템플릿"

New-Item -ItemType Directory -Path $settingDir -Force | Out-Null
New-Item -ItemType Directory -Path $templateDir -Force | Out-Null

@'
---
title: '테스트 설정'
status: '진행 중'
type: '인물'
subtype: '헌터'
region: '-'
created_at: '-'
updated_at: '-'
---

본문
'@ | Set-Content -LiteralPath (Join-Path $settingDir "테스트 설정.md") -Encoding utf8

@'
---
title: '설정 기본 템플릿'
status: '시작 전'
type: ''
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

본문
'@ | Set-Content -LiteralPath (Join-Path $templateDir "설정_기본 템플릿.md") -Encoding utf8

@'
---
title: '신격 기본 템플릿'
status: '시작 전'
created_at: ''
updated_at: ''
pantheon: false
cheongyeon_pantheon: false
rank: ''
alignment: ''
domain: []
portfolio: []
---

본문
'@ | Set-Content -LiteralPath (Join-Path $templateDir "신격_기본 템플릿.md") -Encoding utf8

node (Join-Path $repoRoot "scripts\\normalize-eldros-frontmatter.mjs") --root $inputRoot

$settingContent = Get-Content -LiteralPath (Join-Path $settingDir "테스트 설정.md") -Raw
$templateContent = Get-Content -LiteralPath (Join-Path $templateDir "설정_기본 템플릿.md") -Raw
$deityTemplateContent = Get-Content -LiteralPath (Join-Path $templateDir "신격_기본 템플릿.md") -Raw

if ($settingContent -notmatch "uuid: '[0-9a-f-]{36}'") {
    throw "설정 문서에 uuid 가 추가되지 않았습니다."
}

if ($settingContent -notmatch "docType: 'setting'") {
    throw "설정 문서의 docType 이 setting 으로 정규화되지 않았습니다."
}

if ($settingContent -notmatch "thumbnail: ''") {
    throw "설정 문서에 빈 thumbnail 이 추가되지 않았습니다."
}

if ($settingContent -match "region: '-'|created_at: '-'|updated_at: '-'") {
    throw "설정 문서의 대시 빈값이 '' 로 정규화되지 않았습니다."
}

if ($settingContent -notmatch "region: ''" -or $settingContent -notmatch "created_at: ''" -or $settingContent -notmatch "updated_at: ''") {
    throw "설정 문서의 빈값이 '' 로 유지되지 않았습니다."
}

if ($templateContent -notmatch "uuid: '[0-9a-f-]{36}'") {
    throw "템플릿 문서에 uuid 가 추가되지 않았습니다."
}

if ($templateContent -notmatch "docType: 'template'") {
    throw "템플릿 문서의 docType 이 template 로 추가되지 않았습니다."
}

if ($templateContent -notmatch "thumbnail: ''") {
    throw "템플릿 문서에 빈 thumbnail 이 추가되지 않았습니다."
}

if ($deityTemplateContent -notmatch "docType: 'template'") {
    throw "신격 템플릿의 docType 이 template 로 추가되지 않았습니다."
}

if ($deityTemplateContent -notmatch "thumbnail: ''") {
    throw "신격 템플릿에 빈 thumbnail 이 추가되지 않았습니다."
}

Remove-Item -LiteralPath $tmpRoot -Recurse -Force
Write-Host "PASS"
