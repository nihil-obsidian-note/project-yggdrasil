# Remove Notion IDs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 저장소 내 세계관 문서 파일명과 내부 링크에 붙어 있는 노션 32자리 아이디를 전부 제거하고, 문서 간 연결이 깨지지 않도록 정리한다.

**Architecture:** 먼저 대상 파일과 링크를 전수 조사해 변경 매핑과 미해결 링크 목록을 고정하고, 그 매핑을 기준으로 파일명 변경과 링크 재작성 스크립트를 분리한다. 실제 삭제나 이동 전에 검증 스크립트로 충돌, 미해결 링크, 예외 폴더 포함 여부를 막는다.

**Tech Stack:** PowerShell, ripgrep, Markdown 링크 치환, Git working tree 검증

---

### Task 1: 대상 범위와 이름 변경 매핑 고정

**Files:**
- Create: `scripts/scan-notion-id-targets.ps1`
- Create: `scripts/test-scan-notion-id-targets.ps1`
- Create: `docs/notion-id-rename-map.md`
- Create: `docs/notion-id-unresolved-links.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: 조사 스크립트의 기대값 테스트를 먼저 작성**

```powershell
$sampleNames = @(
  '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md',
  '룩스테라\템플릿\설정_국가 템플릿.md',
  '엘드로스 임시\설정\구버전 문서 11111111111111111111111111111111.md'
)

$matches = $sampleNames | Where-Object { $_ -match ' [0-9a-f]{32}\.md$' }
$matches.Count | Should -Be 2

$renamed = '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md' -replace ' [0-9a-f]{32}(?=\.md$)', ''
$renamed | Should -Be '룩스테라\설정\검은 광기.md'

$isTemp = '엘드로스 임시\설정\구버전 문서 11111111111111111111111111111111.md' -like '엘드로스 임시*'
$isTemp | Should -BeTrue
```

- [ ] **Step 2: 테스트를 실행해 현재는 실패하도록 확인**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-scan-notion-id-targets.ps1' -Output Detailed
'@ | powershell -NoProfile -Command -`

Expected: FAIL because `scripts/test-scan-notion-id-targets.ps1` does not exist yet

- [ ] **Step 3: 조사 스크립트를 작성**

```powershell
param(
  [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실',
  [string]$OutFile = 'C:\Users\nihil\coding\note\프로젝트 위그드라실\docs\notion-id-rename-map.md'
)

$targets = Get-ChildItem -LiteralPath (Join-Path $Root '룩스테라') -Recurse -File |
  Where-Object {
    $_.Extension -eq '.md' -and
    $_.Name -match ' [0-9a-f]{32}\.md$'
  } |
  Where-Object {
    $_.FullName -notlike '*\엘드로스 임시\*'
  } |
  Sort-Object FullName

$rows = foreach ($file in $targets) {
  $newName = $file.Name -replace ' [0-9a-f]{32}(?=\.md$)', ''
  [pscustomobject]@{
    OldPath = $file.FullName.Substring($Root.Length + 1)
    NewPath = (Join-Path $file.DirectoryName $newName).Substring($Root.Length + 1)
    OldName = $file.Name
    NewName = $newName
    NotionId = ([regex]::Match($file.Name, '([0-9a-f]{32})(?=\.md$)')).Value
  }
}

$dupes = $rows | Group-Object NewPath | Where-Object Count -gt 1
if ($dupes) {
  throw "중복 대상 발견: $($dupes.Name -join ', ')"
}

$content = @(
  '# Notion ID Rename Map',
  '',
  '> 자동 생성. 실행 전에 충돌 검토 필수.',
  '',
  '| OldPath | NewPath | NotionId |',
  '| --- | --- | --- |'
)

$content += $rows | ForEach-Object { "| $($_.OldPath) | $($_.NewPath) | $($_.NotionId) |" }
Set-Content -LiteralPath $OutFile -Value $content -Encoding UTF8

$unresolvedPath = Join-Path $Root 'docs/notion-id-unresolved-links.md'
$unresolved = Get-ChildItem -LiteralPath (Join-Path $Root '룩스테라') -Recurse -File |
  Where-Object { $_.Extension -eq '.md' } |
  ForEach-Object {
    $path = $_.FullName
    Select-String -LiteralPath $path -Pattern 'https://app\.notion\.com/p/' |
      ForEach-Object {
        "- $($path.Substring($Root.Length + 1)):$($_.LineNumber)"
      }
  }

Set-Content -LiteralPath $unresolvedPath -Value @(
  '# Notion URL Manual Review',
  '',
  '> 자동 생성. 파일명 매핑만으로 치환되지 않는 노션 URL 검토용 목록.',
  ''
) + $unresolved -Encoding UTF8
```

- [ ] **Step 4: 테스트와 조사 스크립트를 실행해 통과를 확인**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-scan-notion-id-targets.ps1' -Output Detailed
& 'scripts/scan-notion-id-targets.ps1'
'@ | powershell -NoProfile -Command -`

Expected: PASS, 그리고 `docs/notion-id-rename-map.md`, `docs/notion-id-unresolved-links.md` 생성

- [ ] **Step 5: 지침 문구를 보강**

```md
- 문서 파일명 끝의 노션 32자리 아이디는 유지하지 않는다.
- 내부 링크도 아이디 없는 최종 문서명 기준으로 정리한다.
- 원본 노션 URL은 허용하지 않으며, 매핑이 애매한 경우 수동 검토 목록으로 분리한다.
- `엘드로스 임시` 같은 구버전 보관 폴더는 정리 대상에서 제외한다.
```

- [ ] **Step 6: 커밋**

```bash
git add AGENTS.md scripts/scan-notion-id-targets.ps1 scripts/test-scan-notion-id-targets.ps1 docs/notion-id-rename-map.md docs/notion-id-unresolved-links.md
git commit -m "2026 0627 chore: 노션 아이디 제거 범위와 매핑 고정"
```

### Task 2: 파일명 변경 스크립트와 충돌 방지 검증 작성

**Files:**
- Create: `scripts/rename-notion-id-files.ps1`
- Create: `scripts/test-rename-notion-id-files.ps1`
- Modify: `docs/notion-id-rename-map.md`
- Modify: `docs/notion-id-unresolved-links.md`

- [ ] **Step 1: 파일명 변경의 안전 조건 테스트를 먼저 작성**

```powershell
$map = @(
  [pscustomobject]@{ OldPath = '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md'; NewPath = '룩스테라\설정\검은 광기.md' },
  [pscustomobject]@{ OldPath = '룩스테라\설정\국가 11111111111111111111111111111111.md'; NewPath = '룩스테라\설정\국가.md' }
)

($map.NewPath | Group-Object | Where-Object Count -gt 1).Count | Should -Be 0

$sampleLink = '[검은 광기](%EA%B2%80%EC%9D%80%20%EA%B4%91%EA%B8%B0%203c2b3b5aa6f64078bff4fce6cc8d5194.md)'
$sampleLink -replace ' [0-9a-f]{32}(?=\.md\))', '' |
  Should -Be '[검은 광기](%EA%B2%80%EC%9D%80%20%EA%B4%91%EA%B8%B0.md)'
```

- [ ] **Step 2: 테스트를 실행해 현재는 실패하도록 확인**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-rename-notion-id-files.ps1' -Output Detailed
'@ | powershell -NoProfile -Command -`

Expected: FAIL because `scripts/test-rename-notion-id-files.ps1` does not exist yet

- [ ] **Step 3: 파일명 변경 스크립트를 작성**

```powershell
param(
  [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실',
  [switch]$WhatIf
)

$mapPath = Join-Path $Root 'docs/notion-id-rename-map.md'
$lines = Get-Content -LiteralPath $mapPath
$entries = $lines |
  Where-Object { $_ -like '| 룩스테라* | 룩스테라* |' } |
  ForEach-Object {
    $parts = $_.Trim('|').Split('|').Trim()
    [pscustomobject]@{
      OldPath = $parts[0]
      NewPath = $parts[1]
    }
  }

foreach ($entry in $entries) {
  $oldFull = Join-Path $Root $entry.OldPath
  $newFull = Join-Path $Root $entry.NewPath

  if (-not (Test-Path -LiteralPath $oldFull)) {
    throw "원본 파일 없음: $($entry.OldPath)"
  }

  if ((Test-Path -LiteralPath $newFull) -and ($oldFull -ne $newFull)) {
    throw "대상 파일 이미 존재: $($entry.NewPath)"
  }

  if (-not $WhatIf) {
    Move-Item -LiteralPath $oldFull -Destination $newFull
  }
}
```

- [ ] **Step 4: 테스트와 WhatIf 실행으로 안전성을 검증**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-rename-notion-id-files.ps1' -Output Detailed
& 'scripts/rename-notion-id-files.ps1' -WhatIf
'@ | powershell -NoProfile -Command -`

Expected: PASS, 실제 파일 이동 없음

- [ ] **Step 5: 커밋**

```bash
git add scripts/rename-notion-id-files.ps1 scripts/test-rename-notion-id-files.ps1 docs/notion-id-rename-map.md
git commit -m "2026 0627 feat: 노션 아이디 파일명 변경 스크립트 추가"
```

### Task 3: 본문 링크와 위키 링크 재작성

**Files:**
- Create: `scripts/rewrite-notion-id-links.ps1`
- Create: `scripts/test-rewrite-notion-id-links.ps1`
- Modify: `룩스테라/설정/*.md`
- Modify: `룩스테라/신격/*.md`
- Modify: `룩스테라/세력 관계/*.md`
- Modify: `룩스테라/설정 정비/*.md`
- Modify: `룩스테라/스토리 설계/*.md`
- Modify: `룩스테라/비밀 설정/*.md`
- Modify: `룩스테라/템플릿/*.md`

- [ ] **Step 1: 링크 재작성 규칙 테스트를 먼저 작성**

```powershell
$markdownLink = '[발가르 대륙](%EB%B0%9C%EA%B0%80%EB%A5%B4%20%EB%8C%80%EB%A5%99%2033a3ce531dea804fbdcef13f1d6595ef.md)'
$rewrittenMarkdown = $markdownLink -replace ' [0-9a-f]{32}(?=\.md\))', ''
$rewrittenMarkdown | Should -Be '[발가르 대륙](%EB%B0%9C%EA%B0%80%EB%A5%B4%20%EB%8C%80%EB%A5%99.md)'

$notionUrl = '[컬트 오브 디스페어](https://app.notion.com/p/620e3a3c700e406ea8b70ec1ed5d50a5?pvs=21)'
$mapped = '[컬트 오브 디스페어](../설정/컬트 오브 디스페어.md)'
$mapped | Should -Be '[컬트 오브 디스페어](../설정/컬트 오브 디스페어.md)'

$wiki = '[[발가르 대륙 33a3ce531dea804fbdcef13f1d6595ef]]'
$wiki -replace ' [0-9a-f]{32}(?=\]\])', '' | Should -Be '[[발가르 대륙]]'
```

- [ ] **Step 2: 테스트를 실행해 현재는 실패하도록 확인**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-rewrite-notion-id-links.ps1' -Output Detailed
'@ | powershell -NoProfile -Command -`

Expected: FAIL because `scripts/test-rewrite-notion-id-links.ps1` does not exist yet

- [ ] **Step 3: 링크 재작성 스크립트를 작성**

```powershell
param(
  [string]$Root = 'C:\Users\nihil\coding\note\프로젝트 위그드라실'
)

$mapPath = Join-Path $Root 'docs/notion-id-rename-map.md'
$entries = @{}

Get-Content -LiteralPath $mapPath |
  Where-Object { $_ -like '| 룩스테라* | 룩스테라* |' } |
  ForEach-Object {
    $parts = $_.Trim('|').Split('|').Trim()
    $oldLeaf = [System.IO.Path]::GetFileName($parts[0])
    $newLeaf = [System.IO.Path]::GetFileName($parts[1])
    $notionId = $parts[2]
    $entries[$oldLeaf] = [pscustomobject]@{
      NewLeaf = $newLeaf
      NotionId = $notionId
    }
  }

$docs = Get-ChildItem -LiteralPath (Join-Path $Root '룩스테라') -Recurse -File |
  Where-Object { $_.Extension -eq '.md' }

foreach ($doc in $docs) {
  $content = Get-Content -LiteralPath $doc.FullName -Raw

  foreach ($pair in $entries.GetEnumerator()) {
    $escapedOld = [regex]::Escape($pair.Key)
    $content = $content -replace $escapedOld, $pair.Value.NewLeaf
    $content = $content -replace "https://app\.notion\.com/p/$($pair.Value.NotionId)\?pvs=21", $pair.Value.NewLeaf
  }

  $content = $content -replace '\[\[([^\]]+?) [0-9a-f]{32}\]\]', '[[$1]]'
  Set-Content -LiteralPath $doc.FullName -Value $content -Encoding UTF8
}
```

- [ ] **Step 4: 테스트 실행 후 링크 재작성 적용**

Run: `@'
Import-Module Pester
Invoke-Pester -Path 'scripts/test-rewrite-notion-id-links.ps1' -Output Detailed
& 'scripts/rewrite-notion-id-links.ps1'
'@ | powershell -NoProfile -Command -`

Expected: PASS, 대상 문서 내 `.md` 링크, 위키 링크, 직접 노션 URL이 매핑 기준으로 정리됨

- [ ] **Step 5: 커밋**

```bash
git add scripts/rewrite-notion-id-links.ps1 scripts/test-rewrite-notion-id-links.ps1 룩스테라
git commit -m "2026 0627 feat: 노션 아이디 링크 재작성"
```

### Task 4: 실제 파일명 변경 실행과 잔존 아이디 검증

**Files:**
- Modify: `룩스테라/**/*.md`
- Modify: `docs/notion-id-rename-map.md`
- Modify: `docs/notion-id-unresolved-links.md`

- [ ] **Step 1: 실제 파일명 변경 전에 잔존 링크가 있는지 사전 확인**

```powershell
$pending = Get-ChildItem -LiteralPath '룩스테라' -Recurse -File |
  Where-Object { $_.Name -match ' [0-9a-f]{32}\.md$' }
$pending.Count | Should -BeGreaterThan 0
```

- [ ] **Step 2: 파일명 변경을 실제 실행**

Run: `& 'scripts/rename-notion-id-files.ps1'`

Expected: 모든 대상 파일이 아이디 없는 파일명으로 이동

- [ ] **Step 3: 잔존 아이디와 노션 URL을 검증**

Run: `@'
$fileNameIds = Get-ChildItem -LiteralPath '룩스테라' -Recurse -File | Where-Object { $_.Name -match ' [0-9a-f]{32}\.md$' }
$linkIds = rg -n " [0-9a-f]{32}(?=\.md[\)\]])" 룩스테라
$notionUrls = rg -n "https://app\.notion\.com/p/" 룩스테라
if ($fileNameIds.Count -gt 0) { throw "파일명 아이디 잔존" }
if ($linkIds) { throw "링크 아이디 잔존" }
if ($notionUrls) { throw "노션 URL 잔존" }
'@ | powershell -NoProfile -Command -`

Expected: 출력 없음, 종료 코드 0

- [ ] **Step 4: 구버전 폴더가 건드려지지 않았는지 확인**

Run: `Get-ChildItem -LiteralPath '엘드로스 임시' -Recurse -File | Where-Object { $_.Name -match ' [0-9a-f]{32}\.md$' }`

Expected: 결과가 남아 있어도 괜찮음. 이 폴더는 제외 대상이므로 변경되지 않아야 함

- [ ] **Step 5: 커밋**

```bash
git add 룩스테라 docs/notion-id-rename-map.md docs/notion-id-unresolved-links.md
git commit -m "2026 0627 refactor: 룩스테라 문서명에서 노션 아이디 제거"
```

### Task 5: 최종 수동 검토와 운영 문서 정리

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/notion-id-rename-map.md`

- [ ] **Step 1: 대표 문서 샘플을 수동 검토**

Run: `@'
Get-Content -LiteralPath '룩스테라\설정\검은 광기.md' -TotalCount 20
Get-Content -LiteralPath '룩스테라\신격\가뭄과 기근의 신 우르투스.md' -TotalCount 20
Get-Content -LiteralPath '룩스테라\템플릿\신격_기본 템플릿.md' -TotalCount 20
'@ | powershell -NoProfile -Command -`

Expected: 파일명과 본문 링크 모두 아이디 없는 상태

- [ ] **Step 2: 작업 기록을 간단히 남긴다**

```md
## 2026-06-27

- 룩스테라 문서 파일명 끝의 노션 32자리 아이디 제거 완료
- 본문 Markdown 링크와 위키 링크를 최종 파일명 기준으로 재작성
- `엘드로스 임시`는 구버전 보관 폴더로 판단하여 제외
```

- [ ] **Step 3: 최종 검증 명령을 다시 실행**

Run: `@'
rg -n " [0-9a-f]{32}\.md$" 룩스테라
rg -n "https://app\.notion\.com/p/" 룩스테라
'@ | powershell -NoProfile -Command -`

Expected: 결과 없음, 종료 코드 1

- [ ] **Step 4: 커밋**

```bash
git add AGENTS.md docs/notion-id-rename-map.md
git commit -m "2026 0627 docs: 노션 아이디 제거 작업 기록 정리"
```
