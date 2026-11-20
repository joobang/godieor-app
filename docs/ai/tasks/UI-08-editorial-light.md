# UI-08 · 크림·피치 테마와 홈/상세 재구성

- PROD-001/002/004/006/010, GD-001/002/004/006/010. 앱 main 465f1f3, dev 8bb320d에서 분리. 사용자가 밝은 인기 앱을 참조한 전반적 테마 변경을 요청했다.
- Airbnb 탐색의 분명한 분야 탐색과 App Store Today의 이미지 중심 콘텐츠 위계를 참고했다. 고디어의 독자적인 색상·레이아웃을 사용한다.
- 검증 범위는 오늘/월 이동, 필터, 긴 제목·큰 글자·없거나 불러오지 못한 포스터, 게임 플랫폼 원본과 찜, 앱 기기 배포다.

- Airbnb 2025 여름 업데이트 https://news.airbnb.com/product-releases/airbnb-2025-summer-release 및 App Store Today https://apps.apple.com/us/story/id1706582433를 확인했다. 크림 배경, 피치 월 헤더, 민트 OTT·레몬 게임, 첫 일정 강조, 제목과 포스터를 나란히 둔 상세를 구현했다.
- 별도 정적 리뷰에서 큰 글자 카드 잘림 가능성을 발견했다. 접근성 글자 크기에서 카드 및 상세를 세로 배치하고 목록 제목 제한을 풀었다.
- `git diff --check`, Swift 이벤트 묶음 검사, `sh scripts/check-account-flow.sh` 15/15, unsigned Simulator 및 개발 서명 iPhone 빌드 성공. 시뮬레이터에서 홈·포스터 상세·큰 글자 상세·정보의 0.1.0 (6) 확인. iPhone 15 Pro 설치 버전 0.1.0 (6) 확인.
- 앱 및 서버의 기존 상세·세계 일정·기간 API를 소비한다. 전체 통합 승인 미실행, 새 ADR/LEARN 해당 없음(화면 구성만 변경). 담당 해제.
