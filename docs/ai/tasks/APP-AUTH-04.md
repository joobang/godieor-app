# APP-AUTH-04 · 앱 복귀 시 계정 동기화와 찜 요청 중복 방지

- requirement ID: APP-AUTH / BE-SAVED, verifier acceptance draft/PENDING (승인하지 않음).
- 상태: 구현 및 작성자 빌드 완료, 독립 검증 대기. 담당 해제, 세션 codex-auth-resume-01.
- 기준 HEAD/branch/dirty: app f79315c0dc438f008cb0495d523001894711b7a9, backend 0e5c4e6f387c60ee45dff7e8212f4364752c9e9a, verifier eb3a7a009cfb75a6f2b6c1f763a8c35d774c132a; 모두 codex/int-01-secret-check clean.
- 작업 브랜치/checkout: app codex/int-01-secret-check, 단독 작업. 수정 범위 ios/GODIEOR/Account.swift, ContentView.swift, 이 카드 및 공통 인계 문서.
- 사용자 동작: 이미 로그인한 앱을 다시 활성화하면 원격 설정/찜을 갱신한다. 같은 찜을 빠르게 연속 누르더라도 서버에 중복 요청하지 않는다.
- 완료 조건: 앱 복귀 새로고침과 찜 단일 진행 상태 구현, iOS unsigned build와 diff 검사, 문서 인계.
- 예상 실패 사례: 백그라운드 재진입이 로그인/로그아웃과 겹침, 중복 찜 탭, 느린 PUT/DELETE 뒤 계정 전환, 서버 불통.
- 사용자 확정: 계정 설정/찜 동기화. 제안 구현: 활성화 시 갱신 및 mutation 진행 잠금.
- ADR: docs/decisions/002-account-sync.md 기존 정책에 준함. LEARN-ID: 해당 없음 (화면 전환과 단일 요청 경합 방어만 수행).

## 구현·자체 검사

- `git diff --check` exit 0.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth-resume-derived CODE_SIGNING_ALLOWED=NO build` exit 0, BUILD SUCCEEDED; 로그 `/private/tmp/godieor-auth-resume-build.log`.
- 앱 복귀 active 시 서버 동기화, 동일 대상 pending UUID guard, 쓰기와 찜 snapshot revision 경합 검사, 쓰기 성공 후 재조회 구현.
- 실 Google Client ID, HTTPS 접근 주소/실기기 및 두 단말 왕복, 의도적 느린 응답 검사는 미실행.
- 서버 API/migration, verifier acceptance/verdict 변경 없음.
- 다음: 등록 OAuth/HTTPS 환경에서 재로그인·앱 재활성화·찜 중복탭 및 설정 충돌을 실기기로 관찰하고 독립 리뷰 실행.
- 앱 base/head SHA: f79315c0dc438f008cb0495d523001894711b7a9 → 최종 commit HEAD로 확인, backend base/head 0e5c4e6f387c60ee45dff7e8212f4364752c9e9a 불변.

## 독립 검증 handoff

- API 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- 검증 범위 app-only; verifier SHA eb3a7a009cfb75a6f2b6c1f763a8c35d774c132a (dirty 없음); acceptance draft/PENDING.
- Google 실단말 OAuth, 실HTTPS/두기기 동기화, 지연 응답 재현, 독립 리뷰 미실행.
