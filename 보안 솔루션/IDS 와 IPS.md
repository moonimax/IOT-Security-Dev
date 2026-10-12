# IDS 와 IPS

> 📌 개념 요약은 [보안 솔루션 및 장비 이해](<보안 솔루션 및 장비 이해.md>)의 IDS / IPS 항목 참고

---

## 1. IDS와 IPS 개요

**IDS (Intrusion Detection System, 침입 탐지 시스템)**
- 네트워크나 호스트에서 발생하는 트래픽·이벤트를 감시하다가, 공격으로 의심되는 행위를 **탐지하고 알리는** 시스템
- 차단은 하지 않는다. 비유하면 **CCTV**

**IPS (Intrusion Prevention System, 침입 방지 시스템)**
- 탐지에서 그치지 않고, 공격 트래픽을 **실시간으로 차단(Drop)** 하는 시스템
- 비유하면 **CCTV + 차단기**

### IDS vs IPS 비교

| 구분 | IDS | IPS |
| --- | --- | --- |
| 역할 | 탐지 + 알림 | 탐지 + 차단 |
| 설치 방식 | Out-of-band (스위치 미러링 / TAP) | In-line (트래픽 경로 한가운데) |
| 트래픽 영향 | 복사본을 보므로 지연 없음 | 모든 패킷이 거쳐가므로 약간의 지연 발생 |
| 장비 장애 시 | 통신에 영향 없음 | 통신 단절 가능 → Bypass 기능 필요 |
| 오탐 시 영향 | 불필요한 알림만 발생 | **정상 트래픽까지 차단**되는 위험 |

### 설치 위치

```
[IDS - 미러링 방식]
 인터넷 ── 방화벽 ── 스위치 ── 내부망
                       │ (미러링 포트로 복사본 전달)
                      IDS

[IPS - In-line 방식]
 인터넷 ── 방화벽 ── IPS ── 스위치 ── 내부망
                    (모든 트래픽이 IPS를 통과)
```

---

## 2. 탐지 방식

| 방식 | 원리 | 장점 | 단점 |
| --- | --- | --- | --- |
| **시그니처 기반** (Misuse Detection) | 미리 정의된 공격 패턴(룰)과 일치하면 탐지 | 오탐이 적고, 무엇이 탐지됐는지 명확 | 패턴이 없는 **신종 공격(제로데이) 탐지 불가**, 룰 업데이트 필수 |
| **이상 징후 기반** (Anomaly Detection) | 평소 정상 트래픽을 학습해 기준선(Baseline)을 만들고, 벗어나면 탐지 | 알려지지 않은 공격도 탐지 가능 | 정상인데 평소와 다르면 탐지되어 **오탐이 많음** |

### 탐지 결과 4가지

| | 실제 공격 O | 실제 공격 X |
| --- | --- | --- |
| **탐지함** | True Positive (정탐) ✅ | **False Positive (오탐)** ⚠️ |
| **탐지 못함** | **False Negative (미탐)** 🚨 | True Negative (정상) ✅ |

- **오탐(False Positive)** : 정상 트래픽을 공격으로 판단 → IPS에서는 정상 서비스가 차단되는 장애로 이어짐
- **미탐(False Negative)** : 실제 공격을 놓침 → 보안상 가장 위험
- 룰을 엄격하게 하면 오탐↑, 느슨하게 하면 미탐↑ 이므로 **튜닝**이 핵심이다.

> 💡 **운영 팁** : 새로운 룰은 처음부터 `drop`으로 켜지 않는다. `alert`로 먼저 걸어두고 로그를 보면서 오탐이 거의 없는 것을 확인한 뒤 `drop`으로 전환한다.

---

## 3. 종류

| 종류 | 감시 대상 | 예시 |
| --- | --- | --- |
| **NIDS / NIPS** | 네트워크 전체 트래픽 | Snort, Suricata |
| **HIDS / HIPS** | 개별 호스트(서버)의 로그, 파일 변경, 프로세스 | OSSEC, Wazuh |
| **WIPS** | 무선 네트워크 (Rogue AP, 비인가 단말 등) | |
| **NBA** (Network Behavior Analysis) | 트래픽 흐름·양의 이상 (DDoS, 웜 확산 등) | |

---

## 4. 오픈소스 IDS/IPS : Snort와 Suricata

### Snort
- 네트워크를 오고 가는 패킷(OSI 3계층 ~ 7계층)을 실시간으로 살펴보고, 악성코드나 해킹 징후를 탐지하는 오픈소스 NIDS/NIPS
- 1998년 공개된 가장 대표적인 IDS로, **룰 문법의 표준**처럼 쓰인다. (현재 Cisco가 관리)

### Suricata
- OISF에서 개발한 오픈소스 IDS/IPS로, Snort 룰과 거의 호환된다.

### Snort vs Suricata

| 구분 | Snort (2.x) | Suricata |
| --- | --- | --- |
| 처리 구조 | 싱글 스레드 (Snort 3부터 멀티 스레드) | **멀티 스레드** → 고속 트래픽 처리에 유리 |
| 프로토콜 인식 | 주로 포트 기준 | 포트와 무관하게 **애플리케이션 프로토콜 자동 인식** (HTTP, DNS, TLS 등) |
| 로그 | unified2 등 | **EVE JSON** → SIEM(ELK 등) 연동이 쉬움 |
| 룰 | Snort 룰 | Snort 룰 대부분 호환 + `dns.query` 같은 전용 키워드 |

---

## 5. 룰 구조

```
action  protocol  src_ip  src_port  ->  dst_ip  dst_port  (options)
 ───── ───────── ─────── ────────  ──  ─────── ────────  ─────────
 drop    dns     192.168.30.200 any -> 8.8.8.8    53     (msg:"..."; content:"..."; sid:1000003; rev:1;)
```

### Header

| 항목 | 설명 |
| --- | --- |
| **action** | `alert` 탐지·로그 기록 / `drop` 차단 + 로그 (IPS 모드에서만 동작) / `reject` 차단 + 상대에게 거부 응답 전송 / `pass` 검사 제외 |
| **protocol** | `tcp`, `udp`, `icmp`, `ip` + Suricata는 `http`, `dns`, `tls` 등 애플리케이션 프로토콜도 지정 가능 |
| **IP / Port** | `any`, 단일 IP, 대역(`192.168.30.0/24`), 변수(`$HOME_NET`, `$EXTERNAL_NET`) |
| **방향** | `->` 단방향, `<>` 양방향 |

### 주요 Option

| 옵션 | 의미 |
| --- | --- |
| `msg` | 탐지 시 로그에 남길 메시지 |
| `content` | 패킷 안에서 찾을 문자열 |
| `nocase` | 대소문자 구분 안 함 |
| `pcre` | 정규 표현식으로 패턴 매칭 → [정규 표현식](<정규 표현식.md>) 참고 |
| `flow` | 연결 방향·상태 지정 (`to_server`, `established` 등) |
| `dns.query` | (Suricata) DNS 질의 도메인만 검사 대상으로 지정 |
| `dotprefix` | 도메인 앞에 점(.)을 붙여 비교 → `naver.com`과 `sub.naver.com`은 잡고 `notnaver.com`은 제외 |
| `endswith` | 해당 문자열로 끝나는지 비교 |
| `sid` | 룰 고유 번호. **사용자 정의 룰은 1000000 이상** 사용 |
| `rev` | 룰 수정 버전 (수정할 때마다 +1) |
| `classtype` / `priority` | 공격 분류와 위험도 |

---

## 6. IPS 모드 구현 : NFQUEUE와 iptables

IDS는 트래픽을 **보기만** 하면 되지만, IPS는 패킷을 **중간에 붙잡아서 통과/차단을 결정**해야 한다. 리눅스에서는 커널 방화벽(Netfilter/iptables)이 패킷을 사용자 영역의 프로그램(Suricata, Snort)에게 넘겨주는 방식으로 구현한다.

```
패킷 도착 → iptables (NFQUEUE 규칙) → 큐(Queue) → Suricata 검사
                                                   ├─ 정상 → ACCEPT (통과)
                                                   └─ 공격 → DROP (차단)
```

| 구분 | 설명 |
| --- | --- |
| **NFQ (NFQUEUE)** | 커널의 Netfilter가 패킷을 큐에 넣고 사용자 프로그램이 판정하게 하는 **현재 표준 방식**. Suricata와 Snort 모두 이 방식으로 IPS 모드를 구현한다. |
| **IPQ (ip_queue)** | NFQ 이전의 **구버전 방식**. 큐가 하나뿐이라 확장성이 떨어지고, 최신 리눅스 커널에서는 제거되었다. |

> **iptables와 IDS/IPS의 관계**
> 리눅스 네트워크 보안에서 함께 쓰이지만 역할이 완전히 다르다. Snort·Suricata는 네트워크를 감시하고 탐지하는 **CCTV**이고, iptables는 통행을 제어하는 **차단기**다. NFQUEUE는 CCTV가 판단한 결과대로 차단기를 내릴 수 있게 둘을 이어주는 연결 고리다.

**참고 명령어** (Ubuntu가 내부 PC의 게이트웨이 역할을 할 때의 일반적인 구성)
```bash
# 1. 라우팅 허용 (내부 PC 트래픽을 외부로 전달)
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE

# 2. 지나가는 트래픽을 NFQUEUE 0번 큐로 보냄
sudo iptables -I FORWARD -j NFQUEUE --queue-num 0

# 3. Suricata를 IPS(NFQ) 모드로 실행
sudo suricata -c /usr/local/etc/suricata/suricata.yaml -q 0
```

> ⚠️ Suricata가 꺼진 상태에서 NFQUEUE 규칙만 남아 있으면 큐를 받아줄 프로그램이 없어 **모든 통신이 끊긴다.** 실습이 끝나면 `sudo iptables -D FORWARD -j NFQUEUE --queue-num 0` 으로 규칙을 지운다.

---

## 7. 실습 환경 구성

### 네트워크 구성

```
[내부 PC]                     [Ubuntu 24.04 - Suricata]                  [외부]
192.168.30.200  ───  ens34: 192.168.30.1 │ ens33: 192.168.0.200  ───  GW 192.168.0.2 ─── 인터넷 (8.8.8.8)
  (VMnet1)                    (내부 쪽)  │  (외부 쪽, NAT)
```

- 내부 PC의 모든 트래픽이 Ubuntu를 거쳐 나가도록 구성 → Ubuntu에 설치한 Suricata가 In-line으로 검사

### Ubuntu 서버 세팅

![](../Images/Pasted%20image%2020261007092517.png)

*`ip a`로 인터페이스 확인 — ens33(외부, NAT), ens34(내부, VMnet1)*

### 고정 IP 할당 (netplan)

| 인터페이스 | 대역 | IP | Gateway | DNS |
| --- | --- | --- | --- | --- |
| ens33 | NAT | 192.168.0.200/24 | 192.168.0.2 | 8.8.8.8, 8.8.4.4 |
| ens34 | VMnet1 (Host-only) | 192.168.30.1/24 | - | - |

![](../Images/Pasted%20image%2020261007094953.png)

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: no
      addresses:
        - 192.168.0.200/24      # IP/Subnet
      routes:
        - to: default
          via: 192.168.0.2      # Gateway
      nameservers:
        addresses:
          - 8.8.8.8             # Name server
          - 8.8.4.4
    ens34:
      dhcp4: no
      addresses:
        - 192.168.30.1/24
```

```bash
sudo netplan apply   # 설정 적용
```

> 💡 ens34에는 Gateway를 넣지 않는다. 기본 경로(default route)가 두 개가 되면 외부 통신이 꼬일 수 있다.

---

## 8. Suricata 실습

### 실습 1. IDS 모드로 실행

```bash
sudo suricata -c /usr/local/etc/suricata/suricata.yaml -i ens33
```

| 옵션 | 의미 |
| --- | --- |
| `-c` | 설정 파일 경로 |
| `-i` | 감시할 인터페이스 (IDS 모드, 패킷을 복사해서 검사) |
| `-q 0` | NFQUEUE 0번 큐 사용 (IPS 모드, 패킷을 붙잡아서 검사) |

![](../Images/Pasted%20image%2020261007110929.png)

*Suricata 7.0.4 SYSTEM 모드로 실행 → 종료 시 처리한 패킷 수(70)와 드롭 수(0) 확인*

### 실습 2. ICMP(ping) 탐지

내부 PC(192.168.30.200)에서 `ping 8.8.8.8`을 보내면 Suricata가 탐지하여 로그를 남긴다.

```
alert icmp any any -> 8.8.8.8 any (msg:"ICMP 8.8.8.8 Running"; sid:100002; rev:1;)
```
*(fast.log의 sid와 메시지를 기준으로 정리한 룰)*

[▶ Suricata ping test 영상](<../Images/Suricata ping test.mp4>)

[▶ Suricata ping test 1 영상](<../Images/Suricata ping test 1.mp4>)

### 실습 3. DNS 기반 사이트 차단 (IPS)

특정 도메인에 대한 **DNS 질의 자체를 차단**해서 사이트 접속을 막는다.

![](../Images/Pasted%20image%2020261007152406.png)

```
drop  dns 192.168.30.200 any -> 8.8.8.8 53 (msg:"Block naver.com DNS"; dns.query; dotprefix; content:".naver.com"; endswith; nocase; sid:1000003; rev:1;)
drop  dns 192.168.30.200 any -> 8.8.8.8 53 (msg:"Block youtube.com DNS"; dns.query; dotprefix; content:".youtube.com"; endswith; nocase; sid:1000013; rev:1;)
alert dns 192.168.30.200 any -> 8.8.8.8 53 (msg:"This is kisec.com"; dns.query; dotprefix; content:".kisec.com"; endswith; nocase; sid:1000023; rev:1;)
```

| 룰 | 동작 |
| --- | --- |
| naver.com, youtube.com | `drop` → DNS 질의 차단, 접속 불가 |
| kisec.com | `alert` → 통과시키되 로그만 기록 |

> 📝 DNS는 **53번 포트**를 사용한다. 스크린샷의 룰은 목적지 포트가 `443`으로 되어 있는데, DNS 질의를 확실히 잡으려면 `53` 또는 `any`로 지정하는 것이 맞다.

**결과 확인 (내부 PC)**

![](../Images/Pasted%20image%2020261007150156.png)

- `nslookup naver.com` → **timed out** : Suricata가 DNS 질의를 drop 해서 응답이 오지 않음
- `nslookup kisec.com` → **정상 응답** (222.122.52.4) : alert 룰이라 통과됨

**로그 확인 (Suricata 서버)**

```bash
sudo tail -f /usr/local/var/log/suricata/fast.log
```

![](../Images/Pasted%20image%2020261007150212.png)

| 로그 | 의미 |
| --- | --- |
| `ICMP 8.8.8.8 Running` | 실습 2의 ping 탐지 (alert) |
| `[Drop] ... Block naver.com DNS` | naver.com 질의 차단 |
| `[Drop] ... Block youtube.com DNS` | youtube.com 질의 차단 |
| `[Drop] ... This is kisec.com` → `This is kisec.com` | 처음엔 drop으로 차단되다가, 룰을 `alert`로 바꾼 뒤에는 `[Drop]` 표시 없이 탐지만 기록됨 |

> 💡 같은 룰이라도 action에 따라 로그에 `[Drop]`이 붙는지가 달라진다. 이걸로 IDS(탐지)와 IPS(차단)의 차이를 바로 확인할 수 있다.

**로그 파일 종류**

| 파일 | 내용 |
| --- | --- |
| `fast.log` | 한 줄 요약 알림 (사람이 보기 편함) |
| `eve.json` | 모든 이벤트를 JSON으로 상세 기록 (SIEM 연동용) |
| `suricata.log` | 엔진 실행·오류 로그 (룰 문법 오류 확인할 때) |

---

## 9. 참고 : WAF와 IPS의 차이

IPS가 네트워크 전반의 공격을 보는 반면, **WAF(Web Application Firewall)** 는 HTTP(S) 웹 트래픽에 특화되어 SQL Injection, XSS 같은 웹 공격을 막는다.

**WAF의 한계**
- HTTP(S) 본문 해석과 SSL/TLS 복호화 처리 때문에 장비 자체에 부하가 크다.
- **Parsing 불일치 우회** : WAF가 데이터를 해석하는 방식과 백엔드 웹 서버·DB가 해석하는 방식이 다를 때, 그 틈을 노려 WAF는 정상으로 보고 서버는 공격으로 실행하게 만드는 우회 기법이 계속 나온다.

**Proxy 구분**

| 구분 | 위치 | 역할 |
| --- | --- | --- |
| **Forward Proxy** | 내부 **클라이언트** 앞 | 내부 사용자가 외부로 나갈 때 대신 요청 → **클라이언트 IP를 숨김**, 유해 사이트 차단·캐싱 |
| **Reverse Proxy** | 내부 **웹 서버** 앞 | 외부에서 들어오는 모든 요청을 앞단에서 받아 서버로 전달 → **서버 IP를 숨김**, 로드밸런싱·SSL 처리. WAF가 주로 이 방식으로 동작 |
