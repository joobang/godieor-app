# ADR-002 · Google 로그인 및 계정 동기화 초안 구현

상태: 구현 결정, 실제 OAuth·기기간 통합 검증 대기 (2026-11-10)

- 로그인 없는 공개 일정 열람 유지. iOS는 Google Authorization Code + PKCE, state, nonce로 ID token을 얻고 token payload의 nonce·audience를 대조한 다음 backend에 전달한다. backend는 Google JWKS RS256 서명, issuer, audience, exp, iat, sub를 자체 검증한다. ID token 재사용은 세션 발급이 가능하므로 서버측 일회성 token replay 방지/nonce 연계는 후속 보안 검토 대상이다.
- backend는 Google subject를 내부 app_user에 연결하고 난수 32바이트 opaque bearer token을 30일 발급한다. DB에는 SHA256 hash만 저장, 단일 세션 DELETE로 폐기하며 자동 refresh는 없다. iOS는 token을 ThisDeviceOnly Keychain에 저장하고 401이면 지운다. 분실된 기기의 다른 세션 일괄 폐기/계정 삭제는 미정이다.
- 계정 설정에는 서버 version CAS를 사용하여 다른 기기 변경 시 409를 반환한다. iOS는 로그인 시 원격 복원, 명시적 저장 시 서버 업데이트하며 409 이후 재조회한다. 오프라인 변경 자동 병합은 구현하지 않았다.
- 작품 찜/일정 찜은 사용자+대상 유일, 동일 PUT/DELETE 재호출 멱등, 변경 시 favorites_version 증가, 목록은 user/version/limit에 결속된 15분 HMAC 커서를 사용한다. 페이지 사이 변경은 409로 처음부터 다시 조회한다.
- 외부 제공처 비밀은 서버에서 관리한다. Google OAuth 클라이언트 ID는 공개 식별자이며 실제 설정은 앱 빌드/백엔드 환경에 별도로 주입한다. 실제 Google 자격증명·HTTPS backend 없이는 end-to-end 검증을 주장하지 않는다.
- API 계약 0.1.0-draft.2 및 migration digest 변경 없음. 전용 Mac 계정 검증 방식 폐기 상태.
