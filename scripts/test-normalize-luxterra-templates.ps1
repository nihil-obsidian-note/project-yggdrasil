$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tmpRoot = Join-Path $env:TEMP ("luxterra-template-test-" + [guid]::NewGuid().ToString("N"))
$templateDir = Join-Path $tmpRoot "룩스테라\\템플릿"

New-Item -ItemType Directory -Path $templateDir -Force | Out-Null

@'
---
title: '문서이름'
status: '시작 전'
created_at: '2026년 3월 30일 오전 1:26'
updated_at: '2026년 3월 30일 오전 1:31'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $templateDir "설정_기본 템플릿.md") -Encoding utf8

@'
---
title: '국가'
type: '국가'
status: '시작 전'
created_at: '2026년 5월 15일 오후 9:30'
updated_at: '2026년 5월 15일 오후 10:02'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $templateDir "설정_국가 템플릿.md") -Encoding utf8

@'
---
title: '단체'
type: '단체'
status: '완료'
created_at: '2026년 5월 21일 오후 9:13'
updated_at: '2026년 5월 21일 오후 9:19'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $templateDir "설정_단체 템플릿.md") -Encoding utf8

@'
---
title: '대륙'
type: '지형'
subtype: '대륙'
status: '시작 전'
created_at: '2026년 6월 25일 오전 2:59'
updated_at: '2026년 6월 25일 오전 2:59'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $templateDir "설정_대륙 템플릿.md") -Encoding utf8

@'
---
title: '신격 기본 템플릿'
status: '시작 전'
created_at: '2026년 4월 26일 오전 7:40'
updated_at: '2026년 5월 21일 오전 1:15'
pantheon: false
cheongyeon_pantheon: false
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $templateDir "신격_기본 템플릿.md") -Encoding utf8

node (Join-Path $repoRoot "scripts\\normalize-luxterra-templates.mjs") --root $tmpRoot

$existingTemplates = @(
    "설정_기본 템플릿.md",
    "설정_국가 템플릿.md",
    "설정_단체 템플릿.md",
    "설정_대륙 템플릿.md",
    "신격_기본 템플릿.md"
)

foreach ($name in $existingTemplates) {
    $content = Get-Content -LiteralPath (Join-Path $templateDir $name) -Raw

    if ($content -notmatch "uuid: '[0-9a-f-]{36}'") {
        throw "$name 에 uuid 가 추가되지 않았습니다."
    }

    if ($content -notmatch "docType: 'template'") {
        throw "$name 에 docType: 'template' 이 추가되지 않았습니다."
    }

    if ($content -notmatch "thumbnail: ''") {
        throw "$name 에 thumbnail: '' 가 추가되지 않았습니다."
    }
}

$newTemplates = @(
    "설정_종족 템플릿.md",
    "설정_인물 템플릿.md",
    "설정_아이템 템플릿.md",
    "설정_사건 템플릿.md"
)

foreach ($name in $newTemplates) {
    $path = Join-Path $templateDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "$name 파일이 생성되지 않았습니다."
    }

    $content = Get-Content -LiteralPath $path -Raw

    if ($content -notmatch "uuid: '[0-9a-f-]{36}'") {
        throw "$name 에 uuid 가 없습니다."
    }

    if ($content -notmatch "docType: 'template'") {
        throw "$name 에 template docType 이 없습니다."
    }

    if ($content -notmatch "thumbnail: ''") {
        throw "$name 에 빈 thumbnail 이 없습니다."
    }
}

Remove-Item -LiteralPath $tmpRoot -Recurse -Force
Write-Host "PASS"
