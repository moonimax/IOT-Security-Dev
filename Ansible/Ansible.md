
**IAC**
- Instructure As a Code
- Terraform


**구성 요소**
- 제어 노드(Rocky Linux1)
	- 대량의 노드들에게 코드를 제어하여 취약점 탐지에 유리하다.
	- `Ansible` 설치는 제어 노드에서만 이루어진다.
	- 자기 자신도 관리 대상에 포함될 수 있으므로 python 설치 필요
- 관리 노드(Rocky Linux2)
	- python 설치 필요


**제어 노드 기능**
- 관리 노드 목록
	- `Inventory`
- 코드 파일
	- `Playbook(.yaml or .yml)`
- Ansible.config



---

## 환경 세팅

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


5. Ansible Install
```bash
sudo dnf install -y epel-release
sudo dnf install -y ansible
```


6. 
```
sudo vim /etc/sudoers.d/user

user ALL=(ALL) NOPASSWD:ALL
```


7. 동일한 파일이 있을 때 Directory > File
```bash
[user@managed ~]$ sudo vim /etc/sudoers.d/user                                [user@managed ~]$ sudo getenforce                                             Permissive                                                                    [user@managed ~]$ sudo setenforce 1                                           [user@managed ~]$ ls /etc/sudoers                                             /etc/sudoers
```

- 사용자 작업 디렉토리 > 사용자 홈 디렉토리 > etc 디렉토리 > etc 설정 파일


---


**Shell Script vs Ansible**

Shell Script
- 리눅스 명령어의 집합 파일
- 기존 작업을 무시하고 모든 코드를 다 실행


Ansible
- 모듈의 형태로 테스크를 구성하여 playbook 파일 작성
- 변경 사항을 감지하고 변경 사항이 있다면 실행(멱등성)


---


## Inventory 

**단일 주소**
- 관리 노드들을 모아 놓은 파일 형식
- 추후 ansible.cfg 파일 내 `파일명`을 명시

```bash
vim inventory_ex_01

# ip 주소, 도메인 주소
# /etc/hosts는 관여하지 않음
192.168.51.129
192.168.51.131
web01.example.com
[web02.example.com](http://web02.example.com)
```


**그룹 단위 주소**

```bash
#그룹 이름은 [] 대괄호로 묶음
[webservers]
web01.example.com
web02.example.com
192.168.63.134
192.168.63.128

[dbservers]
db01.example.com
db02.example.com

```


**중첩 그룹 단위 주소**
```bash
#중첩 그룹
#그룹을 한 번 더 묶기
#[중첩 그룹 이름 : children]
[webdevelopers]
192.168.51.1
192.168.51.2

[operators]
192.168.51.3
192.168.51.4

[security]
192.168.51.5
192.168.51.6

[company:children]
webdevelopers
operators
security

```


**단일 주소와 그룹 조합**
