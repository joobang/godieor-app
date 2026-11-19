# UI-05 · 일정 상세 포스터 겹침과 가독성 개선

- 요구사항 PROD-004/007/008/010, GD-004/007/008/010. 작업 카드 담당 해제. 구현 및 확인 완료. 릴리스 병합 결과는 GitHub PR, 기기 설치는 Xcode CoreDevice 결과를 기준으로 확인한다.
- 앱 base dev `4369feaecf81af60b9550d40597e22675b5b1ba5`, 고정 코드 head `644de454a760c829b24fbdb87ced93efb0b26667`, 분리 작업 브랜치 `codex/event-detail-20261119`. 기존 checkout의 충돌 및 개인 서명 설정 보존.
- 이타주의자들의 세로 포스터가 제목·일정·상태를 덮는 현상을 실제 iPhone 17 Simulator에서 재현했다. 이미지 뷰를 부모가 준 크기에 고정하고 상세 포스터 비율을 보존했다. 포스터가 없는 경우와 다운로드 실패를 구분한다.
- 요약에 작품명·일정·상태를 표시하고 공개 정보·소개·출처를 구획했다. 상세 읽기가 실패하면 선택 카드의 정보가 남고 다시 조회할 수 있다. 상세를 열 때 선택한 이벤트와 조회 설정을 함께 보관한다.
- 경계 조건은 세로 포스터, 이미지 누락·실패, 긴 제목·큰 글자, 지연·실패 및 재시도다. 날짜만 확인 표기, 이전 일정, 출처 및 가상 데이터 표시를 유지한다.

## 자체 검사 및 리뷰

- `git diff --check` 통과. `sh scripts/check-account-flow.sh` 15/15 통과.
- `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` 성공. `xcrun simctl install`·`launch` 후 11/19 이타주의자들과 영화 뱅드림! 아베 무지카 프리마 오로라 상세에서 겹침 없음, 긴 제목, 포스터 없음, 출처와 닫기 확인. 최종본 접근성 트리에서 포스터 레이블과 수정 시각 소수초 확인.
- 별도 컨텍스트 정적 리뷰의 접근성 레이블, 수정 시각 정밀도, 포스터 오류/부재 구분 지적 3건 반영. 큰 글자 실측 및 네트워크 강제 실패 재현은 미실행.
- `xcodebuild ... -destination 'generic/platform=iOS' DEVELOPMENT_TEAM=<기존 팀> CURRENT_PROJECT_VERSION=2 build`, `codesign --verify --strict` 성공. 개발 서명 로컬 설치 배포를 사용한다.

## 독립검증 인계

- verifier `25c11b798d6be80745c81e458b5b27e31cb282e5`, acceptance `0.1.0-draft`, SHA-256 `c4906283810c8b378800b67930028685a41b6a051923ea9f9415346b2d657063`. 기준과 승인 상태를 수정하지 않았다.
- `scripts/runner --execute` 최초 준비는 앱 기존 계약과 지정 backend의 manifest SHA 불일치로 exit 3. 두 번째 실행은 앱에 기록된 계약 지문과 같은 역사적 backend base/head `306889b922704555ed0311e6cf3fdc51a9020384`를 사용했다. 계약 `0.1.0-draft.5`, manifest SHA-256 `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`, migration digest `ec6966538bd599bf0dcee21ec0e0fb03a63b513ae01654d52b9e2badf5697fd7`.
- 독립 iOS unsigned 빌드 PASS. Prisma 바이너리 조회가 오프라인에서 실패해 DB/API 검사는 SKIPPED. 비밀 검사는 변경 범위 밖 고정 backend에서 3건을 보고했다. runner 전체 ERROR(exit 3). 원본 `/private/tmp/godieor-ui05-verifier-matching/report.md`. 이 결과는 운영 조합 또는 제품 승인으로 해석하지 않는다.
- 공통 상태와 인계 revision SYNC-2026-11-19-UI-05. ADR/LEARN 신규 해당 없음. 기존 API를 사용하는 SwiftUI 화면 배치 보정이다.
