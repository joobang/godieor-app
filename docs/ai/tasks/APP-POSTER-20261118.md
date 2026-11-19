# APP-POSTER · 날짜 카드 및 상세 포스터

- 요구: 달력 날짜 선택 후 카드 왼쪽의 포스터 썸네일, 상세 상단 포스터 표시. 날짜·콘텐츠 ID와 일정 정보 보존.
- 기준: app origin/dev 8190114, 작업 codex/poster-card-20261118; backend origin/dev 66cd353, 보강 분기 codex/ott-poster-enrichment-20261118. 개인 main checkout signing dirty 보존.
- 구현: 기존 `/contents/{id}` 응답 `posterUrl`을 조회해 카드 70×98 썸네일과 상세 이미지를 표시. HTTPS 주소만 허용, 누락/실패는 플레이스홀더. 상세의 로딩 상태는 완료 시 종료.
- 검사: iOS Simulator unsigned `xcodebuild` BUILD SUCCEEDED, `git diff --check` 통과. 실기기 설치·독립 검증·원격 서비스 API 확인은 후속.
- 자료: backend DATA-88, LEARN-0021 참고. 별도 학습 기록 변경 없음. API 계약 및 migration은 변경하지 않음.
