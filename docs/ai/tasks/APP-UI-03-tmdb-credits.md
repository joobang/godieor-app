# APP-UI-03 · TMDB 작품·포스터 출처 표시

- PROD-004/009, GD-004/009. 앱 dev f443d9f 기반 분리 작업. 백엔드 DATA-89의 극장 포스터 보강에 동반하는 이미지 제공처 고지다.
- 계정 시트의 정보 및 출처에서 TMDB 공식 링크·승인 로고·지정 문구를 표시한다. 공식 원본 로고 SHA-256 8e7b30f73a4020692ccca9c88bafe5dcb6f8a62a4c6bc55cd9ba82bb2cd95f6c. 출처 규정 https://developer.themoviedb.org/docs/faq.
- 예상 실패 사례는 앱 번들 에셋 누락·로그아웃 상태에서 출처 접근 불가다. iPhone 17 Simulator unsigned build, 앱 설치 및 계정 시트 헤더·로고·링크·문구 확인 성공. 최초 빌드에서 미지원 SwiftUI modifier를 제거하고 재검사했다.
- 제품 백엔드 계약 및 migration 소비 방식 유지. 독립 승인 미실행, ADR/LEARN 신규 해당 없음. 출처 표시 구현 및 자체 검사 완료, 담당 해제.
