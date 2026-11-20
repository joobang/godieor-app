# UI-10 · 포스터 피드 홈

- PROD-001/002/004/006/010, GD-001/002/004/006/010. app main 0de0961, 분리 작업 codex/poster-feed-20261120. 시안 '포스터 피드'를 사용자 확정.
- 첫 탭에 오늘 포함 최근 3일의 일정과 큰 가로 스크롤 포스터를 배치한다. 플랫폼, 찜, 시스템 공유를 카드에 둔다. 달력 탭에 기존 월간 날짜 탐색을 유지하고 찜 탭은 기존 계정 데이터를 사용한다.
- 회귀 확인: 월·연 경계, 필터와 시간대 전환, 요청 취소, 목록 페이지 revision, PC 미표시와 콘솔 통합 카드, 포스터 없는 일정, 로그인 및 찜, 접근성·긴 제목·좁은 화면.
- ADR/LEARN 신규 해당 없음. 기존 공개 API/계정 모델과 안정 ID 재사용.

## 구현·자체 검사

- 시안과 같은 가로 포스터와 게임·OTT 플랫폼, 찜, 시스템 공유, 날짜별 달력 이동 링크를 홈에 구현했다.
- 별도 맥락 리뷰에서 지적한 첫 찜 동기화 전 저장 동작, 사용자 전환 시 찜 상세, 찜 해제 경로, 자정 경계 및 달력 재진입, OTT 아이콘 실패 대체 표시를 반영했다.
- 계약 `0.1.0-draft.5` / `04cfea7456d83ca141ba64c6d6568365b00cbdf2d5e95eacd8c4dad7249a0f2e`, migration 집합 `feeb684462340075302b9a05ff3102740f6fe7d87c667ea8c455752c1433ba1b`. backend base/head `e807a5807ada8c2c9e5f67c85d7c18b7be184bff` 동일.
- 기준 draft digest `c4906283810c8b378800b67930028685a41b6a051923ea9f9415346b2d657063`. 기준 및 승인 상태 변경 없음.
- `sh scripts/check-account-flow.sh` 16/16 (첫 찜 스냅샷 전 쓰기 금지 추가), `swiftc -swift-version 6 ... PosterFeedChecks.swift` 월·연 경계, 페이지 및 revision, 기존 `ReleaseCardChecks.swift` 통과.
- unsigned iPhone 17 Simulator BUILD SUCCEEDED. 운영 API로 Geo Book 포스터·PlayStation/Xbox, 시스템 공유 시트, 작품 상세, 홈에서 11/19 날짜 선택 및 일정 12개 확인.
