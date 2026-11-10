# iPhone Google 로그인 로컬 HTTPS 확인

이 문서는 개인 개발용이다. Mac과 iPhone이 동일한 신뢰할 수 있는 Wi-Fi에 있을 때만 사용한다. Mac의 루프백 API(`127.0.0.1:3000`)를 지정한 Mac 사설 IPv4의 `3443` 포트로 TLS 연결한다. 인터넷 배포나 인증된 외부 접근 제어가 아니다. 검증 후 Ctrl+C로 프록시를 종료한다.

1. backend 기존 `.env`와 PostgreSQL을 준비하고 `npm start`로 API를 실행한다. Mac에서 `curl http://127.0.0.1:3000/v1/health`가 성공해야 한다. DB와 API는 다른 개발 서비스와 분리한다.
2. Mac의 Wi-Fi IP를 시스템 설정 → 네트워크 → Wi-Fi → 세부사항 → TCP/IP에서 확인한다. 예: `192.168.1.20` (예시이며 자기 IP로 교체).
3. app 저장소에서 `scripts/dev-https.sh 192.168.1.20` 실행한다. 스크립트가 생성한 `godieor-dev-ca.cer` 인증서를 AirDrop 등으로 자신의 테스트 iPhone에 전송한다. iPhone 설정에서 다운로드한 프로파일 설치 후 **일반 → 정보 → 인증서 신뢰 설정**에서 해당 로컬 CA를 명시적으로 신뢰한다. CA 개인키(`ca.key`)와 서버 개인키(`server.key`)는 절대 공유하지 않는다. 인증서를 테스트 폰 이외에 배포하지 않는다.
4. iPhone Safari에서 `https://192.168.1.20:3443/v1/health`를 열어 TLS 연결과 서버 응답을 확인한다. 안 되면 Mac 방화벽, 사설 IP 변경, 공유기 클라이언트 격리 여부를 확인한다. 인증서 신뢰 오류를 무시하고 진행하지 않는다.
5. Xcode Scheme의 Run → Arguments → Environment Variables에 `GODIEOR_API_BASE_URL=https://192.168.1.20:3443/v1`을 추가해 **실행 시** 앱에 전달하거나, 해당 값을 Xcode 빌드 설정에 임시 입력해 앱을 다시 빌드한다. 실행 인자 방식은 Xcode로 직접 실행할 때만 적용된다. 앱의 로그인·설정·찜 API 모두 동일 URL을 사용한다. Release 배포 주소로 이 LAN 주소를 사용하지 않는다.
6. Google Cloud OAuth 동의화면이 Testing이면 사용할 Google 계정을 테스트 사용자로 등록한다. 실제 iPhone에서 로그인 → 앱 종료/재시작 세션 복원 → 설정 변경 → 찜 추가/삭제 → 로그아웃을 확인한다. 두 기기 동기화는 두 번째 기기가 있어야 확인된다.

개발 CA는 30일, 서버 인증서는 14일 뒤 만료된다. Mac IP가 변경되면 새 IP로 실행해 새 CA를 설치한다. 확인 후 iPhone에서 개발 CA의 신뢰와 설치 프로파일을 제거하고 Mac 프록시를 종료한다. 스크립트는 HTTP 본문·Authorization 헤더를 기록하지 않으며 요청을 로컬 API로만 전달한다. 인증서·키는 `${TMPDIR}` 아래에 생성된다.

주의: Xcode Run 환경변수를 이용하는 경우 `GODIEOR_API_BASE_URL`이 실제 앱 프로세스에 전달되는지 확인해야 한다. 일반적인 테스트/배포 빌드에는 Xcode build setting으로 주입해야 한다. 실 Google 인증, iPhone 실기기 동기화와 독립 verifier PASS는 이 문서를 작성했다고 달성되지 않는다.
