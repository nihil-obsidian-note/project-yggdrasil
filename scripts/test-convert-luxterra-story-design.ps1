$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-story-design.ps1"

function Assert-Equal {
    param([string]$Actual, [string]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "$Message`n--- Actual ---`n$Actual`n--- Expected ---`n$Expected" }
}

$sampleInput = @'
# 스토리 1 - 에리디안의 잔향

타입: 스토리
진행 상황: 진행완료
작성일자: 2026년 5월 29일
최종 편집 일시: 2026년 6월 8일 오후 7:32

## 개요
본문
'@

$expectedOutput = @'
---
title: '스토리 1 - 에리디안의 잔향'
type: '스토리'
progress: '진행완료'
written_on: '2026년 5월 29일'
updated_at: '2026년 6월 8일 오후 7:32'
---

## 개요
본문
'@

Assert-Equal (Convert-LuxterraStoryDesignDocumentContent -Content $sampleInput) $expectedOutput '스토리 설계 문서 변환 결과가 예상과 다릅니다.'
Write-Output 'PASS'
