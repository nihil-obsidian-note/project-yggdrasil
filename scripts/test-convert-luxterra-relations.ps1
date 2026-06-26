$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-relations.ps1"

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "$Message`n--- Actual ---`n$Actual`n--- Expected ---`n$Expected" }
}

$sampleInput = @'
# 강철 제국 데우스 ↔ 생명의 신성 왕국 실바니아

A(세력): 강철 제국 데우스 (https://app.notion.com/p/33a3ce531dea80c986ade00e12635044?pvs=21)
B(세력): 생명의 신성 왕국 실바니아 (https://app.notion.com/p/33a3ce531dea80e591a1e4c1d508b2d0?pvs=21)
공개 수준: 부분 공개
관계: 대립
세션 징후: 광산 개발 분쟁, 성림 훼손 사건, 국경 충돌
쟁점(한 줄): 굴착/개발 vs 보존/생태
'@

$expectedOutput = @'
---
title: '강철 제국 데우스 ↔ 생명의 신성 왕국 실바니아'
a_setting: '[[강철 제국 데우스]]'
b_setting: '[[생명의 신성 왕국 실바니아]]'
visibility: '부분 공개'
relation: '대립'
session_signs: '광산 개발 분쟁, 성림 훼손 사건, 국경 충돌'
issue: '굴착/개발 vs 보존/생태'
---
'@

Assert-Equal (Convert-LuxterraRelationDocumentContent -Content $sampleInput) $expectedOutput '세력 관계 문서 변환 결과가 예상과 다릅니다.'

$sampleGodRelation = @'
# 법도천군 ↔ 천마

A(신격): 맹세의 집행자, 법과 형벌의 신 법도천군 (https://app.notion.com/p/db31984dfc7e41c0944bf663701406c1?pvs=21)
B(신격): 만마의 주인, 역천의 신 천마 (https://app.notion.com/p/874ed76f0e644a0b8b8bebe4ab9905b5?pvs=21)
공개 수준: 부분 공개
관계: 대립
'@

$expectedGodRelation = @'
---
title: '법도천군 ↔ 천마'
a_god: '[[맹세의 집행자, 법과 형벌의 신 법도천군]]'
b_god: '[[만마의 주인, 역천의 신 천마]]'
visibility: '부분 공개'
relation: '대립'
---
'@

Assert-Equal (Convert-LuxterraRelationDocumentContent -Content $sampleGodRelation) $expectedGodRelation '신격 관계 문서 변환 결과가 예상과 다릅니다.'
Write-Output 'PASS'
