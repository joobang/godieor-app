# UI-03 · 날짜별 일정 체감 속도 개선 (2026-11-19)

- 요구사항 PROD-002/005, 기존 verifier acceptance 변경 없음.
- 기준 app `323f6f0` (origin/main). 작업 브랜치 `codex/day-cache-game-20261119`, worktree `/private/tmp/godieor-day-cache-game`.
- 범위 iOS 날짜 선택 즉시 미리보기 표시, 동일 필터·카탈로그 버전의 날짜 결과 메모리 캐시, 신규 설치 및 로그아웃 기본 게임 노출.
- 예상 실패 이전 날짜의 목록 혼입, 변경된 카탈로그 결과 재사용, 기존 사용자가 저장한 필터 덮어쓰기, 네트워크 실패에 빈 목록 오인.
- 날짜 버튼에서는 해당 날짜의 달력 미리보기만 먼저 표시하며 서버 전체 응답이 오면 교체한다. 캐시는 날짜·필터·카탈로그 리비전으로 분리한다. 기존 개인/계정 저장 필터는 보존한다.
- 운영 서버 `https://godieor-backend.onrender.com/v1` 실측 (2026-11-19): options 2.78초, 게임 월간 2.2~2.55초, 2026-11-19 게임 단일 날짜 2.53초. 게임 월간 합계 370건, 19일 게임 0건, 공급자 KR scope partial. GTA6 WORLD 로컬 적재 기록(`backend/docs/tasks/DATA-07-global-game-releases.md`)은 있으나 운영 API 반환 없음. 운영 누락 원인(수집 대상·게시 상태)은 backend 후속 확인 필요.
- `git diff --check` 통과, `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath /private/tmp/godieor-day-cache-derived build` BUILD SUCCEEDED.
- 미확인: 실제 시뮬레이터 화면/초기 체감 측정, 운영 서버 데이터 수정, 별도 verifier 통합 PASS. 백엔드 DB/API 및 계약 변경 없음. 학습 기록 해당 없음 (클라이언트 조회 최적화 소규모 변경).
