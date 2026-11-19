# UI-06 · 홈과 일정 상세 리디자인

- 담당 해제. PROD-001/002/004/007/008/010, GD-001/002/004/007/008/010, acceptance 0.1.0-draft.
- 앱 base dev 1c24d20630892eada0fe8ef8a6c1e185059b0dbf, 작업 브랜치 codex/discovery-redesign-20261119. 사용자 작업 트리에서 분리.
- 홈, 월간 달력, 날짜별 목록과 일정 상세의 시각 위계 개선. 캘린더 날짜 상태, 필터 및 기존 정보 노출을 유지한다.
- 예상 실패 사례는 좁은 화면과 큰 글자, 긴 작품명, 6주 달력, 가상·미정·연기·취소·포스터 누락 표시, 필터 조합과 이전/다음 달 탐색이다.

## 구현 및 검사

- 홈을 짙은 남색과 분야별 색상으로 재구성했다. 달력과 오늘 일정을 한 화면 흐름에 배치하고 필터와 계정 버튼을 상단에 뒀다. 상세에는 비율을 유지한 포스터, 분야별 대체 이미지, 제목, 날짜·상태 영역, 정보와 출처가 있다.
- 독립 정적 리뷰 지적 3건 반영. 동일 revision인 달력 사이 이동을 날짜 조회 task의 달력 월로 구분하고, 오늘은 표시 시간대에서 구하며, 검토 OTT와 참고 OTT 출처를 별도 표시한다.
- `git diff --check` 및 `sh scripts/check-account-flow.sh` 15/15 성공. `xcodebuild ... -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`, `xcrun simctl install`·`launch` 성공.
- iPhone 17 Simulator에서 오늘 초기 선택, 다음 달 이동 후 오늘 복귀, 상단 필터, OTT 포스터·영화 포스터 없음, 긴 제목, 접근성 중간 글자 크기의 날짜·상태 배치 확인. 날짜 경계에서 다른 시간대로 전환하는 수동 재현은 미실행.
- `xcodebuild ... -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=<기존 팀> CURRENT_PROJECT_VERSION=3 build` 및 `codesign --verify --strict` 성공.

## 독립 검증 인계

- 앱 base `1c24d20630892eada0fe8ef8a6c1e185059b0dbf`, 고정 코드 head `2a119b51096ce3226de6edb8a64603f86c65b731`. Backend 고정 base/head `306889b922704555ed0311e6cf3fdc51a9020384`. 계약 0.1.0-draft.5 manifest `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`, migration `ec6966538bd599bf0dcee21ec0e0fb03a63b513ae01654d52b9e2badf5697fd7`.
- `scripts/runner --execute`의 독립 iOS 빌드 PASS. 기존 고정 backend의 비밀 검사 실패와 오프라인 Prisma 다운로드 오류로 전체 ERROR, DB/API 단계 SKIPPED. 원본 `/private/tmp/godieor-ui06-verifier/report.md`. acceptance 0.1.0-draft `c4906283810c8b378800b67930028685a41b6a051923ea9f9415346b2d657063`. 검증 기준과 승인 기록 변경 없음.
- ADR/LEARN 신규 해당 없음. 기존 데이터와 계정 흐름을 사용한 SwiftUI 화면 리디자인이다. 공통 revision SYNC-2026-11-19-UI-06.
