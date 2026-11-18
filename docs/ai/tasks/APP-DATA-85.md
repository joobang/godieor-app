# APP-DATA-85 · 수집 워크플로우 수정 인계

- requirement PROD-009/010, 상태: backend 로컬 구현 완료·운영 검증 인계 대기, 담당 해제.
- 원본: backend `docs/tasks/DATA-85-collection-workflow-repair.md`. 앱 코드 변경 없음. app base1ed8962, backend base321fd83, verifier base99daa39. 각각 codex/collection-workflow-repair 별도worktree 사용.
- 최종 자체검사353/353, YAML·bash9단계 성공. 원격 Secret/push/Actions/실DB/독립제품검증 미실행. 실제 timeout 원인은 과거 상세로그 유실로 미확정.
- 변경범위·기대실패·실행명령·binding·남은작업은 원본 카드 참고. 공통status/handoff 동기화, 학습LEARN-0022. 계약/마이그레이션·verdict/승인기준 변경 없음.
