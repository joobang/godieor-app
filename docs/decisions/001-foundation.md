# ADR-001 · 무료 우선 개발 환경

상태: **초기 제안 기록**. 2026-11-09 사용자가 NestJS + PostgreSQL과 TypeORM 제외를 선택했다.
아래 Workers/D1·Wrangler 항목은 현재 선택이 아닌 이전 제안이다. 현행 P02는 `../system/policies.md`를 따른다.
iOS·네 분야 연동·무료 우선 목표는 사용자 확정이며 나머지 선택은 각 정책 상태를 따른다.
2026-11-09 정리: backend의 실행 환경·API·DB·수집은 `godieor-backend`가 소유한다.
이 문서는 초기 환경 제안을 보존하며, 현재 미정 정책과 세 저장소 책임은 `../system/`에서 관리한다.
공식 문서 확인일: 2026-11-06 KST. 가입·결제·원격 DB 생성·배포는 수행하지 않았다.

| 영역 | 초기 선택 제안 | 비용/제약 |
|---|---|---|
| iOS | SwiftUI, iOS 17+, Xcode | 설치된 Mac/Xcode로 로컬 개발. UIKit/크로스플랫폼 의존성 없이 시작 |
| 기기 설정 | UserDefaults의 Codable 설정 | 로그인 없는 필터 설정. 비밀 저장용으로 사용하지 않음 |
| 일정 로컬 캐시 | SwiftData 검토 | 필요한 시점에 도입. 원격 DB를 대체하는 동기화 서비스는 아님 |
| 로컬 API·DB | Wrangler 로컬 실행 + 로컬 D1(SQLite 기반) | 계정 연결 없이 로컬 개발부터. 비밀은 gitignore된 `.dev.vars` |
| 원격 API | Cloudflare Workers Free, TypeScript | 일 100,000 요청, 요청당 CPU 10ms 제한. 가벼운 조회와 분할 수집에 적합 |
| 원격 DB | Cloudflare D1 Free | 일 500만 rows read, 10만 rows write, 계정 합산 5GB. 개별 DB는 Free 500MB 제한 |
| 독립 검증 | 별도 저장소, Python 3.9+ 표준 라이브러리 | 상시 서버·DB 불필요. 로컬 Mac에서 Xcode 검사 |
| AI 리뷰 | 별도 Codex 컨텍스트, 구조화된 결과 | 기존 사용량·계정 제한 적용. API 호출을 무료라고 가정하지 않음 |

## 선택 이유와 대안

일정 조회·정규화·캐시가 중심이므로 초기에는 SQL DB 하나와 작은 API면 충분하다.
앱의 개인 설정은 기기에 두고 서버에는 공개 일정만 둔다. API 키를 iOS에 배포하지 않는다.
이미지 자체를 수집·재호스팅하기보다 제공처가 허용하는 이미지 URL과 출처를 이용한다.

Supabase(Postgres·Auth)는 로그인/동기화가 필요해질 때 다시 비교한다.
Firebase는 인증·모바일 기능이 필요할 때 대안이다. 현재는 두 서비스의 가격이나 제약을
검증하지 않았으므로 무료 한도 우열을 주장하지 않는다. 원격 Postgres·Redis·Kubernetes는 초기 필수 요소가 아니다.

Workers CPU 제한 때문에 모든 제공처·전체 기간을 한 요청에서 수집하지 않는다.
제공처·기간을 나눠 갱신하고, 캐시를 조회한다. 인덱스 없는 전체 테이블 스캔은 D1 read 비용을 키운다.
할당량 초과 시 데이터 오류/오래된 캐시 상태를 보여주는 정책을 정한다. 유료 플랜 전환은 별도 결정한다.

## iOS 배포 비용

Simulator와 개인 기기 개발은 무료 Apple 계정으로 시작할 수 있다.
Personal Team 프로비저닝은 7일 후 갱신이 필요하다.
TestFlight·App Store 배포에는 Apple Developer Program이 필요하고, 공식 기본 가격은 연 US$99
(지역별 통화/가격 적용)다. 로컬 무료 개발과 앱 배포 비용을 구분한다.

## AI 비용 및 실행 경계

초기에는 기존 Codex 환경의 독립 채팅/에이전트로 리뷰하고 결과를 파일로 남긴다.
자동 API 리뷰는 API 비용·모델·호출 한도 확정 이후의 어댑터다.
리뷰 컨텍스트 분리는 저장소 읽기/쓰기 권한 격리와 다르다.
iOS 빌드는 Mac이 필요하므로 Docker만으로 전체 검증을 해결할 수 없다.
정식 제품 PASS 이전에 별도 macOS 실행 사용자 또는 격리된 Mac 실행기를 구성하고,
앱 원본·검증 기준 쓰기 차단과 비밀/네트워크 접근 차단을 실제로 검사한다.

## 공식 근거

- [Workers 가격](https://developers.cloudflare.com/workers/platform/pricing/), [제한](https://developers.cloudflare.com/workers/platform/limits/)
- [D1 가격](https://developers.cloudflare.com/d1/platform/pricing/), [D1 제한](https://developers.cloudflare.com/d1/platform/limits/)
- [D1 로컬 개발](https://developers.cloudflare.com/d1/best-practices/local-development/)
- [Apple 무료 계정](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Apple Developer Program](https://developer.apple.com/programs/whats-included/)
- [Codex 구조화 출력](https://learn.chatgpt.com/docs/non-interactive-mode)
- [Codex 권한·sandbox](https://learn.chatgpt.com/docs/agent-approvals-security)
