# APP-AUTH-07 · 쓰기 API 세션 만료 처리

- requirement ID: APP-AUTH / BE-SAVED, acceptance draft/PENDING.
- 상태: 인계 대기, 담당 해제(codex-auth-write-401-01).
- 기준 HEAD: app a36e72e553b312977ead8e7d0aee47e99d3d2fb0, backend 2e3572aa46a821c17d805aa4e61e4843336b7e71, verifier 749e58b6a6fa32c4bf04ca94cd1eeb7aa6a808c0. 세 저장소 branch `codex/int-01-secret-check`, dirty 없음.
- 작업 checkout: app 단독 작업, `ios/GODIEOR/Account.swift`, 카드, ADR, 공통 상태/인계 문서. 동시 수정 없음.
- 사용자 동작: 설정 저장/찜 쓰기 API에서 만료된 세션(401)을 받으면 계정 및 필터 소유 상태를 즉시 로그아웃 상태로 전환하고 재로그인 안내.
- 완료 조건: 모든 인증 쓰기 401 경계 처리, unsigned iOS 빌드, 문서/커밋.
- 예상 실패: 설정 PUT 401 뒤 refresh 실패로 로그인 상태 잔류, 찜 PUT/DELETE 401 뒤 이전 찜이 계속 노출, 오래된 응답이 새 세션 상태를 지움.
- 사용자 확정: Google 로그인 및 설정/찜 서버 동기화 방향. 구현 판단: 401은 해당 요청의 세션을 즉시 폐기, 409 및 통신 오류는 기존 로그인 유지.
- ADR: 002-account-sync. LEARN-ID 없음(기존 세션 만료 경계 보완).

## 구현·자체 검사

| 실제 명령 | 종료 코드 | 결과 |
|---|---|---|
| `git diff --check` | 0 | 공백 오류 없음 |
| `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth07-derived CODE_SIGNING_ALLOWED=NO build` | 0 | `BUILD SUCCEEDED`; CoreSimulator 서비스 및 AppIntents metadata 경고 |

- `AccountState.saveSettings` 401은 로그인 정보 즉시 삭제 후 재로그인 안내. 나머지 오류는 기존 refresh/에러 경로 유지.
- `AccountState.toggleFavorite` 401 역시 현재 세션일 때만 로그인/찜 정보 삭제. 이전 세션의 느린 응답이 새 세션을 지우지 않도록 generation/token 검사 유지.
- 실제 Google/HTTPS 401, 실기기/계정 전환 UI, 멀티기기, 독립 verifier는 미실행.

## 독립 검증 handoff

- app base 위 SHA / head 커밋 후 Git 확인; backend 2e3572aa46a821c17d805aa4e61e4843336b7e71, verifier 749e58b6a6fa32c4bf04ca94cd1eeb7aa6a808c0.
- 계약 API 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e; migration 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- 범위 app-only; acceptance draft/PENDING, 실제 Google/HTTPS/기기·독립 검증 미실행.

## 다음 개발 세션 인계

- ADR-002·status/handoff revision CONTEXT-2026-11-10-18 반영, 담당 해제. 변경한 app 파일은 Account.swift.
- 등록된 Google Client ID/reversed scheme과 iPhone에서 접근 가능한 HTTPS backend를 준비하여 실제 401·계정 전환·설정/찜 왕복을 확인. 독립 검증 승인 기준은 유지.
- 최종 SHA는 Git 이력에서 확인. 관련 LEARN-ID 없음(기존 세션 경계의 예외 처리 보완).
