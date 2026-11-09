# APP-01A/B · 공개 API 클라이언트와 월간 달력/상세

- 요구사항: PROD-001, PROD-002(기본 분야 선택), PROD-004, PROD-007, PROD-008, PROD-010 / GD-001, GD-002, GD-004, GD-007, GD-008, GD-010 (acceptance draft, 승인 전).
- 상태: 구현·iOS 빌드 완료, 런타임/독립 검증 대기. 담당 해제.
- 세션: `codex-app-public-01`. base app HEAD `e98e8639ef0f2a1853f9785978d2126d5afad2b9` dev clean, backend `85ea4f3398d949e4f59313232306c3325956b7a6` dev clean, verifier `109f918799d6c818ae30ba5af4a5cedb112573e8` dev clean.
- 작업 위치: 기존 app dev checkout(동시 수정 없음 확인). 최종 HEAD는 커밋 이력에서 확인.
- 변경 범위: iOS Swift API DTO/HTTP, 월간 달력, 날짜별 페이지 조회, 상세/출처, 오류/가상/부분 수집 표시, Xcode 빌드 설정과 설명.
- 사용자는 로컬 서버가 있으면 공개 월간 일정을 조회할 수 있다. Google 인증·찜·설정·완전 자동 제공처 연동은 해당 작업에서 제외.

## 실패 사례 및 경계

- 같은 날 결과가 미리보기 2건보다 많으면 `total`과 페이지 커서로 완전 조회해야 한다.
- `date_only`는 연월일 문자열이며 UTC 자정으로 바꾸지 않는다. `unknown`은 달력 날짜를 만들지 않는다.
- `catalogRevision` 변경 시 달력 갱신 후 목록을 한 번 재요청하며 반복 충돌은 오류로 표시한다.
- 카테고리가 모두 OFF면 서버 전체 조회를 수행하지 않는다.
- 가상 fixture와 일부 제공처 데이터의 한계를 표시한다. 네트워크 실패를 빈 일정으로 표시하지 않는다.
- 빠른 월/필터 전환 시 진행 중 선택 날짜 요청의 결과 경합 및 시뮬레이터 실제 화면은 후속 런타임 검사 대상이다.

## 실행과 결과

| 명령 | 결과 |
|---|---|
| `git status --short --branch`, `git rev-parse HEAD` (3저장소) | 위 기준 상태 확인 |
| `./scripts/build-ios.sh` | 첫 실행 Swift 상세 오류로 실패. 오류 및 충돌 재시도 처리 수정 후 최종 `BUILD SUCCEEDED` (exit 0) |
| `git diff --check` | 통과 (exit 0) |

시뮬레이터 런타임 서비스 `simdiskimaged` 오류 메시지가 있으므로 실제 앱 실행·backend HTTP 연결·UI 테스트는 실행하지 못했다. 기존 backend 계약 예시를 참고했지만 실제 네트워크 decode 테스트/독립 verifier PASS는 아니다.

## 독립 검증 인계

- app base `e98e8639`; head 최종 Git 커밋 참조.
- backend base/head `85ea4f3398d949e4f59313232306c3325956b7a6` (수정 없음).
- verifier `109f918799d6c818ae30ba5af4a5cedb112573e8`, clean (수정 없음).
- 계약 `0.1.0-draft.2`, app `docs/api/contract-reference.json`의 manifest SHA-256 `8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e`. migration digest도 해당 파일 참조. 고정 계약 독립 승인 전.
- 검사 범위: app 빌드만. 독립 기준 초안 `godieor-verifier/requirements/acceptance.yaml`은 수정하지 않음.
- 다음: 실제 로컬 backend + iOS 시뮬레이터 날짜별 조회/상세/429/409/페이지 커서/날짜 경계 테스트. APP-01C/D 설정 및 오류/캐시 보완. `catalog/options` 조회 및 지원 국가/시간대 설정 연결.
- ADR/학습: 새로운 기술 선택 없음(기존 계약 소비); LEARN-ID 해당 없음(기존 날짜 정밀도 원칙 구현).
- 공통 status/handoff 사본: backend 저장소 쓰기 권한이 없는 현재 세션에서는 3개 사본을 함께 동기화할 수 없어 수정하지 않음. 다음 문서 통합 세션에서 이 카드로 상태 갱신 필요.
