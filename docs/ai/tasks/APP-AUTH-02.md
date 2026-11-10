# APP-AUTH-02 · 실기기 계정 API 연결 준비와 찜 동기화 재시도

- requirement ID: APP-AUTH / BE-SAVED. verifier acceptance.yaml draft; 승인 변경 없음.
- 상태: 앱 구현·자체 빌드 완료, 실 OAuth/실DB 검증 대기. 담당 해제.
- 세션: codex-auth-next-01.
- 기준: app 924d2da9e52236a038e3d2a657c4378cfe33e2aa, backend 04a0bee23840046f9bda7730f76b9eb87c49e428, verifier d0875e09cb5ac8fb12caaba0f37e2bcfa62153ed. 세 저장소 branch codex/int-01-secret-check, 시작 시 clean.
- 작업 checkout: app 기존 checkout 순차 작업, 동시 수정 증거 없음. 변경 범위는 iOS Account/Info.plist/Xcode 설정 및 인계문서.
- 사용자 동작: 기기용 HTTPS 계정 API 주소를 빌드 설정에서 주입하고, 찜 페이지 도중 다른 기기가 저장한 경우 전체 페이지 조회를 한 번 재시도한다.
- 예상 실패: 미설정 API URL, 비HTTPS/잘못된 URL, 토큰 만료, 찜 커서 버전 변경이 2번 연속 발생, 미등록 OAuth Client ID.
- 구현: 계정 API 기본 localhost 제거, HTTPS URL 검증, Xcode build setting `GODIEOR_API_BASE_URL` → Info.plist 주입, API 미설정 안내. 찜 목록 pagination 409 시 기존 부분 결과 폐기 후 처음부터 한 번 재시도.

## 자체 검사 및 한계

- 앱: `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth-next-derived CODE_SIGNING_ALLOWED=NO build` → exit 0, BUILD SUCCEEDED.
- backend: `npm test` → exit 1, 코드 검사 이전 `dist/src/app.module.js` unlink EPERM(해당 backend checkout의 쓰기권한 없음), 실행 Node20.20.2. 종전 51개 PASS 기록을 이번 검증으로 취급하지 않음.
- 실 Google OAuth/실단말 HTTPS/2기기 계정 동기화/임시DB 충돌 및 독립 verifier: 미실행. OAuth Client ID와 서버 주소/서버 접근 설정 필요.
- verifier의 acceptance/verdict/review 및 API 계약·마이그레이션 무변경. LEARN-ID 별도 없음(설정 UX 구현 상세를 본 카드에 기록).

## 검증 인계

- app base: 924d2da9e52236a038e3d2a657c4378cfe33e2aa, head: 최종 Git 커밋 확인.
- backend base/head: 04a0bee23840046f9bda7730f76b9eb87c49e428; verifier: d0875e09cb5ac8fb12caaba0f37e2bcfa62153ed.
- API: 0.1.0-draft.2, digest 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration digest 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- 다음: iOS Google OAuth ID/reversed scheme 및 HTTPS API를 설치 빌드에 주입하고 실제 로그인/세션폐기/2기기 409/찜 변경 확인. backend 테스트는 Node24와 쓰기 가능한 checkout에서 실행. 독립 리뷰 및 verifier 상태는 PENDING.
