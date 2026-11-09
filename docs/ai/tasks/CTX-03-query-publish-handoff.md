# CTX-03 · Prisma 규칙과 검토 후보 반영 상태의 세 저장소 인계

- SYS-01/02, 담당 codex-query-04, 구현 문서 동기화 완료·담당 해제.
- 기준 app eca26d8/dev clean, backend0799404/dev clean, verifier aab266d/dev clean. 기존 checkout 순차 수정, 보조 구현은 /private/tmp 스테이징만 사용. 동일 checkout 동시 수정 없음.
- 범위: backend BE-04/DATA-02B 결과를 공통5문서 SYNC17/CONTEXT06, 생성기 공개문서 목록, 학습 기록에 반영. 앱 API 계약/코드 변경 없음.
- 실패 예상: 과거 가상전용 상태를 현재로 오인, 문서 사본 불일치, 수동 부분 publish를 자동 전수 수집으로 표현, 낡은 웹 전달본.
- 실제 backend 결과: 6aac1d3 Client 우선, 222f67f 수동 publish. 전체47개 검사/임시DB API 회귀·저장/정정/거부, 로컬 provider4+fixture7 조회 확인. 독립 승인 기준은 draft.
- LEARN-0010/0011, backend ADR-012/013. 공통 원본 app에서만 편집하고 세 사본 동일 여부/고정 계약·migration digest 불변/웹 전달본 최신 여부를 종료 시 확인한다.
- 다음: APP-01 iOS 공개 API/캘린더·상세 + 독립 VFY 통합 검증. Google/개인 쓰기는 세션 설계 후. push/배포 없음.

실제 종료 검사: 공통5문서3사본 byte 일치, git diff --check 통과. 계약 문서/manifest·Prisma/migration 해시 고정본과 일치. package-lock의 계약pin 차이는 이번 시작HEAD부터 존재함을 확인하여 backend 카드/공통status에 기록했다. app export-context.py는 새 문서 포함57개 출처 생성 성공; 최종 커밋 후 재생성/--check 수행한다.
