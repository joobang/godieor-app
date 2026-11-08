# 다음 작업 순서 · 세 저장소 기준

공통 작업 순서의 원본은 [docs/system/plan.md](system/plan.md)다.
[iOS 담당 작업](repository-plan.md), [정책 결정 목록](system/policies.md)을 함께 읽는다.

1. 사용자 정책 답변을 기록하고 미정 항목을 유지한다.
2. backend API/이벤트 계약과 독립 acceptance 변경안을 검토한다.
3. 두 SHA·계약·DB 조합을 기록하는 evidence v2와 snapshot/실행 경계를 만든다.
4. backend의 임시 DB·fixture API와 iOS 소비를 연결해 한 가지 통합 흐름을 검사한다.
5. 네 분야의 실제 제공처를 순차 연결하고 부분 지원·지연·누락을 확인한다.
6. 검증된 버전 조합으로 원격 운영·iOS 배포를 준비한다.

우선 목표는 로컬 PostgreSQL·Prisma·NestJS API와 Simulator/본인 iPhone 연결이다.
최종 형태는 iPhone + 클라우드 API/DB, Mac verifier로 확정했으며 현재는 1단계 준비 문서까지다. backend 실제 코드, evidence v2, 자동 runner, 실제 권한 격리,
실제 연동과 원격 배포는 아직 구현하지 않았다.
기술 결정은 각 저장소 ADR, 통합 학습 카탈로그는 verifier/docs/learning을 원본으로 유지한다.
