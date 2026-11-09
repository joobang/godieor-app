# GODIEOR · 고디어

‘곧이어’ 만날 영화·OTT 드라마·게임·EPL 일정을 모으는 iOS 앱.

현재 단계는 **공개 일정 iOS 연결 초기 구현**이다. 월간 달력·날짜별 목록·상세를 백엔드 공개 API에 연결했으며, 실행 중인 로컬 서버가 필요하다. 시뮬레이터 실동작/독립 통합 검증은 아직 완료되지 않았다.
검증 시스템은 별도 저장소 [godieor-verifier](https://github.com/joobang/godieor-verifier)에서 관리한다.
일정 수집·정규화·DB·조회 API는 [godieor-backend](https://github.com/joobang/godieor-backend)가 담당한다.
backend는 로컬 PostgreSQL·Prisma·공개 API·가상 수집 및 검토된 OTT 수동 반영까지 구성했다. iOS 공개 조회 클라이언트 구현은 빌드했지만 실제 연결 실행 검증은 남았다.
세 저장소의 현재 상태·미해결 문제·다음 작업은 [현재 상태](docs/system/status.md)를 기준으로 확인한다.

## 로컬 시작

1. Xcode에서 `ios/GODIEOR.xcodeproj`를 연다.
2. GODIEOR scheme과 설치된 iPhone Simulator를 선택해 실행한다.
3. 서명 없는 빌드 확인: `./scripts/build-ios.sh`.

시뮬레이터의 기본 API는 `http://localhost:3000/v1`이다. 로컬 backend가 실행 중이어야 일정이 표시된다. Xcode Scheme 실행 환경 변수 `GODIEOR_API_BASE_URL`로 주소를 바꿀 수 있다. 실기기는 Mac의 localhost가 아닌 휴대폰에서 접근 가능한 API 주소와 HTTPS 구성이 필요하다. 초기 화면 분야 선택은 임시 상태이며 계정 동기화는 아직 구현하지 않았다.

실기기는 Xcode에서 본인 Personal Team을 선택한다. 저장소에 팀 ID나 인증서를 기록하지 않는다.
iOS 17 이상, SwiftUI, 외부 패키지 없는 시작점을 유지한다. 계정은 Google 연동 방향이며 개인 설정 저장/동기화 범위는 P03 상세 정책에 따라 정한다.
첫 목표는 로컬 API/DB와 앱의 연결이며, 최종 사용 형태는 본인 iPhone + 클라우드 API/DB다. verifier는 Mac에서 실행한다.

## 먼저 읽을 문서

- [새 계정·대화 시작점](docs/system/status.md) · [작업 인계·동시 개발·ChatGPT 웹 전달](docs/system/handoff.md)
- [세 저장소 공통 아키텍처](docs/system/architecture.md)
- [공통 작업 순서](docs/system/plan.md) · [사용자가 정할 정책](docs/system/policies.md)
- [iOS 저장소 작업 범위](docs/repository-plan.md)
- [확정된 제품 범위와 미정 사항](docs/product.md)
- [개발·서버·DB 비용과 기술 제안](docs/decisions/001-foundation.md)
- [데이터 제공처 조사와 공개일 정확성](docs/data-sources.md)
- [AI 구현 → 독립 검증 → 사람 결정](docs/ai/workflow.md)
- [다음 작업 순서](docs/roadmap.md)
- [통합 학습·면접/블로그 카탈로그](https://github.com/joobang/godieor-verifier/tree/dev/docs/learning) · 로컬 경로: godieor-verifier/docs/learning

원격 운영 계정·클라우드 DB 생성·배포는 아직 하지 않았다. 로컬 DB 실행 기록과 구분한다.
검증 기준은 초안이며 제품 PASS 판정은 없다.

웹 전달본 생성: `python3 scripts/export-context.py`. 생성 후 `--check`로 최신 여부를 확인하고
`work/context/chatgpt-context.md`를 업로드한다. 두 Codex 계정은 같은 저장소의 위 시작점부터 읽는다.
