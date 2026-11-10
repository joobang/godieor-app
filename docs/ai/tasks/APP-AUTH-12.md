# APP-AUTH-12 · 계정 동기화 상태 표시

- requirement ID: GD-003/GD-010 (verifier 기준 draft/PENDING; 승인 아님)
- 상태: 완료 (작성자 구현 및 빌드; 독립 검증 대기)
- 담당: codex-sync-status-01
- 기준 app: 19267a9610f2018e9eebf6ec973712673eefdf15, codex/app-auth-phone-ready, `ios/GODIEOR.xcodeproj/project.pbxproj` 기존 사용자 미커밋 변경 보존
- 기준 backend: 2c914478b83af79f428a196774820a79975d4d9; verifier: a699e4a91dd855f04142119958cae5ccf582cba9
- 작업 브랜치: 현재 app 브랜치 순차 작업, 별도 동시 수정 없음
- 범위: `ios/GODIEOR/Account.swift`, `ios/GODIEOR/ContentView.swift`, 카드·상태·인계 문서
- 완료 조건: 계정 원격 조회 진행/최종 성공 여부 표시, 로그아웃·계정전환에서 초기화, 필터의 로컬 변경과 서버 저장 구분, iOS unsigned build
- 예상 실패 사례: 이전 계정의 완료 시간이 다음 사용자에 남음; 오래된 refresh가 완료 표시; 실패를 성공으로 표시; 로컬 필터 변경을 서버 저장으로 오해
- 사용자 확인: iPhone 실제 Google 로그인 성공 보고. 세션 복원/서버 설정·찜 다른 기기 왕복은 아직 검증되지 않음.
- API 계약·마이그레이션·verifier 승인 기준 변경 없음.

## 구현·자체 검사

- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-auth12-derived CODE_SIGNING_ALLOWED=NO build`: exit 0, `BUILD SUCCEEDED`.
- 실기기 신규 UI/계정 설정·찜 기기간 왕복/재실행 세션 검사는 미실행. 사용자 Google 로그인 성공 보고만 있음.
- 예상 동시성 문제 방어: 세션 generation/token 및 최신 refresh revision이 일치할 때만 성공 시각 반영. 설정/찜 쓰기 경합으로 스냅샷이 미반영이면 전체 완료 시각은 갱신하지 않음.

## 독립 검증 handoff

- app base: 19267a9610f2018e9eebf6ec973712673eefdf15, head: 작업 종료 후 Git 참조
- backend base/head: 2c914478b83af79f428a196774820a79975d4d9
- manifest digest: 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e
- migration digest: 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9
- verifier: a699e4a91dd855f04142119958cae5ccf582cba9, clean, acceptance draft/PENDING
- 범위: app-only, 독립 검증 미실행.

## 다음 개발 세션 인계

- APP-AUTH-12 구현 종료, 담당 해제. 기존 사용자 미커밋 `ios/GODIEOR.xcodeproj/project.pbxproj` 수정은 별도로 보존.
- 다음: 실 iPhone에 새 빌드 설치 후 계정 동기화 UI/세션 복원/서버 찜·필터 설정 검증.

## 결정·학습

- ADR: 해당 없음 (기존 계정 API 및 정책 유지)
- LEARN-ID: 해당 없음 (사용자 표시와 원격 완료 상태 기록만 추가)
