# GODIEOR OTT 수집·게시 인계 · 2026-11-13 (DATA-50 반영)

## DATA-50 공식 후보 5개 추가·PAW 게임 식별 (2026-11-13)

- 원본 backend `docs/tasks/DATA-50-official-gap-review.md`. 공식Netflix game83098128→AppStore6818349835와정확한제목·개발자·Games를대조해PAW의정체성미확인을해결,OTT에서게임제외(Academy별칭아님). 게임일정게시0.
- 오늘CJ공식TVING추천작5개를정확한날짜null/첫공개미확정후보로추가: staging169→174,반복신규0. 문무TVING제공근거를NetflixKR날짜로이식하지않음. 전지적집착·문무Netflix·나인투식스Netflix3개는목표OTT일자미확인유지.
- 관련기존18/18통과,SQL읽기61건/연중63건재확인,제품신규게시0·검토state/게시매핑hash불변. 앱/계약/migration/runtime변경없음. 전체검사/독립runner/실폰/클라우드재실행없음,이전ERROR유지. 다음: TVING5개정확한첫날확보/3개날짜미확인근거보강. 개인dirty보존·담당해제.

## DATA-49 다큐 시리즈 1건 로컬 게시 (2026-11-13)

- 원본 backend `docs/tasks/DATA-49-reviewed-documentary.md`, evidence/data49. 로컬DB에 기존다큐migration적용 후 `캐런 리드 재판` Netflix KR11/23·시즌1·documentary/series를명시검토해게시. 같은11~12월KR4OTT60→61, Netflix11월54, 연중전체매핑/이벤트63. 신규1건date_only/instantNULL. 기존62개event전체row불변확인.
- SQL·임시API200/61행/다큐상세·날짜·시즌·출처·달력확인. 재게시이벤트63/신규변경이력1유지. Node24추적CJS+ESM154/154(working tree검사,기존미추적제외). 런타임코드/계약/migration파일/앱변경없음. 공식KR날짜는11/12저장관측,오늘공식Tudum·title에서시리즈형식/날짜재대조.
- DATA-48 secret-rule환경변수참조1탐지·SKIPPED/ERROR는미해결그대로, 신규독립runner/실폰/클라우드/OS격리미실행. 다음: 다른OTT공식근거확대/PAW정체성/날짜의미검토·독립finding검토. 기존개인dirty보존,담당해제.

## DATA-48 기록 검산·Node24 고정소스·다큐 지원 (2026-11-13)

- 원본 backend `docs/tasks/DATA-48-ott-support-alignment.md`, evidence/data48. 실제KR11~12월4OTT60건/고정매핑62건 재검산, 신규게시0. 사용자 영화·시리즈·예능·다큐 확정에 따라 product/검토형태/정규화/새migration/API분류/iOS다큐배지 구현. 실제개발DB migration/다큐후보게시 미실행.
- 검증기 ESM누락·가상수집smoke설정 수정, 계약manifest/소비자참조/options버전 동기화(draft.4). Node24 고정HEAD 서버154/154, verifier109/109, unsigned iOS/임시DB migration·반복수집/API/다큐DDL12경계/Swift해석 성공. 검사HEAD·digest는원본카드. 기존dirty포함 Node22결과와 구분.
- 최종runner ERROR/exit3: secret-check가 실제키가 아닌runtime 환경변수참조1건을탐지(판정유지), 필수4항목SKIPPED/독립review대기/acceptance미승인. 독립PASS·OS격리·클라우드·최신실폰관찰 아님. 다음은literal규칙검토와로컬migration후다큐검토게시, 다른OTT공식근거확대. 기존개인dirty보존, 담당해제.

## 읽는 순서와 작업 경계

1. AGENTS.md, app docs/system/status.md, docs/system/handoff.md.
2. 이 문서, backend docs/tasks/DATA-50-official-gap-review.md, DATA-49-reviewed-documentary.md.
3. 이전 근거가 필요하면 DATA-46-netflix-search-disambiguation.md, DATA-45-netflix-official-identities.md, DATA-43-netflix-reviewed-batch.md, DATA-44-netflix-review-backlog.md.

DATA-47 시작 기준: app `81d1d20` / backend `f7480e4` / verifier `b3c9721`. 작업 브랜치는 세 곳 모두 `codex/data47-netflix-official-recovery`다. 현재 HEAD는 각 저장소에서 다시 조회한다. 기존 app 개인 signing pbxproj, backend .env.example/package.json과 audit 관련 미추적 4개 파일은 보존했다. 공통 status/handoff 원본은 app이고 backend/verifier 사본을 동일하게 유지한다. 동시 작업은 별도 브랜치/worktree로 분리한다.

## 최신 실제 결과 · DATA-47 (2026-11-13)

- 과거 공식 상세 실패16개 원URL을 재조회한 웹 도구는 모두 실패했지만, 공개 브라우저에서는12개가 실제 콘텐츠 페이지로 redirect됐고4개는NSES-404였다. 별도 공식 도움말로3개 게임을 확인했다. 로그인·재생 클릭·계정 변경 없이 화면 제목/장르/URL만 읽었다.
- 일반 시리즈·예능·다큐8건의TMDB 대조에서 단일 시즌날짜 일치6/차이2를 확인했다. 드라마4건은 공식 배우 최소2명·국가까지 일치했다. 처음6개 검토 중documentary가 게시 스키마에서 거부됐고 후보state/매핑 보존을 확인한 뒤 지원되는5개만 게시했다.
- 신규5건: 스타 & 웨딩: 아넬레와 버자11/13, 머더 인 갈리시아11/13, 발렌치나의 열두 별자리11/18, 로 오브 비스트11/18,24시간 온콜11/26. 모두 실제확인된시즌1/date_only/instant_at=NULL이다.
- 같은11~12월/KR/4OTT/ott_reviewed 로컬 범위 **55→60건(+5)**, Netflix11월53건, 연중전체 고정매핑/이벤트62건. SQL·임시API200/60행/신규5ID 확인 후 임시API종료. 재게시이벤트62/신규변경이력5 유지. Node22 전체154/154(기존dirty포함) 통과, 권장Node24/독립검증/클라우드/실폰 미실행이다.
- 16건 최종 결과는5게시/1게시유형미지원/2날짜차이/3게임/2영상모음집/1Volume/1레슬링/1정체성미확인이다. 과거16건 전체를 단순 조회실패로 계속 표현하지 않는다.
- 캐런 리드 재판은 공식 다큐 시리즈/첫 날짜 근거를 확보했지만 현재reviewSchema·Canonical/API ottCategory가documentary를 지원하지 않아 보류했다. 후보lineup에 분류를 저장할 수 있다는 사실과 게시 지원은 다르다. 유형을 다른 이름으로 바꾸거나 enum 하나만 늘리지 말고 제품/계약/정규화/iOS 영향을 검토한다.

## 이전 DATA-46 실측 · 2026-11-13

- 기존 검색잘림4건과 제목 미발견2건을 공식 배우·제작국가·연도로 재대조했다. 연도 제한 검색은 모두 끝까지 확인했고, 6건 결과는 날짜/정체성 일치2, 정체성 일치·날짜차이2, 상세 정체성 미확인1, 제목 미발견1이다.
- **앨런**(movie1518204, 공식 배우3명/AU,11/12)과 **고르돈**(tv340280, 공식 배우3명/AR,시즌1,11/18)을 수동 검토·로컬 게시했다. 한국 날짜는 DATA-43의 공식 KR 목록 관측을 유지했고, 해외 보도자료만으로 생성하지 않았다.
- 같은11~12월/KR/4개OTT/ott_reviewed 로컬 범위 **53→55건(+2)**, Netflix11월48건, 연중 전체 고정 매핑/이벤트57건이다. 신규2건은date_only/instant_at=NULL, 시즌null/1이다.
- SQL과 임시 로컬API(HTTP200/55행/신규2ID) 확인 후 임시API를 종료했다. 재게시 전후 이벤트57/신규2건의변경이력2로 동일했다. Node22.22.3 작성자 검사154/154 통과(기존dirty포함), 권장Node24/독립검증/실폰/클라우드 미실행이다.
- My Best Friend의 미국 동명작과 The Child의 라트비아 동명작을 배우/국가로 배제했다. 맞는 브라질/스페인 작품을 찾았지만 각각TMDB09/03 vsKR11/02, TMDB11/13 vsKR11/27이라 게시하지 않았다.
- Nate Bargatze 후보1824177은 상세 날짜·출연진이 비어 있어 보류했다. Mike Ward: Modest는 연도 제한/해제 검색에서 정확한 제목을 찾지 못했다. 과거4건을 더 이상 검색잘림 상태로 표시하지 않는다.

## 이전 DATA-45 실측 · 2026-11-12

- DATA-45에서 로컬 PostgreSQL의 **2026년 11~12월 KR 4개 OTT 일정 42→53건(+11)**을 실제 SQL로 확인했다. Netflix 11월은35→46건, 연중 전체 ott_reviewed 고정 매핑/이벤트는44→55건이다. 신규11건은 영화·예능·시리즈로 검토한 작품이며 시리즈 시즌은 실제 확인된1, 영화·단독 스페셜은null을 보존했다. 모두 date_only이고 instant_at은NULL이다.
- 임시 로컬 API의 GET /v1/events 기간 조회는HTTP200/53행이며 신규11개ID가 모두 포함됐다. 검사 후 임시API를 종료했다. 기존 서버·iPhone 설치는 변경하지 않았다.
- 같은55개 매핑을 다시 게시해도 이벤트55건/신규11건의 변경 이력11건으로 동일했다. Node22.22.3 전체 작성자 검사149/149 통과(기존 dirty 포함 working tree). 권장Node24, 독립 verifier, 클라우드, iPhone 신규 표시 확인은 미실행이다.

## DATA-44의44건을 어떻게 이어받았는가

- 공식 Netflix 한국 월간 목록75건 중 기존 TMDB 날짜 단일 매칭31건을 제외한44건이 DATA-44 조사 대상이었다. 당시 한국어 검색 미발견33건, 후보 날짜 이전10건, 이후1건이다. 이는 실제 미게시 수가 아니다.
- 이번에는44개 videoID의 공식 상세를 모두 조회 시도했다. 영문 표시명·형식 확인28건, 웹 도구 fetch 실패16건이다. 미발견33건 중22건, 날짜차이11건 중6건에서 상세를 확인했다. fetch 실패는 Netflix에 작품이 없다는 뜻이 아니다.
- 공식 상세의 영문 제목을 videoID와 묶어 TMDB를 재조회했다. 목록 title2는 시즌/부제일 수 있어 원제로 쓰지 않는다. 상세에서 다른 국가로 redirect되더라도 한국 날짜는 공식KR목록에서만 가져온다. JSON-LD dateCreated/startDate나 예고편 시즌을 한국 첫 공개일로 대입하지 않는다.
- 상세 확인28건 중 NFL 생중계1건은 OTT 신작 게시 대상에서 제외했다. 나머지27건의 TMDB 재조회는 날짜 일치14, 날짜 차이11, 제목 미발견2다. 날짜 일치14 중 기존 알리시아의 법1건과 검색잘림 Allen/Gordon2건을 제외한11건을 작성자 수동 검토·게시했다. 보고서 자체는 자동 게시하지 않는다.
- 알리시아의 법은 videoID82013595→시리즈82013594, 공식 시즌1/TVSeries와 TMDB tv338562 시즌1 11/11이 일치해 기존 시즌1 검토를 재확인했다. 중복 게시하지 않았다.
- 오버액션 갱은 공식KR11/05, 가능한 사랑은11/06을 유지한다. TMDB 극장/해외 날짜로 덮어쓰지 않는다. 날짜 차이가 있는 작품을 이번에 신규 게시하지 않았다.

## 다음 작업 순서 (DATA-50 이후)

1. 세 저장소 HEAD/dirty와 후보state/로컬DB를 확인하고 같은KR/11~12월/provider/4서비스61건을기준으로진행한다. 개인설정·미추적도구를보존한다.
2. 다큐지원설계(DATA-48)와로컬migration/캐런리드검토·게시(DATA-49)는완료했다. 다른OTT공식한국최초공개근거를확대하고충분한경우에만추가review→고정mapping→게시→SQL/API/멱등성확인한다. secret룰runtime참조탐지검토/독립필수검사는별도미완료다.
3. **PAW Patrol: The Game**은 DATA-50에서 공식게임route와AppStore ID로정확히게임식별완료. OTT첫공개에서제외하며 Academy와합치지않는다. 같은정체성조사를반복하지말고 새TVING5개미정후보의정확한일자를확보한다. ABCmouse/Thomas & Friends: Whistle & Go/Bad Dinosaurs는 공식 도움말상 게임이다. KPop2개는영상모음집, Sesame Volume4는시즌4 근거가 아니며 WWE는레슬링 묶음이므로 OTT첫공개로 자동 게시하지 않는다.
4. **이런, 북극!**은KR11/05 vsTMDB시즌2 09/08, **필리핀의 크리스마스 선물**은KR11/26 vsTMDB시즌1 12/03 차이가 남았다. 다른 날짜차이 건도 한국첫제공일/입점일/극장·해외방영일을 분리한다. arrival 유형은별도ADR/계약/migration/iOS 검토가 필요하다.
5. TVING/Disney+/Coupang 한국 공식 원천을 확대하고 근거가 있는 후보만review→고정mapping→로컬publish→SQL/API/멱등성 확인한다. Mike Ward 대체제목과 Nate 상세날짜/출연진은 새 공식 근거나 원천갱신이 있을 때 재조회한다. 클라우드·실폰·독립 검증은 실제 실행 전에 완료로 표현하지 않는다.

StreamPick 참고11건은 일치7/공식 날짜 차이1/한국OTT날짜 미확인3 상태다. 미확인3은 전지적 집착 시점(TVING11/08), 문무(Netflix11/14), 나인 투 식스(Netflix11/25)다. 방송 시작일만으로 해당OTT 제공일을 확정하지 않는다. 참고 달력885이벤트(회차849+신작36)와 GODIEOR 첫 공개/입점 건수를 같은 모수로 비교하지 않는다.

## 재현 파일과 명령

backend 원본:

- docs/tasks/DATA-47-netflix-official-recovery.md:16건 복구·분류·5건 게시·다큐 유형 거부·실제 명령/digest.
- data/reference/netflix-official-recovery-2026-11-13.json:공식 브라우저redirect/형식·게임도움말·보류 근거.
- data/reference/netflix-official-recovery-tmdb-2026-11-13.json:8건실조회,4건추가배우/국가 대조 입력과결과.
- data/curated/netflix-kr-reviewed-recovered-2026-11-13.json:5개수동review·고정mapping, 유형미지원1개blockedItems. DATA-47 당시전체는62개이며 현재63개다.
- data/reference/netflix-official-recovery-publication-evidence-2026-11-13.json:16건최종상태·preflight거부·SQL/API/재게시작성자증거.
- docs/reviewed-publish.md:후보 분류와 게시 지원 유형의 차이. verifier/docs/learning/entries/0011-reviewed-candidates-to-events.md에구현담당관측연결.

이전 DATA-46/45 파일은 관측·재현 경로로 보존한다:

- docs/tasks/DATA-46-netflix-search-disambiguation.md:6건의 조사·보류 사유,2건 게시, 실제 명령과고정digest.
- scripts/disambiguate-netflix-tmdb.mjs / tests/netflix-disambiguation.test.mjs:공식 배우·국가·완료한 검색·상세/시즌 날짜 대조, 자동 게시 없음.
- data/reference/netflix-disambiguation-input-2026-11-13.json 및 netflix-disambiguation-report-2026-11-13.json:공식 사실과 실TMDB보고서.
- data/curated/netflix-kr-reviewed-disambiguated-2026-11-13.json:신규2건의수동review·고정mapping. DATA-46 당시전체57개였으며 현재 ott-reviewed-mappings.json은63개다.
- data/reference/netflix-disambiguation-publication-evidence-2026-11-13.json:작성자SQL/API/멱등성증거.

아래 DATA-45 파일은 이전 관측·복원 경로로 보존한다:

- docs/tasks/DATA-45-netflix-official-identities.md:44건 조사표,11건 게시표, 실제 명령·검사·digest.
- data/reference/netflix-official-identities-2026-11-12.json:공식ID에 묶인 수동 상세 관측. 영문 표시명은 제작 원제라는 뜻이 아니다.
- scripts/enrich-netflix-identity-aliases.mjs 및 tests/netflix-identity-aliases.test.mjs:영문 별칭의 읽기 전용 TMDB대조, 합성 경계 검사.
- data/reference/netflix-identity-tmdb-crosscheck-2026-11-12.json:실TMDB관측(오류/잘림 유지).
- data/curated/netflix-kr-reviewed-identities-2026-11-12.json:11개 수동review·TMDBID·고정mapping.
- data/curated/ott-reviewed-mappings.json:현재전체63개 고정 매핑(DATA-45때55개,DATA-46때57개,DATA-47때62개). 후보state는Git제외이므로 새 환경은 원본75개lineup bridge와 각 curated review로 복원한다.
- data/reference/netflix-identity-publication-evidence-2026-11-12.json:작성자SQL/API/재게시 증거. 독립 정답fixture·verdict가 아니다.

```sh
cd /Users/dojoohwan/workspace/godieor-backend
node --test tests/netflix-disambiguation.test.mjs
# 키가 설정된 경우에만 실행하는 읽기 전용 실조회. 출력 파일은 새 경로 사용.
node --env-file=.env scripts/disambiguate-netflix-tmdb.mjs data/reference/netflix-disambiguation-input-2026-11-13.json /private/tmp/godieor-next-disambiguation.json --live
# 로컬 DB 읽기 전용 비교:
node --env-file=.env scripts/audit-ott-published.mjs data/reference/streampick-2026-11-12-gap11.json
# 검토·고정 매핑·후보state가 준비된 경우에만 의도적으로 로컬 DB에 게시:
# node --env-file=.env dist/src/cli/publish-reviewed.js --file data/curated/ott-reviewed-mappings.json
```

권장Node는package.json engines 기준이다. DATA-47의Node22 결과를 권장Node24 검증으로 표현하지 않는다. 전체154개 검사는 기존 dirty/미추적 파일을 포함한 당시 작업 트리 기준이다.

요구사항 PROD-005/006/007/009(GD-005/006/007/009). 계약0.1.0-draft.2 digest `e2e368a3b285ab0dae7d5f1d6f497c3de28ca0c099b2da10344a0a1a857e515c`, migration집합 digest `a6009a82ea00e08cfefa5d294ed40e2f5fb30a0e6e6807bf22e3db79217bb2e7`은 DATA-47에서 재확인했고 변경하지 않았다. verifier acceptance는draft/미승인 그대로다. 새로운 독립review에는 구현 대화·작성자 판단을 정답으로 주입하지 않는다. 담당codex-data47-01은 종료 시 해제한다.
