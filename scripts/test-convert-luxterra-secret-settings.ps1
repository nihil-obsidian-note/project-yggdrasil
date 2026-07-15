$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-secret-settings.ps1"

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
# 가라앉은 왕권의 신 탈라소르

비밀 등급: 태고
비밀 유형: 개념
상태: 진행 중
생성 일시: 2026년 6월 19일 오전 7:55
최종 편집 일시: 2026년 6월 19일 오전 7:55

# 개요

본문
'@

$expectedOutput = @'
---
title: '가라앉은 왕권의 신 탈라소르'
secret_rank: '태고'
secret_type: '개념'
status: '진행 중'
created_at: '2026년 6월 19일 오전 7:55'
updated_at: '2026년 6월 19일 오전 7:55'
---

# 개요

본문
'@

$actualOutput = Convert-LuxterraSecretSettingDocumentContent -Content $sampleInput
Assert-Equal -Actual $actualOutput -Expected $expectedOutput -Message '비밀 설정 문서 기본 변환 결과가 예상과 다릅니다.'

$sampleMinimal = @'
# 비밀 설정

상태: 시작 전
생성 일시: 2026년 5월 6일 오전 5:21
최종 편집 일시: 2026년 5월 6일 오전 5:28

# 개요

내용
'@

$expectedMinimal = @'
---
title: '비밀 설정'
status: '시작 전'
created_at: '2026년 5월 6일 오전 5:21'
updated_at: '2026년 5월 6일 오전 5:28'
---

# 개요

내용
'@

$actualMinimal = Convert-LuxterraSecretSettingDocumentContent -Content $sampleMinimal
Assert-Equal -Actual $actualMinimal -Expected $expectedMinimal -Message '비밀 설정 문서 최소 변환 결과가 예상과 다릅니다.'

Write-Output 'PASS'
