
## 계정/비밀번호 정리

| 구분                                | 계정        | 비밀번호           | 비고                               |
| --------------------------------- | --------- | -------------- | -------------------------------- |
| Linux (SSH)                       | `labuser` | `labuser`      | sudo 권한 있음                       |
| MySQL                             | `root`    | `TestPass123!` | skip-grant-tables 모드에서 재설정       |
| MySQL                             | `lab`     | `LabPass123!`  | 인증 플러그인: `mysql_native_password` |
| 앱 계정 (lab02, `admin_account` 테이블) | `finance` | `F!nance2024`  | 평문 저장 (실습용)                      |
| DB 이름                             | `lab`     | -              | lab01용                           |
| DB 이름                             | `lab02`   | -              | lab02용                           |

---

## 전체 구조

- **서버**: Rocky Linux, IP `192.168.63.128`
- **접속 방식**: Windows에서 SSH로 접속 (`labuser` 계정, 관리자 권한 있음 / `user` 계정, 일반 사용자)
- **DB**: MySQL 8.0.46 (systemd 서비스 `mysqld`)
- **애플리케이션**: Node.js + Express + EJS + MySQL(mysql2, sequelize)
    - `/opt/labs/lab01-sqli` — SQL Injection 실습 (포트 3001)
    - `/opt/labs/lab02-code-injection` — 코드 삽입(계산기) 실습 (포트 3002)

각 `lab, lab02`은 `취약 코드(vuln)`와 `패치된 코드(patched)`를 함께 두고, 실제 취약점 공격과 방어 코드를 비교하며 학습하는 구조다.

---

## 1. MySQL 초기 설정 문제

### 증상

- 데이터 디렉터리 초기화 실패, `root` 계정 접속 거부(`Access denied`) 반복

### 원인 및 해결

- `root` 계정 비밀번호를 정확히 알 수 없는 상태 → **`--skip-grant-tables` 모드**로 임시 부팅해 비밀번호 재설정
- 재설정 과정에서 여러 mysqld 프로세스가 동시에 떠서 소켓(`mysql.sock`) 충돌 발생 → 좀비 프로세스 정리, 소켓/PID 파일 삭제 후 서비스 재시작
- 비밀번호 정책(`validate_password`) 때문에 단순 비밀번호 거부 → 정책을 만족하는 비밀번호로 재설정
- 최종적으로 `root` 계정 비밀번호 재설정 성공 → `lab` 계정에 권한 부여(`GRANT`) 및 스키마/시드 데이터 적용

### 특이 사항

- `mysqld` config 개별 설정으로 `root`로 직접 실행 불가 → `--user=mysql` 옵션 필요
- 여러 mysqld 인스턴스가 같은 소켓을 두고 충돌하면 서비스가 죽거나 이상하게 인증됨 → 항상 `ps aux | grep mysqld`로 프로세스 상태 확인 후 작업 필요. 좀비 프로세스가 죽지 않고 포트를 물고 있는 상황으로 트러블 슈팅에 어려움 겪음

---

## 2. lab01 애플리케이션 DB 연결 문제

### 증상

- Node.js 앱에서 로그인 시 `ER_NOT_SUPPORTED_AUTH_MODE` / `ER_ACCESS_DENIED_ERROR` 발생

### 원인 및 해결

- MySQL 커맨드라인 클라이언트와 달리, **Node.js의 `mysql2` 드라이버는 `localhost`를 자동으로 유닉스 소켓으로 처리하지 않고 TCP로 접속**함
- `lab` 계정의 인증 플러그인이 `caching_sha2_password`로 되어 있어 TCP 연결 시 인증 오류 발생 → `mysql_native_password`로 변경
- 알고 보니 진짜 원인은 **오래된 좀비 `node` 프로세스가 이미 3001번 포트를 점유**하고 있어서, `.env`를 아무리 고쳐도 예전 값으로 계속 응답하고 있었던 것 → 포트 점유 프로세스(`lsof -i :포트`)를 찾아 종료 후 해결

### 배운 점

- 설정 파일을 고쳐도 반영이 안 될 때는, **그 포트를 실제로 누가 물고 있는지(`lsof -i :포트`)부터 확인**하는 것이 중요

---

## 3. lab02 서비스(systemd) 설정 문제

### 증상

- `lab02.service`가 계속 재시작을 반복 (`activating (auto-restart)`)

### 원인들 (순차적으로 발생)

1. 서비스 유닛 파일에 불필요한 문자(`t`)가 끼어들어 문법 오류 발생 → 파일 수정 후 `daemon-reload`
2. `app.js`가 요구하는 라우트 파일(`routes/vuln.js`, `routes/patched.js`)이 삭제되어 없음 → 복구/재작성
3. `routes/index.js` 파일이 편집 과정에서 내용이 중복 붙여넣기 됨 → 정리
4. `views/login.ejs`, `views/error.ejs` 뷰 파일이 없거나 다른 페이지(계산기) 내용과 섞여 있음 → 분리하여 재작성
5. 로그 파일(`/var/log/labs/lab0X-access.log`) 권한 문제 — `labuser`와 `user` 두 계정을 오가며 작업하다 파일 소유자가 계속 바뀌어 `EACCES` 권한 오류 반복 발생 → 권한 정리
6. 최종적으로 `.env`의 `DB_NAME`이 `lab`로 되어 있어 실제 데이터(`lab02` DB)가 있는 곳과 다른 DB를 조회 → `DB_NAME=lab02`로 수정

### 배운 점

- **한 서버 안에서 두 개의 리눅스 계정(`labuser`, `user`)을 오가며 작업하면 파일 소유권/권한 문제가 자주 발생**함 → 가능하면 한 계정으로 통일해서 작업
- systemd 서비스가 계속 재시작될 때는 `journalctl -u 서비스명 -n 50 --no-pager`로 로그를 확인하는 것이 문제 파악의 기본
- 애플리케이션 에러가 또 다른 에러(뷰 파일 없음 등)에 가려질 수 있으므로, 에러 핸들러가 참조하는 파일(`views/error.ejs`)도 반드시 준비해두어야 진짜 원인이 보임

---

## 공통적으로 유용했던 명령어

```bash
# 프로세스 확인
ps aux | grep <검색어>

# 포트 점유 확인
sudo lsof -i :<포트번호>

# systemd 서비스 상태/로그
sudo systemctl status <서비스명>
sudo journalctl -u <서비스명> -n 50 --no-pager

# MySQL 계정/권한 확인
mysql -u root -p -e "SELECT user, host, plugin FROM mysql.user;"
```