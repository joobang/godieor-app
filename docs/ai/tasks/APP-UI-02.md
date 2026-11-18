# APP-UI-02 · 일정 상세 포스터 표시

- requirement ID: PROD-004 / GD-004, PROD-010 / GD-010
- 상태: 구현 완료, 실제 기기·독립 검증 대기
- 담당: codex/poster-detail-20261118, 작업 종료 시 해제
- 기준: app `origin/dev` 1eda7bf, backend 계약 0.1.0-draft.5 / manifest SHA256 `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`
- 범위: `ios/GODIEOR/ContentView.swift`, `ios/GODIEOR/PublicAPI.swift`, 작업·인계 문서
- 사용자 동작: 일정 상세에서 작품의 HTTPS 포스터와 설명을 표시. 이미지·콘텐츠 조회 실패, 포스터 미등록, EPL 등 contentId 미존재 시 안내 자리표시자 표시. 기존 일정·출처 유지.
- 예상 실패: 비어 있는 posterUrl, HTTP 이미지 링크, 이미지 네트워크 오류, 콘텐츠 404, 빠른 화면 전환.

## 구현·자체 검사

- `GET /contents/{contentId}`의 기존 `posterUrl`과 `synopsis` 사용. 상세 이벤트의 `contentId`가 달라질 때 SwiftUI task 재조회.
- `AsyncImage` HTTPS 제한, 이미지 로드 오류 자리표시자. 콘텐츠 API 실패가 이벤트 상세 조회를 중단시키지 않음.
- `git diff --check` 통과.
- iOS Simulator unsigned 빌드 결과는 실행 로그에 따라 최종 기록. 실제 iPhone 시각 검증과 독립 verifier는 미실행.

## 독립 검증 handoff

- app base `1eda7bf`, head는 PR 커밋 참조. backend 코드를 변경하지 않았으므로 backend base/head 동일.
- API 계약 0.1.0-draft.5, manifest `0ffd7cbcdcb3c46b450e626ced90055e985308d728c279832aa00ec76b24e9c9`. migration 변경 없음.
- 검증 범위 app-only. 승인·verdict 수정 없음.
- 실기기에서 포스터 있는 콘텐츠와 없는 콘텐츠, 이미지 실패, 상세 출처와 날짜를 확인해야 함.
- LEARN-ID 해당 없음. 기존 콘텐츠 조회 계약을 UI에서 재사용하는 범위이며 신규 기술 결정 없음.
