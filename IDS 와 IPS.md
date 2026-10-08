![](Images/Suricata%20ping%20test.mp4)
---

### Ubuntu 서버용 세팅
![](Images/Pasted%20image%2020261007092517.png)


 **[Ubuntu 24.04 고정 ip 할당]**
 - NAT 대역
	 - IP = 192.158.0.100
	 - Gateway = 192.168.0.2
- Subnet = 255.255.255.0 or 192.168.0.100/24
- name server : 8.8.8.8 or 8.8.4.4


**VMnet1**
- IP = 192.168.30.1
- Subnet = 255.255.255.0

![](Images/Pasted%20image%2020261007094953.png)


![](Images/Pasted%20image%2020261007110929.png)



---
### Suricata

NFQUEUE 라이브러리를 활용하여 패킷을 확인한다
- 커널 패킷 필터로 큐에 대한 접근 권한을 주는 라이브러리

![](Images/Suricata%20ping%20test%201.mp4)


![](Images/Pasted%20image%2020261007150156.png)

![](Images/Pasted%20image%2020261007152406.png)


![](Images/Pasted%20image%2020261007150212.png)


---

Snort
- NFQ
	- IPTables 패킷을 처리하는 새롭고 개선된 방법
	- 네트워크 트래픽을 드랍하거나 허용하는 기능 제공
		위에서 구현한 suricata와 연동하기 위해서 만들어진 소프트웨어 제품군이라고 판단하면 좋음
- IPQ
	- IPTableㄴ 패킷을 처리하는 오래된 방법
	- in-line 구조를 대체하는 기능을 제공한다.

> IPTables란?
> 