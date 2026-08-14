# SUPERPOWERS SETTINGS REGISTRY

## 목적

이 문서는 `프로젝트 위그드라실/docs/superpowers`에서 관리하는 설정 폴더 전용 Superpowers 작업의 공식 상태 정본이다.

설계·실행 계획·검증 보고서는 당시의 작업 내용과 진행 기록을 보존한다. 설정 정본의 현재 사실과 적용 상태는 관련 정본 문서에서 확인하며, 프로젝트 공통 설정 정비의 상태는 `프로젝트 위그드라실/설정 정비/설정 정비 현황.md`가 관리한다.

## 상태 값

`설계 중` / `설계 완료` / `실행 계획 완료` / `진행 중` / `검증 중` / `완료` / `중단` / `폐기` / `상태 확인 필요`

## 현재 작업

### 2026-08-14-project-world-category-initial-seed

- 작업명: 프로젝트 위그드라실 초기 프로젝트·월드·카테고리 시드
- 상태: 완료
- 작업 유형: DB 이관 초기 데이터 SQL 작성
- 시작일: 2026-08-14
- 설계: `specs/2026-08-14-relation-v1-freeze-design.md`
- 실행 계획: `plans/2026-08-14-project-world-category-initial-seed.md`
- 기준 데이터: `../../설정 정비/데이터베이스 이관 사전 작업/검토 및 추적/카테고리 이관 데이터 v1 최종 검토 및 동결.md`
- 목표: 프로젝트 위그드라실과 룩스테라·엘드로스 월드, 각 월드의 최대 2단계 초기 카테고리 시드를 작성하고 검증한다.
- 산출물: `../../설정 정비/데이터베이스 이관 사전 작업/초기 프로젝트·월드·카테고리 시드.postgresql.sql`, `../../설정 정비/데이터베이스 이관 사전 작업/초기 프로젝트·월드·카테고리 시드.sqlite.sql`
- 검증: 공통 97개·세계별 확장 20개·총 214개 시드 행, 룩스테라 114개, 엘드로스 100개, 최대 레벨 2를 정적 검증했다.
- 실행 전제: 각 스크립트의 `tmp_seed_config` 삽입값 `0`을 활성 `ADMIN`의 실제 ID로 바꾼다. 로컬 PostgreSQL·SQLite 클라이언트와 DB 연결 정보가 없어 실제 실행은 수행하지 않았다.

### 2026-08-09-database-migration-relation-design

- 작업명: 프로젝트 위그드라실 데이터베이스 이관 사전 작업 — 범용 관계 유형 설계
- 상태: 완료
- 작업 유형: 프로젝트 공통 설정 문서 DB 이관 전 관계 유형 설계·검증
- 시작일: 2026-08-05
- 설정 정비 상태: `../../설정 정비/설정 정비 현황.md`
- 대표 정비 문서: `../../설정 정비/데이터베이스 이관 사전 작업 정비.md`
- 완료 범위: 2.1~2.15 관계 확정, COMMON 936개·대상 역할 2,813개, 2.14·2.15 이관·보류 전부 해소, COMMON·용종·클래스 매핑 동기화, 신규 관계 파트 종료.
- 현재 결과: 2.14 정보·기록·표현·의미 41개와 2.15 시간·연대·순서 9개를 전역 ID 887~936으로 확정했다.
- 검증: 전역 ID 1~936의 연속성·중복·누락, COMMON 936개·대상 역할 2,813개, 원천 매핑 해시를 교차 검증했다. 동명 관계 8쌍은 괄호형 독립 관계로, 동일 관계 안의 역할명 중복 8건은 서로 다른 역할명으로 확정했다.
- 동결 문서: `../../설정 정비/데이터베이스 이관 사전 작업/검토 및 추적/범용 관계 유형 v1 최종 검토 및 동결.md`
- 다음: 별도 DB 시드 작업에서 프로젝트·월드·카테고리 초기 적재 쿼리부터 작성한다.

## 상태 확인 필요 이력

| 작업 식별자 | 기록 |
| --- | --- |
| 2026-06-27-luxterra-frontmatter-rollout | `plans/2026-06-27-luxterra-frontmatter-rollout.md` |
| 2026-06-27-remove-notion-ids | `plans/2026-06-27-remove-notion-ids.md` |
| 2026-07-01-document-metadata-rollout | `specs/2026-07-01-document-metadata-standard-design.md`, `plans/2026-07-01-document-metadata-rollout.md` |
| 2026-07-13-luxterra-five-setting-prose-normalization | `specs/2026-07-13-luxterra-five-setting-prose-normalization-design.md` |
| 2026-07-16-rakshara-vertical-ecology | `specs/2026-07-16-rakshara-vertical-ecology-design.md`, `plans/2026-07-16-rakshara-vertical-ecology.md` |
| 2026-07-26-setting-type-folder-migration | `specs/2026-07-26-setting-type-folder-migration-design.md`, `plans/2026-07-26-setting-type-folder-migration.md` |
| 2026-08-01-continent-spatial-layout | `plans/2026-08-01-continent-spatial-layout.md` |
| 2026-08-02-data-warehouse-and-character-prompt | `specs/2026-08-02-character-creation-prompt-design.md`, `plans/2026-08-02-data-warehouse-and-character-prompt.md` |

## 완료 이력

### 2026-08-13-relations-2.14-2.15-integrated-finalization

- 작업명: 2.14 정보·기록·표현·의미 및 2.15 시간·연대·순서 통합 확정
- 상태: 완료
- 완료일: 2026-08-13
- 설계: `specs/2026-08-13-relations-2.14-2.15-final-scope-design.md`
- 실행 계획: `plans/2026-08-13-relations-2.14-2.15-integrated-finalization.md`
- 검증 보고서: `reports/2026-08-13-database-migration-relations-2.14-2.15-verification.md`
- 결과: 신규 50개, ID 887~936, 누적 COMMON 936개·대상 역할 2,813개.
- 다음: 전체 종료 감사와 관계 유형 v1 동결 후 DB 이관 구조 설계.

### 2026-08-13-relations-2.13-finalization

- 작업명: 2.13 개념·법칙·영향 관계 확정
- 상태: 완료
- 완료일: 2026-08-13
- 결과: 신규 COMMON 45개·역할 155개를 ID 842~886으로 확정하고 기존 ID 836 재사용과 후보 1개 통합 제외를 반영했다.

### 2026-08-13-relations-2.8-record-reconciliation

- 작업명: 2.8 지식·연구·발견 관계 기록 정합화
- 상태: 완료
- 완료일: 2026-08-13
- 결과: 최종 확정본 37개의 존재와 상태 기록을 정합화했다.
