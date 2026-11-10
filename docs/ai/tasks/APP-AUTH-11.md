# APP-AUTH-11 · 실제 LAN HTTPS 확인과 iPhone 준비
- 상태: Mac준비완료·iPhone소유자실행대기. 담당 codex-phone-ready 해제.
- 기준: app10d74bd/backende78eab0/verifier84a7683, 시작clean. 요구사항 APP-AUTH/GD-010 초안.
- 범위: 이미실행중인 GODIEOR LAN HTTPS proxy와loopback backend의실제TLS/HTTP확인, 공개CA인증서전달준비. 기존DB/계정정보쓰기·Mac/iPhone신뢰설정변경없음.
- 실패사례: 자체서명검증무시(-k)로성공오인·인증서SAN/IP불일치·CA개인키공유·공개/인증경계혼동·폰검사미실행PASS.
- 관찰: 기존proxy PID96590 192.168.2.40:3443, loopback3000 health databaseconnected/mixed. 이작업이시작한서비스아니며중단/재시작하지않는다.
- LEARN-ID 해당없음: 기존HTTPS운용절차의실행확인, 신규기술정책선택없음.

## 실제 실행 (2026-11-10)
- Mac Wi-Fi IPv4와이미실행중인proxy PID/인증서경로확인. 기존서비스재시작/중단없음. loopback health200/databaseconnected/mixed.
- 공개CA만 work/iphone/godieor-dev-ca.cer 로복사, certificate-info.txt에공개subject/만료/지문, README.md에현재실제주소와기기단계준비. Git제외확인. CA/server 개인키는읽거나복사하지않음. CA/server keychain신뢰저장소변경없음.
- openssl x509 -checkip으로실제IP SAN일치확인. urllib ssl.create_default_context(cafile=기존CA)로체인/hostname 검증유지(-k/검증해제없음).
- 실제LAN TLS GET health200/DB연결, catalog/options200/계약0.1.0-draft.2, 인증없는me/settings401, invalid idToken POST auth/google401. 정상토큰/사용자개인정보·설정·찜쓰기/실Google검증은실행안함.
- xcodebuild -sdk iphoneos -destination generic/platform=iOS -derivedDataPath /private/tmp/godieor-auth11-device-derived GODIEOR_API_BASE_URL=실제LAN_HTTPS CODE_SIGNING_ALLOWED=NO build: BUILD SUCCEEDED. 생성Info.plist에동일실제HTTPS주소확인. 이것은서명/기기설치/로그인성공이아님. source buildsetting placeholder는변경하지않음.
- 사용자 iPhone프로파일설치/신뢰는미실행. 현재Apple공식안내 https://support.apple.com/en-us/102390 를확인해직접설치후별도SSL/TLS신뢰필요를문서화. 다음은동일Wi-Fi폰Safari health조회이며소유자가직접수행한다.
- 코드변경없는운용실행확인. 신규독립코드리뷰/독립verdict/통합PASS 없음. 계약manifest8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e, migration29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9 및acceptance초안불변.
- 상태: Mac준비완료·기기소유자단계대기, 담당해제. 다음요청은phoneSafari health결과확인후Xcode실기기서명설치/Google로그인·세션복원·설정/찜왕복. 기존서비스는사용자폰연결을위해유지. IP/프로세스생존은다음세션에재확인한다.
