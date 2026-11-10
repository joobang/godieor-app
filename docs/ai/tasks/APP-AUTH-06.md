# APP-AUTH-06 · 로그아웃 후 계정 필터 설정 잔류 방지

- requirement ID: APP-AUTH / BE-SAVED, acceptance draft/PENDING.
- 상태: 인계 대기, 담당 해제(codex-auth-filter-boundary-01).
- 기준 HEAD/branch/dirty: app d923ddbc8c4af1536982e0cb468f9382c1fa2f25, backend ff093742723158c2cdb0ad1ad2e7436ffc438434, verifier 0a6ff973f369d2d479d21c3c26c597a54a9addcd; codex/int-01-secret-check / 세 저장소 clean.
- 작업 브랜치/checkout: app codex/int-01-secret-check 단독 작업. 변경 범위 ContentView.swift, ADR, 이 카드, 공통 handoff/status.
- 사용자 동작: 로그아웃/세션 만료 시 이전 계정 필터를 새 방문자에게 노출하지 않고 기본 기기 필터로 되돌림. 앱 재시작 후 복구 실패해도 이전 계정 필터가 남지 않음.
- 완료 조건: 계정 소유 필터와 게스트 임시 필터 경계, iOS unsigned build, 문서/커밋.
- 예상 실패 사례: 로그아웃 후 계정 지역·시간대·OTT 필터가 AppStorage에 잔류, Keychain 복구 실패 상태에서 이전 계정 필터 표시, 다른 계정 로그인과 동일 설정 버전 충돌.
- 사용자 확정: 비로그인 공개 열람 및 계정 설정 서버 동기화. 구현 제안: 로컬 임시 필터의 계정 소유 표식으로 분리하고 로그아웃/재실행 시 초기화. 별도 guest 설정 보존은 향후 정책.
- ADR: docs/decisions/002-account-sync.md; LEARN-ID: 해당 없음 (기존 필터 로컬 상태 경계 보완).

## 구현·자체 검사

| 실제 명령 | 종료 코드 | 결과 |
|---|---|---|
| `git diff --check` | 0 | 공백 오류 없음 |
| `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth-filter-derived CODE_SIGNING_ALLOWED=NO build` | 0 | `BUILD SUCCEEDED`; CoreSimulator 서비스 및 AppIntents metadata 경고 |

- 계정 user ID를 필터 소유 표식으로 기록한다. 로그아웃·401·계정 변경 시 필터 기본값 복귀, 앱 시작에서 이전 계정 필터 삭제 후 원격 복구.
- 실제 Google 인증, 계정 전환 UI, iPhone HTTPS, 두 기기 동기화, 독립 리뷰·runner 미실행.

## 독립 검증 handoff

- app base d923ddbc8c4af1536982e0cb468f9382c1fa2f25 / head 최종 Git 기준.
- backend base/head ff093742723158c2cdb0ad1ad2e7436ffc438434, verifier 0a6ff973f369d2d479d21c3c26c597a54a9addcd.
- API 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- scope app-only, acceptance draft/PENDING. 실 Google/HTTPS/두기기 확인 및 독립 검증 별도.

## 다음 개발 세션 인계

- ADR-002 및 공통 상태/인계 revision CONTEXT-2026-11-10-17 반영, 담당 해제.
- 다음: 등록 Google OAuth Client ID/reversed scheme 및 iPhone HTTPS backend로 로그아웃·401·다중 기기 설정/찜 확인. verifier 승인 기준은 draft/PENDING.
- 최종 SHA는 Git 이력 참조. LEARN-ID 없음(기존 필터 기기 상태 경계 보완).
