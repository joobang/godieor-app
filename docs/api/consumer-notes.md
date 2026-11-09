# iOS의 API 소비 계약 초안

- 작업 SYS-02 / PROD-001~008. 상태: 구현 담당의 소비자 관점 설계, 독립 리뷰/실제 decode 결과 아님.
- backend 계약 0.1.0-draft.1. 정확한 commit/digest는 [참조 파일](contract-reference.json).
- 소유 원본은 backend/contracts. iOS 저장소에서 OpenAPI 사본을 별도 수정하지 않는다.

## 캘린더에서 필요한 순서

1. 비로그인 /catalog/options로 지원 값/기본값을 읽는다. 로그인되어 있으면 /me/settings를 복원한다.
2. 기본 movie/ott 또는 저장한 활성 분야와 임시 필터의 교집합을 명시해 /calendar를 요청한다.
3. day.total과 previews를 표시한다. 총 건수를 previews.count로 계산하지 않는다. 모든 분야 OFF는 안내이며 빈 categories로 전체를 호출하지 않는다.
4. 날짜 선택 시 /events에 같은 필터와 catalogRevision, 해당 날짜 from/다음 날 to를 전송한다. 한 날짜 100건이 넘어도 nextCursor까지 받아 전체를 표시한다.
5. 409 CATALOG_CHANGED이면 현재 월/날짜 결과를 버리고 첫 요청부터 다시 받는다. 개인 달력은 favoritesVersion도 유지한다.
6. 미정은 schedule=undated로 별도 조회한다. date_only는 Foundation Date의 UTC 자정으로 저장하지 않고 연/월/일 값으로 다룬다.
7. 응답 Event.kind로 표시한다. OTT는 시즌 최초 공개만, EPL은 match 정보 사용. contentId=null인 EPL을 decode 실패로 처리하지 않는다.

## 찜/로그인/설정

찜 탭은 /me/favorites의 직접 관계를 모으고 작품/이벤트 상세를 조회한다. 페이지 version이 바뀌면 다시 읽는다.
달력의 찜만은 /me/calendar, 선택 날짜는 /me/events를 사용한다. 공개 응답에 찜 필드가 있다고 가정하지 않는다.
작품 상속/직접 일정 저장을 별도로 표시하고 해제 후에도 상속으로 남는 결과를 설명한다.
최초 찜/설정 저장은 Google 로그인 → /auth/google → token Keychain → /me/settings/찜 복원 순서다.
설정 PUT는 전체 값+expectedVersion. 409면 최신값을 읽고 덮어쓰기 대신 사용자 의도를 조정한다.
로그아웃/계정 변경은 개인 응답 캐시와 자격을 지운다. 공개 일정 캐시는 개인 데이터와 분리한다.
서비스 만료면 Google token 재확보/세션 교환을 시도하고 취소/실패 시에도 공개 캘린더는 유지한다.

## 화면과 추가 확인

가상 예시는 실제 일정이 아니다. fixture 표식을 유지한다. freshness 실패/미지원/미설정과 빈 일정을 구분한다.
서비스·기기 조건은 해당 분야에만 적용한다. 예: 넷플릭스를 골라도 극장 영화는 유지한다.
SDK 자동 생성/Swift DTO/실제 iOS 네트워크 연결은 아직 없다. 개발 단계에 계약 decode를 직접 확인해야 한다.
알림/팀 구독/시청 기록은 계약 소비 범위가 아니다.
