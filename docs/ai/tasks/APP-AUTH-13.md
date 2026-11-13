# APP-AUTH-13 · 계정 복원·저장·찜·전환·실패 흐름

- 요구사항 PROD-003/006/010, GD-003/006/010. acceptance draft/승인 상태 불변.
- 상태 완료(구현·자체검사 범위), 담당 codex-account-flow-01 해제. 구현 담당, 원본 app/docs/ai/tasks/APP-AUTH-13.md.
- base app b4ade8fc32f82bbb7bda59cc35688023b5cfa2ee / backend1e5b1d09532e16bcc2b42baa57a30ff27b170373 / verifier466cc023541a5444595497f8f3da589a19d37921.
- branch 세 저장소 codex/account-flow-recovery, 기존checkout순차/동시작업없음. 개인pbxproj/backend.env.example/package.json/미추적감사도구·테스트보존.
- 범위/완료: 실제AccountState를계정저장소·인증·HTTP의주입가능한경계로구성하고로그인/복원/설정저장/찜/계정전환/로그아웃/401·409·오프라인·지연응답을결정적으로검사한다. 실제Google·Keychain·외부망을쓰지않는합성시나리오와unsigned iOS빌드결과를구분한다. 제품데이터추가·변경0.
- 코드검토가설: 로그아웃이busy를초기화하지않아지연쓰기동안재로그인차단;오래된settings PUT응답이더새쓰기/refresh를덮음;기존operation defer가새operation의busy를해제;초기restore오프라인때저장세션재시도UI부재. 각각수정전실패·수정후통과로검증하고미재현은구분한다.
- 예상실패: 이전계정값/지연401이새계정에반영,실패를완료로표시,복원실패로키삭제,테스트가실Keychain/Google접근,구현복사테스트,합성상태기검사를실폰/독립PASS로표현.
- 기존계약/정책유지. ADR/LEARN-ID 및 실제검사·공통인계는종료전기록. 실폰·독립review·기기간전체통합은별도미완료.

## 구현 결과

개발 중 합성 실행에서 4건을 재현하고 수정했다. 실제 사용자 장애로 표현하지 않는다.

- 새 계정 최초 조회 실패 시 이전 계정 설정·찜이 남음 → 새 세션 발급 직후 이전 snapshot/pending/동기화 정보를 비움.
- 로그아웃 후 이전 저장이 끝날 때까지 busy 유지 → 로컬 종료 즉시 busy/소유권 무효화.
- 이전 작업의 defer가 새 계정 저장의 busy 해제 → UUID가 일치하는 현재 작업만 해제.
- 늦은 v2 저장 응답이 새 v3 저장을 덮음 → 설정 mutation revision과 세션을 성공·오류·오류 후 재조회에서 확인.
- 초기 복원 오프라인은 세션 보존, 재시도/로그아웃 UI 및 active 복귀 재조회 추가. UI 클릭 실험은 미실행.
- iOS 기본 URLSession/Keychain/Google 인증을 유지하고 검사에만 합성 HTTP/메모리 저장소/인증 결과를 주입. 실제 AccountState 실행이며 복사 구현을 정답으로 쓰지 않음.

## 실제 자체검사

| 명령 | 종료 | 관찰/근거 |
|---|---|---|
| `xcrun swiftc -module-cache-path /private/tmp/godieor-account-flow/swift-cache -parse-as-library ios/GODIEOR/PublicAPI.swift ios/GODIEOR/Account.swift tests/AccountFlowChecks.swift -o /private/tmp/godieor-account-flow/baseline` (수정 전, 의존성 주입만 적용) | 0 | 실제 AccountState 빌드 |
| `/private/tmp/godieor-account-flow/baseline --expect-known-failures` | 0 | 11/15, 정확히 위4실패가 있어야 exit0인 재현 모드. 통과 판정 아님 |
| 동일 swiftc 명령, 출력 `fixed` / `/private/tmp/godieor-account-flow/fixed` | 0 / 0 | 수정 후15/15, 일반 모드에서 실패 시 exit1 |
| `sh scripts/check-account-flow.sh` | 0 | 새 임시 컴파일 경로에서15/15; HTTP/Google/Keychain 실제 접근 없음 |
| `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/godieor-account-flow/DerivedData CODE_SIGNING_ALLOWED=NO build` | 0 | 작업트리 iOS unsigned 성공(개인 pbxproj 포함 상태) |
| `git archive dc3bab01d675e1fff28c8265dcf6d07606866992`를 임시 source로 추출 후 같은 xcodebuild (`-project /private/tmp/godieor-account-flow/fixed-source/ios/GODIEOR.xcodeproj`, derivedData `FixedDerivedData`) | 0 | 개인 pbxproj 제외한 고정 소스 iOS unsigned 성공. CoreSimulator runtime/service 경고 및 AppIntents metadata skip; 실행 관찰 아님 |
| `git diff --check` | 0 | 공백 검사 |

원시 자체검사 출력/수정 전 의존성 패치: `docs/ai/evidence/app-auth-13/`. baseline patch는 base Account.swift에 적용해 테스트 가능 경계만 추가하는 패치다. 고정 소스 추출 첫 시도는 로컬 Python tarfile이 filter 인자를 지원하지 않아 실패, 로컬 git archive→tar 추출로 재시도 성공했다. 최초 빈 프로젝트 xcodebuild exit66과 성공한 빌드를 구분한다.

15개 시나리오: 복원(두 찜 종류), 로그인/세션 저장, 인증 실패, 새 계정 조회 실패, 서버 로그아웃 실패, 오프라인 복원/재시도, 만료401, 설정409, 찜409 전체 재시도, cursor 순환/마지막 성공 유지, 찜500 후 재시도, 이전 계정401 무시, 로그아웃 busy 해제, 연속 저장 지연, 이전 defer의 새 작업 간섭.

## 독립 검증 handoff

- app base 위 항목 / 코드 head `dc3bab01d675e1fff28c8265dcf6d07606866992`. 종료 문서만 후속 커밋이며 최종 HEAD는 Git 이력/웹 전달본에서 확인.
- backend base=head `1e5b1d09532e16bcc2b42baa57a30ff27b170373` (이후 공통 문서만 동기화).
- verifier base `466cc023541a5444595497f8f3da589a19d37921` (이후 공통 문서/LEARN 초안만 갱신).
- 계약 `0.1.0-draft.4` manifest digest `96cc08536324f8b5a7c537783caa93a1ce33de533526032e01621282fb601122`.
- migration runner digest `853337eadc11cd3c8c619c9e53d961cb7eead5fe0a79368c5d167324598bb697`.
- acceptance `0.1.0-draft` / `c4906283810c8b378800b67930028685a41b6a051923ea9f9415346b2d657063`, draft/approved_by null 유지.
- 범위 app-only 작성자 합성 검사/unsigned compile. 신규 독립 runner·실폰·실 Keychain·실 Google·backend HTTP/DB 왕복·두기기 검증 미실행. 제품DB 접근/신규 적재0. 기존 runner ERROR/4 SKIPPED/독립review 대기는 변경하지 않음.

## 다음 개발 세션

- 다음 제품 단위는 달력→목록→상세·설정 복원의 빈 결과/실패/지연 응답/마지막 성공 상태 검사. 데이터 보강으로 되돌아가지 않음.
- 개인 pbxproj 및 backend env/package/미추적 감사도구는 보존, 커밋 대상에서 제외. push/가입/배포 없음.
- 공통 status/handoff/plan 동일 사본, README/roadmap 갱신. ADR-003 / LEARN-0020 연결.
- 실제 기기 인증·왕복/독립 승인 미완료를 유지. 사용자 이해/성과 측정 주장 없음.
