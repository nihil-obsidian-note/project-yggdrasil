$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\convert-luxterra-gods.ps1"

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
# 가정과 평안의 여신 베스티아

상태: 완료
등급: 대신격
성향: 선신
도메인: 평화, 화로
포트폴리오: 가정, 가족, 귀가, 안식, 온기, 화로, 휴식
생성 일시: 2026년 4월 28일 오전 4:21
최종 편집 일시: 2026년 6월 8일 오전 3:06
성향 정렬값: 1
등급 정렬값: 2
대표: Yes
청연 만신전: No

# 개요

본문
'@

$expectedOutput = @'
---
title: '가정과 평안의 여신 베스티아'
status: '완료'
rank: '대신격'
alignment: '선신'
domain:
  - '평화'
  - '화로'
portfolio:
  - '가정'
  - '가족'
  - '귀가'
  - '안식'
  - '온기'
  - '화로'
  - '휴식'
created_at: '2026년 4월 28일 오전 4:21'
updated_at: '2026년 6월 8일 오전 3:06'
pantheon: true
cheongyeon_pantheon: false
---

# 개요

본문
'@

$actualOutput = Convert-LuxterraGodDocumentContent -Content $sampleInput
Assert-Equal -Actual $actualOutput -Expected $expectedOutput -Message '기본 신격 문서 변환 결과가 예상과 다릅니다.'

$sampleNoList = @'
# 검은 갑각의 신 카르카노스

상태: 완료
등급: 대신격
성향: 악신
도메인: 어둠
포트폴리오: 갑각
대표: No
청연 만신전: Yes

# 개요
내용
'@

$expectedNoList = @'
---
title: '검은 갑각의 신 카르카노스'
status: '완료'
rank: '대신격'
alignment: '악신'
domain:
  - '어둠'
portfolio:
  - '갑각'
pantheon: false
cheongyeon_pantheon: true
---

# 개요
내용
'@

$actualNoList = Convert-LuxterraGodDocumentContent -Content $sampleNoList
Assert-Equal -Actual $actualNoList -Expected $expectedNoList -Message '단일 배열값/불리언 변환 결과가 예상과 다릅니다.'

Write-Output 'PASS'
