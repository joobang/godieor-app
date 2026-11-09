# APP-01C/D · 임시 필터 저장과 공개 일정 실패 상태

- 요구사항: PROD-003 / GD-003(초안), PROD-008 / GD-008(초안), PROD-010 / GD-010(초안).
- 상태: 앱 코드 구현·iOS Simulator 대상 빌드 완료. 시뮬레이터 UI, 실서버 통합 및 독립 검증 대기. 담당 해제.
- 세션: `codex-app-state-01`. 시작 app HEAD `40fe1e5ea76746315e2232c6e746ef897c5ceece` (`dev`, clean). backend `dev`, verifier `dev`, 시작 시 모두 clean.
- 수정 범위: `ios/GODIEOR/ContentView.swift`, 이 작업 카드.
- 검토할 실패 사례: 날짜/분야/월을 빠르게 바꿀 때 오래된 응답 덮어쓰기, HTTP 409 재조회, 월간 실패 시 이전 정상 조회 표시, 수집 실패 시 마지막 성공 시각, 재실행 후 분야 선택, 빈 분야 필터의 전체 조회.

## 구현

- 앱 시작 월은 현재 월이다. 분야 선택은 `@AppStorage`로 해당 기기에 **임시** 유지한다. 초기 기본값은 영화·OTT이고 전부 선택 해제 시 계약에 빈 `categories`를 보내 전체 조회한다.
- 월간 조회/날짜별 조회는 SwiftUI `.task(id:)`의 취소를 이용하고, 응답을 화면에 반영하기 직전에 선택 날짜·월/분야 키·취소 여부를 확인한다.
- 같은 월/분야의 마지막 성공 월간 결과는 앱 메모리에 보존한다. 다시 조회하다 실패하면 기존 달력과 최신성 경고를 보여준다. **앱 종료 후 복구되는 영속 캐시가 아니다.**
- `catalogRevision` 충돌 시 달력을 다시 조회하고 날짜 목록을 한 번 재시도한다. 수집 일부/가상 데이터 및 제공처 마지막 성공 시각을 화면에 표시한다.
- 로그인/Google 인증과 `/me/settings` 서버 동기화는 아직 미구현이다. 이 임시 저장을 사용자 계정 설정이라고 설명하지 않는다.

## 실제 실행과 남은 검증

- `./scripts/build-ios.sh` → `BUILD SUCCEEDED`. 첫 수정 도중 SwiftUI 타입 검사 시간 초과 컴파일 오류가 있어 뷰를 분리한 후 다시 빌드해 해결했다.
- 이전 세션에서 `xcrun simctl list devices available`는 CoreSimulatorService 연결 오류였고, 로컬 `127.0.0.1:3000/v1/health`는 connection refused였다. 이번 세션은 시뮬레이터 실제 기동 및 backend HTTP 통합 동작을 검증하지 않았다.
- 의미 있는 후속 검사: 실기기/시뮬레이터에서 다중 날짜 빠른 탭, 분야 전환, 종료 후 분야 유지, 서버 오류 이후 이전 월간 결과, 서버 revision 충돌, 실제 수집 상태 문구를 확인한다.
- 외부 verifier의 acceptance/verdict를 변경하거나 PASS로 선언하지 않았다.
- ADR/LEARN-ID: 기존 계약 소비 및 기본 SwiftUI 상태 제어로 신규 기술 결정 없음. 관련 학습 기록 없음.
- 공통 상태 문서 원본과 사본은 backend 쓰기 권한이 없어 이 세션에서는 갱신하지 않았다. 후속 문서 통합 시 이 작업 카드를 바탕으로 app/backend/verifier status·handoff를 같은 revision으로 갱신한다.
