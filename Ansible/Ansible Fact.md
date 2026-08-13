
**Ansible Facts**
playbook 실행 시 `gather_facts: true` 명령어가 기본적으로 세팅되어 수집되는 정보들이다.


*default ipv4*
- 서버의 기본 네트워크 인터페이스 정보를 담은 딕셔너리
- 주요 키
	- `address` : IP 주소
	- `gateway` : 기본 게이트웨이
	- `interface` : 인터페이스 이름 (예: ens33)
	- `netmask`, `network`, `prefix` : 서브넷 관련 정보
	- `macaddress` : MAC 주소
![](Images/Pasted%20image%2020260813113426.png)


*interfaces*
- 서버에 존재하는 모든 네트워크 인터페이스 이름의 리스트
![](Images/Pasted%20image%2020260813112957.png)


*ipv4*
개별 인터페이스별 IPv4 상세 정보
![](Images/Pasted%20image%2020260813113039.png)


*lsblk*
- 원격 서버가 아닌 리눅스 자체의 명령어
- 디스크 및 파티션 구조를 트리 형태로 표현
![](Images/Pasted%20image%2020260813113200.png)


*fqdn*
- host의 전체 도메인 이름
![](Images/Pasted%20image%2020260813113305.png)


*dns*
- 서버에 설정된 DNS 관련 정보
![](Images/Pasted%20image%2020260813113531.png)


---




```yaml
---
- name: Check ipv4 address & Check loopback interface
  hosts: 192.168.63.134
  tasks:
    - name: check ipv4 address
      debug:
        msg: "The default ipv4 address is {{ ansible_facts['default_ipv4']['address'] }}"

    - name: check loopback interface
      debug:
        msg: "The interface name of loopback is {{ ansible_facts['interfaces'] | select('match', '^lo') | list }}"
```

![](../Images/Pasted%20image%2020260813121820.png)


gather_facts: false룰 넣어서 Gather facts 태스크를 출력하지 않게 바꿀 수 있다. 아래와 같다.
```yaml
---
- name: Install httpd and Start httpd
  hosts: 192.168.63.134
  gather_facts: false
  tasks:
    - name: sudo dnf -y install httpd
      dnf:
        name: httpd
        state: present

    - name: sudo systemctl enable httpd --now
      service:
        name: httpd
        state: started
        enabled: yes

- name: Install mysql-server and Start mysqld
  hosts:
    - 192.168.63.134
  gather_facts: false
  tasks:
    - name: Install mysql-server
      dnf:
        name: mysql-server
        state: present

    - name: Start mysqld
      service:
        name: mysqld
        state: started
        enabled: true
```



```yaml
vars:
  mail_servers:
    - postfix
    - dovecot

tasks:
  - name: sudo dnf install mail packages
    dnf:
      name: "{{ item }}"
    loop: "{{ mail_servers }}"          
```




- 리스트 원소가 **딕셔너리**(key-value 쌍) — 각 원소가 `name`, `group` 두 개의 속성을 가짐
- 그래서 `item` 하나로 끝나지 않고, **`item.name`**, **`item.group`**처럼 딕셔너리의 키를 지정해서 값을 꺼내야 함





