
## 목차

1. [전체 흐름 요약](#1-%EC%A0%84%EC%B2%B4-%ED%9D%90%EB%A6%84-%EC%9A%94%EC%95%BD)
2. [Rocky Linux 준비 (IP 확인 → SSH → MariaDB)](#2-rocky-linux-%EC%A4%80%EB%B9%84-ip-%ED%99%95%EC%9D%B8--ssh--mariadb)
3. [MariaDB 데이터베이스 및 계정 설정](#3-mariadb-%EB%8D%B0%EC%9D%B4%ED%84%B0%EB%B2%A0%EC%9D%B4%EC%8A%A4-%EB%B0%8F-%EA%B3%84%EC%A0%95-%EC%84%A4%EC%A0%95)
4. [방화벽 설정 (3306 포트 개방)](#4-%EB%B0%A9%ED%99%94%EB%B2%BD-%EC%84%A4%EC%A0%95-3306-%ED%8F%AC%ED%8A%B8-%EA%B0%9C%EB%B0%A9)
5. [Kali Linux에서 mysql 클라이언트 설치](#5-kali-linux%EC%97%90%EC%84%9C-mysql-%ED%81%B4%EB%9D%BC%EC%9D%B4%EC%96%B8%ED%8A%B8-%EC%84%A4%EC%B9%98)
6. [최종 원격 접속 테스트](#6-%EC%B5%9C%EC%A2%85-%EC%9B%90%EA%B2%A9-%EC%A0%91%EC%86%8D-%ED%85%8C%EC%8A%A4%ED%8A%B8)
7. [🔧 에러별 조치 모음 (트러블슈팅 챕터)](#7-%EC%97%90%EB%9F%AC%EB%B3%84-%EC%A1%B0%EC%B9%98-%EB%AA%A8%EC%9D%8C-%ED%8A%B8%EB%9F%AC%EB%B8%94%EC%8A%88%ED%8C%85-%EC%B1%95%ED%84%B0)

---

## 1. 전체 흐름 요약

```
[Rocky Linux 서버]                              [Kali Linux 클라이언트]
192.168.63.128                                   192.168.63.130
   │                                                  │
   ├─ IP 확인 (ip a)                                  │
   ├─ MobaXterm SSH 접속 ◄────────────────────────────┤ (MobaXterm 프로그램)
   ├─ MariaDB 설치 (dnf)                              │
   ├─ testdb 데이터베이스 생성                          │
   ├─ test 계정 생성 + 권한 부여 (192.168.%)            │
   ├─ 방화벽 3306 포트 개방                             │
   │                                                  ├─ mysql 클라이언트 설치 (apt) ⚠️ 여러 에러 발생
   │ ◄────────────────────── mysql -h 192.168.63.128 -u test -p ──┤
   └─ 접속 성공, testdb 확인 완료                        └─ 접속 성공
```

---

## 2. Rocky Linux 준비 (IP 확인 → SSH → MariaDB)

### IP 주소 확인

bash

```bash
ip a
```

- `ens33` 인터페이스에서 `inet 192.168.63.128/24` 확인
- `/24` = 서브넷 마스크 (24비트가 네트워크 부분, 즉 `192.168.63.X` 대역 전체가 한 네트워크)
- `brd 192.168.63.255` = 브로드캐스트 주소 (네트워크 전체에 신호 보낼 때 쓰는 특수 주소, 실접속에는 사용 안 함)

### MobaXterm SSH 접속

- Session → SSH → Remote host: `192.168.63.128`, username 입력 → 접속

![](../Images/Pasted%20image%2020260725150136.png)
### MariaDB 설치


```bash
sudo dnf install mariadb-server mariadb -y
```

### 서비스 시작 및 등록


```bash
sudo systemctl enable mariadb --now
systemctl is-active mariadb   # 결과: active
```

### 보안 초기 설정

bash

```bash
sudo mysql_secure_installation
```

- root 비밀번호 설정
- `Disallow root login remotely?` → **Y** 선택
	- root는 로컬 전용, 원격은 별도 계정(`test`)으로 분리하는 것이 보안상 권장됨

---

## 3. MariaDB 데이터베이스 및 계정 설정

### 콘솔 접속


```bash
mysql -u root -p
```

### 데이터베이스 생성


```sql
CREATE DATABASE testdb;
SHOW DATABASES;
```

### 원격 접속용 사용자 생성


```sql
-- 'user'@'host' 사이에 공백 없이 붙여써야 함
CREATE USER 'test'@'192.168.%' IDENTIFIED BY 'P@ASSW0RD';

-- 권한 부여
GRANT ALL PRIVILEGES ON *.* TO 'test'@'192.168.%';

-- 권한 테이블 즉시 반영
FLUSH PRIVILEGES;
```

> `192.168.%`는 `192.168.`로 시작하는 모든 IP 대역에서 접속 허용을 의미

### 생성 확인

sql

```sql
-- 사용자 존재 확인
SELECT user, host FROM mysql.user WHERE user='test';

-- 부여된 권한 확인
SHOW GRANTS FOR 'test'@'192.168.%';

-- 비밀번호 재설정이 필요할 때
ALTER USER 'test'@'192.168.%' IDENTIFIED BY 'P@ASSW0RD';
FLUSH PRIVILEGES;
```

### Rocky Linux 내부에서 네트워크 경유 접속 테스트 (로컬 아님, IP로 접속)

bash

```bash
mysql -h 192.168.63.128 -u test -p
```

> 콘솔 작업(`FLUSH PRIVILEGES;` 등)은 반드시 `MariaDB [(none)]>` 프롬프트 안에서 실행. Bash 쉘(`[root@localhost ~]#`)에서 SQL 명령어를 치면 `command not found` 에러 발생.

---

## 4. 방화벽 설정 (3306 포트 개방)

Bash 쉘로 나온 뒤 (`exit;`으로 콘솔 종료) 실행:

bash

```bash
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

|옵션|의미|
|---|---|
|`--permanent --add-port`|포트 개방을 영구 설정으로 예약|
|`--reload`|예약된 설정을 실제 적용|
|`--list-ports`|열려있는 포트 확인 (`3306/tcp` 나오면 성공)|

---

## 5. Kali Linux에서 mysql 클라이언트 설치

> 이 단계에서 정말 많은 에러가 발생했다. 에러 해결 과정은 [7장](#7-%EC%97%90%EB%9F%AC%EB%B3%84-%EC%A1%B0%EC%B9%98-%EB%AA%A8%EC%9D%8C-%ED%8A%B8%EB%9F%AC%EB%B8%94%EC%8A%88%ED%8C%85-%EC%B1%95%ED%84%B0)에 모아뒀습니다. 여기서는 **최종적으로 성공한 순서만** 정리합니다.

bash

```bash
# 1. Chrome 저장소 제거 (mysql 설치와 무관, 충돌 방지용)
sudo rm /etc/apt/sources.list.d/google-chrome.list

# 2. 패키지 캐시 정리
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*

# 3. Kali 공식 키 재등록
wget https://archive.kali.org/archive-key.asc
sudo gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg archive-key.asc

# 4. 패키지 목록 갱신
sudo apt update

# 5. mysql 클라이언트 설치 (파일 충돌 시 강제 덮어쓰기 옵션 필요)
sudo apt install mariadb-client -y -o Dpkg::Options::="--force-overwrite"

# 6. 남은 의존성 정리
sudo apt --fix-broken install -y -o Dpkg::Options::="--force-overwrite"
```

### 설치 확인


```bash
which mysql
mysql --version
```

결과: `/usr/bin/mysql`, `mysql Ver 15.1 Distrib 10.6.7-MariaDB` → 설치 성공

---

## 6. 최종 원격 접속 테스트

### Kali → Rocky 네트워크 연결 확인


```bash
ping -c 4 192.168.63.128
```

→ 4개의 `0% packet loss` 확인

### Kali에서 원격 mysql 접속


```bash
mysql -h 192.168.63.128 -u test -p
```

비밀번호(`P@ASSW0RD`) 입력 → `MariaDB [(none)]>` 프롬프트로 진입하면 성공

### 접속 후 확인

sql

```sql
SHOW DATABASES;                 -- testdb 존재 확인
SELECT current_user();          -- 현재 test 계정으로 접속했는지 확인
SELECT user, host FROM mysql.user WHERE user='test';
SHOW GRANTS FOR 'test'@'192.168.%';
```

→ 전체 목표 **Rocky MariaDB 서버에 Kali 클라이언트가 원격 접속** 달성 완료

---

## 7. 에러별 조치 모음 (트러블슈팅 챕터)

#### 7-1. `mysql -h ... ERROR 2002 (HY000): Can't connect to server`

| 원인                     | 조치                                                   |
| ---------------------- | ---------------------------------------------------- |
| MariaDB 서비스 미실행        | `sudo systemctl status mariadb` → `enable --now`로 시작 |
| 서비스명 착각 (`mysqld`로 조회) | Rocky Linux는 서비스명이 `mariadb`, `mysqld`가 아님           |
| 방화벽 3306 미개방           | `firewall-cmd --add-port=3306/tcp` 후 `--reload`      |

#### 7-2. `ERROR 1064 (42000): You have an error in your SQL syntax`

| 실수                                 | 원인        | 수정                                            |
| ---------------------------------- | --------- | --------------------------------------------- |
| `SHOW DATABASE;`                   | 단수형 오타    | `SHOW DATABASES;` (복수형)                       |
| `CREATE USER 'test' @ '192.168.%'` | `@` 앞뒤 공백 | `CREATE USER 'test'@'192.168.%'` (공백 없이 붙여쓰기) |

#### 7-3. `bash: FLUSH: command not found`

- **원인**: MariaDB 콘솔에서 나온(Bash 쉘) 상태에서 SQL 명령어를 입력함
- **조치**: `mysql -u root -p`로 콘솔에 다시 접속 후, `MariaDB [(none)]>` 프롬프트인지 확인하고 SQL 명령어 재입력

#### 7-4. `ERROR 1045 (28000): Access denied for user (using password: YES)`

| 원인                        | 조치                                                                            |
| ------------------------- | ----------------------------------------------------------------------------- |
| 비밀번호 오타 (`0`↔`O`, 대소문자 등) | `ALTER USER 'test'@'192.168.%' IDENTIFIED BY '새비밀번호'; FLUSH PRIVILEGES;`로 재설정 |
| 계정 자체 미생성                 | `SELECT user, host FROM mysql.user WHERE user='test';`로 존재 여부 먼저 확인           |

#### 7-5. Kali `apt update` 시 `404 Not Found`

- **원인**: 로컬 패키지 캐시가 오래되어 이미 삭제/변경된 버전을 요청
- **조치**:

```bash
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*
sudo apt update
```

#### 7-6. Kali `apt update` 시 GPG `NO_PUBKEY` 에러

- **원인**: 저장소 공개키(서명 검증용 키)가 없음
- **조치**:

```bash
# Kali 저장소 키
wget https://archive.kali.org/archive-key.asc
sudo gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg archive-key.asc

# Chrome 저장소는 mysql 설치와 무관하므로 제거해서 정리
sudo rm /etc/apt/sources.list.d/google-chrome.list
```


### 7-7. `openssl-provider-legacy` 설치 중 dpkg 에러 (파일 충돌)

```
trying to overwrite '.../legacy.so', which is also in package libssl3
```

- **원인**: OpenSSL 3.0→3.6 전환 과정에서 신구 패키지가 같은 파일을 두고 충돌
- **조치**: 강제 덮어쓰기 옵션 사용


```bash
sudo apt install mariadb-client -y -o Dpkg::Options::="--force-overwrite"
sudo apt --fix-broken install -y -o Dpkg::Options::="--force-overwrite"
```

### 7-8. `apt full-upgrade` 도중 시스템 전체가 꼬이는 경우 (최악의 시나리오)

- **증상**: `dpkg --configure -a`, `apt --fix-broken install`을 반복해도 계속 거대한 의존성 에러 목록이 나옴 
	- `libgnutls30t64`, `libreadline8t64`, `perl-modules-5.40` 등 수십 개 패키지가 서로 안 맞물림
- **원인**: 업그레이드 도중 특정 패키지(`libcurl4-gnutls` 등) 설치가 실패하면서, 전체 dpkg 설정 작업이 중간에 끊김. 반쯤 걸친 상태(`iU`, `iF`)의 패키지가 대량으로 쌓임
- **시도했던 조치들** (부분적으로만 효과 있었음):
    - `sudo dpkg --configure -a` (반복 실행)
    - `sudo apt --fix-broken install -y`
    - 특정 라이브러리 직접 지정 설치 시도
    - `aptitude`로 전환 시도
- **최종 해결책**: 위 방법들로도 해결이 안 될 정도로 꼬였다면, **VM을 새로 만드는 것이 가장 빠르고 확실함**
    - VMware에서 기존 VM 삭제
    - 원본 `.ova`/`.ova` 이미지를 재임포트
    - 재부팅 후 **처음부터 `apt update`까지만 먼저 안전하게 완료**하고, 필요한 패키지(`mariadb-client`)만 설치 (전체 `full-upgrade`는 굳이 먼저 돌리지 않는 것이 안전)

#### 7-9. Kali → Rocky `ping` 실패 (`Destination Host Unreachable`)

| 원인                                       | 조치                                                    |
| ---------------------------------------- | ----------------------------------------------------- |
| 상대 VM이 꺼져있음                              | Rocky Linux VM을 켰는지 확인                                |
| VM 방금 재부팅 직후라 네트워크 초기화 지연                | 잠시 후 재시도                                              |
| 서로 다른 네트워크 어댑터(NAT/Bridged/Host-only) 사용 | 두 VM의 Network Adapter 설정이 동일한지 확인 (VMware 설정 편집 화면에서) |

## 참고: 자주 헷갈리는 서비스/명령어 이름 정리

| 잘못 쓰기 쉬운 것                             | 올바른 것                           | 비고                       |
| -------------------------------------- | ------------------------------- | ------------------------ |
| `sudo systemctl status ssh` (Rocky)    | `sudo systemctl status sshd`    | RHEL 계열은 `sshd`          |
| `sudo systemctl status mysqld` (Rocky) | `sudo systemctl status mariadb` | Rocky 기본 DB는 MariaDB     |
| `ufw` (Rocky)                          | `firewall-cmd`                  | Rocky/RHEL 계열은 firewalld |
| `SHOW DATABASE;`                       | `SHOW DATABASES;`               | 복수형                      |
| `'user' @ 'host'`                      | `'user'@'host'`                 |                          |