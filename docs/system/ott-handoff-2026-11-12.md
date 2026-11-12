# GODIEOR OTT 수집·게시 다음 에이전트 인계 · 2026-11-12

## 먼저 확인할 것

- `AGENTS.md` → `docs/system/status.md` → `docs/system/handoff.md` → 본 문서 → backend `docs/tasks/DATA-43-netflix-reviewed-batch.md` 및 `docs/tasks/DATA-44-netflix-review-backlog.md` 순으로 읽는다.
- 이번 인계의 관측 기준(새 작업 전 HEAD 재조회): app `1478906` / backend `772db30` / verifier `e68fbf6`, 브랜치 `codex/data44-netflix-backlog` (3곳 동일). 이 문서 커밋 이후 HEAD는 바뀌므로 실제 `git rev-parse HEAD`, `git branch --show-current`, `git status --short`를 다시 확인한다.
- 공통 상태·인계 원본은 app `docs/system/`; backend/verifier 사본은 내용 동일하게 유지. 동시 작업 시 별도 worktree/`codex/` 브랜치 사용.

## 현재까지 입증된 사실

- 2026-11-12 DATA-43 시점 로컬 PostgreSQL에서 **2026년 11~12월 KR 4개 OTT 이벤트 17→42건(+25)** 실측. 그중 Netflix 11월 10→35건. 전체 `ott_reviewed` 고정 매핑 19→44. 이것은 **로컬 DB** 결과로, Cloud/Render/Supabase/iPhone 배포 완료를 뜻하지 않는다. DATA-44에서는 DB 재조회/신규 게시가 없었다.
- Netflix 한국 공식 신규 공개 목록 `data/lineups/netflix-kr-2026-11-12-auto.json` **75건**. 저장된 TMDB 관측에서 영화 또는 해당 TV 시즌의 날짜가 일치한 단일 매칭 **31건**, 그 중 중복·기존 확인을 제외한 **25건**을 검토/게시했다. 날짜는 **한국 Netflix 등록·제공 날짜**이고 전 세계 시리즈 최초 공개나 작품의 극장 첫 개봉일과 항상 같지 않다.
- DATA-44는 남은 **44건**을 읽기 전용으로 분류: 검색 미발견 33, TMDB 후보 날짜가 Netflix 한국 날짜보다 이전 10, 이후 1. 기존 검토의 제목·플랫폼·날짜·시즌 일치 2, 시즌 추가 확인 1, 미일치 41. 이 **41은 실 DB 미게시 수가 아니다**. 작품 종류 자동 확정/게시 0.
- StreamPick 11건 참고 샘플: 기존 검증 일치 7, Netflix `오버액션 갱`은 공식 한국 공개일 **11/05**(참고 사이트 11/04), OTT 한국 공개일 미확인 **3건**(`전지적 집착 시점` TVING 11/08, `문무` Netflix 11/14, `나인 투 식스` Netflix 11/25). TMDB 방송 시작 날짜만으로 특정 OTT 한국 제공일을 확정하지 않는다.
- StreamPick 2026년 11~12월 885 이벤트는 회차 849+신작 36이다. 대상 4 OTT에서 신작 15 플랫폼행·회차 703 플랫폼행. GODIEOR 첫 공개/입점 이벤트 수와 회차 합계를 같은 모수로 비교하지 않는다.

## 다음 작업의 정확한 순서

1. **현 상태·변경 충돌 확인**: 3개 저장소 HEAD/dirty, `work/ott-candidates/state.json` 존재 여부, `.env`/PostgreSQL 접속 가능 여부 검사. 기존 개인 iOS 서명 설정, backend `.env.example`, `package.json`, 기존 감사 스크립트/테스트의 미커밋 변경을 덮어쓰지 않는다.
2. **DATA-44 44건 중 33건의 정체성 확인**: 한국 Netflix videoID로 공식 상세 페이지/원제/콘텐츠 유형·시즌을 다시 조사한다. 남은 날짜 불일치 11건은 동일 작품·시즌 여부와 Netflix **한국 서비스 등록일** vs TMDB 극장·방송일을 구분한다. `알리시아의 법` 시즌 null vs 기존 시즌 1 재대조. 자동으로 `premiereConfirmed=true`를 넣지 않는다.
3. **후보 → 검토 → 게시 연결**: 근거가 있는 작품은 플랫폼·국가·작품·시즌·날짜를 검토하고 안정적인 별도 contentKey/eventKey를 매핑한다. 중복 작품/다른 OTT 입점일을 한 이벤트로 합치지 않는다. `backend/docs/reviewed-publish.md` 및 `backend/data/curated/netflix-kr-reviewed-2026-11-12.json` 참고. 날짜만 있으면 `date_only`, 시각 추정 금지.
4. **실측하고 비교**: 게시 전후 같은 `2026-11-01 <= local_date < 2027-01-01`, `release_market='KR'`, `provider_key='ott_reviewed'`, 4개 서비스 조건으로 조회. Netflix 75개 목록 중 게시 상태, StreamPick **신작**과 회차를 따로 보고, 미일치 제목/날짜/시즌/플랫폼과 근거를 표로 기록한다. 수치가 같아도 한국 첫 제공일 근거 없이는 임의 게시 금지.
5. **출처 확대·제품 반영**: TVING/Disney+/Coupang Play 한국 공식 예정작 수집도 Netflix와 같은 원천+TMDB 방식 적용. `ott_season_premiere`와 한국 OTT 새 입점일을 명확히 분리할 데이터 모델은 ADR/API/마이그레이션/iOS 영향 검토 후 구현. 클라우드·iPhone 배포/독립 verifier 승인은 별도 실행·확인 필요.

## 재현 명령 및 파일

```sh
cd /Users/dojoohwan/workspace/godieor-backend
# 지원 Node 버전은 package.json engines 확인. DATA-44는 Node22로 자체검사 145/145 통과 기록.
node --test tests/ott-review-backlog.test.mjs
node scripts/classify-ott-review-backlog.mjs data/lineups/netflix-kr-2026-11-12-auto.json data/reference/netflix-kr-tmdb-evidence-2026-11-12.json data/reference/ott-reviewed-mapping-snapshot-2026-11-12.json /private/tmp/godieor-next-backlog.json
# 로컬 DB 및 .env가 준비된 경우에만 (읽기 전용):
node --env-file=.env scripts/audit-ott-published.mjs data/reference/streampick-2026-11-12-gap11.json
# 검토된 후보·고정 매핑이 준비된 경우, 의도적으로 로컬 DB를 변경하는 명령:
# npm run publish:reviewed -- --file data/curated/ott-reviewed-mappings.json
```

- 백엔드 원본 입력: `data/reference/netflix-kr-tmdb-evidence-2026-11-12.json`, `data/reference/ott-reviewed-mapping-snapshot-2026-11-12.json`, 분류 결과 `data/reference/netflix-kr-review-backlog-2026-11-12.json`, 구현 `scripts/classify-ott-review-backlog.mjs`, 검사 `tests/ott-review-backlog.test.mjs`.
- DATA-43 Node22 전체 테스트 **138/138**, DATA-44 Node22 전체 테스트 **145/145**는 각각 해당 당시의 작성자 검사. 이번 문서 전용 작업의 신규 DB 조회/앱 빌드/독립 검증은 수행하지 않았다.
- verifier `requirements/acceptance.yaml`은 구현자가 승인하지 않는다. API 계약 `0.1.0-draft.2` digest `e2e368a3b285ab0dae7d5f1d6f497c3de28ca0c099b2da10344a0a1a857e515c`, migration digest `a6009a82ea00e08cfefa5d294ed40e2f5fb30a0e6e6807bf22e3db79217bb2e7` (DATA-44 기준). 새 검증 전 재계산.
- 작업 기록용 요구사항: `PROD-005/006/007/009` (GD-005/006/007/009). 예상 실패: 잘못된 TMDB 동명 작품 매칭, 동일 시즌의 중복 게시, 방송 날짜를 Netflix 날짜로 오판, 서로 다른 플랫폼 이벤트 병합. ADR/LEARN 신규 없음(기존 수집 절차 인계만 수행).
