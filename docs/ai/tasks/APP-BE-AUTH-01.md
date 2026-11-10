# APP-BE-AUTH-01 · Google 로그인·세션·설정/찜 동기화

- requirement ID / acceptance: APP-AUTH, BE-AUTH, BE-SAVED, VFY-AUTH; verifier/requirements/acceptance.yaml draft (독립 승인 없음).
- 상태: 완료 (자체 구현·검사 범위), 독립 검증 인계 대기; 담당 해제.
- 담당 세션: codex-auth-01.
- 기준 HEAD: app 81c3338f508faf99806b0915802c242da55d0d72 / backend 838411fca7830b3b4e6e3c09605f785b960fbe79 / verifier 1d434c31b9f5d4eec4396d45330685fbbb5a6d70; app/backend dirty 상태의 기존 진행 변경을 이어받음.
- 브랜치: codex/int-01-secret-check 기존 checkout에서 순차 진행; 동시 수정자 없음으로 인계됨.
- 카드 원본: app/docs/ai/tasks/APP-BE-AUTH-01.md.
- 사용자 동작: Google 로그인, Keychain 세션 복원/로그아웃, 계정 필터 저장/충돌, 작품/일정 찜 서버 동기화.
- 범위/완료: 백엔드 Google JWT/opaque session, 사용자별 설정/찜 API; iOS 인증/찜 UI, 자체 빌드·테스트, 문서 인계. 실제 OAuth/독립 통합 판정은 환경 준비 후 별도.
- 사용자 확정: 전용 Mac 계정 폐기, 계정 기반 V1; 서버 계정 sync와 기기 필터 구분.
- 구현 정책: 30일 비갱신 세션, 로그아웃 단일 세션 폐기, 설정 optimistic version 409, 찜 저장 멱등/계정 격리. 계정 삭제·다중 세션 관리 UI는 추후 결정.

## 가정·실패 예상

- 미설정 OAuth client, 잘못된 토큰 발급자/audience/서명/nonce, 세션 만료·로그아웃 이후 접근, 타 사용자 데이터 접근, 동시 최초 로그인, 필터 버전 충돌, 찜 커서 위조/버전 변경/대량 페이지, 네트워크 중단.
- 비밀은 앱/fixture/로그에 저장하지 않는다. Google OAuth 실제 단말 검사는 실 Client ID와 backend HTTPS 없이는 미실행.

## 구현·자체 검사

- backend `npm test` → exit 0, 51 tests PASS(신규 auth-sync 4 subtests).
- iOS `xcodebuild ... -derivedDataPath /private/tmp/godieor-auth-derived CODE_SIGNING_ALLOWED=NO build` → exit 0 BUILD SUCCEEDED.
- 기본 DerivedData 첫 빌드 exit 1(쓰기 권한), writable DerivedData로 교정 후 통과.
- 실 Google 로그인/실DB 왕복/기기간 동기화/독립 verifier: 미실행(자격증명과 실서버 없음).

## 독립 검증 handoff

- app/base: 81c3338f508faf99806b0915802c242da55d0d72; backend/base: 838411fca7830b3b4e6e3c09605f785b960fbe79.
- 계약: 0.1.0-draft.2 / 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration: 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- verifier/base: 1d434c31b9f5d4eec4396d45330685fbbb5a6d70; 기준 draft, review PENDING.
- 앱·backend 자체 검사 결과는 독립 통합 PASS가 아니다.

## 다음 인계

- backend/app Google 클라이언트 ID 설정, 휴대폰 접근 가능 HTTPS API, 임시 DB에서 다중 사용자·실 OAuth·동시 로그인 검증. 설정 충돌 시 원격 재조회와 수동 재적용 UX 확인. Google 동의화면/앱 등록 설정 준비.
- verifier acceptance/approved verdict 변경 금지. 전체 통합 runner 미실행. 커밋 SHA는 Git 이력에서 확인.

## 결정·학습 기록

- ADR: docs/decisions/002-account-sync.md.
- LEARN-ID: 해당 없음(계정 기능 구현 결과는 본 카드/ADR에 기록, 학습 해설 별도 미작성).
