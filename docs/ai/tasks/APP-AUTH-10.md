# APP-AUTH-10 · 공개/계정 API 주소 통일
- 상태: 구현·작성자검사·독립코드재검토 완료, 담당해제.
- 기준: app af502deaff85772656bfe26f47f468808a492859/backend a4759669e45b93a2f5595c15240a70cd1f5c6485/verifier e6baf71717837729069e66e1d59e50b960f127ff. 시작 모두 clean.
- 요구사항: APP-AUTH/GD-004/010(초안). 범위: PublicAPI/AccountStore 동일설정읽기, 실기기localhost fallback차단, 주소설정회귀·iOS빌드.
- 실제발견: AccountStore는Info.plist의GODIEORAPIBaseURL을읽으나 PublicAPI는환경변수만읽어 Xcode빌드설정을무시. iPhone계정API와달력API가다른서버로갈수있음(정적확인, 실제폰재현은미실행).
- 실패사례: env/bundle우선순위·placeholder·잘못된HTTPS·user/pass/query/fragment혼입·기기localhost·계정평문HTTP·Simulator개발fallback손상.
- API계약/migration/승인상태/실제OAuth설정 변경없음. LEARN-ID 후속연결예정.

## 구현과 실행
- APIEndpointConfiguration 단일resolver: env→bundle 우선순위, HTTPS공통주소, Simulator공개loopback만허용, 기기fallback차단, 잘못된override설정거부. PublicAPI 잘못된URL force unwrap 제거. AccountStore도동일resolver 사용.
- 최초swiftc는 기본사용자 module cache 쓰기EPERM으로실패, 명시 /private/tmp module-cache-path로재실행해통과. 코드문법오류와구분한다.
- Swift 회귀: bundle HTTPS·env우선·placeholder·userinfo/query/fragment·HTTP LAN거부·device/Simulator경계 통과. 별도리뷰 Lagrange가scheme/host대소문자지적(P2)하여 lowercased비교·혼합대소문자회귀추가.
- xcodebuild genericSimulator /private/tmp/godieor-auth10-derived CODE_SIGNING_ALLOWED=NO 최초전체빌드성공. 실제Info.plist에 GODIEORAPIBaseURL key가있음을확인했고, reserved테스트주소 override빌드/실제bundle값 resolver대조를후속실행중.
- 실제iPhone/Google/JWT·설정/찜왕복/HTTPSproxy실연결은미실행. 현재source의실제backendURL placeholder를 실제주소로임의대체하지않았다. 인증서·키체인·OS계정설정변경없음.

## 고정 입력·미검증 범위

API0.1.0-draft.2, manifest8dfc69a8c6a5f9feb91f2d0cf6d661eec16a1aacb8e980b7abe880cd0b1f3b1e, migration29ef8ef0d520f44b6a633e8f017144a3e2b2199189461a88ba99bc296c42f5b9. app base af502de, head 커밋후Git참조, backend base/head a4759669e45b93a2f5595c15240a70cd1f5c6485(코드변경없음), verifier e6baf71717837729069e66e1d59e50b960f127ff. 기준초안/승인/독립통합PASS 변경없음.

## 최종 결과
- reserved HTTPS override빌드 BUILD SUCCEEDED. 생성된 Info.plist를 endpoint회귀실행파일에전달하여 실제번들주입값과 두resolvermode동일URL을확인, exit0. 정상기본빌드와override빌드 모두성공.
- reviewer Lagrange(01a1c3f3-9ea9-74a2-b77e-2840f0b3c0a0, fork_context=false) 수정후Swift검사/diff검사성공·추가문제없음보고. 실제빌드plist검사와iOS전체빌드는작성자실행이며reviewer실행으로표현하지않는다.
- 상태: 수정·작성자검사·분리컨텍스트코드재검토완료, 담당해제. LEARN-0018(verifier/docs/learning/entries/0018-shared-api-endpoint.md). 기존ADR002/HTTPS설정방향 구현수정으로신규정책ADR없음.
- 다음: 실제Mac LAN IP와backend기동을확인하고APP-AUTH09 HTTPS프록시실연결/기기소유자의인증서신뢰·iPhone로그인·재실행·설정/찜왕복을수행한다. 현재buildsetting의실제주소는여전히placeholder이며테스트reservedURL은검사용buildoverride일뿐source/운영설정에저장하지않았다.
