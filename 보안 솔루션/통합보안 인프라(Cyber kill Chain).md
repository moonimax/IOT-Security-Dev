통합 보안 인프라를 활용한 위협탐지 실습
= Cyber Kill Chain 기반의 시나리오 실습

**Cyber Kill Chain이란?
-> 사이버 보안 모델 중 하나로, 록히드 마틴이 제일 처음 발표하게 됨

-> 군사 공격 개념에서 시작이 됐고, 공격을 수행하는(침입 과정)을 일련의 순차적인 단계로 나누어서 분석함

1. 정찰
2. 무기화
3. 전달
4. 공격 ㅣㄹ행
5. 설치
6. C&C
7. 목표 달성

## 정찰
- nmap을 활용한 ping 스캔으로 호스트 식별
-  nmap -sn 192.168.0.200/24
- sn은 ping scan할떄 사용하는 옵션(-sP) 포트 스캔은 수행하지 않ㄴ는다. 호스트가 살아있는지만 검사
	- nmap -sV -sC -p 192.168.0.200
- -sV (Version Detection) , -sC(Defualt Script Scanning), -p (All ports Scan)
	- 열려있는 포트ㅡ에서 어떤 서비스가 실행중인지(+정확한 버전)
- 익명 FTP 접속 허용 여부, SSH 호스트 키 확인, robots.txt 분석 등 기본적인 설정 오류나 위험 요소를 스캐닝
	- 기본적으로 nmap이 스캔하는 1,000포트(well-know port)들 뿐만 아니라, 1-65535번까지의 포트를 빠짐없이 싹 다 스캐해준다.
- export WP_SCAN_KEY=yAOUBAV7nMedCjyDjJdLlfES57WGgUd5mNemuLwnWbM
- wpscan --url http://192.168.0.200 --api-token $WP_SCAN_KEY --plugins-detection aggressive

![](../Images/Pasted%20image%2020261019111502.png)


![](../Images/Pasted%20image%2020261019111435.png)



![](../Images/Pasted%20image%2020261019111809.png)


---

```
https://www.sentinelone.com/vulnerability-database/cve-2023-3460/
https://www.cve.org/CVERecord?id=CVE-2022-1329
```

위 취약점들이 스캐닝됨 대표적으로 아래 두가지가 있음

ultimate-member
- 2.6.6
	- CVE-2023-3460
		- 비인가자가 관리자 계정을 생성할 수 있는 취약점

- elementor
	- CVE-2022-1329
	- 파일 업로드 취약점으로 RCE까지 이어질 수 있는 취약점

무기화(Weaponization)
- 초기 침투용 Exploit 준비
- 1. CVE-2023-3460
	- Ultimate-member plugin 안에 사용자 등록 시 특정 메타데이터 키를 사용자가 직접 수정하지 못하도록 하는 Black List 필터링 방식을 활용함
	- 필터링 로직상의 결함이 존재하여 대소문자 혹은 특정 인코딩을 사용하여 우회 가능한 취약점이 존재했늣다.
	- 공격자는 회원가입 요청 패킷에 특정 조작된 필드를 포함해서 전송 -> 필터링 로직을 위회한 값이 서버에서 그대로 처리됨 -> 일반 사용자로 회원 가입이 되어야할 요청이 관리자 권한을 가진 계정으로 생성 -> 인증 없이 최고 관리자 권한 root 을 생성(탈취)할 수 있음



![](../Images/Pasted%20image%2020261019112752.png)


![](../Images/Pasted%20image%2020261019112856.png)