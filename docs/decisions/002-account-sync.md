# ADR-002 · Google 로그인 및 계정 동기화 초안 구현

상태: 구현 결정, 실제 OAuth·기기간 통합 검증 대기 (2026-11-10)

- 로그인 없는 공개 일정 열람 유지. iOS는 Google Authorization Code + PKCE, state, nonce로 ID token을 얻고 token payload의 nonce·audience를 대조한 다음 backend에 전달한다. backend는 Google JWKS RS256 서명, issuer, audience, exp, iat, sub를 자체 검증한다. ID token 재사용은 세션 발급이 가능하므로 서버측 일회성 token replay 방지/nonce 연계는 후속 보안 검토 대상이다.
- backend는 Google subject를 내부 app_user에 연결하고 난수 32바이트 opaque bearer token을 30일 발급한다. DB에는 SHA256 hash만 저장, 단일 세션 DELETE로 폐기하며 자동 refresh는 없다. iOS는 token을 ThisDeviceOnly Keychain에 저장하고 401이면 지운다. 분실된 기기의 다른 세션 일괄 폐기/계정 삭제는 미정이다.
- 계정 설정에는 서버 version CAS를 사용하여 다른 기기 변경 시 409를 반환한다. iOS는 로그인 시 원격 복원, 명시적 저장 시 서버 업데이트하며 409 이후 재조회한다. 오프라인 변경 자동 병합은 구현하지 않았다.
- 작품 찜/일정 찜은 사용자+대상 유일, 동일 PUT/DELETE 재호출 멱등, 변경 시 favorites_version 증가, 목록은 user/version/limit에 결속된 15분 HMAC 커서를 사용한다. 페이지 사이 변경은 409로 처음부터 다시 조회한다.
- 외부 제공처 비밀은 서버에서 관리한다. Google OAuth 클라이언트 ID는 공개 식별자이며 실제 설정은 앱 빌드/백엔드 환경에 별도로 주입한다. 실제 Google 자격증명·HTTPS backend 없이는 end-to-end 검증을 주장하지 않는다.
- API 계약 0.1.0-draft.2 및 migration digest 변경 없음. 전용 Mac 계정 검증 방식 폐기 상태.

## APP-AUTH-02 (2026-11-10)

- 계정 API의 iPhone `localhost` 기본주소를 제거했다. Debug/Release `GODIEOR_API_BASE_URL` → 앱 Info.plist의 `GODIEORAPIBaseURL`로 주입하며, 테스트 실행 시 `GODIEOR_API_BASE_URL` 프로세스 환경변수로 덮어쓸 수 있다. 계정 API는 HTTPS 주소만 허용한다. Google iOS Client ID와 reversed URL scheme은 기존 빌드 설정을 사용한다. 이 값들은 아직 placeholder라 실 로그인은 되지 않는다.
- 찜 cursor/version 충돌(409) 때 부분 목록을 버리고 처음부터 최대 한 번 재시도한다. 반복 충돌 시 오류로 남겨 오래된 스냅샷을 사용하지 않는다.

## APP-AUTH-03 · 늦은 응답과 로그아웃 경합 (2026-11-10)

- iOS `AccountState`에 세션 generation과 요청 시작 token 대조를 추가했다. 로그인/로그아웃 사이에 완료된 이전 refresh, 설정 저장, 찜 변경의 응답은 현재 상태를 덮어쓰지 않는다. 연속 조회 및 쓰기 요청의 bearer token도 요청 시작 시점에 고정한다.
- 로그아웃은 기기의 Keychain/화면 상태를 즉시 지우고, 캡처한 이전 bearer token으로 서버 단일 세션을 폐기한다. 폐기 실패는 현재 세션이 여전히 로그아웃 상태일 때만 안내한다. 서버 폐기 실패 시 이전 세션은 만료 전까지 서버에 남을 수 있으므로 최종 인증 통합 검증에서 확인할 위험으로 기록한다.
- unsigned iOS 컴파일만 확인했으며 지연 네트워크/실제 Google 로그인 UI 계측 테스트를 수행한 것은 아니다.

## APP-AUTH-05 · 동시 refresh 완료 순서 (2026-11-10)

- 여러 앱 복귀/수동 refresh가 겹쳐 완료될 때 마지막으로 시작한 refresh만 상태를 갱신하도록 순번을 적용했다. 서버 요청 자체는 취소하지 않는다.
- 설정 저장 동안 시작된 이전 refresh가 새 저장 응답을 덮지 않도록 설정 변경 revision을 구분한다.
- 찜 쓰기 성공 후 pending 해제를 먼저 끝내고 원격 찜 snapshot 재조회를 시작한다. 이전 구현에서는 재조회가 pending 상태를 포착하여 찜 반영이 건너뛰어질 수 있었다.
- 실제 네트워크 지연·다중 단말 재현은 미검증이며 다음 실기기 테스트 대상이다.

## APP-AUTH-06 · 기기 필터의 계정 소유 경계 (2026-11-10)

- 로그인 계정 설정을 반영하면 내부 user ID를 `temporaryFiltersAccountOwner`에 기록한다. 로그아웃·401·다른 계정 전환 시 기본 필터로 초기화한다.
- 앱 재시작에서 계정 소유 필터는 Keychain 복원 전에 지우고 정상 계정 복구 시 원격 설정을 재적용한다. 비로그인 상태에서 직접 설정한 필터는 계정 표식이 없으면 유지한다.
- 계정 설정은 명시적 저장만 서버에 반영한다. 별도 게스트 필터 복구는 지원하지 않는다. 실제 인증·기기간 왕복·독립 검증은 미실행이다.
