# APP-DEPLOY-01 · Render 운영 API 주소 iOS 연결

- Requirement: PROD-009/010, GD-009/010 (독립 기준 승인 변경 없음).
- 상태: 구현·자체 검사 완료, PR 제출 대기. 담당 해제.
- app base: `1ed896294a6a6430a96b66e7e16139454a0bf4bb` (`dev`, clean).
- backend 관측 HEAD: `f8b9d7486370f24b98c6e87a1e0d4e0d8339aeba` (서버 배포 SHA는 별도 확인 필요).
- verifier 관측 HEAD: `25c11b798d6be80745c81e458b5b27e31cb282e5` (clean).
- branch/worktree: `codex/ios-render-api-20261118`, `/private/tmp/godieor-ios-render-app`.
- 범위: Debug/Release 앱의 공통 공개·계정 HTTPS API 주소를 `https://godieor-backend.onrender.com/v1`로 설정.
- 예상 실패: Render Free 기동 지연, 원격 데이터 공백, 미배포된 서버 변경, iPhone 설치·Google 로그인 미확인.
- 사용자 확정: 일일 수집은 Actions에 위임하고, 배포 서버에 iOS 앱 연결 진행.
- API 계약: app `docs/api/contract-reference.json` 버전 `0.1.0-draft.5`, manifest SHA256 `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`. API 계약·migration 변경 없음. verifier acceptance/verdict 변경 없음.

## 실제 검사

| 검사 | 결과 |
|---|---|
| `xcodebuild ... -configuration Debug -sdk iphonesimulator ... CODE_SIGNING_ALLOWED=NO build` | exit 0, BUILD SUCCEEDED (CoreSimulator 런타임 경고). |
| `xcodebuild ... -configuration Release -sdk iphoneos ... CODE_SIGNING_ALLOWED=NO build` | exit 0, BUILD SUCCEEDED (CoreSimulator 런타임 경고). |
| 빌드된 Debug/Release `Info.plist`의 `GODIEORAPIBaseURL` | 둘 다 `https://godieor-backend.onrender.com/v1`. |
| Render `/v1/health` | HTTP 200, `status=ok`, `database=connected`, `dataMode=provider`. |
| Render `/v1/catalog/options` | HTTP 200, 계약 `0.1.0-draft.5`. |
| Render `/v1/calendar?month=2026-11` | HTTP 200, 날짜 30개 반환. |
| Render `/v1/events?schedule=dated&from=2026-11-01&to=2026-12-01&limit=100` | HTTP 200, 이벤트 100개와 nextCursor 반환. |
| `git diff --check` | 통과. |

- 잘못된 쿼리 `/events?from=...&to=...`는 필수 `schedule`이 빠져 HTTP 400. 올바른 파라미터 재조회 HTTP 200으로 확인.
- 실기기 설치·로그인/계정 저장·기기에서의 실제 조회 및 독립 runner/승인은 미실행. 배포된 정확한 backend SHA와 GitHub Actions 자연 스케줄 실행 여부는 미확인.
- 학습 LEARN-ID 해당 없음. 기존 HTTPS API 설정값 교체로, 새로운 기술적 문제 해결이나 설계 결정은 없음.
