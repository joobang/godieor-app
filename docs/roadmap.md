# 다음 작업 순서 · 세 저장소 기준

공통 작업 순서의 원본은 [docs/system/plan.md](system/plan.md)다.
아래는 전체 계획이며 현재 완료/진행 상태·당장 이어받을 작업은 [status.md](system/status.md)에서 확인한다.
[iOS 담당 작업](repository-plan.md), [정책 결정 목록](system/policies.md)을 함께 읽는다.

1. 사용자 정책 답변을 기록하고 미정 항목을 유지한다.
2. backend API/이벤트 계약과 독립 acceptance 변경안을 검토한다.
3. 두 SHA·계약·DB 조합을 기록하는 evidence v2와 snapshot/실행 경계를 만든다.
4. backend의 임시 DB·fixture API와 iOS 소비를 연결해 한 가지 통합 흐름을 검사한다.
5. 네 분야의 실제 제공처를 순차 연결하고 부분 지원·지연·누락을 확인한다.
6. 검증된 버전 조합으로 원격 운영·iOS 배포를 준비한다.

우선 목표는 로컬 PostgreSQL·Prisma·NestJS API와 Simulator/본인 iPhone 연결이다.
최종 형태는 iPhone + 클라우드 API/DB, Mac verifier로 확정했다. backend 로컬 공개 API·DB·가상 파이프라인은 구성했다.
iOS 공개 조회 연결은 구현했고 로컬 API 연동을 작성자가 확인했다. 독립 통합 검증, evidence v2, 자동 runner, 실제 권한 격리, 전체 분야 실데이터 제공처 연동과 원격 배포는 아직 완료하지 않았다.
기술 결정은 각 저장소 ADR, 통합 학습 카탈로그는 verifier/docs/learning을 원본으로 유지한다.


## 현재 권장 다음 작업 · DATA-53 OTT 대조 우선

사용자 최신 확정으로 StreamPick 신작·시즌 첫 공개 대조가 최우선이다. DATA-53에서 TMDB 독립 월별/시즌 발견과 공식 교차검증을 연결했다. 최신 참조52행의 후보발견49/52·공식재확인39행·제품일치26/52/DB67행이다. 다음은 공식 파서 미지원·조회실패 보완과 검증된 전체 배치 연결이다. 회차 제외와 미달 exit2를 유지하며, 미확인 일정 표시 도입은 선택하지 않았다.

이후 달력→목록→상세·설정 복원과 실제 Google·Keychain·기기간 서버 왕복/독립 검증을 진행한다. 개별 작품 적재를 작업 단위로 반복하지 않고 공통 원인별 배치로 처리한다.
