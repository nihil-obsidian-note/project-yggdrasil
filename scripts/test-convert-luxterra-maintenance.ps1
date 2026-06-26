$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-maintenance.ps1"

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "$Message`n--- Actual ---`n$Actual`n--- Expected ---`n$Expected" }
}

$sampleInput = @'
# 신격 신앙 형태 조정 대상 리스트

진행 상황: 작성완료
작성일자: 2026년 5월 15일
최종 편집 일시: 2026년 6월 8일 오후 7:43

## 제외
본문
'@

$expectedOutput = @'
---
title: '신격 신앙 형태 조정 대상 리스트'
progress: '작성완료'
written_on: '2026년 5월 15일'
updated_at: '2026년 6월 8일 오후 7:43'
---

## 제외
본문
'@

Assert-Equal (Convert-LuxterraMaintenanceDocumentContent -Content $sampleInput) $expectedOutput '설정 정비 문서 변환 결과가 예상과 다릅니다.'

$sampleMinimal = @'
# 문서

진행 상황: 준비중
최종 편집 일시: 2026년 6월 8일 오후 7:44

# 개요
내용
'@

$expectedMinimal = @'
---
title: '문서'
progress: '준비중'
updated_at: '2026년 6월 8일 오후 7:44'
---

# 개요
내용
'@

Assert-Equal (Convert-LuxterraMaintenanceDocumentContent -Content $sampleMinimal) $expectedMinimal '작성일자 없는 설정 정비 문서 변환 결과가 예상과 다릅니다.'
Write-Output 'PASS'
