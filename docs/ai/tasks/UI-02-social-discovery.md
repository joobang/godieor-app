# UI-02 · A2 소셜 디스커버리 디자인 반영

- 요구사항 PROD-001~004 / GD-001~004. 사용자 2026-11-19 선택 시안 A2.
- 상태 진행. 구현 checkout app main dc56ca7, origin/main과 이력 차이 있음.
- 기존 사용자 변경 `ContentView.swift`, `PublicAPI.swift`, `project.pbxproj` 및 시안 HTML은 작업 시작 전부터 dirty였음. 변경된 iOS 기능/API 연결을 보존하고 시각 개선.
- 변경 범위 iOS 화면 디자인. 검증 승인, 백엔드 계약·DB·배포 설정은 이 작업 범위에 없음.
- 실패 사례 서비스 필터 미선택(전체), 분야 전부 해제, 캐시/조회실패, 로그인/찜 실패, 실제 이미지 불러오기 실패, 시뮬레이터 부팅 불가.

## 구현

- A2 검정·라임 컬러, 카테고리 스토리 버튼, OTT 필터 아이콘, 원형 날짜/일정 점, 일정 포스터 카드/기기 아이콘 반영.
- OTT/게임 플랫폼 표식은 각 서비스의 실제 공식 도메인 파비콘을 HTTPS 이미지 엔드포인트에서 로드. 네트워크 실패는 SF Symbol로 표시. 외부 엔드포인트의 운영/브랜드 정확도는 실기기 검증 필요.
- 기존 API 날짜·시각/지역/계정/찜/포스터 조회 경로 유지. 게임 기기 아이콘도 목록에 노출.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath /private/tmp/godieor-a2-build build` 종료 0, BUILD SUCCEEDED (2026-11-19).
- `git diff --check` 종료 0. CoreSimulatorService 연결 문제로 앱 실제 시뮬레이터 실행/시각 스냅샷은 미검증.

## 인계

- app base dc56ca7, head/원격 반영은 Git 로그로 확인. 현재 컨텍스트 기반 기존 사용자 파일 수정이 남아 있어 별도 변경 보존.
- backend 계약, 마이그레이션, verifier acceptance/verdict는 변경하지 않음. 독립 통합검증 미실행.
- ADR 해당 없음(시각 스타일), LEARN 해당 없음(기존 UI 로직 재사용).
- 실제 App Store/TestFlight 배포는 iOS 코드 변경만으로 발생하지 않으며 별도 서명·업로드 필요.

## 원격 main 통합 확인 (2026-11-19)

- 원격 `origin/main` ac7fa35를 기반으로 별도 worktree `/private/tmp/godieor-a2-main-integration`에서 UI 구현과 작업 카드를 통합. 기존 주 checkout의 개인 Xcode 프로젝트 dirty 파일은 그대로 보존.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath /private/tmp/godieor-a2-main-derived build` 결과 `BUILD SUCCEEDED`.
- 실기기 설치, 시뮬레이터 실제 실행, App Store/TestFlight 업로드는 검증하지 않음.
