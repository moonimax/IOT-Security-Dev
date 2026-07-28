

---

## LONG TIME AGO..

ORACLE 과거에는 패스워드가 알려진 기본 계정으로 로그인되서 해킹당하는 해킹사고가 존재했다.

현재는 대부분의 계정은 로그인 안되돌고 잠겨있고, 로그인이 되는 계정은 패스워드를 변경하도록 하고 있다.

하지만 실제 존재하는 ORACLE DB에서 간혹 유명한 ID/PASS 조합로 로그인되는 취약점을 남겨두는 경우가 있다.

- [password oracle inurl:github]()


---
## 2. MS-SQL (SQL SERVER)

#### SA (sysadmin)
- 비밀번호가 없거나 취약한 경우
- 최근에는 기본적으로 패스워드가 강력하거나 아예 sa 계정이 비활성화되어 있음


**MS-SQL 인증방식**
- 1. WINDOWS 인증: 윈도우에 인증된 사용자/그룹만 MSSQL 접근 허용
- 2. 혼합 인증 : WINDOWS + MS-SQL 자체 계정 인증도 활성
	- 외부 로그인이 편함


---

**보안 준수**
1. 패스워드를 강력하게 설정해야 한다.
2. root는 공격의 1순위 표적이므로 이름 변경을 권장한다.

```
전통적인 루트 이름 변경 방식
-  MYSQL -u root -p
- use mysql;
- UPDATE user SET user='abcdadm' WHERE user = 'root'
- FLUSH PRIVILEGES;

```
3. 하지만 최근 추세에 의하면 시스템, 시스템 베이스 설정 값을 직접 변경하는 것을 권장하지 않음


취약한 패스워드 3개 조합으로 8글자..?

```
ALTER USER 'abcdadm'@'localhost' IDENTIFIED WITH mysql_native_password BY 'qwer1234';

ALTER USER 'abcdadm'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'St0ng!Passw0rd#2026'

```


---


**불필요한 계정, 권한 최소화**
- 불필요한 계정은 삭제, 사용자/애플리케이션 별로 다른 계정 사용
	- 다른 계정을 사용해야 문제 발생시 추적이 쉽고, 계정 별 권한 분리가 가능하다.
- SHUTDOWN_PRIV : 서버 종료
- PROCESS_PRIV : 실행 중 프로세스 명령 / 조회
- FILE_PRIV : 서버에서 파일 읽기 / 쓰기
	- LOAD_FILE / INTO OUTFILE - 파일 유출이나 악성코드 제작
- 다른 세션의 쿼리, 정보 노출, 시스템 종료로 DOS 공격



---

**위험한 권한 확인**

```
  MariaDB [mysql]> SELECT host,user,file_priv,process_priv,shutdown_priv FROM user;
+-----------+-------------+-----------+--------------+---------------+
| Host      | User        | File_priv | Process_priv | Shutdown_priv |
+-----------+-------------+-----------+--------------+---------------+
| localhost | mariadb.sys | N         | N            | N             |
| localhost | abcdadm     | Y         | Y            | Y             |
| localhost | mysql       | Y         | Y            | Y             |
| 192.168.% | test        | Y         | Y            | Y             |
| localhost | user0       | N         | N            | N             |
+-----------+-------------+-----------+--------------+---------------+

```


---

**특정 권한 제거하기**
```
UPDATE mysql.user
-> SET file_priv = 'N'; process_priv = 'N';, shutdown_priv = 'N';
WHERE user = 'root';
FLUSH PRIVILEGES;

// 이 방식은 권장되지 않음
---------------------------------------------
REVOKE FILE, PROCESS, SHUTDOWN ON *.* FROM 'root'@'localhost';

// 위 방식으로 권한 회수로 방지할 수 있음
```



---


**웹 기반 DB 관리도구 노출**
- root / apmsetup

보안 대책
1. 관리 도구는 안사용하는 걸 권장. 굳이 사용한다면 절대로 외부에 노출하지 말고 필요하다면 내부망/VPN/화이트리스트 방식
2. 비밀번호 강력하게 + 2중 인증
3. 기본 credential(root/apmsetup) 는 쓰지말자



---


**운영체제 보안과 파일 접근 제어**
- DB 데이터 파일에 대한 OS 수준 접근 제어를 생각해보자.
	- mysqld.cnf
		- 640보다 권한이 많이 부여되었으면 취약
	- ```
	  [user@localhost ~]$ ls -ld /var/lib/mysql
drwxr-xr-x. 7 mysql mysql 4096 Jul 28 10:12 /var/lib/mysql

	  ```
	- ls -ld /var/lib/mysql
		- 권한이 755로 설정되어 있어 취약하다고 판단
	- grep mysql /etc/passwd
		- mysql:x:27:27:MySQL Server:/var/lib/mysql:/sbin/nologin
		- ~ /nologin을 통해 일반적으로 계정 접근이 막힘


---


**네트워크 접근 제어**

- 1. 원칙 : DB에는 DB관리자, 개발자, 웹 서버(WAS)만 접속가능해야 한다.

- 2. 네트워크 보안 장비
	- 방화벽 -> IP, 포트 단위 차단
	- DB 접근제어 솔루션 : 접속 ip, 사용자 인증 정보, 클라이언트 프로그램, 접근대상 DB 객체

- 3. DB 객체
	- 종합적으로 고려해서 세밀하게 접근 제어 솔루션.

4. Proxy 방식
	1. 설명 보충 필요
	


---

DB 설정 기반 접근 제어
![](../Images/Pasted%20image%2020260728143954.png)
- 192.168.63.1
- CREATE USER 'webapp'@'192.168.63.1' IDENTIFIED BY 'str0ng!Pass#2026'
- GRANT, SELECT, INSERT,UPDATE,DELETE ON schoo_db.* TO 'webapp'@'192.168.63.1';
- SELECT user, host FROM mysql.user;



2. 취약점 점검하는 sql -> plugin이 mysql_native_password인 데이터 조회
3. 행위 기반 모니터링(이상 행위 탐지)
	1. 비정상 접속, 쿼리 행위를 탐지하고 차단.
	2. 평소와 다른 접속 패턴, 평소와 다른 쿼리 패턴
	3. 대량으로 데이터 덤프 등등 특이사항을 탐지하는 것을 행위기반 모니터링
4. 버전 관리
	1. 항상 취약점이 없는 최신 버전을 사용해야 한다.(EOL)
	2. EOL은 8.4나 9버전 사용을 권장




---

## 애플리케이션 보안
- inc, conf, xml, env 등등 보안 파일
- github에 올리면 안된다. 소스코드 관리
- id 값을 credential 값을 하드코딩이 아닌 별도 시크릿관리도구로 관리하거나 환경변수로 관리
-> hashicorp vault , AWS secrets Manager 등


```
MariaDB [(none)]> SHOW SESSION STATUS LIKE 'ssl_%'
    -> ;
+--------------------------------+-------+
| Variable_name                  | Value |
+--------------------------------+-------+
| Ssl_accept_renegotiates        | 0     |
| Ssl_accepts                    | 0     |
| Ssl_callback_cache_hits        | 0     |
| Ssl_cipher                     |       |
| Ssl_cipher_list                |       |
| Ssl_client_connects            | 0     |
| Ssl_connect_renegotiates       | 0     |
| Ssl_ctx_verify_depth           | 0     |
| Ssl_ctx_verify_mode            | 0     |
| Ssl_default_timeout            | 0     |
| Ssl_finished_accepts           | 0     |
| Ssl_finished_connects          | 0     |
| Ssl_server_not_after           |       |
| Ssl_server_not_before          |       |
| Ssl_session_cache_hits         | 0     |
| Ssl_session_cache_misses       | 0     |
| Ssl_session_cache_mode         | NONE  |
| Ssl_session_cache_overflows    | 0     |
| Ssl_session_cache_size         | 0     |
| Ssl_session_cache_timeouts     | 0     |
| Ssl_sessions_reused            | 0     |
| Ssl_used_session_cache_entries | 0     |
| Ssl_verify_depth               | 0     |
| Ssl_verify_mode                | 0     |
| Ssl_version                    |       |
+--------------------------------+-------+

// Ssl_version, Ssl_cipher 빈 값
// TLS 1.3 이상 암호


```