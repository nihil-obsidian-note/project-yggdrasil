# 관계 대상 카테고리 매핑 실행 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 2.10 설화·전승·서사 관계를 확정하고 2.1~2.10 모든 관계 대상 역할을 문서 카테고리와 매핑한다.

**Architecture:** 관계 유형별 의미 역할을 기준으로 카테고리 허용 목록을 정규화한다. 기존 2.1~2.5의 권장 문서는 범용 11개 카테고리로 변환하고, 권장 문서가 없는 2.5.1·2.6~2.10은 관계 의미를 분석해 단일·복수·범용 전체 허용으로 판정한다. 룩스테라의 용종과 엘드로스의 클래스는 세계별 확장 카테고리로 분리하며 기본 매핑에는 포함하지 않는다.

**Tech Stack:** Markdown 정본, Google Drive 파일 ID 유지 갱신, 관계 유형·역할·카테고리 다대다 데이터 모델

## Global Constraints

- 관계 대상은 2개 이상 4개 이하로 유지한다.
- 모든 대상 역할에 범용 11개 허용 카테고리를 명시한다.
- 룩스테라의 `용종`과 엘드로스의 `클래스`는 세계별 확장 카테고리로 기록하되 범용 기본 매핑에 자동 포함하지 않는다.
- 기존 파일 수정 시 파일명과 Drive 파일 ID를 유지한다.
- 새 매핑 문서는 범용 관계 유형 폴더에 저장한다.
- 확정·추적·정비·인계·레지스트리 문서를 함께 갱신한다.

---

### Task 1: 2.10 관계 확정

**Files:**
- Create: `범용 관계 유형/2.10. 범용 관계 유형 - 설화·전승·서사 관계 확정본.md`

- [x] 후보 55개를 자체 확정·기존 재사용·후속 이관으로 판정한다.
- [x] 자체 relation type 48개의 방향·대상 수·역할·템플릿을 확정한다.
- [x] 각 대상 역할에 허용 카테고리를 명시한다.
- [x] 누적 relation type 753개를 검산한다.

### Task 2: 2.1~2.10 대상 카테고리 전수 매핑

**Files:**
- Create: `범용 관계 유형/2.1~2.10 관계 대상 카테고리 매핑.md`

- [x] 2.1~2.10과 2.5.1의 relation type 753개를 수집한다.
- [x] 대상 역할 2,141개를 추출한다.
- [x] 범용 11개 카테고리 기준으로 단일·복수·범용 전체 허용을 판정한다.
- [x] 관계별 대상 역할과 카테고리 목록을 문서화한다.

### Task 3: 추적 문서 동기화

**Files:**
- Modify: `데이터베이스 이관 사전 작업 정비.md`
- Modify: `범용 관계 유형 검토·이관 추적 문서.md`
- Modify: `카테고리 및 관계 설계 인계서.md`
- Modify: `설정 정비 현황.md`
- Modify: `SUPERPOWERS WORK REGISTRY.md`

- [x] 2.10 확정 수량과 재사용·이관 결과를 반영한다.
- [x] 대상 카테고리 매핑 수량과 정본 경로를 반영한다.
- [x] 다음 작업을 2.11 범위 재구성으로 이동한다.

### Task 4: 검증 및 Drive 반영

**Files:**
- Create: `reports/2026-08-12-database-migration-relations-2.10-target-category-verification.md`

- [x] 2.10 관계 48개와 누적 753개를 검산한다.
- [x] 대상 역할 2,141개의 카테고리 공란이 없는지 검사한다.
- [x] Drive에 신규 파일 2개와 운영 문서 갱신본을 반영한다.
- [x] 파일명·폴더·내용을 Drive에서 다시 읽어 검증한다.



### Task 5: 세계별 확장 카테고리 전수 매핑

**Files:**
- Create: `범용 관계 유형/룩스테라 용종 관계 대상 확장 매핑.md`
- Create: `범용 관계 유형/엘드로스 클래스 관계 대상 확장 매핑.md`

- [x] 용종을 생물 개체·인물 호환 역할 기준으로 2,141개 역할 전수 판정한다.
- [x] 클래스를 인물 보유 요소·아이템 사용 자격·클래스 계보 기준으로 2,141개 역할 전수 판정한다.
- [x] 용종과 클래스 확장을 각각 별도 정본으로 작성한다.

### Task 6: 범용·세계별 적용 구조 확정

**Files:**
- Create: `범용 관계 유형/범용·세계별 관계 대상 카테고리 매핑 적용 규칙.md`

- [x] 범용과 세계별 확장 매핑의 적용 순서를 정의한다.
- [x] `COMMON`·`SERIES` 범위의 역할-카테고리 DB 연결 구조를 정의한다.
- [x] UI 노출과 서버 저장 검증의 동일 허용 집합 규칙을 정의한다.

### Task 7: 확장 매핑 동기화 및 검증

**Files:**
- Create: `reports/2026-08-12-database-migration-relations-series-category-extension-verification.md`

- [x] 정비·추적·인계·현황·레지스트리를 갱신한다.
- [x] 신규 확장 정본 3개를 Drive에 반영한다.
- [x] Drive 재조회로 수량·파일명·부모 폴더를 검증한다.
