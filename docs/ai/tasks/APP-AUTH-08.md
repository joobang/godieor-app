# APP-AUTH-08 · Google iOS OAuth 공개 클라이언트 연결

- requirement ID: APP-AUTH/BE-AUTH, acceptance draft/PENDING.
- 상태: 인계 대기 / 담당 해제 (codex-google-client-01).
- 기준 HEAD: app 9f5ad6de31a972ba294a4493edec13b33558c096, backend 66b1ee23f8bc779ee25b3c0f1e6a618f1525fae3, verifier e75060f (동일 브랜치 codex/int-01-secret-check, clean).
- 범위: iOS Xcode Debug/Release Google OAuth Client ID 및 reversed callback scheme, backend 로컬 .env audience, 상태/인계 문서.
- 사용자 확정: iOS OAuth 공개 Client ID 제공. 번들 ID com.joobang.godieor 유지.
- 완료 조건: 공개 ID/URL scheme 설정 일치, 설정 확인, 서명 없는 iOS 빌드, 기록.
- 예상 실패: reversed scheme 불일치로 redirect 미수신, API URL placeholder 때문에 로그인 이후 세션 API 접속 실패, Google 테스트 사용자 누락.
- ADR: 기존 002-account-sync 유지. LEARN-ID 해당 없음 (OAuth 공개 설정 연결).

## 구현·자체 검사

- 앱 Debug/Release 클라이언트 ID 및 reversed callback scheme 설정. backend 기존 .env의 GOOGLE_CLIENT_ID를 GOOGLE_IOS_CLIENT_ID로 변경, 기존 비밀 설정 보존.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth08-derived CODE_SIGNING_ALLOWED=NO build`: exit 0, BUILD SUCCEEDED. CoreSimulator 서비스 및 로그 권한 경고 관찰.
- 생성된 Debug GODIEOR.app Info.plist: Client ID 일치, reversed scheme 일치, CFBundleURLSchemes 등록 모두 True. API URL은 placeholder.
- backend 로컬 .env: 동일 audience 일치 및 legacy 키 제거 확인 True. .env Git 제외, 내용 출력하지 않음.
- 실 Google OAuth 로그인·실기기·HTTPS API 왕복은 아직 미실행. 서버 주소 placeholder 남음.

## 독립 검증 handoff

- app base 위 SHA; head 커밋 후 Git 확인. backend base 위 SHA, verifier base e75060f.
- API 0.1.0-draft.2 / digest 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e; migration digest 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9; 변경 없음.
- acceptance draft/PENDING, 독립 verifier 미실행.

## 다음 개발 세션 인계

- iPhone 접근 가능한 HTTPS backend를 구성하고 GODIEOR_API_BASE_URL 갱신 후 실제 계정 로그인/복원/설정/찜 동기화 검증. Google 테스트 모드 시 테스트 사용자 추가 필요.
