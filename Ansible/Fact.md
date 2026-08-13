

default ipv4
![](Images/Pasted%20image%2020260813113426.png)

인터페이스
![](Images/Pasted%20image%2020260813112957.png)


ipv4
![](Images/Pasted%20image%2020260813113039.png)


lsblk
- 디스크 공간 할당
![](Images/Pasted%20image%2020260813113200.png)


fqdn
![](Images/Pasted%20image%2020260813113305.png)


dns
![](Images/Pasted%20image%2020260813113531.png)




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


