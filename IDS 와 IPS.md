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

Snort는 네트워크가 오고 가는 패킷(iSO 3-Layer)을 실시간으로 참아보고 , 악성코드나 해킹 징후를 탐지하는 시스템한다.


- NFQ
	- IPTables 패킷을 처리하는 새롭고 개선된 방법
	- 네트워크 트래픽을 드랍하거나 허용하는 기능 제공
		위에서 구현한 suricata와 연동하기 위해서 만들어진 소프트웨어 제품군이라고 판단하면 좋음
- IPQ
	- IPTableㄴ 패킷을 처리하는 오래된 방법
	- in-line 구조를 대체하는 기능을 제공한다.

> IPTables란?
> 리눅스 네트워크 보안에서 함께 사용되면서, 완전히 다른 역할을 하는 도구이다. Snort는 네트워크를 감시하고 탐지하는 'CCTV' 이고, IPtables는 통해을 제어하는 '차단기' 역할을 수행한다.


---

WAF(Web Application Firewall)

HTTP(s) 본문 해석과 SSL/TLS 처리를 위하여 장비 자체의 부하 발생
Forward Proxy
- 외부에서 내부 웹서버 접근 시 웹 서버 IP를 숨겨주는 역할
Reverse Proxy
- 인터넷에 들어오는 모든 트래픽을 앞단에서 맞이하는 역할