dfdf

## 1. Handlers 실습

### playbook1.yaml - handler 


```yaml
---
- name: handler is running
  hosts: 192.168.63.134
  tasks:
    - name: Install httpd
      dnf:
        name: httpd
        state: present
      notify: Install mysql-server

  handlers:
    - name: Install mysql-server
      dnf:
        name: mysql-server
        state: present
```

- `httpd` 설치 태스크가 변경(changed)되면 `notify`를 통해 handler 호출

---

### playbook2.yaml 

```yaml
---
- name: Install httpd & start httpd, Install mysql-server & start mysqld
  hosts: 192.168.63.134
  tasks:
    - name: sudo dnf -y install httpd
      dnf:
        name: httpd
        state: present
      notify: start httpd

    - name: sudo dnf -y install mysql-server
      dnf:
        name: mysql-server
        state: present
      notify: start mysqld

  handlers:
    - name: start httpd
      service:
        name: httpd
        state: started
        enabled: yes

    - name: start mysqld
      service:
        name: mysqld
        state: started
        enabled: true
```

- 패키지 설치(`httpd`, `mysql-server`) 후 각각의 handler를 통해 서비스 시작 및 부팅 시 자동 실행 설정(`enabled`)
- 하나의 태스크가 하나의 handler를 notify하는 1:1 구조

---

### playbook3.yaml - handler 2 개 



```yaml
---
- name: One task & two handlers
  hosts: 192.168.63.134
  tasks:
    - name: echo test
      command: /user/bin/echo test

  handlers:
    - name: restart httpd
      service:
        name: httpd
        state: restarted
```

- `command` 모듈로 단순 echo 태스크 실행
- 

---

## ignore_errors 



```yaml
---
- name: Install notapkg
  hosts: 192.168.63.134
  tasks:
    - dnf:
        name: not a package
        state: present
      ignore_errors: yes
```

- 존재하지 않는 패키지(`not a package`) 설치
- `ignore_errors: yes`로 플레이북 실행이 중단되지 않고 진행됨

---

### playbook2.yaml - handler + ignore_errors 조합



```yaml
---
- name: handlers & ignore_errors
  hosts: 192.168.63.134
  tasks:
    - name: echo test
      command: /usr/bin/echo test
      notify: restart httpd

    - name: failed task
      dnf:
        name: notapkg
        state: present
      ignore_errors: yes

  handlers:
    - name: restart httpd
      service:
        name: httpd
        state: restarted
```

- 태스크가 실패해도 이전에 notify된 handler 실행

---

### playbook3.yaml - failed_when으로 커스텀 실패 조건 지정



```yaml
---
- name: failed_when
  hosts: 192.168.63.134
  tasks:
    - name: restart httpd
      service:
        name: httpd
        state: restarted
      register: result
      failed_when: result.status.UMask=="0022"

    - name: debug result
      debug:
        var: result
```

- `service` 모듈로 httpd 재시작 후 결과를 `register: result`로 저장
- `failed_when` 조건식(`result.status.UMask=="0022"`)이 참이면 태스크를 강제로 실패 처리

![](../Images/Pasted%20image%2020260814103550.png)

![](../Images/Pasted%20image%2020260814103648.png)



