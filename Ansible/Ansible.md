
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


**command vs shell**
- command : 단순 명령어 실행
- shell : 쉘 내장 변수, 함수 등을 사용하여 명령어 실행


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



**인벤토리 조회**
```bash
[user@control 01_ansible_inventory]$ ansible 192.168.51.1 --list-hosts 
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit         localhost does not match 'all'                                                                       [WARNING]: Could not match supplied host pattern, ignoring: 192.168.51.1      


[user@control 01_ansible_inventory]$ ansible 192.168.51.1 -i inventory_ex_04 --list-hosts              hosts (1):                                    192.168.51.1   
```


---

## Ansible.cfg

- 작업 디렉토리의 ansible.cfg
- 사용자 홈 디렉토리의 ansible.cfg
- etc 디렉토리의 ansible.cfg


**Ansible 파일 설정 위치**
```bash
[user@control 02_ansible_cfg]$ ansible --version
config file = /etc/ansible/ansible.cfg                                                               configured module search path = ['/home/user/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']


[defaults] - ansible 작업의 기본값 설정

inventory = /etc/ansible/hosts
remote_user = root
ask_pass = True

  

[privilege_escalation] 

#become=True           --사용자 전환 허용
#become_method=sudo    
#become_user=root
#become_ask_pass=False   -- 사용자 sudo 사용 시 pass 요청

```

[[Ansible 기본 파일 설정]( https://github.com/ansible/ansible/blob/stable-2.9/examples/ansible.cfg)]



---


관리 노드에서 ssh 키를 제어 노드에 넘기기


제어 노드
```bash
ssh-keygen -- 공개키 생성

공개키 생성 후 위치 확인
/home/user/.ssh/id_ed25519.pub

vim playbook.yaml 

--원격 접속
ansible-playbook playbook.yaml
```

```yaml
---
- name: Public key is deployed to managed hosts for ansible
  hosts: 192.168.51.131
  tasks:
    - name: Ensure key is in user's authorized_keys
      authorized_keys:
        user: user
        state: present
        key: '{{ item }}'
      with_file:
        - ~/.ssh/id_ed25519.pub
```

```bash
ansible --help
```


---

에드훅

구조 : `ansible host-pattern -m MODULE_NAME -a MODULE_ARGS -i INVENTORY`

디렉토리 생성
```bash
mkdir 03_ansible_adhoc
cp ../02_ansible_cfg/inventory .
co ../02_ansible_cfg/ansible.cfg .
```

ansible.cfg 편집
```cfg
inventory = inventory
ask_pass = False
```


ssh 타 통신 서버 icmp 확인
```bash
ansible [host-name] -m ping
SUCCESS => {                                                                            "ansible_facts": {                                                  "discovered_interpreter_python": "/usr/bin/python3"},                         "changed": false,                                                             "ping": "pong"         
```


```bash

ansible 192.168.51.131 -m user -a 'name=ansible_user uid=1111 state=present'
192.168.63.134 | CHANGED => {                                                                            "ansible_facts": {                                                                                       "discovered_interpreter_python": "/usr/bin/python3"                                              },                                                                                                   "changed": true,                                                                                     "comment": "",                                                                                       "create_home": true,                                                                                 "group": 1111,                                                                                       "home": "/home/ansible_user",                                                                        "name": "ansible_user",                                                                              "shell": "/bin/bash",                                                                                "state": "present",                                                                                  "system": false,                                                                                     "uid": 1111                                                                                      }  

ansible 192.168.51.131 -m user -a 'name=ansible_user uid=1122 state=present'
```



**manage linux 쪽 세팅**
```shell
#!/bin/bash
echo "hello i am managed OS"
```


일반적으로 ssh로 /usr/bin 경로 내 명령어 실행
```bash
ls -l hello.sh                                                      -rw-r--r--. 1 user user 42 Aug 11 15:24 hello.sh
chmod a+x hello.sh 
[user@managed ~]$ cp hello.sh /usr/bin/hello                                  cp: cannot create regular file '/usr/bin/hello': Permission denied            [user@managed ~]$ sudo cp hello.sh /usr/bin/hello                             [user@managed ~]$ hello                                                       hello i am managed OS                             
```


**control node**
```bash
[user@control 03_ansible_adhoc]$ ansible 192.168.63.134 -m command -a /usr/bin/hello              
192.168.63.134 | CHANGED | rc=0 >>                                            hello i am managed OS  
```