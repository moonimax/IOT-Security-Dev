IAC
- Instructure As a Code
- Terraform


두 가지를 이용해서 시작
- 제어 노드(Rocky Linux1)
	- 대량의 노드들에게 코드를 제어하여 취약점 탐지에 유리하다.
	- Ansible 설치는 제어 노드에서만 이루어진다.
	- 자기 자신도 관리 대상에 포함될 수 있으므로 python 설치 필요
- 관리 노드(Rocky Linux2)
	- python 설치 필요


파일 형식
- .yaml or .yml

네트워크
- 소켓 통신
- IP 주소
- TCP / UDP
- 포트 번호

리눅스
- 운영 체제
- 서버용
- 구성 & 명령어
- 오픈 소스

---

환경 세팅

1. 사용자 비밀번호 로그인 가능 설정 

```bash
 sudo vim /etc/ssh/sshd_config
```

2. 터미널 1 rocky1 연동

![](Images/Pasted%20image%2020260811093232.png)

3. 제어 노드

```bash
-- 제어 노드
sudo hostnamectl set-hostname control
-- 관리 노드
sudo hostnamectl set-hostname managed

bash
```

4. 제어 노드와 관리 노드 설정 완료

![](Images/Pasted%20image%2020260811093706.png)
![](Images/Pasted%20image%2020260811093733.png)


5. 