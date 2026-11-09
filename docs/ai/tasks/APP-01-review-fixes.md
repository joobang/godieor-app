# APP-01H · 독립 리뷰 수정과 UI 확인
- 상태: 진행. 담당 codex-app-review-fixes.
- 요구사항: GD-001/004/008 (초안). base app 0493cf8, backend 24899cb, verifier ac671df.
- 범위: 독립 리뷰(IR-001~003) 수정, iOS 빌드 및 날짜→목록→상세/필터 UI 확인.
- 실패 사례: 최신 상세 상태와 목록 상태 불일치, EPL 개최국 누락, 오래된 revision 응답 덮어쓰기.
- LEARN-ID: 후속 기록 연결 예정. 독립 승인/통합 PASS는 이 작업에 포함하지 않는다.

## 결과
- 독립 reviewer Godel(01a1bf0c-b63f-7413-bca2-bf2503fc400f), fork_context=false: 구현 대화/작업 카드/학습 기록 없이 고정 app e98e863→f36adb7 및 backend85ea4f3 계약 검토. IR-001 최신 상세 상태 미반영(high), IR-002 EPL 개최국 누락(medium), IR-003 이전 revision 날짜 응답 덮어쓰기(medium) 보고. 모두 수정.
- 수정 도중 발견된 IR-004(월 재시도 UUID 무효화 시 로딩 정체)는 무효화 제거로 수정. 최종 dirty diff 별도 정적 재검토: 추가 확정 오류 없음. reviewer 실행은 diff/check, 실제 UI/DB/지연 주입 실행 아님.
- 작성자: scripts/build-ios.sh 두 번 최종 BUILD SUCCEEDED; git diff --check 통과.
- CUA Simulator: 2026-11-18(1건) 클릭→비엔나 게임 목록→상세(날짜만 확인, 예정, KR, disney_plus, 출처) 확인. 닫기→OTT 해제→동일 날짜0건, 프로세스 terminate/launch 후0건 유지→OTT 복원 후1건 확인. 이 값은 관찰값이며 독립 fixture 정답이 아니다.
- 기본 sandbox simctl 연결 오류는 escalated 실행으로 우회. 첫 launch는 bundle ID 오기로 실패 후 com.joobang.godieor로 성공. 로컬 Node24.19.0으로 기존 backend dist 재실행, 기존 DB 유지. 이 작업이 시작한 API process PID45665.
- 미실행: 취소/연기 서버 변경, EPL 개최국 실제 UI, 409/응답 지연 주입, DST/전국가 전수 UI. 일반 탐색은 수정 최초 빌드에서 수행; 최종 UUID 한 줄 수정 후 빌드 재확인, 동일 탐색 반복하지 않음.
- 상태: 구현 수정·작성자 UI 점검·독립 정적 재검토 완료. 담당 해제. acceptance draft 유지, 통합 PASS 아님.
- 학습: LEARN-0012, verifier/docs/learning/entries/0012-detail-and-request-revision.md. 다음 VFY-01 요구사항 관찰점 정리 후 기존 VFY-02 evidence v2 진행(VFY-05 신설 불필요).
