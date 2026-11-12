# GODIEOR OTT 수집·게시 인계 · 2026-11-12 (DATA-45 반영)

## 읽는 순서와 작업 경계

1. AGENTS.md, app docs/system/status.md, docs/system/handoff.md.
2. 이 문서, backend docs/tasks/DATA-45-netflix-official-identities.md.
3. 이전 근거가 필요하면 DATA-43-netflix-reviewed-batch.md, DATA-44-netflix-review-backlog.md.

DATA-45 시작 기준: app `ed5453c` / backend `fd76c95` / verifier `91dfc9e`. 작업 브랜치는 세 곳 모두 `codex/data45-netflix-identities`다. 현재 HEAD는 각 저장소에서 다시 조회한다. 기존 app 개인 signing pbxproj, backend .env.example/package.json과 audit 관련 미추적 4개 파일은 보존했다. 공통 status/handoff 원본은 app이고 backend/verifier 사본을 동일하게 유지한다. 동시 작업은 별도 브랜치/worktree로 분리한다.

## 최신 실제 결과

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

## 다음 작업 순서

1. 세 저장소 HEAD/dirty와 후보state, 로컬 DB 준비를 확인한다. 비밀값은 출력하지 않는다. 날짜 범위와 provider 조건을 고정해53건을 재측정할 수 있다.
2. **공식 상세 실패16건**을 작품ID와 공식 접근 가능한 자료로 확인한다. 게임/보너스/회차/스포츠를 제목만으로 영화·드라마로 분류하지 않는다. www.netflix.com robots의 일반bot 제한을 확인했으므로 임의의 직접 상세 스크래핑 배치를 재개하지 않는다.
3. **TMDB 제목 미발견2건**(Mike Ward: Modest, Nate Bargatze: Good For Nathan)은 공식 제목 변형과 대체 제목을 확인한다. **검색잘림4건**(My Best Friend, Allen, Gordon, The Child)은 연도·배우·제작국가로 정체성을 좁힌다. 후보 날짜가 같다는 이유로 자동 승인하지 않는다.
4. **날짜 차이11건**은 같은 작품/시즌인지 먼저 확인하고 한국 플랫폼 첫 제공일과 극장/해외방송 날짜를 구분한다. arrival 유형 분리는ADR/API/migration/iOS 영향을 검토한 뒤 별도 구현한다.
5. 공식 근거를 검토한 후보만 review→고정 mapping→로컬 publish하고 전후 SQL/API·멱등성을 확인한다. TVING/Disney+/Coupang 공식 원천 확대도 남아 있다. 클라우드·실폰·독립 검증은 실제 실행 전 완료로 표현하지 않는다.

StreamPick 참고11건은 일치7/공식 날짜 차이1/한국OTT날짜 미확인3 상태다. 미확인3은 전지적 집착 시점(TVING11/08), 문무(Netflix11/14), 나인 투 식스(Netflix11/25)다. 방송 시작일만으로 해당OTT 제공일을 확정하지 않는다. 참고 달력885이벤트(회차849+신작36)와 GODIEOR 첫 공개/입점 건수를 같은 모수로 비교하지 않는다.

## 재현 파일과 명령

backend 원본:

- docs/tasks/DATA-45-netflix-official-identities.md:44건 조사표,11건 게시표, 실제 명령·검사·digest.
- data/reference/netflix-official-identities-2026-11-12.json:공식ID에 묶인 수동 상세 관측. 영문 표시명은 제작 원제라는 뜻이 아니다.
- scripts/enrich-netflix-identity-aliases.mjs 및 tests/netflix-identity-aliases.test.mjs:영문 별칭의 읽기 전용 TMDB대조, 합성 경계 검사.
- data/reference/netflix-identity-tmdb-crosscheck-2026-11-12.json:실TMDB관측(오류/잘림 유지).
- data/curated/netflix-kr-reviewed-identities-2026-11-12.json:11개 수동review·TMDBID·고정mapping.
- data/curated/ott-reviewed-mappings.json:전체55개 고정 매핑. 후보state는Git제외이므로 새 환경은 원본75개lineup bridge와 각 curated review로 복원한다.
- data/reference/netflix-identity-publication-evidence-2026-11-12.json:작성자SQL/API/재게시 증거. 독립 정답fixture·verdict가 아니다.

```sh
cd /Users/dojoohwan/workspace/godieor-backend
node --test tests/netflix-identity-aliases.test.mjs
# 키가 설정된 경우에만 실행하는 읽기 전용 실조회. 출력 파일은 새 경로 사용.
node --env-file=.env scripts/enrich-netflix-identity-aliases.mjs data/reference/netflix-official-identities-2026-11-12.json /private/tmp/godieor-next-identity-crosscheck.json --live
# 로컬 DB 읽기 전용 비교:
node --env-file=.env scripts/audit-ott-published.mjs data/reference/streampick-2026-11-12-gap11.json
# 검토·고정 매핑·후보state가 준비된 경우에만 의도적으로 로컬 DB에 게시:
# node --env-file=.env dist/src/cli/publish-reviewed.js --file data/curated/ott-reviewed-mappings.json
```

권장Node는package.json engines 기준이다. DATA-45의Node22 결과를 권장Node24 검증으로 표현하지 않는다. 전체149개 검사는 기존 dirty/미추적 파일을 포함한 당시 작업 트리 기준이다.

요구사항 PROD-005/006/007/009(GD-005/006/007/009). 계약0.1.0-draft.2 digest `e2e368a3b285ab0dae7d5f1d6f497c3de28ca0c099b2da10344a0a1a857e515c`, migration집합 digest `a6009a82ea00e08cfefa5d294ed40e2f5fb30a0e6e6807bf22e3db79217bb2e7`은 DATA-45에서 재확인했고 변경하지 않았다. verifier acceptance는draft/미승인 그대로다. 새로운 독립review에는 구현 대화·작성자 판단을 정답으로 주입하지 않는다. 담당codex-data45-01은 종료 시 해제한다.
