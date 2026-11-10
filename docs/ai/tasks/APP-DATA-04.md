# APP-DATA-04 · OTT 카테고리 표시

- 요구사항: PROD-005~009, backend DATA-04. 독립 승인 기준 변경 없음.
- 담당: codex-context-01, 종료 시 해제. 기준 app a4c08d5, backend c051d98, verifier 3111879, codex/app-auth-phone-ready.
- 범위: `ios/GODIEOR/PublicAPI.swift`에서 서버 응답의 nullable `ottCategory`를 읽고 영화·오리지널 시리즈·예능·기타 구분 표시.
- 실패 가정: 과거 응답에 분류 없음, 알 수 없는 분류, 신규 DB migration 미적용, 앱 기기 캐시.
- 이전 응답에는 기본 시리즈 라벨을 사용. `project.pbxproj` 개인 서명 변경은 제외.
- 확인: `git diff --check` 성공. unsigned iOS Simulator 대상 `xcodebuild ... CODE_SIGNING_ALLOWED=NO build -quiet` 종료 0, CoreSimulatorService 연결 오류 경고로 실제 simulator 실행 검사는 미실행.
- backend `npm test` 62/62 통과, backend 변경 코드 SHA 6da3358. 별도 iPhone 설치·실제 데이터 UI 확인·독립 검증 미실행.
- ADR·LEARN-ID 새 항목 없음. 기존 API 응답 표시 확장.
- 다음: 신규 backend migration/API와 iOS 빌드 설치 후 OTT 분류 실제 데이터 표시 확인. backend DATA-04 참고.
