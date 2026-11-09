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
iOS 연결, evidence v2, 자동 runner, 실제 권한 격리, 실제 제공처 연동과 원격 배포는 아직 구현하지 않았다.
기술 결정은 각 저장소 ADR, 통합 학습 카탈로그는 verifier/docs/learning을 원본으로 유지한다.


## 현재 권장 다음 작업 · DATA-02A 후속

정확한 연·월·일 OTT 일정만 반영하고 불완전 날짜는 후보로 보류하는 정책을 확정했다.
backend 후보 수집/검토/내보내기는 구현·자체 실행했다. 아직 제품 일정 DB로 publish하지 않았다.
다음은 안정 작품/시즌/이벤트 키 매핑과 검토 후보→기존 publish 어댑터 연결이다.
동일 작품의 복수 공지·공지 수정/연기 시 ID 보존과 한 공지의 여러 작품을 처리해야 한다.
고정 계약·입력 정책을 독립 검토하고 API/iOS 소비로 이어간다. 전수 coverage나 독립 통합 PASS는 아직 없다.
