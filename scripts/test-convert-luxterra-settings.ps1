$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-settings.ps1"

function Assert-Equal {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message`n--- Actual ---`n$Actual`n--- Expected ---`n$Expected"
    }
}

$sampleInput = @'
# 가호 사냥꾼

타입: 개념
서브타입: 일반
상태: 완료
생성 일시: 2026년 4월 29일 오전 4:29
최종 편집 일시: 2026년 4월 30일 오후 12:11

# 개요

본문
'@

$expectedOutput = @'
---
title: '가호 사냥꾼'
type: '개념'
subtype: '일반'
status: '완료'
created_at: '2026년 4월 29일 오전 4:29'
updated_at: '2026년 4월 30일 오후 12:11'
---

# 개요

본문
'@

$actualOutput = Convert-LuxterraSettingDocumentContent -Content $sampleInput
Assert-Equal -Actual $actualOutput -Expected $expectedOutput -Message '설정 문서 기본 변환 결과가 예상과 다릅니다.'

$sampleWithRegion = @'
# 공포의 의회

타입: 단체
서브타입: 주요
영역: 범대륙
상태: 완료
생성 일시: 2026년 4월 6일 오후 6:43
최종 편집 일시: 2026년 5월 31일 오전 4:56

# 개요

본문
'@

$expectedWithRegion = @'
---
title: '공포의 의회'
type: '단체'
subtype: '주요'
region: '범대륙'
status: '완료'
created_at: '2026년 4월 6일 오후 6:43'
updated_at: '2026년 5월 31일 오전 4:56'
---

# 개요

본문
'@

$actualWithRegion = Convert-LuxterraSettingDocumentContent -Content $sampleWithRegion
Assert-Equal -Actual $actualWithRegion -Expected $expectedWithRegion -Message '영역 포함 설정 문서 변환 결과가 예상과 다릅니다.'

Write-Output 'PASS'
