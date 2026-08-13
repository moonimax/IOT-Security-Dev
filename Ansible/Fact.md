

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




```vim
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