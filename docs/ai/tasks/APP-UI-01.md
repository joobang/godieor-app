# APP-UI-01 · 월간 달력 가독성 및 상단 공간 개선

- Requirement ID PROD-001 / GD-001. 상세 포스터는 PROD-004 / GD-004 후속 작업.
- 상태 자체 구현·시뮬레이터 빌드 완료, 독립 검증 및 실기기 시각 검사 대기. 담당 해제.
- 담당 세션 codex/calendar-readability-20261118.
- app base `690808fc51b0fbcba9ce9916f4fcd15393ab835e` (`origin/dev`, clean), head SHA는 Git 이력에서 확인.
- backend HEAD는 이번 작업에서 재조회하지 않았다. 계약 참조의 backend SHA `46751285a88f96ac88ea719a4e5daff791d96a5a`는 배포 SHA가 아니다.
- verifier 관측 HEAD `25c11b798d6be80745c81e458b5b27e31cb282e5` (clean).
- 브랜치 `codex/calendar-readability-20261118`, 별도 worktree `/private/tmp/godieor-calendar-readability`. 원본 main checkout의 사용자 signing/API 임시 변경은 보존한다.
- 계약 `0.1.0-draft.5`, manifest SHA256 `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`. migration digest는 이번 변경에서 재계산하지 않았다.
- 변경 동작 상단 계정 영역을 계정 시트로 이동하고 월간 날짜 셀에서 일정 수와 대표 제목을 확대한다. 기존 로그아웃·동기화 작업은 시트에서 제공한다.
- 예상 실패 사례 작은 화면의 긴 한글 제목 말줄임, Dynamic Type 확대 시 달력 높이, 계정 시트와 상세 시트 동시 노출, 실제 디바이스 네트워크·계정 인증.
- 완료 범위 UI 수정, 계약 버전 검사 보정 및 unsigned simulator 컴파일. 실제 폰 배포·포스터 API 연결은 후속.

## 구현·자체 검사

| 실제 명령 | 종료 코드 | 관찰 결과 |
|---|---|---|
| `git diff --check` | 0 | 공백 오류 없음 |
| `xcodebuild -project ios/GODIEOR.xcodeproj -scheme GODIEOR -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -derivedDataPath work/DerivedData build` | 0 | `BUILD SUCCEEDED` |

## 독립 검증 handoff

- app base SHA `690808fc51b0fbcba9ce9916f4fcd15393ab835e`, head SHA는 현재 브랜치 Git 이력 참조.
- backend base/head SHA는 현 작업에서 재조회하지 않음. API 계약 `0.1.0-draft.5`, manifest digest 위 참조. migration 집합 digest는 미계측.
- 검사 범위 app-only. verifier SHA `25c11b798d6be80745c81e458b5b27e31cb282e5`, 기준 및 verdict 수정 없음.
- 외부 리뷰 입력 변경된 ContentView/PublicAPI, 원본 요구 GD-001, 원본 계약 참조 파일.
- 미실행 실기기 화면 점검·독립 runner·리뷰 및 승인.

## 다음 개발 세션 인계

- 별도 브랜치에서 개발 완료. 원본 checkout 사용자 변경은 미수정.
- 다음 단계 실제 iPhone 시각 확인과 posterUrl 제공 여부 조사, 검증 기준을 바꾸지 않고 상세 이미지 카드 연결.
- status.md와 handoff.md 갱신. 공통 정책 및 ADR 변경 없음.
- 학습 LEARN-ID 해당 없음. 기존 SwiftUI 요소의 표시 및 배치 조정과 계약 버전 상수 일치이며 새로운 기술 설계 결정은 없다.
