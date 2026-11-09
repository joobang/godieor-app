# APP-01F · 실제 백엔드와 iOS 연결 점검

- 요구사항: PROD-003/GD-003, PROD-007/GD-007, PROD-008/GD-008, PROD-010/GD-010 (모두 초안).
- 상태: 작성자 통합 점검 완료, 독립 검증 대기. 담당 해제.
- 기준: app `92021e1fd56053b95ea1a451673707ce0ab256a0` dev clean, backend `85ea4f3398d949e4f59313232306c3325956b7a6` dev clean, verifier `109f918799d6c818ae30ba5af4a5cedb112573e8` dev clean.
- 작업 checkout: app dev (기존 연속 구현), backend/verifier는 읽기만. 원본 카드: 이 파일.
- 범위: 백엔드 로컬 API 실행 및 옵션/월/일/상세 조회, iOS Simulator 실행 및 표시 확인, 발견된 앱 버그 수정, 앱 빌드 및 결과 기록.
- 완료 조건: 가능한 실제 통합 시나리오를 실행하고 결과·불가능한 항목을 구분하여 기록하고 커밋한다.
- 예상 실패: CoreSimulator 권한, 개발 Node 버전, 서버 접속 불가, 앱 HTTP ATS, 옵션 또는 필터 쿼리 계약 불일치, 날짜 전환 레이스, 409 revision 변동.
- 사용자 확정 사항: 계약 및 국가/시간대/OTT/기기 필터를 유지, 서버 사용자 계정 동기화는 별도 과제.

## 실제 실행 기록

- 2026-11-09: Docker PostgreSQL 기존 컨테이너를 유지한 채 Node 24.19.0으로 기존 backend `dist`를 실행. `/v1/health`, `/v1/catalog/options`, `/v1/calendar`, `/v1/events` HTTP 200 확인. `/catalog/options` 계약 `0.1.0-draft.2`, 2026-11 달력 30일과 일정 3건 확인.
- iPhone 17 Pro Simulator(866174BE-CB3E-44E6-BED4-2AD8D82A460B) 부팅, 앱 설치·실행, 2026-11 달력의 가상 영화/드라마 및 제공처 반영 일정 표시 확인. 실행 직후 첫 캡처의 흰 화면은 후속 캡처에서 정상 표시 확인되어 지속 오류로 판단하지 않음.
- 달력과 날짜별 조회: 11/11 `date_only` 가상 영화, 11/12 `instant` 가상 OTT, 11/18 `date_only` 제공처 일정 확인. Netflix OTT 필터 1건, 미국 국가 필터 0건, PlayStation 게임 필터 0건, Asia/Tokyo 필터 3건; 모든 요청 HTTP 200. 409 재현은 수행하지 않음(`stale` 문자열 revision 요청은 유효성 검사로 HTTP 400).
- 실제 버그: 앱의 상세 요청이 `country`를 추가로 보냈으나 계약과 backend `DetailQueryPipe`는 `timeZone`만 허용. 실제 요청 HTTP 400 확인. `PublicAPI.detail`에서 `country` 제거. 같은 UUID에 `timeZone=Asia/Seoul`만 보내 HTTP 200, `date_only`, 출처 1개 확인.
- `./scripts/build-ios.sh`: Xcode iOS Simulator Debug 빌드 `BUILD SUCCEEDED`. `git diff --check` 및 커밋은 종료 단계에서 확인.
- 앱 화면에서 날짜 셀 탭→상세 화면 표시까지 자동 UI 조작은 미실행. 시뮬레이터 실행 화면과 API 요청은 각각 직접 확인했으나 독립 통합 PASS는 아님.
- 변경: `ios/GODIEOR/PublicAPI.swift` 상세 쿼리 수정, 본 카드 및 상태 문서. 계약과 데이터베이스 수정 없음.

## 독립 검증 인계

작성자 실행과 verifier 승인/통합 PASS는 구분한다. app 기준 `92021e1fd56053b95ea1a451673707ce0ab256a0` → 이 작업 커밋 HEAD, backend `85ea4f3398d949e4f59313232306c3325956b7a6`, verifier `109f918799d6c818ae30ba5af4a5cedb112573e8`. API `0.1.0-draft.2`; manifest SHA-256 `8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e`; 초기 migration SHA-256 `29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9`. verifier 기준/승인 상태 수정 없음.

## 후속 작업

독립 검토/증거 v2에서 날짜·상세 탐색을 검증하고, iOS UI 조작 및 국가/시간대 전환 후 선택 상태를 확인한다. `APP-01` 공개 일정 표시 이후 로그인·계정 설정은 별도 과제. 기존 계약 준수 버그 수정이므로 신규 ADR/LEARN-ID는 해당 없음. backend 원본 status/handoff와 verifier 공통 사본은 이 세션 backend 쓰기 권한이 없어 동기화하지 못함.
