# APP-AUTH-05 · 계정 재조회 순서 및 찜 반영 경합 수정

- requirement ID: APP-AUTH / BE-SAVED; verifier acceptance draft/PENDING.
- 상태: 작성자 구현 및 빌드 완료·독립 검증 대기, 담당 해제 codex-auth-order-01.
- base SHA: app 1cf38b10aa26d73819283973d59062375356a324 / backend d3e1d584f9c6946b112652a2d3055204d57651de / verifier d88eab699ac40d1df6f7f3da57fa3475423132fd. 모두 codex/int-01-secret-check clean.
- 범위: app Account.swift 경합 및 관련 작업 문서. API 계약/DB/verifier acceptance 변경 없음. checkout 독점.
- 사용자 동작: 최신 refresh만 설정/찜에 반영, 찜 저장 직후 서버와 실제 재동기화.
- 예상 실패: 늦게 끝난 이전 refresh의 오래된 설정 덮어쓰기, 찜 저장 완료 전에 시작한 refresh가 새 찜을 덮어쓰기, 서버 실패/계정 전환 중 쓰기 응답 도착.
- 완료 조건: 경합 순서 수정, unsigned iOS build, diff check, 공통 문서/작업 카드/커밋.
- 기술 제안: refresh 요청 순번으로 마지막 시작 요청만 반영, 찜 쓰기 pending 해제 후 서버 재조회. 계정 전환 generation/token 검사는 유지.
- ADR: docs/decisions/002-account-sync.md. LEARN-ID: 해당 없음 (기존 동기화 구현 경합 수정).

## 실행·검사

- `git diff --check`: exit 0.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth-order-derived CODE_SIGNING_ALLOWED=NO build`: exit 0, BUILD SUCCEEDED. 로그 `/private/tmp/godieor-auth-order-build.log`; CoreSimulator runtime discovery / simdiskimaged 경고가 있었지만 unsigned 컴파일 성공.
- 최신 refreshRevision 검사로 오래된 refresh 응답/오류 메시지 폐기. settingsMutationRevision으로 PUT 설정 완료 후 오래된 원격 스냅샷 반영 방어. 찜 pending 종료 후 서버 재조회 예약.
- 실제 iPhone OAuth/HTTPS 네트워크 지연 교차/두 기기 복원 및 외부 독립 runner는 수행하지 않았다. 코드 경합 통과를 실기기 검증으로 주장하지 않는다.
- 문서 원본 및 backend/verifier 공통 사본 CONTEXT-2026-11-10-16 동기화, 정책 SYNC-2026-11-10-02 유지. 커밋 전 app 변경분만 있으며 backend/verifier 구현/기준 수정 없음.
- 다음: OAuth Client 등록·HTTPS iPhone 환경 확보 후 연속 앱 복귀/동시 찜 탭/설정 CAS 409를 실네트워크로 재현, 독립 검토. 최종 SHA는 Git HEAD로 확인.

## 독립 handoff

- app base 1cf38b10aa26d73819283973d59062375356a324; head는 커밋 후 Git 확인.
- backend base/head d3e1d584f9c6946b112652a2d3055204d57651de; verifier d88eab699ac40d1df6f7f3da57fa3475423132fd (둘 다 clean 시작).
- API 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- scope app-only; acceptance draft/PENDING, verifier verdict/approval 변경하지 않음.
- 실 Google OAuth·기기간 HTTPS 동기화·독립 외부 검증은 별도.
