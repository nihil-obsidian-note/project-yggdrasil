# Document Metadata Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `프로젝트 위그드라실` 원본 문서들에 `uuid`와 `thumbnail`을 포함한 표준 메타데이터를 안정적으로 보강하고, `setting`/`deity` 계열 메타 검증 체계를 만든다.

**Architecture:** 문서군별 프론트매터 구조를 샘플링해 규칙 테이블로 고정하고, 공통 메타 정규화 스크립트와 검증 스크립트를 분리한다. 본문은 건드리지 않고 YAML 프론트매터만 수정하며, `uuid`는 재실행 안정성을 보장해야 한다.

**Tech Stack:** PowerShell 스크립트, ripgrep, Git, YAML frontmatter, markdown files

---

### Task 1: 메타데이터 표준 규칙 문서와 운영 지침 정리

**Files:**
- Modify: `AGENTS.md`
- Reference: `docs/superpowers/specs/2026-07-01-document-metadata-standard-design.md`

- [ ] `AGENTS.md`에 공통 필수 메타데이터 `uuid`, `title`, `docType`, `thumbnail`, `status`, `created_at`, `updated_at` 규칙을 추가한다.
- [ ] `thumbnail`이 없을 때는 빈 문자열 `''`로 두고 앱에서 기본 썸네일을 대체한다는 규칙을 명시한다.
- [ ] `setting.type`, `setting.subtype`, `setting.region`과 `deity` 필드군을 현재 운영 기준대로 정리한다.
- [ ] `quartz/content`는 원본의 심볼릭 링크 성격으로 보고 직접 대상에서 제외한다는 규칙을 적는다.
- [ ] `이름` 대신 `title`을 공통 제목 키로 사용한다는 통일 방침을 적는다.

### Task 2: 현재 문서군 메타데이터 실태를 인벤토리화

**Files:**
- Create: `scripts/audit-document-frontmatter.ps1`
- Create: `docs/document-frontmatter-audit.md`

- [ ] `룩스테라`, `엘드로스`, `위그드라실` 원본 문서만 대상으로 순회하는 감사 스크립트를 만든다.
- [ ] 문서별로 `title`, `이름`, `docType`, `uuid`, `thumbnail`, `type`, `subtype`, `region`, `rank`, `alignment`, `domain`, `portfolio` 존재 여부를 기록하게 한다.
- [ ] 결과를 문서군별 누락 현황 표로 `docs/document-frontmatter-audit.md`에 정리한다.
- [ ] `quartz/content`와 템플릿, 제외 폴더가 감사 결과에 섞이지 않는지 확인한다.

### Task 3: 공통 메타 정규화 스크립트 작성

**Files:**
- Create: `scripts/normalize-document-frontmatter.ps1`
- Create: `scripts/test-normalize-document-frontmatter.ps1`

- [ ] 샘플 문서 복사본을 이용해 failing test를 먼저 만든다.
- [ ] 테스트에서 `uuid`가 없는 문서에 새 UUID가 주입되는지 검증한다.
- [ ] 테스트에서 기존 `uuid`가 이미 있으면 유지되는지 검증한다.
- [ ] 테스트에서 `thumbnail`이 없을 때 `thumbnail: ''`가 들어가는지 검증한다.
- [ ] 테스트에서 `이름:`가 있으면 `title:`로 치환되고 본문은 유지되는지 검증한다.
- [ ] 최소 구현으로 테스트를 통과시킨다.

### Task 4: 문서군별 `docType` 판별 규칙 구현

**Files:**
- Modify: `scripts/normalize-document-frontmatter.ps1`
- Modify: `scripts/test-normalize-document-frontmatter.ps1`

- [ ] 폴더 경로 기반으로 최소 `docType` 판별 규칙을 추가한다.
- [ ] `룩스테라/신격`, `엘드로스/신격` 계열은 `docType: deity`가 되도록 한다.
- [ ] `룩스테라/설정`, `엘드로스/설정`, `위그드라실/설정` 계열은 `docType: setting`이 되도록 한다.
- [ ] 후속 문서군 확장 여지를 위해 `secret_setting`, `relation`, `story_design`, `maintenance`, `template` 분기 지점을 코드 구조에 남긴다.
- [ ] 샘플 테스트에 `setting`과 `deity` 판별 케이스를 추가한다.

### Task 5: `setting` 허용값 검증 스크립트 작성

**Files:**
- Create: `scripts/validate-setting-frontmatter.ps1`
- Create: `scripts/test-validate-setting-frontmatter.ps1`

- [ ] `type` 누락을 실패로 처리하는 테스트를 작성한다.
- [ ] `subtype`와 `region`이 허용 후보 밖일 때 실패하는 테스트를 작성한다.
- [ ] 룩스테라와 엘드로스의 `subtype` 허용값 집합이 다르다는 점을 테스트에 반영한다.
- [ ] 실제 허용값 목록은 `AGENTS.md`와 스펙 문서 기준으로 코드에 상수화한다.
- [ ] 테스트 통과 후 대표 `setting` 문서 몇 개로 수동 검증한다.

### Task 6: `deity` 필드 검증 스크립트 작성

**Files:**
- Create: `scripts/validate-deity-frontmatter.ps1`
- Create: `scripts/test-validate-deity-frontmatter.ps1`

- [ ] `rank`, `alignment`, `domain`, `portfolio` 누락 시 실패하는 테스트를 작성한다.
- [ ] `domain`과 `portfolio`가 배열인지 검사하는 테스트를 추가한다.
- [ ] `pantheon`, `cheongyeon_pantheon`이 boolean 계열로 유지되는지 검사한다.
- [ ] 테스트 통과 후 대표 신격 문서 표본을 검토한다.

### Task 7: 전체 문서에 정규화 적용

**Files:**
- Modify: `룩스테라/**/*.md`
- Modify: `엘드로스/**/*.md`
- Modify: `위그드라실/**/*.md`

- [ ] 적용 전 `git status --short`로 작업 트리를 확인한다.
- [ ] `scripts/normalize-document-frontmatter.ps1`를 원본 문서군에 실행한다.
- [ ] `uuid`가 모든 대상 문서에 들어갔는지 확인한다.
- [ ] `thumbnail`이 모든 대상 문서에 존재하는지 확인한다.
- [ ] 대표 문서 표본 10개 내외를 열어 본문 불변 여부를 확인한다.

### Task 8: 전체 검증과 중복 검사

**Files:**
- Modify: `scripts/validate-setting-frontmatter.ps1`
- Modify: `scripts/validate-deity-frontmatter.ps1`
- Create: `scripts/check-duplicate-uuids.ps1`

- [ ] 전체 문서를 대상으로 `uuid` 중복 검사 스크립트를 만든다.
- [ ] `uuid` 누락, 중복, 빈 문자열 여부를 모두 검증한다.
- [ ] `setting` 검증 스크립트를 전체 설정 문서에 실행한다.
- [ ] `deity` 검증 스크립트를 전체 신격 문서에 실행한다.
- [ ] 검증 실패 목록을 남기고 원인별로 분류한다.

### Task 9: 템플릿 문서 동기화 여부 결정 및 반영

**Files:**
- Modify: `룩스테라/템플릿/*.md`
- Modify: `엘드로스/템플릿/*.md`
- Modify: `AGENTS.md`

- [ ] 템플릿에도 `uuid`를 넣을지 정책을 결정한다.
- [ ] 템플릿에 `thumbnail: ''`, `docType`, `title` 표준을 반영할지 결정한다.
- [ ] 결정 사항을 `AGENTS.md`에 명시한다.
- [ ] 템플릿을 실제 운영 문서와 같은 키 순서로 맞춘다.

### Task 10: 최종 검증과 커밋

**Files:**
- Modify: 관련 스크립트와 문서 전반

- [ ] `git status --short`로 변경 범위를 최종 확인한다.
- [ ] 정규화 스크립트 테스트를 전부 실행한다.
- [ ] 검증 스크립트를 전부 실행한다.
- [ ] 대표 문서군 표본 점검 결과를 기록한다.
- [ ] 커밋 메시지는 날짜 접두와 한글 타입을 포함해 작성한다.
