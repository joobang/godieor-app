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


## 현재 권장 다음 작업 · APP-AUTH-13 후속

계정 코드의 지연 응답·계정전환 결함4개를 묶어 수정하고 합성15개 시나리오 및 고정 소스 unsigned iOS 빌드를 확인했다. 다음은 달력→목록→상세·설정 복원의 빈 결과/실패/지연/마지막 성공 상태를 제품 흐름 단위로 검사한다. 실제 Google·Keychain·기기간 서버 왕복 및 독립 검증은 아직 남았다.
데이터는 공통 plan/ott-batch-backlog의 원인 유형별 배치로 관리하며 개별 작품 적재를 다음 작업으로 반복하지 않는다.
