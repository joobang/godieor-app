# APP-DEMO-01 · 간소화 UI와 실데이터 전용 데모 배포 준비

- Requirement: P03/P07, PROD-004~006 (verifier acceptance draft/PENDING, 승인 변경 없음)
- 상태: 인계 대기, 담당: codex-demo-01 (담당 해제)
- 시작 SHA: app a56172dfcfbc032310b2644a09d135b29745bf10, backend 587b9b910eb4d19c92f60bc8e84a92dea3c3b628, verifier fe66b08f1100cc7d1164d753352d7f1a8560e20b
- Branch: codex/app-auth-phone-ready. 시작 dirty: app `ios/GODIEOR.xcodeproj/project.pbxproj` (사용자 Xcode 변경, 수정·커밋 제외), backend/verifier clean.
- 범위: iOS 하트 1개(작품 존재 시 content, 없으면 event), 달력 수집 성공 시각/개별 진단 제거; backend `CATALOG_PROVIDER_ONLY` 필터(목록·달력·미정·freshness), Render Blueprint, Github CI, 데모 안내.
- 실패 사례: 두 찜 유형이 다른 의미를 가지므로 이미 저장된 직접 event 찜은 해당 작품 content 하트에 반영되지 않을 수 있음; 공식 일정이 적재되지 않은 DB에서 빈 달력; Render 무료 DB 30일 만료; iOS 네이티브 코드 자동 갱신 불가; DB migration/Google 인증 설정 누락.
- 사용자 확정: UI 단순화 → 실제 일정 → 현재 버전 클라우드 데모 → PR 머지 후 서버 자동 반영. 승인/외부 배포 자체는 별도 실행.
- LEARN-ID: 해당 없음(이번 작업은 UX 표시 및 배포 설정 변경, 독립 새 기술 해설 없음).

## 자체 검사 및 미완료

- iOS: `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-demo-derived CODE_SIGNING_ALLOWED=NO build` exit 0, `BUILD SUCCEEDED` (CoreSimulator 경고 포함).
- backend: `./node_modules/.bin/tsc --noEmit -p tsconfig.json; git diff --check` exit 0.
- backend: `npm test` exit 1, 기본 Node 20.20.2 및 기존 `dist/src/app.module.js` unlink EPERM으로 빌드 진입 전 실패. 새 테스트 결과로 확대 불가. Node24.11+ 및 허용된 dist 쓰기 환경에서 재실행 필요.
- 실제 배포된 Render URL/데이터 적재 및 실제 계정 동기화 검사는 수행하지 않음.
- 외부 실데이터 재검토·새 Render DB 적재, 계정 실기기 왕복, 외부 Render 생성/배포, PR 머지·push, verifier 독립 실행은 별도 남은 단계.

## 인계 메모

- API 계약 0.1.0-draft.2와 migration은 수정하지 않음. 변경된 API 스키마 없음.
- 사용자 iOS Signing 및 로컬 HTTPS 주소가 들어 있는 기존 미커밋 pbxproj는 그대로 보존.
- Backend Render Blueprint, GitHub CI의 실제 원격 작동 검사는 미실행. 외부 배포 전 실제 매핑·Git 원격·서비스 설정 필요.
