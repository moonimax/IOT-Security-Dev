---
title: pfSense 기반 망 분리 + ELK 관제 환경 구축
date: 2026-10-15
tags:
  - pfSense
  - ELK
  - SOC
  - VMware
  - 네트워크
---

# pfSense 기반 망 분리 + ELK 관제 환경 구축

## 1. 전체 구성

![[01_architecture.png]]

| 구분 | 대역 | VMware 네트워크 | pfSense 인터페이스 | 게이트웨이 |
|---|---|---|---|---|
| 외부 (Internet) | 192.168.0.0/24 | VMnet8 (NAT) | WAN – `le0` | DHCP (192.168.0.128) |
| 업무망 | 192.168.30.0/24 | VMnet1 | LAN – `le3` | 192.168.30.1 |
| ELK 서버 | 192.168.10.0/24 | VMnet3 | OPT1 – `le1` | 192.168.10.1 |
| SOC (관제망) | 192.168.20.0/24 | VMnet2 | OPT2 – `le2` | 192.168.20.1 |

- 방화벽/IPS: **pfSense 2.7.2-RELEASE**
- ELK 서버: **Ubuntu 20.04** + Elasticsearch / Kibana / Logstash **7.16.2**
- 업무망·SOC PC: Ubuntu Desktop

---

## 2. VMware 가상 네트워크 설정

**Edit → Virtual Network Editor → Change Settings** (관리자 권한)

![[02_vmnet_list.png]]

VMnet1 / VMnet2 / VMnet3 공통 설정:
- **Host-only**
- **Use local DHCP service** → 해제 (pfSense가 게이트웨이 역할)
- **Connect a host virtual adapter** → 해제 (호스트 어댑터가 `.1`을 가져가 pfSense와 IP 충돌 방지)
- Subnet: 위 표의 대역에 맞게 지정

![[03_vmnet_hostonly.png]]

VMnet8(NAT)은 기본값 유지 → pfSense WAN이 DHCP로 IP를 받음.

---

## 3. pfSense VM 네트워크 어댑터

| 어댑터 | 연결 | 용도 |
|---|---|---|
| Network Adapter | NAT (VMnet8) | WAN |
| Network Adapter 2 | Custom – VMnet3 | ELK |
| Network Adapter 3 | Custom – VMnet2 | SOC |
| Network Adapter 4 | Custom – VMnet1 | 업무망 |

![[04_pfsense_adapters.png]]

> [!important]
> 각 어댑터의 **Connected / Connect at power on** 체크 필수. 클라이언트 VM도 마찬가지.

![[05_adapter4_vmnet1.png]]

> [!tip]
> 어댑터 순서와 pfSense 인터페이스 번호가 맞는지는 어댑터 **Advanced → MAC Address**와 pfSense의 `ifconfig` MAC을 비교해서 확인.

---

## 4. pfSense 콘솔 설정

### 4-1. 인터페이스 지정 (메뉴 `1) Assign Interfaces`)

![[06_assign_interfaces.png]]

| 질문 | 입력 |
|---|---|
| Should VLANs be set up now? | `n` |
| WAN interface | `le0` |
| LAN interface | `le3` |
| Optional 1 interface | `le1` |
| Optional 2 interface | `le2` |
| 이후 Optional | Enter |
| Do you want to proceed? | `y` |

### 4-2. 인터페이스 IP 설정 (메뉴 `2) Set interface(s) IP address`)

![[07_set_ip_menu.png]]

인터페이스마다 반복. (WAN은 DHCP 그대로 두므로 생략)

| 질문 | LAN (업무망) | OPT1 (ELK) | OPT2 (SOC) |
|---|---|---|---|
| Configure IPv4 via DHCP? | `n` | `n` | `n` |
| IPv4 address | `192.168.30.1` | `192.168.10.1` | `192.168.20.1` |
| Subnet bit count | `24` | `24` | `24` |
| Upstream gateway | Enter | Enter | Enter |
| Configure IPv6 via DHCP6? | `n` | `n` | `n` |
| IPv6 address | Enter | Enter | Enter |
| Enable DHCP server? | `n` | `n` | `n` |
| Revert to HTTP? | `n` | `n` | `n` |

> 이번 구성에서는 DHCP 서버를 쓰지 않고, 모든 클라이언트에 **고정 IP**를 부여.

### 4-3. 결과 확인

![[08_pfsense_final_menu.png]]

메뉴에 IP가 표시되는 것과 실제 적용은 별개이므로 `8) Shell`에서 확인:

```sh
ifconfig | grep -E "^le|inet "
```

![[09_ifconfig_all_up.png]]

네 인터페이스 모두 `UP` 플래그와 `inet` 주소가 있어야 정상.

---

## 5. 클라이언트 고정 IP 설정

### 업무망 PC (Ubuntu Desktop, VMnet1)

**Settings → Network → 유선 톱니바퀴 → IPv4 → Manual**

| 항목 | 값 |
|---|---|
| Address | 192.168.30.50 |
| Netmask | 255.255.255.0 |
| Gateway | 192.168.30.1 |
| DNS | 192.168.30.1 |

![[10_work_static_ip.png]]

명령어로 할 경우:
```sh
sudo nmcli con add type ethernet ifname ens33 con-name lan ipv4.method manual ipv4.addresses 192.168.30.50/24 ipv4.gateway 192.168.30.1
sudo nmcli con up lan
```

### SOC PC (VMnet2)
- IP `192.168.20.100/24`, 게이트웨이 `192.168.20.1`

### ELK 서버 (Ubuntu Server 20.04, VMnet3) — netplan

```sh
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    ens33:
      addresses: [192.168.10.10/24]
      gateway4: 192.168.10.1
      nameservers:
        addresses: [192.168.10.1, 8.8.8.8]
```

```sh
sudo netplan apply
```

cloud-init이 netplan을 덮어쓰지 않도록:
```sh
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
```

### 연결 확인

각 VM에서 자기 게이트웨이로 ping:

```sh
ping -c 3 192.168.20.1   # SOC PC 예시
```

![[11_ping_gateway_ok.png]]

---

## 6. pfSense 웹 설정 & 방화벽 규칙

업무망 PC 브라우저 → `https://192.168.30.1` (기본 계정 `admin` / `pfsense`, 첫 접속 시 비밀번호 변경)

> [!note]
> LAN에는 기본 허용 규칙이 있지만 **OPT1 / OPT2는 규칙이 없으면 전부 차단**된다.

**Firewall → Rules**

**OPT1 (ELK)**
| Action | Protocol | Source | Destination | Port | 용도 |
|---|---|---|---|---|---|
| Pass | Any | OPT1 subnets | any | - | 패키지 설치·업데이트 |

**OPT2 (SOC)**
| Action | Protocol | Source | Destination | Port | 용도 |
|---|---|---|---|---|---|
| Pass | TCP | OPT2 subnets | 192.168.10.10 | 5601 | Kibana 접속 |
| Pass | Any | OPT2 subnets | any | - | 인터넷 |

규칙 추가 후 **Save → Apply Changes**.

---

## 7. ELK 서버

### 7-1. Elasticsearch 확인

```sh
sudo systemctl enable --now elasticsearch
sudo systemctl enable --now kibana
curl -s http://localhost:9200
```

![[12_es_version.png]]

→ 버전 7.16.2, 보안 기능 비활성 상태(HTTP, 인증 없음).

Kibana 외부 접속 설정 (`/etc/kibana/kibana.yml`):
```yaml
server.host: "0.0.0.0"
```

### 7-2. SOC PC → Kibana 접속

SOC PC 브라우저 → `http://192.168.10.10:5601`

![[13_kibana_home.png]]

→ 그림의 **SOC → ELK** 흐름 완성.

---

## 8. pfSense 로그 → ELK 연동

```
pfSense ──(UDP 5140)──▶ Logstash ──▶ Elasticsearch ──▶ Kibana
```

### 8-1. Logstash 설정 (ELK 서버)

```sh
sudo nano /etc/logstash/conf.d/pfsense.conf
```

```
input {
  udp {
    port => 5140
  }
}
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "pfsense-%{+YYYY.MM.dd}"
  }
}
```

```sh
sudo /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t   # Configuration OK 확인
sudo systemctl restart logstash
sudo ss -ulnp | grep 5140
```

### 8-2. pfSense 원격 로깅

**Status → System Logs → Settings → Remote Logging Options**
- Enable Remote Logging: ✅
- Source Address: OPT1
- Remote log servers: `192.168.10.10:5140`
- Remote Syslog Contents: Everything
- Save

### 8-3. 수신 확인

```sh
curl -s "http://localhost:9200/_cat/indices?v" | grep pfsense
```

![[14_pfsense_index.png]]

> `yellow`는 단일 노드라 레플리카를 배치할 곳이 없어서이며 실습 환경에선 정상.

### 8-4. Kibana에서 확인

1. **Stack Management → Index Patterns → Create index pattern**
2. Name: `pfsense-*`, Timestamp field: `@timestamp`

![[15_index_pattern.png]]

3. **Discover** → 인덱스 패턴 `pfsense-*` 선택

![[16_discover_pfsense.png]]

→ pfSense 필터 로그가 실시간으로 수집되는 것 확인.

---

## 9. 진행 현황

| 항목 | 상태 |
|---|---|
| 망 분리 (업무망 / SOC / ELK) | ✅ |
| 각 망 → 게이트웨이 통신 | ✅ |
| SOC → ELK (Kibana) | ✅ |
| pfSense → ELK 로그 전송 | ✅ |
| pfSense IPS (Suricata) | ⬜ 예정 |
| Logstash 필드 파싱 (grok) / 대시보드 | ⬜ 예정 |
