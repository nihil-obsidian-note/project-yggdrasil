# Luxterra Frontmatter Rollout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `룩스테라`의 문서군 전체를 노션식 상단 메타에서 YAML 프론트매터 형식으로 순차 전환한다.

**Architecture:** 문서군별로 메타 형식을 샘플링해 고정하고, 각 문서군마다 테스트 스크립트와 변환 스크립트를 만든 뒤 실제 문서에 적용한다. 본문은 첫 본문 헤더 또는 본문 시작점부터 그대로 보존하고, 제목 및 상단 메타만 프론트매터로 이동한다.

**Tech Stack:** PowerShell 스크립트, ripgrep, YAML frontmatter, markdown files

---

### Task 1: 설정 문서 전환

**Files:**
- Create: `scripts/test-convert-luxterra-settings.ps1`
- Create: `scripts/convert-luxterra-settings.ps1`
- Modify: `룩스테라/설정/*.md`

- [ ] 샘플 메타 형식 고정
- [ ] failing test 추가
- [ ] 테스트 실패 확인
- [ ] 최소 변환 구현
- [ ] 테스트 통과 확인
- [ ] 전체 적용 후 표본 검증

### Task 2: 비밀 설정 문서 전환

**Files:**
- Create: `scripts/test-convert-luxterra-secret-settings.ps1`
- Create: `scripts/convert-luxterra-secret-settings.ps1`
- Modify: `룩스테라/비밀 설정/*.md`

- [ ] 샘플 메타 형식 고정
- [ ] failing test 추가
- [ ] 테스트 실패 확인
- [ ] 최소 변환 구현
- [ ] 테스트 통과 확인
- [ ] 전체 적용 후 표본 검증

### Task 3: 설정 정비 문서 전환

**Files:**
- Create: `scripts/test-convert-luxterra-maintenance.ps1`
- Create: `scripts/convert-luxterra-maintenance.ps1`
- Modify: `룩스테라/설정 정비/*.md`

- [ ] 샘플 메타 형식 고정
- [ ] failing test 추가
- [ ] 테스트 실패 확인
- [ ] 최소 변환 구현
- [ ] 테스트 통과 확인
- [ ] 전체 적용 후 표본 검증

### Task 4: 세력 관계 문서 전환

**Files:**
- Create: `scripts/test-convert-luxterra-relations.ps1`
- Create: `scripts/convert-luxterra-relations.ps1`
- Modify: `룩스테라/세력 관계/*.md`

- [ ] 샘플 메타 형식 고정
- [ ] failing test 추가
- [ ] 테스트 실패 확인
- [ ] 최소 변환 구현
- [ ] 테스트 통과 확인
- [ ] 전체 적용 후 표본 검증

### Task 5: 스토리 설계 문서 전환

**Files:**
- Create: `scripts/test-convert-luxterra-story-design.ps1`
- Create: `scripts/convert-luxterra-story-design.ps1`
- Modify: `룩스테라/스토리 설계/*.md`

- [ ] 샘플 메타 형식 고정
- [ ] failing test 추가
- [ ] 테스트 실패 확인
- [ ] 최소 변환 구현
- [ ] 테스트 통과 확인
- [ ] 전체 적용 후 표본 검증

### Task 6: 지침 정리

**Files:**
- Modify: `AGENTS.md`

- [ ] 실제 프론트매터 키 이름 기준으로 각 문서군 지침 갱신
- [ ] 정렬값 제거/배열 필드/불리언 필드를 문서화
