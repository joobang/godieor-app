# GODIEOR · 고디어

‘곧이어’ 만날 영화·OTT 드라마·게임·EPL 일정을 모으는 iOS 앱.

현재 단계는 **초기 환경 구성**이다. SwiftUI 시작 화면만 있으며 실제 일정 API는 연결하지 않았다.
검증 시스템은 별도 저장소 [godieor-verifier](https://github.com/joobang/godieor-verifier)에서 관리한다.

## 로컬 시작

1. Xcode에서 `ios/GODIEOR.xcodeproj`를 연다.
2. GODIEOR scheme과 설치된 iPhone Simulator를 선택해 실행한다.
3. 서명 없는 빌드 확인: `./scripts/build-ios.sh`.

실기기는 Xcode에서 본인 Personal Team을 선택한다. 저장소에 팀 ID나 인증서를 기록하지 않는다.
iOS 17 이상, SwiftUI, 외부 패키지 없는 시작점이다. iOS 최소 버전과 저장 방식은 기술 제안이다.

## 먼저 읽을 문서

- [확정된 제품 범위와 미정 사항](docs/product.md)
- [개발·서버·DB 비용과 기술 제안](docs/decisions/001-foundation.md)
- [데이터 제공처 조사와 공개일 정확성](docs/data-sources.md)
- [AI 구현 → 독립 검증 → 사람 결정](docs/ai/workflow.md)
- [다음 작업 순서](docs/roadmap.md)
- [학습·문제 해결·면접/블로그 기록](docs/learning/README.md)

운영 계정·DB 생성·배포는 아직 하지 않았다. 검증 기준은 초안이며 제품 PASS 판정은 없다.
