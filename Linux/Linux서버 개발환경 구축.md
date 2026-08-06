
### 설정

>labuser / labuser
>MYSQL root -> TestPass123!
>MYSQL lab -> password 혹은 P@SSW0RD / P@SSW0RD




![](Images/sdfgdfg4.png)

**프레임워크**

> 프론트 & 백에서 실행을 할 수 있도록 도와주는 기능을 하지만 실제 서버를 구동하고 관리하는 기능이 없기 때문에 프레임워크에 ngnix 서버를 함께 구축할 수 있도록 해야 한다.




**빌드 도구**

이와 관련한 모든 Development Tool인 개발 도구를 모두 설치

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y python3 git curl unzip

```


해당 프로그램을 관리할 계정을 관리자가 아닌 일반 사용자로 생성
```bash
-- labuser로 생성
sudo adduser labuser

-- vi 확인 시 wheel 그룹에 모든 권한이 반영되는 점 확인
sudo usermod -aG wheel labuser

-- ssh-keygen을 생성하여 접속 서버 ssh에 대한 공개키를 생성
[user@localhost ~]$ ssh-keygen -t ed25519 -C "labuser@secure-coding"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519): 

--windows C\home\user\.ssh 경로로 위 값을 넣어놓고 key 2개를 생성
```

![](../Images/Pasted%20image%2020260805104325.png)


다시 rocky linux로 돌아와서
```bash
mkdir .ssh
cd .ssh
vim authorized_keys
-- 위 id_ed25519.pub내용을 이제 다시 해당 텍스트 내용을 복사해서 붙여넣으면 된다.

-- root login에 대한 권한을 막기 위해 아래와 같이 설정
sudo vim /etc/ssh/sshd_config
> PermitRootLogin no
> PasswordAuthentication no

sudo systemctl restart sshd

```


windows 터미널로 돌아와서
```bash

-- 원격 접속을 하기 위해서 키를 지정하겠다
ssh -i id_ed25519 labuser@(ip)
ssh -i i_ed25519 labuser@192.168.63.128 

```


다시 Rocky linux로 돌아와서 
- 80, 22, 443, 3001-3013 tcp를 열어준다.


![](../Images/Pasted%20image%2020260805113105.png)



# 리눅스 서버 개발 환경 구축

---

## 공통 애플리케이션 스캐폴드

| 조건          | 내용                                            |
| ----------- | --------------------------------------------- |
| ① 일관된 레이아웃  | 헤더 · 내비게이션 · 사이드바 · 푸터를 갖춘 하나의 레이아웃 위에서 화면 구성 |
| ② 로그인 상태 구분 | 비로그인 사용자와 로그인 사용자가 볼 수 있는 화면을 구분              |
| ③ 오류 화면 처리  | 존재하지 않는 페이지, 서버 오류 등 비정상 요청에 의미 있는 오류 화면 제공   |
| ④ 요청 로깅     | 모든 요청을 로그로 남김                                 |

### 표준 디렉토리 구조

```
lab01-sqli/
├── app.js                  # 애플리케이션 진입점
├── package.json
├── .env                    # 환경변수 (Git에 포함하지 않음)
├── config/
│   └── index.js            # 설정값 로딩
├── models/
│   ├── db.js                # mysql 드라이버 커넥션 풀
│   └── sequelize.js         # Sequelize 인스턴스
├── routes/
│   ├── index.js              # 공통 라우터 (대시보드 등)
│   ├── vuln.js                # 취약 버전 라우트
│   └── patched.js             # 안전 버전 라우트
├── controllers/
│   └── ...                     # 라우트가 호출하는 실제 처리 로직
├── services/
│   └── ...                     # 데이터베이스 접근 등 비즈니스 로직
├── middlewares/
│   ├── auth.js               # 로그인 여부 확인
│   └── errorHandler.js       # 공통 에러 처리
├── views/
│   ├── layout.ejs             # 공통 레이아웃
│   ├── partials/
│   │   ├── header.ejs
│   │   ├── nav.ejs
│   │   └── footer.ejs
│   ├── index.ejs
│   └── error.ejs
└── public/
    ├── css/style.css
    └── js/main.js
```

### 디렉토리/계층 설계 이유

|요소|역할|설계 이유|
|---|---|---|
|`routes/`|URL 경로 ↔ 처리 함수 연결만 담당|실제 로직은 `controllers`/`services`로 분리 → **"취약한 버전"과 "안전한 버전"을 나란히 비교할 때 차이가 정확히 어느 계층에 있는지 명확히 드러남**|
|`routes/vuln.js` vs `routes/patched.js`|같은 기능의 취약 버전 / 패치 버전 라우트 분리|하나의 앱 안에서 URL만 `/lab/vuln` ↔ `/lab/patched`로 바꿔 **즉시 두 버전의 동작 차이를 강의 중 그 자리에서 비교** 가능 (프로젝트를 완전히 분리하면 서버를 껐다 켜거나 포트를 바꿔야 하는 번거로움 발생)|
|`views/layout.ejs` + `partials/`|헤더/내비/푸터를 공통 조각으로 분리|여러 페이지에서 반복되는 부분을 한 곳에서만 관리 (13개 앱 전체에서 재사용)|
|`.env` + `config/index.js`|민감한 설정값(DB 비밀번호, 세션 키 등)을 코드와 분리|`.env`를 `.gitignore`에 등록해 저장소에 노출되는 사고 방지, 서버마다 값만 바꿔 적용 가능|
|`middlewares/auth.js` (`requireLogin`)|로그인 필요한 라우트 앞단 공통 검사|세션에 로그인 정보 없으면 자동으로 `/login`으로 리다이렉트 — 14장(보안기능 결정 부적절)의 "쿠키가 아닌 세션에 권한 정보를 저장해야 하는 이유"의 기반이 됨|
|`middlewares/errorHandler.js`|예외를 최종적으로 받아 처리|서버 내부 오류 메시지·스택 트레이스를 사용자에게 그대로 노출하지 않고 일반화된 문구만 표시 → 교재 전반의 **"에러 메시지 정보노출 방지"** 원칙 구현|
|`/var/log/labs`에 로그 기록|`morgan` 미들웨어로 모든 HTTP 요청 기록|이후 각 장에서 "공격이 실제 어떤 요청 형태로 들어왔는가"를 사후에 다시 살펴볼 때 사용|
|`/healthz` 엔드포인트|단순 "ok" 응답|0.8절 서비스 등록 후 상태 확인, 0.9절 환경 점검에서 반복 사용|
|`/lab/report` (공통 페이지)|그 장의 취약점 개요·핵심 코드 차이·참고자료를 정리해 보여주는 요약 페이지|강의 말미에 내용을 한 화면으로 복습 가능하게 함|

### EJS 템플릿 구조 핵심 개념

```
layout.ejs
 ├─ <head> (문자 인코딩 / 페이지 제목 / CSS)
 ├─ header.ejs   (include)
 ├─ nav.ejs       (include, layout 내부)
 ├─ <%- body %>   ← 페이지별 콘텐츠가 삽입되는 지점
 └─ footer.ejs   (include)
```

- `<%= 변수 %>` → 변수 값을 HTML에 출력
- `<%- include('파일') %>` → 다른 EJS 파일을 현재 위치에 삽입
- `<%- body %>` → 페이지별 본문을 레이아웃 안에 삽입

→ `layout.ejs`는 공통 구조, `body`는 페이지별 콘텐츠를 담당하도록 역할을 분리.

### 세션 기반 로그인 골격

`express-session`을 이용해 로그인 기능의 공통 골격을 미리 구성한다.

- 세션 저장 방식: 기본값(MemoryStore) 사용 → **실습 환경에서는 서버 재시작 시 세션 소실, 운영 환경에는 부적합**하지만 교육용으로는 충분
- `cookie.httpOnly: true` → JavaScript에서 쿠키 직접 접근 차단 (XSS 발생 시 쿠키 탈취 방지 목적, 단 XSS 자체를 막지는 못함)
- `cookie.maxAge: 1000 * 60 * 60` → 세션 쿠키 유효기간 1시간

### 취약/안전 라우트 공존 설계 (핵심 설계 결정)

> 이 스캐폴드에서 **가장 중요한 설계 결정**은 취약한 코드와 안전한 코드를 별도 프로젝트로 나누지 않고, **하나의 애플리케이션 안에 라우트만 다르게 하여 공존**시킨다는 점이다.

- 별도 프로젝트로 분리했다면 → 강의 중 두 코드를 비교하기 위해 서버를 껐다 켜거나 포트를 바꿔가며 오가야 하는 번거로움 발생
- 하나의 앱 안에 `/lab/vuln/...`과 `/lab/patched/...`로 공존 → 브라우저 주소창의 경로 한 부분만 바꿔서 즉시 두 버전의 동작 차이를 나란히 시연 가능

---

## 서비스 운영 — systemd와 Nginx

### 상시 실행 서비스가 필요한 이유

`node app.js`로 터미널에서 직접 실행하는 방식의 한계:

- 터미널 창을 닫으면 애플리케이션도 함께 종료
- 서버 재부팅 시 모든 애플리케이션을 하나하나 재실행해야 함
- 오류로 죽어도 자동으로 재시작해주는 장치 없음

→ 리눅스의 서비스 관리자인 **systemd**에 "서비스"로 등록하여 해결.

### systemd 유닛 파일 구조 (`/etc/systemd/system/lab01.service`)

```ini
[Unit]
Description=lab01-sqli - SQL 삽입 실습 애플리케이션
After=network.target mysql.service

[Service]
Type=simple
User=labuser
WorkingDirectory=/opt/labs/lab01-sqli
ExecStart=/usr/bin/node /opt/labs/lab01-sqli/app.js
EnvironmentFile=/opt/labs/lab01-sqli/.env
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

|항목|의미 / 설계 이유|
|---|---|
|`After=network.target mysql.service`|네트워크와 MySQL이 준비된 후에 시작되도록 순서 지정|
|`User=labuser`|**관리자(root) 계정이 아닌 0.2절에서 만든 최소 권한 실습 계정으로 실행** → 최소 권한 원칙을 실제 구현. 만약 root로 실행했다면 6장의 OS 명령어 삽입 공격 시 서버 전체가 장악될 수 있음|
|`WorkingDirectory`, `ExecStart`|실행 디렉토리와 실행 명령 지정|
|`EnvironmentFile`|`.env`의 환경변수를 프로세스 시작 시 함께 불러오도록 지정|
|`Restart=always`|어떤 이유로든 종료되면 자동 재시작 → 서비스 안정성 확보|

### 서비스 등록·기동·확인 명령

```bash
sudo systemctl daemon-reload        # 유닛 파일 변경 시 필수
sudo systemctl enable --now lab01   # 등록 + 즉시 시작 + 부팅 시 자동시작
sudo systemctl status lab01         # 상태 확인
sudo systemctl restart lab01        # 코드 변경 후 재시작
journalctl -u lab01 -f              # 로그 실시간 확인
```

### 다중 앱 관리: 템플릿 유닛 (심화, 선택적)

- `@` 기호를 이용한 템플릿 유닛 기능으로 하나의 템플릿(`lab@.service`)으로 `lab01`, `lab02` 등 여러 서비스 관리 가능
- 단, 각 애플리케이션의 포트 번호·디렉토리가 서로 달라 이 교재는 **장마다 개별 유닛 파일을 만드는 방식을 기본으로 채택**, 템플릿 방식은 심화 옵션으로만 소개

### Nginx — 리버스 프록시

**필요한 이유**: 각 애플리케이션이 3001~3013번 개별 포트에서 실행 중이지만, 실제 웹사이트는 포트 번호 없이(80번) 접속하는 것이 일반적이며, 여러 앱을 하나의 도메인 아래 경로/서브도메인으로 연결해줄 역할이 필요함.

```
사용자 요청 → Nginx(80번 포트) → 요청 내용(경로/도메인) 판단 → 해당 Node.js 앱(3001~3013)으로 전달
```

**설정 예시** (`/etc/nginx/sites-available/lab01.conf`):

```nginx
server {
    listen 80;
    server_name lab01.local;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

|설정|이유|
|---|---|
|`proxy_pass`|요청을 백엔드(3001번 등)로 전달|
|`proxy_set_header ...`|원래 요청 정보(접속자 IP, 원 호스트명 등)가 프록시를 거치며 사라지지 않고 뒷단까지 전달되도록 함|
|심볼릭 링크 활성화 (`sites-available` → `sites-enabled`)|Ubuntu 계열 방식|
|`nginx -t` → `systemctl reload nginx`|문법 검사 후 무중단 반영|

**도메인/호스트 매핑** (`/etc/hosts`):

```
127.0.0.1  lab01.local lab02.local board.local bank.local
127.0.0.1  attacker.local
```

- `attacker.local`을 별도로 두는 이유: 5장(XSS)·12장(CSRF)의 공격자 서버를 `localhost`로 그냥 접속하면 실습 앱과 "같은 출처(origin)"인지 "다른 출처"인지 브라우저 관점에서 모호해짐. XSS·CSRF는 서로 다른 출처 간 신뢰 오남용이 본질이므로, **명확히 구분되는 별도 이름을 부여해 "출처가 다르다"는 개념을 눈으로 확인 가능하게 함**

**SELinux 대응** (Rocky Linux):

```bash
sudo setsebool -P httpd_can_network_connect on
```

→ 하지 않으면 Nginx가 뒷단 포트로 연결하지 못해 502 Bad Gateway 발생

**업로드 디렉토리 권한 설계** (7장 파일 업로드 대비):

```bash
sudo chown labuser:www-data /var/lab-uploads
sudo chmod 750 /var/lab-uploads
```

→ 애플리케이션 실행 계정(labuser)에는 읽기/쓰기, Nginx 실행 그룹(www-data)에는 읽기만 부여, 그 외에는 권한 없음. **"업로드된 파일이 실행 가능한 스크립트로 취급되어 웹셸 공격에 악용되는" 시나리오를 방지**하기 위한 근거가 이 권한 설계에 있음.

**HTTPS(자체 서명 인증서)**: 12장(CSRF)의 `Secure` 쿠키 속성 실습을 위해 필요.

```bash
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
```

---

##  환경 점검

### 설치 항목 체크리스트

```bash
node -v                              # Node.js 설치 확인
npm -v                               # npm 설치 확인
systemctl is-active mysql            # MySQL 서비스 동작 확인
systemctl is-active nginx            # Nginx 서비스 동작 확인
sudo ufw status                      # 방화벽 규칙 확인 (Rocky: firewall-cmd --list-all)
curl http://localhost:3001/healthz   # 애플리케이션 정상 응답 확인
```

### 트러블슈팅 요약

|증상|원인|대응|
|---|---|---|
|`EADDRINUSE` (포트 충돌)|다른 프로세스가 해당 포트 점유 중|`ss -tlnp \| grep 포트번호`로 확인 후 프로세스 종료|
|`EACCES` (권한 오류, 1024번 이하 포트)|일반 사용자 권한으로 80번 등 직접 열려 함|이 구조상 애플리케이션은 항상 3000번대 포트만 사용하고 Nginx가 80번을 대신 열므로 애초에 발생하지 않도록 설계됨|
|MySQL 인증 플러그인 오류 (`ER_NOT_SUPPORTED_AUTH_MODE`)|Node.js 구형 드라이버가 `caching_sha2_password` 미지원|계정 인증 방식을 `mysql_native_password`로 변경 또는 드라이버 업그레이드|
|SELinux 차단 (Rocky)|Nginx의 뒷단 연결 시도 자체를 차단|`setsebool -P httpd_can_network_connect on`, 원인 확인은 `sudo ausearch -m avc -ts recent`|
|Nginx 502 Bad Gateway|① 뒷단 Node.js 앱이 아직 시작 안 됨/오류로 종료됨 (`systemctl status lab01`, `journalctl -u lab01`로 확인) 또는 ② SELinux·방화벽이 연결 차단|위 두 원인 순서대로 점검|
