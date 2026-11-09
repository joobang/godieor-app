# APP-01E · 카탈로그 옵션 기반 공개 필터

- 요구사항: PROD-003 / GD-003(초안), PROD-008 / GD-008(초안), PROD-010 / GD-010(초안). 독립 승인 전.
- 상태: 앱 구현·빌드 완료, 실제 iOS 화면/서버 통합 및 독립 검증 대기. 담당 해제.
- 세션: `codex-app-options-01`.
- 기준: app `7b7202455005cc796b949ac70aee639c8e4a3c0b` (dev, 시작 시 clean), backend `85ea4f3398d949e4f59313232306c3325956b7a6` (dev, clean), verifier `109f918799d6c818ae30ba5af4a5cedb112573e8` (dev, clean).
- 작업 브랜치: app `dev`, 동일 checkout의 순차 작업. 원본 카드: 이 파일.
- 수정: `ios/GODIEOR/PublicAPI.swift`, `ios/GODIEOR/ContentView.swift`, `README.md`, 이 카드.
- 완료 조건: 고정 `0.1.0-draft.2` 계약의 `/catalog/options` 응답으로 국가/시간대/OTT 서비스/게임 기기 옵션 표시, 해당 필터를 공개 조회에 전달, 전부 꺼진 분야는 호출 중단, 설정은 기기에 임시 저장, 빌드 통과.
- 실패 사례: 옵션 서버 다운/계약 버전 불일치, 저장된 옵션이 서버에서 제거됨, 빠른 필터 변경 중 오래된 응답 도착, 선택 분야 없음, 날짜만 있는 일정의 임의 UTC 시각 부여, `409` 카탈로그 수정.

## 구현·검사

- API의 옵션 응답을 디코딩하며 계약 버전을 검사한다. 지원하지 않는 저장 국가/시간대는 서버 기본값으로 복구한다.
- 영화/OTT 초기 선택 유지. OTT 서비스 및 게임 기기는 선택이 비면 해당 분야 전체이며 분야 모두 선택 해제 시 월/일 API 요청을 건너뛴다.
- 국가/시간대/분야/서비스/기기로 월간 캐시 키를 나눈다. 월/일/상세에 국가와 시간대를 전달하며 날짜 정밀도(`date_only`)는 그대로 유지한다.
- 신선도 상태 표시를 계약 값 `succeeded` 및 `available` 기준으로 수정했다. 로그인 및 `/me/settings` 동기화는 수행하지 않았다.
- `./scripts/build-ios.sh` → 종료 0, `BUILD SUCCEEDED` (iOS Simulator generic 대상 컴파일).
- `git diff --check` → 종료 0.
- 이전 확인에서 로컬 `127.0.0.1:3000` 연결 거절, 이번 빌드에도 CoreSimulatorService 연결 오류 로그가 있어 시뮬레이터 인터랙션 및 실제 서버 통합은 검증하지 않았다. 컴파일은 성공했다.

## 독립 검증 handoff·다음 작업

- app base/head: `7b7202455005cc796b949ac70aee639c8e4a3c0b` / 커밋 후 Git 이력 확인.
- backend base/head: `85ea4f3398d949e4f59313232306c3325956b7a6` / 동일. verifier: `109f918799d6c818ae30ba5af4a5cedb112573e8`, clean.
- API: `0.1.0-draft.2`, app pinned manifest SHA256 `8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e`; migration digest는 `docs/api/contract-reference.json`의 `runtimeFiles`에 기록. app-only 자체 빌드이며 통합 PASS 아님.
- 승인 기준: verifier `requirements/acceptance.yaml` 소유. 승인/verdict/review는 이 세션에서 수정하지 않음.
- 다음: backend 실제 실행 후 시뮬레이터에서 옵션 요청·필터 조합·재조회·409·오류 복구·날짜 정확도를 점검하고 독립 검증에 고정 SHA를 전달한다.
- 공통 status/handoff: backend 동기 사본을 갱신할 쓰기 권한이 없어 원본/사본을 수정하지 않았다. 기존 `status.md`의 APP-01 미착수 표기는 오래된 상태이므로 이 카드와 최신 Git 이력을 우선 확인하여 동시 revision으로 갱신할 것.
- ADR/LEARN-ID: 이미 고정된 공개 API 계약을 소비하는 UI 연결로 신규 ADR·학습 기록 없음.
