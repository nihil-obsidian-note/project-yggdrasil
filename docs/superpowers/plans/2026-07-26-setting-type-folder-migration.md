# 설정 문서 타입별 폴더 이관 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 룩스테라·엘드로스 설정 문서를 타입별 폴더로 재배치하고, 청연을 별도 지역 경계로 분류하며, TRPG 데이터의 설정 라우팅 프롬프트를 새 구조와 동기화한다.

**Architecture:** 이동 판정은 각 Markdown의 YAML 프론트매터 `type`과, 룩스테라에서만 우선 적용하는 `region: 청연`으로 결정한다. 파일 본문과 이름은 바꾸지 않고 이동 전 매니페스트의 SHA-256, 문서 수, 분류별 수를 이동 후 결과와 비교한다. 경로를 직접 설명하는 로컬 프롬프트 문서는 새 탐색 규칙으로 갱신한다.

**Tech Stack:** PowerShell 7, Git 이동 추적, YAML 프론트매터 텍스트 검사, ripgrep, Markdown

## Global Constraints

- 현재 대화의 최신 지시가 모든 기존 경로 규칙보다 우선한다.
- 룩스테라 `region: 청연`은 `설정/청연/<type>/`에, 나머지 룩스테라는 `설정/<type>/`에 둔다.
- 엘드로스는 모두 `설정/<type>/`에 둔다.
- 문서의 이름·내용·프론트매터·UUID·공개 수준을 변경하지 않는다.
- 기존 사용자 변경사항을 되돌리거나 덮어쓰지 않는다.
- Google Drive 커넥터·Google Drive 직접 파일 조작·GitHub 직접 푸시는 사용하지 않는다.
- 파일 시스템 이관은 현재 작업 공간 `master`에서만 수행한다는 사용자의 명시 승인을 받은 뒤 시작한다.

---

### Task 1: 이동 전 매니페스트와 분류 검증

**Files:**
- Read: `프로젝트 위그드라실/룩스테라/설정/*.md`
- Read: `프로젝트 위그드라실/엘드로스/설정/*.md`
- Create: `%TEMP%/yggdrasil-setting-migration-before.json`

**Interfaces:**
- Consumes: 각 문서의 첫 YAML 프론트매터에 있는 `type`, `region`
- Produces: `source`, `destination`, `sha256`, `type`, `region` 필드가 있는 이동 매니페스트

- [ ] **Step 1: 현재 평면 설정 문서를 수집한다.**

  `Get-ChildItem -LiteralPath <series>/설정 -File -Filter '*.md'`로 두 시리즈의 직접 하위 파일만 수집한다.

- [ ] **Step 2: 유형과 지역을 판정한다.**

  각 파일의 YAML 헤더에서 `type`을 읽고, 룩스테라는 `region: 청연`일 때 `설정/청연/<type>/<filename>`을 목적지로 계산한다. 그 밖의 파일은 `설정/<type>/<filename>`을 목적지로 계산한다.

- [ ] **Step 3: 이관 가능성을 검증한다.**

  빈 `type`, 동일 목적지, 목적지 기존 파일, 설정 폴더 아래의 예상 밖 하위 폴더가 하나라도 있으면 중단하고 보고한다. 모든 원본의 SHA-256과 분류별 수를 `%TEMP%/yggdrasil-setting-migration-before.json`에 기록한다.

### Task 2: 유형별 폴더 이관

**Files:**
- Move: `프로젝트 위그드라실/룩스테라/설정/*.md` → `프로젝트 위그드라실/룩스테라/설정/(청연/)?<type>/*.md`
- Move: `프로젝트 위그드라실/엘드로스/설정/*.md` → `프로젝트 위그드라실/엘드로스/설정/<type>/*.md`

**Interfaces:**
- Consumes: Task 1 매니페스트
- Produces: 매니페스트의 모든 `destination`에 정확히 한 파일이 존재하는 폴더 트리

- [ ] **Step 1: 목적지 폴더를 만든다.**

  매니페스트의 목적지 부모 폴더만 `New-Item -ItemType Directory -Force`로 만든다.

- [ ] **Step 2: 현재 파일을 이동한다.**

  매니페스트마다 `Move-Item -LiteralPath <source> -Destination <destination>`을 사용한다. 파일을 복사·재작성하지 않는다.

- [ ] **Step 3: 이동 직후 매니페스트를 대조한다.**

  각 원본 경로가 사라졌고 각 목적지 경로가 존재하며 SHA-256이 동일한지 검사한다. 두 시리즈의 평면 `설정/*.md` 수가 0인지 확인한다.

### Task 3: 설정 라우팅·마스터 프롬프트 갱신

**Files:**
- Modify: `G:\내 드라이브\TRPG 데이터\AGENTS.md`
- Modify: `G:\내 드라이브\TRPG 데이터\1. 프롬프트\AGENTS.md`
- Modify: `G:\내 드라이브\TRPG 데이터\1. 프롬프트\00. TRPG 세션 매니저 프로젝트 기본 지침.md`
- Modify: `G:\내 드라이브\TRPG 데이터\1. 프롬프트\0. TRPG 데이터 프롬프트 통합 마스터 프롬프트.md`
- Modify: `G:\내 드라이브\TRPG 데이터\1. 프롬프트\8. 설정 관련 요청 프롬프트\*.md`

**Interfaces:**
- Consumes: Task 2의 새 트리
- Produces: 설정 탐색 지침에 타입별 폴더와 청연 우선 경계를 명시한 로컬 Markdown 문서

- [ ] **Step 1: 옛 평면 경로와 설정 탐색 설명을 전수 검색한다.**

  `rg -n --glob '*.md' '룩스테라/설정|엘드로스/설정|설정 폴더|설정 문서'`로 실제 경로 또는 탐색 규칙을 가진 문서를 확인한다.

- [ ] **Step 2: 공통 진입점에 새 분류 규칙을 반영한다.**

  두 시리즈의 `설정` 문서는 `type` 폴더 아래에 있고, 룩스테라 `region: 청연` 문서는 `청연/<type>` 아래에 있다는 탐색 원칙을 반영한다. Codex는 동기화된 로컬 Markdown을 읽고 Google Drive 커넥터를 호출하지 않는다는 전역 규칙과 충돌하는 문구도 함께 정정한다.

- [ ] **Step 3: 8번 설정 관련 요청 자료를 동기화한다.**

  8번 기능의 `AGENTS.md`, 마스터 프롬프트, 지침·점검 수칙에 설정 문서 탐색 순서와 새 폴더 구조를 반영한다. 문서군 역할·정본 우선순위·시리즈 구분은 유지한다.

### Task 4: 참조·무결성 검증

**Files:**
- Read: `프로젝트 위그드라실/**/*.md`
- Read: `G:\내 드라이브\TRPG 데이터\**/*.md`
- Read: `%TEMP%/yggdrasil-setting-migration-before.json`

**Interfaces:**
- Consumes: Task 1 매니페스트, Task 2 트리, Task 3 경로 정책
- Produces: 검증 결과와 실패 시 정확한 파일 목록

- [ ] **Step 1: 수와 해시를 완전 대조한다.**

  매니페스트의 모든 목적지 파일을 재해시하고, 전체·시리즈별·타입별·청연 타입별 수가 이동 전과 동일한지 비교한다.

- [ ] **Step 2: 내부 링크와 명시 경로를 검사한다.**

  Markdown 위키 링크의 대상 이름 중 이관한 파일명이 실제로 하나의 문서로 해석되는지 확인한다. 상대 Markdown 링크와 `프로젝트 위그드라실/.../설정/` 명시 경로는 새 위치가 존재하는지 검사한다.

- [ ] **Step 3: Git과 프롬프트 동기화를 검증한다.**

  `git diff --check`를 실행하고, 모든 이관 파일이 삭제·생성이 아닌 이름 변경으로 인식되는지 검토한다. 공통 진입점과 8번 프롬프트에서 새 분류 규칙이 모두 확인되는지 검색한다.

- [ ] **Step 4: 변경 범위를 보고한다.**

  파일 이동 수, 시리즈·타입별 분포, 청연 분포, 수정된 프롬프트 문서 목록, 무결성 검사 결과, 기존 사용자 변경사항 보존 여부를 보고한다.
