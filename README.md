# GODIEOR · 고디어

‘곧이어’ 만날 영화·OTT 드라마·게임·EPL 일정을 모으는 iOS 앱.

현재 단계는 **초기 환경 구성**이다. SwiftUI 시작 화면만 있으며 실제 일정 API는 연결하지 않았다.
검증 시스템은 별도 저장소 [godieor-verifier](https://github.com/joobang/godieor-verifier)에서 관리한다.
일정 수집·정규화·DB·조회 API는 [godieor-backend](https://github.com/joobang/godieor-backend)가 담당한다.
backend는 현재 문서 구성 단계이며 실제 API가 구현된 상태는 아니다.

## 로컬 시작

1. Xcode에서 `ios/GODIEOR.xcodeproj`를 연다.
2. GODIEOR scheme과 설치된 iPhone Simulator를 선택해 실행한다.
3. 서명 없는 빌드 확인: `./scripts/build-ios.sh`.

실기기는 Xcode에서 본인 Personal Team을 선택한다. 저장소에 팀 ID나 인증서를 기록하지 않는다.
iOS 17 이상, SwiftUI, 외부 패키지 없는 시작점을 유지한다. 계정은 Google 연동 방향이며 개인 설정 저장/동기화 범위는 P03 상세 정책에 따라 정한다.
첫 목표는 로컬 API/DB와 앱의 연결이며, 최종 사용 형태는 본인 iPhone + 클라우드 API/DB다. verifier는 Mac에서 실행한다.

## 먼저 읽을 문서

- [세 저장소 공통 아키텍처](docs/system/architecture.md)
- [공통 작업 순서](docs/system/plan.md) · [사용자가 정할 정책](docs/system/policies.md)
- [iOS 저장소 작업 범위](docs/repository-plan.md)
- [확정된 제품 범위와 미정 사항](docs/product.md)
- [개발·서버·DB 비용과 기술 제안](docs/decisions/001-foundation.md)
- [데이터 제공처 조사와 공개일 정확성](docs/data-sources.md)
- [AI 구현 → 독립 검증 → 사람 결정](docs/ai/workflow.md)
- [다음 작업 순서](docs/roadmap.md)
- [통합 학습·면접/블로그 카탈로그](https://github.com/joobang/godieor-verifier/tree/dev/docs/learning) · 로컬 경로: godieor-verifier/docs/learning

운영 계정·DB 생성·배포는 아직 하지 않았다. 검증 기준은 초안이며 제품 PASS 판정은 없다.
