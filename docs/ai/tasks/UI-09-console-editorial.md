# UI-09 · 중립색 에디토리얼 테마와 콘솔·모바일 게임 카드

- PROD-001/002/004/006/010, GD-001/002/004/006/010. 앱 main 1bc2d2b에서 분리. 사용자 요청의 밝고 성숙한 테마와 게임 카드를 수정한다.
- 콘텐츠 ID·일정·상태·원천이 같은 게임은 날짜 목록 카드 한 장에서 지원 플랫폼 아이콘을 모두 표시한다. 시각/날짜 정밀도·상태·작품이 다른 출시를 분리하고 각 원본 지역·플랫폼 상세를 유지한다.
- 실패 사례는 PC 저장 필터, 예전 앱과의 호환, 여러 시장의 같은 플랫폼, 긴 제목과 큰 글자, 게임 상세와 찜이다.

## 구현·자체 검사

- `swiftc ios/GODIEOR/PublicAPI.swift tests/ReleaseCardChecks.swift` 카드 그룹 검사 통과.
- `sh scripts/check-account-flow.sh` 가상 계정 15/15 통과.
- unsigned iPhone 17 Simulator 빌드 및 실행. Geo Book 카드 한 장에 PlayStation과 Xbox 로고가 동시에 표시됨.
- DATA-93의 구현·운영 상태는 backend 작업 카드를 참조한다. 기존 공개 계약이나 필드 형식을 바꾸지 않았다.
- ADR/LEARN 신규 해당 없음. 표시 변경은 기존 안정 ID, 기기, 공개시각의 규칙을 따른다.
- 별도 맥락 리뷰에서 세계·국내가 섞인 카드의 공통 지역 문구를 생략하고 플랫폼 선택에 개별 지역을 표시하도록 보완했다. 상세 첫 화면에도 합친 기기 아이콘을 표시한다.

## 통합 검증 인계

- UI 구현 검토 app base `1bc2d2bb65da023874d99ce5cf820e05dd558194`, head `b6250a04dfa5f42d11d5f273d145da513ff4b006`. 최초 앱 main 병합 `8dac886b6688b5757d4630f7e4b7bc11235181f0`.
- backend base `bf6f957b2ac0d1190ca1d59a731bf3c50fefcb3b`, 구현 head `c3255b9ce98d211e2097d037dbd5a04bba742da8`.
- API `0.1.0-draft.5` / `04cfea7456d83ca141ba64c6d6568365b00cbdf2d5e95eacd8c4dad7249a0f2e`, migration 집합 `feeb684462340075302b9a05ff3102740f6fe7d87c667ea8c455752c1433ba1b`. 검증 기준 draft digest `c4906283810c8b378800b67930028685a41b6a051923ea9f9415346b2d657063`.
- 첫 독립 통합 runner는 기존 앱의 이전 계약 지문에서 snapshot 오류를 반환했다. backend 원본으로 앱 참조를 동기화했다. 기준·승인·verdict 파일은 수정하지 않았다.
- main과 iOS 소스 일치 확인 후 개발 서명 앱 `0.1.0 (7)`을 iPhone 15 Pro에 설치하고 devicectl로 버전 확인 및 실행 성공. Simulator Geo Book 상세에서 두 콘솔 아이콘을 확인했다.
