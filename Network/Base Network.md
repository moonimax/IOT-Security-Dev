
---

### 1. Wireshark 기초 

- **패킷 캡처와 MAC 주소**
	- WireShark에서 캡처 인터페이스를 선택하여 어댑터를 지나가는 Frame, Packet을 볼 수 있다. Frame (2계층), Packet(3계층)
- **MAC 주소 확인**
	- 통신의 시작/도착 지점은 IP만이 아니라 물리 계층에서는 MAC 주소로도 식별됨. 같은 로컬 네트워크(서브넷)에서 통신할 때는 Source/Destination MAC이 게이트웨이(라우터)의 MAC으로 식별되는 경우가 많다
- **MAC 주소 구조**: `00:00:00:00:00:00` 형태의 6바이트(48비트) 주소. `FF:FF:FF:FF:FF:FF`는 브로드캐스트 주소(같은 네트워크의 모든 장치에게 전송)


**ICMP**
- ICMP(Internet Control Message Protocol)는 4계층 전송 계층에서 통신 중 발생하는 오류를 보고하고, 상태 진단하는 프로토콜이 있다. 대표적인 예시로 `ping`, `traceroute`가 있다.
- `ping 8.8.8.8` -> Google Public DNS
- `ping 1.1.1.1` -> Cloudflare Public DNS
  공식적으로 Google과 Cloudflare에서 열어놓은 도메인 주소로 ping 전송을 통해 패킷의 정보를 확인할 수 있다.



**실습**

![](../Images/icmpping.png)

```bash
C:\Users\ > arp -a
인터페이스: 192.168.202.255 --- 0x8                       --실질적인 물리적 주소와 매핑
```


---

### 2. 터널링 / VPN

- **개념**
	- **터널링** : 네트워크 위 가상의 파이프라인을 구축하는 기술. 엔드포인트 단에서 암/복호화를 수행.
	- **VPN** : 터널링을 활용한 대표 사례.
	- OSI 2계층(데이터링크)는 자체적으로 보안 매커니즘이 부족하기 때문에 3계층 *IPsec* 같은 프로토콜로 보완한다.

### 실습 Lab 네트워크 구성

 Kali / Rocky Linux / Windows 3대를 **같은 가상 네트워크(Host-only 또는 Internal Network)**에 붙여서 진행한다. 

| 역할              | OS          | 예시 IP           |
| --------------- | ----------- | --------------- |
| 터널 엔드포인트 A      | Kali Linux  | 192.168.63.133  |
| 터널 엔드포인트 B      | Rocky Linux | 192.168.63.134  |
| 관찰자 / VPN 클라이언트 | Windows     | 192.168.202.255 |

**실습 A. GRE(Kali ↔ Rocky Linux) GRE 캡슐화**

1. **Kali 터미널 실행**

```bash
   sudo modprobe ip_gre
   lsmod | grep gre
```

2. **Kali 터미널 실행** → GRE 터널 인터페이스 생성 (local/remote는 실제 물리 IP, 뒤의 10.0.0.1은 터널 내부용 가상 IP)


```bash
   sudo ip tunnel add gre1 mode gre remote 192.168.100.20 local 192.168.100.10 ttl 255
   sudo ip link set gre1 up
   sudo ip addr add 10.0.0.1/30 dev gre1
```

3. **Rocky Linux 터미널 실행** 
→ Rocky는 기본적으로 `firewalld`가 켜져 있어 GRE(프로토콜 47)를 막을 수 있어 방화벽 허용


```bash
   sudo firewall-cmd --add-protocol=gre --permanent
   sudo firewall-cmd --reload
```

4. **Rocky Linux 터미널 실행** → 동일하게 GRE 터널 생성 (local/remote를 반대로)


```bash
   sudo modprobe ip_gre
   sudo ip tunnel add gre1 mode gre remote 192.168.100.10 local 192.168.100.20 ttl 255
   sudo ip link set gre1 up
   sudo ip addr add 10.0.0.2/30 dev gre1
```

5. **Kali 터미널 실행** → 터널 내부 IP로 통신 테스트


```bash
   ping -c 4 10.0.0.2
```

→ 응답이 오면 GRE 터널이 정상 동작하는 것 6. **Windows에서 Wireshark 실행** → (Windows가 같은 네트워크 세그먼트를 볼 수 있도록 브리지/스팬 구성이 안 되어 있다면, 대신 **Kali나 Rocky의 물리 인터페이스(eth0)**에서 캡처) → 필터에 입력

```
   ip.proto == 47
```

7. **결과 확인** → GRE로 캡슐화된 패킷을 열어보면:
    - 바깥쪽 IP 헤더: Kali(192.168.100.10) ↔ Rocky(192.168.100.20)
    - 그 안에 **원본 ICMP 패킷(10.0.0.1 ↔ 10.0.0.2)이 평문 그대로 보임**
    - 즉, GRE는 캡슐화만 할 뿐 암호화는 하지 않는다는 것을 직접 눈으로 확인하는 단계입니다.