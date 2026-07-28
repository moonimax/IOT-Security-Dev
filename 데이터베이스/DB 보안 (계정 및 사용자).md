

---

## 1. Oracle - LONG TIME AGO..

- ORACLE 과거에는 패스워드가 알려진 기본 계정으로 로그인되서 해킹당하는 해킹사고가 존재했다.

- 현재는 대부분의 계정은 로그인 안되게 잠겨있고, 로그인이 되는 계정은 패스워드를 변경하도록 하고 있다.

- 하지만 실제 존재하는 ORACLE DB에서 간혹 유명한 ID/PASS 조합로 로그인되는 취약점을 남겨두는 경우가 있다.

- 참고 검색 : [password oracle inurl:github]()


---
## 2. MS-SQL (SQL SERVER)

#### SA (sysadmin) 계정
- 비밀번호가 없거나 취약한 경우가 위험 요인
- 최근에는 기본적으로 패스워드가 강력하거나 아예 'sa' 계정이 비활성화된 경우가 많음


**MS-SQL 인증방식**
- 1. **WINDOWS** 인증: 윈도우에 인증된 사용자/그룹만 MSSQL 접근 허용
- 2. **혼합 인증** : WINDOWS + MS-SQL 자체 계정 인증 모두 활성 (외부 로그인이 편함)


---

## 3. 계정 보안 준수 사항
1. 패스워드를 강력하게 설정해야 한다.
2. 'root'는 공격의 1순위 표적이므로 **이름 변경을 권장**한다.

#### 전통적인 root 이름 변경 방식
```sql
mysql -u root -p
USE mysql;
UPDATE user SET user='abcdadm' WHERE user = 'root';
FLUSH PRIVILEGES;
```

> 단, 최근 추세는 시스템/시스템 베이스 설정 값을 직접 변경하는 것을 권장하지 않음.

### 취약한 패스워드 예시 (3개 조합 8글자 수준 등)

```sql
ALTER USER 'abcdadm'@'localhost' IDENTIFIED WITH mysql_native_password BY 'qwer1234';

ALTER USER 'abcdadm'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'St0ng!Passw0rd#2026';
```

---

## 4. 불필요한 계정, 권한 최소화

- 불필요한 계정은 삭제하고, 사용자/애플리케이션별로 **다른 계정**을 사용한다.
    - 계정을 분리해야 문제 발생 시 추적이 쉽고, 계정별 권한 분리가 가능하다.

### 위험한 권한 종류

|권한|설명|
|---|---|
|`SHUTDOWN_PRIV`|서버 종료|
|`PROCESS_PRIV`|실행 중인 프로세스 명령/조회|
|`FILE_PRIV`|서버에서 파일 읽기/쓰기 (`LOAD_FILE`/`INTO OUTFILE` → 파일 유출, 악성코드 제작에 악용 가능)|

- 이런 권한이 노출되면 다른 세션의 쿼리·정보 노출, 시스템 종료를 통한 DoS 공격으로 이어질 수 있음.

### 위험한 권한 확인


```sql
MariaDB [mysql]> SELECT host, user, file_priv, process_priv, shutdown_priv FROM user;
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

### 특정 권한 제거하기

**권장되지 않는 방식 (직접 UPDATE)**

```sql
UPDATE mysql.user
SET file_priv = 'N', process_priv = 'N', shutdown_priv = 'N'
WHERE user = 'root';
FLUSH PRIVILEGES;
```

**권장 방식 (REVOKE):**

```sql
REVOKE FILE, PROCESS, SHUTDOWN ON *
```

---

## 5. 웹 기반 DB 관리도구 노출

- 흔한 취약 사례: `root / apmsetup` 같은 기본 credential 노출

### 보안 대책

1. 웹 기반 관리 도구는 사용하지 않는 것을 권장. 굳이 사용해야 한다면 외부에 노출하지 말고, 내부망/VPN/화이트리스트
2. 비밀번호를 강력하게 설정하고 **2중 인증(2FA)** 적용
3. 기본 credential(`root`/`apmsetup` 등)은 쓰지 말자.

---

## 6. 운영체제 보안과 파일 접근 제어

- DB 데이터 파일에 대한 OS 수준 접근 제어를 고려해야 한다.
    - `mysqld.cnf` 등 설정 파일 권한이 **640보다 많이 부여**되어 있으면 취약

### 디렉토리 권한 확인


```bash
[user@localhost ~]$ ls -ld /var/lib/mysql
drwxr-xr-x. 7 mysql mysql 4096 Jul 28 10:12 /var/lib/mysql
```

- 권한이 `755`로 설정되어 있으면 취약하다고 판단

### 계정 쉘 확인


```bash
grep mysql /etc/passwd
mysql:x:27:27:MySQL Server:/var/lib/mysql:/sbin/nologin
```

- `/sbin/nologin`을 통해 일반적으로 해당 계정으로의 직접 로그인이 막혀 있음

---

## 7. 네트워크 접근 제어

1. **원칙**: DB에는 DB 관리자, 개발자, 웹 서버(WAS)만 접속 가능해야 한다.
2. **네트워크 보안 장비**
    - 방화벽 → IP, 포트 단위 차단
    - DB 접근제어 솔루션 → 접속 IP, 사용자 인증 정보, 클라이언트 프로그램, 접근 대상 DB 객체 통제
3. **DB 객체**
    - 여러 요소를 종합적으로 고려한 세밀한 접근 제어 솔루션 적용
4. **Proxy 방식**
    - (설명 보충 필요)



### DB 설정 기반 접근 제어 예시

```sql
-- 웹 애플리케이션 서버(192.168.63.1)에서만 접속 가능한 계정 생성
CREATE USER 'webapp'@'192.168.63.1' IDENTIFIED BY 'str0ng!Pass#2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON school_db.* TO 'webapp'@'192.168.63.1';

SELECT user, host FROM mysql.user;
```


### 기타 점검 사항

1. 취약점 점검용 SQL → `plugin`이 `mysql_native_password`인 계정 조회
2. **행위 기반 모니터링 (이상 행위 탐지)**
    - 비정상 접속, 쿼리 행위를 탐지하고 차단
    - 평소와 다른 접속 패턴, 평소와 다른 쿼리 패턴 탐지
    - 대량 데이터 덤프 등 특이사항 탐지
3. **버전 관리**
    - 항상 취약점이 없는 최신 버전 사용 (EOL 버전 지양)
    - EOL 대응: 8.4나 9버전 사용 권장

---

## 8. 애플리케이션 보안

- `.inc`, `.conf`, `.xml`, `.env` 등 보안 관련 파일은 GitHub 등 소스코드 관리 도구에 올리면 안 됨
- ID/credential 값은 하드코딩하지 말고, 별도 시크릿 관리 도구나 환경 변수로 관리
    - 예: HashiCorp Vault, AWS Secrets Manager 등

### SSL/TLS 상태 확인


```sql
MariaDB [(none)]> SHOW SESSION STATUS LIKE 'ssl_%';
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
```

- `Ssl_version`, `Ssl_cipher`가 빈 값 → SSL 미사용 상태
- 권장: TLS 1.3 이상 암호 사용

### 특정 계정에 SSL 강제 적용


```sql
MariaDB [(none)]> ALTER USER 'webapp'@'192.168.63.1' REQUIRE SSL;
Query OK, 0 rows affected (0.001 sec)
```

- `webapp` 계정(해당 IP 한정)에 SSL 접속을 요구하도록 설정

---

## 9. 저장 데이터 암호화

### 암호화 적용 수준

1. **애플리케이션 수준**: 애플리케이션이 저장 전에 암호화하고, 키는 DB 안에 저장하지 않음
2. **파일 시스템 수준**: OS가 제공하는 암호화 파일 시스템 이용
3. **DB 수준**
    - **TDE (Transparent Data Encryption)**: DBMS가 데이터를 디스크에 쓰고 읽을 때 자동으로 암/복호화
    - **컬럼 암호화**: 특정 민감 컬럼만 골라 암호화 (SQL 쿼리문에 키가 들어가므로 키가 그대로 노출되는 단점 있음)
    - DB 자체 암호화 기능


### 실무 권장 사항

- 파일 시스템 수준 암호화(OS/클라우드 기본 제공)를 기본으로 사용
- TDE를 기본으로 상시 적용
- 주민등록번호, 패스워드 등 민감 정보는 애플리케이션 수준 암호화 사용
- 패스워드는 **일방향 암호화(해시)** 적용
