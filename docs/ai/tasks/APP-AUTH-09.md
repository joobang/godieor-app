# APP-AUTH-09 · iPhone 로컬 HTTPS 개발 접속

- requirement ID: APP-AUTH / BE-AUTH. acceptance draft/PENDING.
- 상태: 인계 대기 / 담당 해제 (codex-local-https-01).
- 기준: app 8d2d10f69ad763a4b7dd1aba588a31f22e7a3e73; backend a9ed427238f98df24315404cb0199a6a5a123377; verifier 9a213bde959cd235ae9c73b05436efd983f2333b. codex/int-01-secret-check, clean.
- 범위: iPhone용 로컬 HTTPS 역방향 프록시·설정 문서·연결 자체검사. API 계약·DB·verifier 승인 기준 불변.
- 완료 조건: 개발자가 자신의 Mac LAN IP로 HTTPS 프록시를 시작하고, iPhone 인증서 신뢰 후 앱 URL을 지정할 수 있음.
- 예상 실패: Wi-Fi 격리/방화벽, 인증서 신뢰 누락, IP 변경, backend 종료, Google 테스트 사용자 미등록.
- ADR: 002-account-sync 유지. LEARN-ID: 해당 없음(로컬 연결 운용 절차).

## 구현·자체 검사

- `python3` AST 구문 검사: 성공. `sh -n scripts/dev-https.sh`: 성공.
- `xcodebuild ... -derivedDataPath /private/tmp/godieor-auth09-derived CODE_SIGNING_ALLOWED=NO build`: exit 0 / BUILD SUCCEEDED.
- `scripts/dev-https.sh 192.168.254.254`: CA/server 인증서 발급 성공. Mac sandbox의 포트 bind는 EPERM(코드 1), 실제 LAN에서 TLS 응답 확인은 미실행.
- `openssl x509 -checkip` IP SAN 일치, `openssl verify -CAfile` chain 검증 OK.
- 동일 revision status/handoff 3 저장소 반영. API/DB/verifier acceptance 변경 없음.
- 실기기 Google OAuth/설정/찜 왕복과 독립 검증은 미실행.

## 독립 검증 handoff

- app/backend 기준 SHA는 위와 같으며 결과 HEAD는 종료 후 Git 이력에서 확인.
- API 0.1.0-draft.2 / digest 8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e.
- migration digest 29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9.
- verifier 기준 draft/PENDING, 독립 검증 미실행.

## 다음 개발 세션 인계

- Mac 실제 Wi-Fi IPv4 확인 후 `scripts/dev-https.sh <IP>` 실행, iPhone에서 개발 CA 설치·신뢰 및 Safari health 검사. Xcode Run 환경변수로 API base URL 지정 후 앱 로그인/세션·설정·찜 검증.
- 현재 Docker API 소켓 접근은 permission denied; backend `127.0.0.1:3000` 미기동. 로컬 프록시 테스트는 bind EPERM. 사용자 기기·Google 테스트 사용자 구성 상태 미확인.
- 개별 기기 실제 로그인/독립 runner verdict를 PASS로 표시하지 않음.
- status/handoff, 실행 문서 갱신 완료. 실사용 코드와 무관하므로 별도 ADR/LEARN 기록 없음.
