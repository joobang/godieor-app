# APP-DATA-06 · 모바일 게임 기기 필터

- Requirement PROD-002/005/009, 담당 codex-context-01 (완료 후 해제).
- app base 65d42c0, backend base 8551ba3, branch codex/app-auth-phone-ready.
- 사용자 요청 Android와 iOS도 게임 출시 및 기기 필터에서 선택 가능하도록 구현.
- `ContentView.swift`의 서버 제공 옵션 토글에 iOS/Android 및 플랫폼 이름을 사람이 읽기 쉬운 형태로 표시. 실제 설정 키는 기존 `ios`/`android`를 사용하므로 계정 동기화 경로 유지.
- 예상 오류는 서버의 구형 options 응답, migration 미반영, 실기기 캐시/계정 저장 전 불일치.
- 작성자 테스트 unsigned iOS Simulator 빌드 성공(마지막 상세 기기명 변경 포함). 로컬 DB ios/android 각 1건 확인. 실폰 재설치·배포·독립 UI 검증 미실행.
- 관련 backend 원본 카드 `docs/tasks/DATA-06-mobile-platforms.md`. 개인 pbxproj 서명 변경 보존.
- ADR/LEARN 해당 없음(기존 기기 필터 표시 확장).
