# APP-DATA-86 · 초기 수집 트랜잭션 수정 인계

- requirement PROD009/010, 원본 backend docs/tasks/DATA-86-control-transactions.md. 상태 로컬구현/검증완료·원격재실행인계, 담당해제.
- 앱코드불변. backend357/357·별도리뷰관련27/27, 고정digest임시DB의5초초과/rollback재현성공. 실제Supabase/Actions/독립제품검증성공과구분.
- 사용자수정·push명시요청, 각codex/collection-control-transactions분리작업. 공통status/handoff동기화, LEARN0022 본문보완. head는최종Git이력확인.
- push후Actions새Run workflow/main/backfill사용. Secret추가없음. 계약/migration/승인기준/verdict불변.
