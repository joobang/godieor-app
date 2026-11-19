# UI-04 · 디스커버리 달력·카드·상세 화면 마무리

- 요구사항 PROD-001~004, GD-001~004. 상태: 자체 구현·빌드 완료, 독립 실기기 검증 대기.
- 기준 app origin/main `323f6f0`, 분리 작업 `codex/ui-polish-complete-20261119` / `/private/tmp/godieor-ui-polish`.
- 변경 범위 SwiftUI ContentView 한 파일. 기존 사용자 체크아웃의 `project.pbxproj` 및 디자인 HTML은 보존.
- 실패 사례 필터 초기화, 빈 날짜, 이전 월/날짜 재조회, 목록 미리보기 지연·실패, 이미지 부재, 접근성 선택 상태, 시뮬레이터 연결 실패.

## 구현·자체 검사

- 기존 UI-03의 날짜별 미리보기·revision/필터/날짜 기반 목록 캐시를 통합했다. 기본 노출 분야에 게임을 추가했다.
- 제공처 필터 초기화 및 선택 상태 접근성, 달력 날짜별 개수(최대 `99+`)·선택 상태, 날짜 미선택 안내, 초기 달력 로딩, 목록 갱신 안내, 빈 날짜 메시지, 카드 타이포그래피·선택/찜 접근성, 상세 작품 소개·포스터 레이아웃을 개선했다.
- `git diff --check` 종료 0.
- `sh scripts/check-account-flow.sh` 15/15 성공. 테스트는 합성 계정/전송 회귀만 확인한다.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath /private/tmp/godieor-ui-polish-build build` 종료 0, `BUILD SUCCEEDED`.
- CoreSimulatorService `Code=61` 및 runtime image service 응답 실패로 시뮬레이터 실제 부팅·화면 확인은 미실행.

## 독립 검증·인계

- app base `323f6f0`; head는 Git 기록 확인. backend·verifier 코드 미변경.
- API 계약·migration digest 변경 없음. 별도 검증 runner 및 외부 승인 미실행. verifier의 승인·판정 수정 없음.
- ADR 해당 없음(기존 SwiftUI 레이아웃·API 계약 재사용). LEARN 해당 없음(신규 아키텍처 선택·기술 원리 변경 없음).
- 다음 확인 iOS Simulator service가 정상인 Xcode에서 프로젝트 열어 화면 상호작용과 실제 API 이미지 표시 확인.
