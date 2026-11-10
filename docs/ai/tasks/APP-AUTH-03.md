# APP-AUTH-03 · 계정 전환 중 지연 응답 격리

- requirement ID: APP-AUTH / BE-SAVED, acceptance draft (승인하지 않음).
- 상태: 앱 경합 방어 구현·unsigned 빌드 성공, 독립 계측 검증 대기. 담당 해제, 세션 codex-auth-race-01.
- 기준 SHA: app d8358ecb47e07bfb3bda4beaa27ae18288515086, backend 04a0bee23840046f9bda7730f76b9eb87c49e428, verifier d0875e09cb5ac8fb12caaba0f37e2bcfa62153ed.
- 브랜치: codex/int-01-secret-check, 시작 시 세 저장소 clean. 동일 checkout 동시 수정 미확인.
- 변경 범위: iOS 계정 요청 경합 차단, 자체 검증 및 문서. backend/verifier 기준·판정 미변경.
- 목표: 로그아웃/다른 계정 로그인 이후 도착한 이전 요청이 사용자·설정·찜 상태에 반영되지 않도록 한다.
- 예상 실패: 지연된 refresh/찜 PUT/설정 PUT, 로그아웃 서버 DELETE 실패, 세션 401과 새 로그인 교차.

## 검증 및 인계

- 앱: `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth-race-derived CODE_SIGNING_ALLOWED=NO build` 최종 token 고정 및 오류 문구 수정 이후 다시 실행, exit 0, `BUILD SUCCEEDED`. CoreSimulator runtime 조회 경고는 있었으나 generic Simulator 컴파일은 성공. 로그 `/private/tmp/godieor-auth-race-build.log`.
- backend 기존 dist에 대해 `node --test tests/*.test.cjs` exit 1, 45개 중 44개 통과. 실패 1개는 architecture HTTP 테스트의 `listen EPERM: operation not permitted 127.0.0.1`; 이 sandbox가 loopback bind를 거부함. 이것을 코드 회귀로 판정하지 않음. 신규 auth-sync 4개는 통과.
- backend `npm test` 전체 재컴파일/Node24/DB 실통합은 실행하지 않음. backend 쓰기 제한, Node20 기본 환경 및 Docker socket 권한 거부 상태.
- iOS 경합을 실제 지연 HTTP로 재현하거나 실기기 Google OAuth/계정별 동기화·DB 격리·독립 검증은 미실행.
- 앱 `git diff --check` 공백 검사. 요청 시작 bearer token은 사용자 프로필·설정·찜 페이지 로딩과 쓰기 요청 전체에 고정, 로그아웃 서버 폐기에만 이전 token을 명시 전달.
- 계약: 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration: 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- 검증 범위: app-only + backend 기존 테스트 재확인. 독립 검증, 실 Google OAuth/2기기 DB 동기화 별도.
- 다음: 승인된 HTTPS Backend와 OAuth 등록값이 준비되면 요청 지연 중 로그아웃/다른 사용자 로그인, 401 동시 도착, 설정 409 및 찜 멱등을 실 통합 계측. 세 저장소 동일 문서 revision 유지.
- ADR: docs/decisions/002-account-sync.md. LEARN-ID: 별도 없음, iOS 경합 방지 변경을 카드/ADR에 기록.
- 공통 상태/인계: `CONTEXT-2026-11-10-12`, backend/verifier 동일 SHA-256 사본 동기화. 최종 app/backend/verifier HEAD는 각 Git 이력으로 확인.
