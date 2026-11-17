# DATA-84 · 임시 OTT fallback 적재 인계

- Requirement PROD-005/006/007/009 · GD-005/006/007/009, backend-only. 사용자 요청 21+1 후보 로컬 DB 게시.
- backend 원본 `docs/tasks/DATA-84-streampick-tmdb-provisional-fallback.md`, backend HEAD `30e34a6` (`codex/learning-explanations`). app HEAD는 변경 전 현재 SHA, 앱 코드 미변경.
- 별도 `ott_fallback` 원천 ID와 매니페스트별 검증 수준 보존. 기존 source 및 favorite 참조 삭제 없음. 향후 공식 확인 시 공개 event ID를 보존하는 승격/중복 조정 필요.
- 실제 검증: `node --env-file=.env scripts/publish-streampick-fallback.mjs --publish` 22건, 재실행 신규0, event 32695→32717. Node24 스크립트 구문·JSON 유효. `npm test` 342/343(최신 TMDB 스냅샷 기간 가정 1실패).
- 독립 검증 미실행, remote DB 미반영, API provenance 표시 미지원, 전체 데이터 적재 완료 아님. 관련 LEARN-0021.
