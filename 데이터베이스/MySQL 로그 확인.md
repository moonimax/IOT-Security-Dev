
---

### 감사 로깅(Audit Logging)

- 클라우드 취약점 점검 가이드에서 다루는 항목
- General log 확인
- Slow log 확인

### MySQL 로그 종류

- **mysqld.log**
    - 서버 기동, 정지, 오류, 접속 실패 기록
    - 실행 시 자동으로 켜짐
- **general_log**
    - 일반 쿼리 로그, SQL문 전수 기록
    - 성능에 영향 있고, SQL 평문 노출로 보안에 취약
- **slow_query_log**
    - `long_query_time` 기준으로 처리량이 많거나 응답이 느린 쿼리 기록
    - 저부하라 성능에 미치는 영향은 미미
- **감사 로그 (audit plugin)**
    - 강력 추천되는 방식
- **에러 로그**