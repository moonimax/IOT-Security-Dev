# MobaXterm SSH 접속 & Rocky Linux MariaDB 설정 트러블슈팅

> 환경: Kali Linux(클라이언트) ↔ MobaXterm ↔ Rocky Linux VM(서버, VMware, IP: `192.168.36.129`)

---

## 목차
1. [SSH 연결 문제 해결](#1-ssh-연결-문제-해결)
2. [VMware 네트워크 어댑터 문제](#2-vmware-네트워크-어댑터-문제)
3. [Kali Linux APT 저장소 오류 해결](#3-kali-linux-apt-저장소-오류-해결)
4. [Rocky Linux에 MariaDB 설치](#4-rocky-linux에-mariadb-설치)
5. [MariaDB 사용자 생성 및 원격 접속 권한 설정](#5-mariadb-사용자-생성-및-원격-접속-권한-설정)
6. [방화벽 포트(3306) 개방](#6-방화벽-포트3306-개방)
7. [자주 헷갈렸던 실수 모음](#7-자주-헷갈렸던-실수-모음)
8. [전체 명령어 요약 (복사용)](#8-전체-명령어-요약-복사용)

---

## 1. SSH 연결 문제 해결

### 증상
MobaXterm에서 `Network error: Connection timed out` 발생.

### 원인 분석 순서

| 확인 항목 | 결과 |
|---|---|
| SSH 서비스명 | Rocky Linux는 `ssh`가 아니라 **`sshd`** |
| sshd 실행 상태 | `active (running)` 확인됨 |
| 포트 리스닝 (`0.0.0.0:22`) | 정상 |
| 방화벽(firewalld) | `ssh` 서비스 허용되어 있음 → 정상 |
| **VM 네트워크 모드** | ⚠️ **여기가 진짜 원인** |

### 핵심 명령어

```bash
# sshd 서비스 상태 확인 (Rocky/RHEL 계열은 ssh가 아니라 sshd)
sudo systemctl status sshd
sudo systemctl enable sshd --now

# sshd가 실제로 포트 22에서 듣고 있는지 확인
sudo ss -tlnp | grep :22

# 방화벽 상태 및 서비스 목록 확인
sudo firewall-cmd --state
sudo firewall-cmd --list-services

# ssh 서비스가 방화벽에 없다면 추가
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# 서버 IP 확인
ip a
```

> 💡 **배운 점**: RHEL 계열(Rocky/CentOS/Alma)은 서비스명이 `sshd`, Debian 계열(Kali/Ubuntu)은 `ssh`. 방화벽도 RHEL 계열은 `firewalld`, Debian 계열은 `ufw`를 주로 사용.

---

## 2. VMware 네트워크 어댑터 문제

### 증상
- Rocky Linux는 sshd 정상, 방화벽도 정상
- 그런데 Windows에서 `ping 192.168.36.129` 시도 → **100% 패킷 손실**

### 원인 진단 과정

1. Windows `ipconfig` 결과에 **VMware 관련 어댑터(VMnet1, VMnet8)가 아예 없음** 발견
2. `services.msc`에서 **`VMware Authorization Service`가 목록에 없음** 확인
   → **VMware 설치 자체가 손상되었거나 불완전했던 것이 근본 원인**

### 해결 방법

1. 제어판 → 프로그램 및 기능 → VMware Workstation/Player 확인
2. **복구(Repair)** 시도 → 안 되면 **완전 삭제 후 재설치**
3. 재설치 후 재부팅
4. `services.msc`에서 VMware 서비스들이 정상적으로 보이는지 확인
5. `ipconfig`로 `VMnet1`(Host-only), `VMnet8`(NAT) 어댑터가 생성됐는지 확인

> 💡 **배운 점**: VMware 네트워크(Host-only/NAT/Bridged)가 정상 작동하려면 Windows 쪽에 해당 서비스와 가상 어댑터가 반드시 있어야 함. 이게 없으면 VM 설정이 아무리 맞아도 호스트↔게스트 통신 자체가 불가능.

---

## 3. Kali Linux APT 저장소 오류 해결

### 증상 1: 404 Not Found

```
E: Failed to fetch http://http.kali.org/kali/pool/main/... 404 Not Found
```

**원인**: 로컬 패키지 목록(캐시)이 오래되어 이미 삭제/변경된 버전을 요청.

**해결**:
```bash
sudo apt update
sudo apt clean
sudo apt install --fix-missing mariadb-server mariadb-client -y
```

### 증상 2: GPG 서명 검증 실패

```
NO_PUBKEY FD533C07C264648F
NO_PUBKEY ED65462EC8D5E4C5
```

**원인**: 저장소 공개키(GPG key)가 시스템에 없어서 패키지 신뢰성 검증 실패.

**해결**:
```bash
# Kali 공식 키링 재설치
sudo apt install --reinstall kali-archive-keyring -y

# Google Chrome 저장소 키 추가
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

# 안 쓰는 저장소면 아예 제거해도 무방
sudo rm /etc/apt/sources.list.d/google-chrome.list
sudo apt update
```

> 💡 **배운 점**: `apt update` 시 나오는 `NO_PUBKEY` 에러는 패키지가 없어서가 아니라 **저장소를 신뢰할 수 없다는 서명 오류**. 키를 추가하거나 재설치하면 해결됨.

---

## 4. Rocky Linux에 MariaDB 설치

Rocky Linux는 MySQL 대신 기본 저장소에 **MariaDB**(MySQL 호환)가 포함되어 있음.

```bash
# 설치
sudo dnf install mariadb-server mariadb -y

# 서비스 시작 및 자동 시작 등록
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl status mariadb

# 최초 보안 설정 (root 비밀번호 등)
sudo mysql_secure_installation
```

> ⚠️ 서비스명은 `mysqld`가 아니라 `mariadb`. `sudo systemctl status mysqld` → `Unit mysqld.service could not be found` 에러가 났었음.

---

## 5. MariaDB 사용자 생성 및 원격 접속 권한 설정

### 콘솔 접속
```bash
sudo mysql -u root -p
```
> 프롬프트가 `MariaDB [(none)]>` 로 바뀌면 SQL 명령어를 칠 준비가 된 것. 이 안에서는 `firewall-cmd` 같은 리눅스(Bash) 명령어는 실행 불가.

### 데이터베이스 목록 확인
```sql
SHOW DATABASES;    -- DATABASE(단수) X, DATABASES(복수) O
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

`192.168.%`는 `192.168.`로 시작하는 모든 IP 대역 허용을 의미 (예: `192.168.36.129`, `192.168.36.130` 등).

### 계정 확인용 명령어

```sql
-- 사용자 존재 확인
SELECT user, host FROM mysql.user WHERE user='test';

-- 부여된 권한 확인
SHOW GRANTS FOR 'test'@'192.168.%';

-- 비밀번호 재설정이 필요할 때
ALTER USER 'test'@'192.168.%' IDENTIFIED BY 'P@ASSW0RD';
FLUSH PRIVILEGES;
```

### 원격 접속 테스트
```bash
mysql -h 192.168.36.129 -u test -p
```

> ⚠️ `Access denied for user 'test'@'...' (using password: YES)` 에러가 발생하면 → 비밀번호 오타(대소문자, 숫자 0과 알파벳 O 혼동 등) 또는 계정/권한 미반영이 원인일 확률이 높음. `ALTER USER`로 비밀번호 재설정 후 재시도.

---

## 6. 방화벽 포트(3306) 개방

MariaDB 기본 포트인 **3306번**을 외부에서 접속 가능하도록 열어야 함.

```bash
# 1단계: 포트 개방을 영구 설정으로 "예약"
sudo firewall-cmd --permanent --add-port=3306/tcp

# 2단계: 예약된 설정을 실제로 "적용"
sudo firewall-cmd --reload

# 3단계: 정상적으로 열렸는지 "확인"
sudo firewall-cmd --list-ports
```

| 옵션 | 의미 |
|---|---|
| `--permanent` | 재부팅 후에도 유지되는 영구 설정 (단, 즉시 적용은 안 됨) |
| `--reload` | 방화벽 설정을 다시 읽어서 실제로 반영 |
| `--list-ports` | 현재 열려있는 포트 목록 확인 |

> ⚠️ **주의**: 이 명령어들은 반드시 **Bash 쉘**(`[root@localhost ~]#`)에서 실행해야 함. `MariaDB [(none)]>` 콘솔 안에서 입력하면 `bash: FLUSH: command not found` 같은 에러가 나거나, 세미콜론을 기다리며 `->` 프롬프트가 계속 뜸 → `exit;` 또는 `\c`로 빠져나온 뒤 실행.

---

## 7. 자주 헷갈렸던 실수 모음

| 실수 | 올바른 표현 |
|---|---|
| `SHOW DATABASE;` | `SHOW DATABASES;` (복수형) |
| `CREATE USER 'test' @ '192.168.%'` (공백 있음) | `CREATE USER 'test'@'192.168.%'` (공백 없이 붙여쓰기) |
| MariaDB 콘솔 안에서 `firewall-cmd` 입력 | Bash 쉘에서 실행 (`exit;`로 콘솔 먼저 나가기) |
| `Sudo firewall-cmd` (대문자 S) | `sudo` (반드시 소문자, 리눅스는 대소문자 구분) |
| `fierewall-cmd` (오타) | `firewall-cmd` |
| Rocky에서 서비스명 `ssh`, `mysqld`로 조회 | RHEL 계열은 `sshd`, `mariadb`가 정확한 서비스명 |
| IP `192.198.36.129` (오타) | `192.168.36.129` (168 확인) |

---

## 8. 전체 명령어 요약 (복사용)

### Rocky Linux 서버 설정 (SSH + MariaDB 전체 순서)

```bash
# --- SSH ---
sudo systemctl enable sshd --now
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# --- MariaDB 설치 ---
sudo dnf install mariadb-server mariadb -y
sudo systemctl enable mariadb --now
sudo mysql_secure_installation

# --- 방화벽 3306 포트 개방 ---
sudo firewall-cmd --permanent --add-port=3306/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

### MariaDB 콘솔 안에서 (사용자 생성 및 권한)

```sql
SHOW DATABASES;

CREATE USER 'test'@'192.168.%' IDENTIFIED BY 'P@ASSW0RD';
GRANT ALL PRIVILEGES ON *.* TO 'test'@'192.168.%';
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user WHERE user='test';
SHOW GRANTS FOR 'test'@'192.168.%';

exit;
```

### Kali Linux 클라이언트에서 접속 테스트

```bash
mysql -h 192.168.36.129 -u test -p
```

---

## 참고: 네트워크 구조 요약

```
[Kali Linux]  --- SSH(22) / MySQL(3306) --->  [Rocky Linux VM: 192.168.36.129]
   (클라이언트)                                      (서버, VMware 위에서 실행)
```

- Rocky Linux: SSH(sshd) + MariaDB 서버 실행
- 방화벽: `ssh` 서비스, `3306/tcp` 포트 모두 개방 필요
- VMware 네트워크 어댑터가 정상 작동해야 호스트-게스트 간 통신 가능
