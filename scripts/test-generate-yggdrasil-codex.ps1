$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$tmpRoot = Join-Path $env:TEMP ("series-codex-test-" + [guid]::NewGuid().ToString("N"))
$inputRoot = Join-Path $tmpRoot "vault"
$luxterraOutputPath = Join-Path $tmpRoot "luxterra-codex.json"
$eldrosOutputPath = Join-Path $tmpRoot "eldros-codex.json"

New-Item -ItemType Directory -Path (Join-Path $inputRoot "룩스테라\\신격") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $inputRoot "룩스테라\\설정") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $inputRoot "룩스테라\\비밀 설정") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $inputRoot "엘드로스\\설정") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $inputRoot "엘드로스\\템플릿") -Force | Out-Null

@'
---
title: '빛의 신 룬다르'
status: '완료'
rank: '주신격'
alignment: '선신'
domain:
  - '빛'
  - '생명'
portfolio:
  - '빛의 원소'
created_at: '2026년 4월 19일 오전 7:57'
updated_at: '2026년 6월 8일 오전 2:05'
pantheon: true
cheongyeon_pantheon: false
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "룩스테라\\신격\\빛의 신 룬다르.md") -Encoding utf8

@'
---
title: '룩스테라'
type: '개념'
subtype: '주요'
status: '완료'
created_at: '2026년 3월 30일 오전 1:35'
updated_at: '2026년 6월 19일 오전 10:25'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "룩스테라\\설정\\룩스테라.md") -Encoding utf8

@'
---
title: '엘드로스'
uuid: 'c81308a1-36a6-44de-94ec-9ebe0d2b2c7d'
docType: 'setting'
thumbnail: ''
type: '주요 개념'
subtype: '시스템'
status: '진행 중'
created_at: ''
updated_at: ''
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "엘드로스\\설정\\엘드로스.md") -Encoding utf8

@'
---
title: '클래스'
uuid: '88ef31e6-c5bf-4de4-b4c3-83402eb9f3aa'
docType: 'setting'
thumbnail: ''
type: '클래스'
status: '진행 중'
region: ''
created_at: ''
updated_at: ''
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "엘드로스\\설정\\클래스.md") -Encoding utf8

@'
---
title: '설정 기본 템플릿'
uuid: 'b159d90b-6773-43cf-81ef-bcce19742f29'
docType: 'template'
thumbnail: ''
status: '시작 전'
type: ''
subtype: ''
region: ''
created_at: ''
updated_at: ''
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "엘드로스\\템플릿\\설정_기본 템플릿.md") -Encoding utf8

@'
---
title: '비공개 메모'
secret_rank: '상급'
secret_type: '사건'
status: '진행 중'
created_at: '2026년 7월 1일 오전 2:00'
updated_at: '2026년 7월 1일 오전 2:10'
---

## 개요
'@ | Set-Content -LiteralPath (Join-Path $inputRoot "룩스테라\\비밀 설정\\비공개 메모.md") -Encoding utf8

node (Join-Path $repoRoot "scripts\\generate-yggdrasil-codex.mjs") --input $inputRoot --series 룩스테라 --output $luxterraOutputPath
node (Join-Path $repoRoot "scripts\\generate-yggdrasil-codex.mjs") --input $inputRoot --series 엘드로스 --output $eldrosOutputPath

if (-not (Test-Path -LiteralPath $luxterraOutputPath)) {
    throw "룩스테라 출력 JSON 파일이 생성되지 않았습니다."
}

if (-not (Test-Path -LiteralPath $eldrosOutputPath)) {
    throw "엘드로스 출력 JSON 파일이 생성되지 않았습니다."
}

$luxterraJson = Get-Content -LiteralPath $luxterraOutputPath -Raw | ConvertFrom-Json
$eldrosJson = Get-Content -LiteralPath $eldrosOutputPath -Raw | ConvertFrom-Json

if (
    $luxterraJson.PSObject.Properties.Name.Count -ne 5 -or
    -not ($luxterraJson.PSObject.Properties.Name -contains "deity") -or
    -not ($luxterraJson.PSObject.Properties.Name -contains "setting") -or
    $null -eq $luxterraJson.deityCount -or
    $null -eq $luxterraJson.settingCount -or
    $null -eq $luxterraJson.totalCount
) {
    throw "룩스테라 루트 객체는 deity, setting 배열과 각 문서 수 필드를 가져야 합니다."
}

if ($luxterraJson.deity.Count -ne 1 -or $luxterraJson.setting.Count -ne 1) {
    throw "룩스테라 문서 수가 예상과 다릅니다."
}

if ($luxterraJson.deityCount -ne 1 -or $luxterraJson.settingCount -ne 1 -or $luxterraJson.totalCount -ne 2) {
    throw "룩스테라 count 필드가 예상과 다릅니다."
}

if ($luxterraJson.deity[0].docType -ne "deity" -or $luxterraJson.setting[0].docType -ne "setting") {
    throw "룩스테라 docType 분류가 잘못되었습니다."
}

if ($luxterraJson.deity[0].PSObject.Properties.Name -contains "name") {
    throw "룩스테라 JSON 에 name 필드가 남아 있으면 안 됩니다."
}

if ($luxterraJson.setting[0].title -ne "룩스테라") {
    throw "룩스테라 설정 title 이 예상과 다릅니다."
}

if ($luxterraJson.deity[0].domain.Count -ne 2 -or $luxterraJson.deity[0].domain[0] -ne "빛") {
    throw "룩스테라 신격 배열 필드가 보존되지 않았습니다."
}

if ($luxterraJson.setting.title -contains "비공개 메모") {
    throw "룩스테라 비밀 설정 문서가 setting 배열에 포함되었습니다."
}

if (
    $eldrosJson.PSObject.Properties.Name.Count -ne 5 -or
    -not ($eldrosJson.PSObject.Properties.Name -contains "deity") -or
    -not ($eldrosJson.PSObject.Properties.Name -contains "setting") -or
    $null -eq $eldrosJson.deityCount -or
    $null -eq $eldrosJson.settingCount -or
    $null -eq $eldrosJson.totalCount
) {
    throw "엘드로스 루트 객체는 deity, setting 배열과 각 문서 수 필드를 가져야 합니다."
}

if ($eldrosJson.deity.Count -ne 0) {
    throw "엘드로스 deity 배열은 비어 있어야 합니다."
}

if ($eldrosJson.setting.Count -ne 2) {
    throw "엘드로스 setting 배열 개수가 예상과 다릅니다: $($eldrosJson.setting.Count)"
}

if ($eldrosJson.deityCount -ne 0 -or $eldrosJson.settingCount -ne 2 -or $eldrosJson.totalCount -ne 2) {
    throw "엘드로스 count 필드가 예상과 다릅니다."
}

if ($eldrosJson.setting[0].docType -ne "setting") {
    throw "엘드로스 설정 항목의 docType 이 setting 이 아닙니다."
}

if ($eldrosJson.setting.title -contains "설정 기본 템플릿") {
    throw "엘드로스 템플릿 문서가 setting 배열에 포함되었습니다."
}

Remove-Item -LiteralPath $tmpRoot -Recurse -Force
Write-Host "PASS"
