


## LONG TIME AGO..

ORACLE 과거에는 패스워드가 알려진 기본 계정으로 로그인되서 해킹당하는 해킹사고가 존재했다.

현재는 대부분의 계정은 로그인 안되돌고 잠겨있고, 로그인이 되는 계정은 패스워드를 변경하도록 하고 있다.

하지만 실제 존재하는 ORACLE DB에서 간혹 유명한 ID/PASS 조합로 로그인되는 취약점을 남겨두는 경우가 있다.

- [password oracle inurl:github]()


## 2. MS-SQL (SQL SERVER)

#### SA (sysadmin)
- 비밀번호가 없거나 취약한 경우
- 최근에는 기본적으로 패스워드가 강력하거나 아예 sa 계정이 비활성화되어 있음


**MS-SQL 인증방식**
- 1. WINDOWS 인증: 윈도우에 인증된 사용자/그룹만 MSSQL 접근 허용
- 2. 혼합 인증 : WINDOWS + MS-SQL 자체 계정 인증도 활성
	- 외부 로그인이 편함


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


**불필요한 계정, 권한 최소화**
- 불필요한 계정은 삭제, 사용자/애플리케이션 별로 다른 계정 사용
	- 다른 계정을 사용해야 문제 발생시 추적이 쉽고, 계정 별 권한 분리가 가능하다.
- SHUTDOWN_PRIV : 서버 종료
- PROCESS_PRIV : 실행 중 프로세스 명령 / 조회
- FILE_PRIV : 서버에서 파일 읽기 / 쓰기
	- LOAD_FILE / INTO OUTFILE - 파일 유출이나 악성코드 제작
- 다른 세션의 쿼리, 정보 노출, 시스템 종료로 DOS 공격


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

