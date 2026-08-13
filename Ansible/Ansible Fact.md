
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

## Playbook 모음


## 1. 패키지/서비스 설치



```yaml
---
- name: Install httpd and Start httpd
  hosts:
    - 192.168.63.134
    - 192.168.63.128
  vars_files:
    - httpd.yaml
  tasks:
    - name: sudo dnf install httpd
      dnf:
        name: "{{ httpd_pkg }}"
        state: present

    - name: sudo systemctl enable httpd --now
      service:
        name: "{{ httpd_svc }}"
        state: started
        enabled: yes
```

**목적**
패키지명/서비스명을 `vars_files`로 외부 변수 파일에서 불러오도록 구성

---

## 2. Ubuntu / Rocky 배포판별 조건 설치


```yaml
---
- name: Rocky & Ubuntu
  hosts: 192.168.51.131
  tasks:
    - name: Install web package in Ubuntu
      apt:
        name: apache2
        state: present
      when: ansible_distribution == "Ubuntu"

    - name: Install web package in Rocky
      dnf:
        name: httpd
        state: present
      when: ansible_distribution == "Rocky"
```

**목적**
Playbook 내 (Ubuntu는 apt, Rocky는 dnf)을 분리하여 설치. 
`when` 조건으로 `ansible_distribution`로 패키지 구분

---

## 3. vars / loop


```yaml
---
- name: Configurer Mail Server
  hosts:
    - 192.168.63.128
    - 192.168.63.134
  vars:
    mail_servers:
      - postfix
      - dovecot
  tasks:
    - name: sudo dnf install mail packages
      dnf:
        name: "{{ item }}"
        state: present
      loop: "{{ mail_servers }}"

    - name: sudo systemctl enable packages --now
      service:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop: "{{ mail_servers }}"
```

**목적** 
여러 패키지(postfix, dovecot)를 반복문으로 한 번에 설치 

---

## 4. 딕셔너리 리스트 + loop



```yaml
---
- name: User exists and are in the correct group
  hosts: 192.168.63.128
  tasks:
    - name: Check user or Create user
      user:
        name: "{{ item.name }}"
        state: present
        group: "{{ item.group }}"
      loop:
        - name: Jane
          group: wheel
        - name: Joe
          group: root
```

**목적**
사용자별 `item.name`, `item.group`로 구분지음 

---

## 5. 변수 정의 when 여부에 따른 실행



```yaml
---
- name: Test variable is defined
  hosts: 192.168.63.134
  vars:
    my_service: httpd
  tasks:
    - name: sudo dnf -y install "{{ my_service }}"
      dnf:
        name: "{{ my_service }}"
        state: present
      when: my_service is defined
```


**목적**
변수가 정의되어 있을 때만 task를 실행

>  `vars`의 변수명과 `when`에서 변수명이 일치 필요하며 다를 시 `skipping` 처리

---

## 6. 디스크 여유 공간 조건부 설치


```yaml
---
- name: Install mysql-server all server
  hosts: all
  tasks:
    - name: sudo dnf -y install mysql-server
      dnf:
        name: mysql-server
        state: present
      loop: "{{ ansible_mounts }}"
      when: item.mount == "/" and item.size_available >= 300000000
```

**목적**
실습 삼아 루트(`/`)  파티션의 디스크 공간이 300MB 이상일 때만 mysql-server를 설치. `loop`으로 마운트 목록을 순회하며 `when` 조건으로 필터링


---

## 7. register + ignore_errors + when



```yaml
---
- name: Restart httpd if postfix is running
  hosts: 192.168.63.134
  tasks:
    - name: Get postfix server status
      command: /usr/bin/systemctl is-active postfix
      ignore_errors: yes
      register: result

    - name: Restart httpd based on postfix status
      service:
        name: httpd
        state: restarted
      when: result.rc == 0
```

**목적**
postfix 서비스 결과 값을 `register`로 저장해두고 `rc`을 이전 명시한 task의 `when` 조건으로 사용. `ignore_errors`로 명령 실패 시 playbook 이어서 진행

---




