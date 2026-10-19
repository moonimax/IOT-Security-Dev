
---

## 1. 전체 구성

| 역할 | VM | OS | 망 | IP | VMnet |
|---|---|---|---|---|---|
| 방화벽 / IDS | Firewall | pfSense 2.7.2 | 전 구간 | WAN 192.168.0.200 / LAN 10.10.10.1 / OPT1 10.10.20.1 / OPT2 10.10.30.1 | NAT / VMnet1 / VMnet2 / VMnet3 |
| 관제 PC | Clone of soc | Ubuntu | LAN (내부망) | 10.10.10.100 | VMnet1 |
| 개발 PC (DMZ 접근용) | DevPC | Ubuntu | LAN (내부망) | 10.10.10.150 | VMnet1 |
| SIEM (ELK + Wazuh) | Elastick_Stack | Ubuntu 20.04 Server | OPT1 (관제망) | 10.10.20.120 | VMnet2 |
| 관제 대상 웹서버 | Webserver | Ubuntu | OPT2 (DMZ) | 10.10.30.100 | VMnet3 |

pfSense 인터페이스 매핑은 `le0=WAN`, `le1=LAN`, `le2=OPT1`, `le3=OPT2`

![pfSense 콘솔 인터페이스](../Images/secops-02-pfsense-interfaces-final.png)
![pfSense VM 네트워크 어댑터](../Images/secops-03-pfsense-vm-adapters.png)



### 로그 수집 흐름

| 로그 | 경로 | Elasticsearch 인덱스 |
|---|---|---|
| Wazuh 알람 | Webserver Wazuh Agent → Wazuh Manager → Filebeat → Logstash `5044/TCP` | `wazuh-alerts-*` |
| 웹 접근 로그 | Webserver Filebeat(apache 모듈) → Logstash `5046/TCP` | `web-access-log-*` |
| 방화벽 로그 | pfSense syslog → Logstash `5045/UDP` | `pfsense-firewall-*` |
| Snort 탐지 | pfSense syslog → Logstash `5045/UDP` | `pfsense-snort-*` |

### 가이드와 다르게 적용한 부분

| 항목                  | 가이드                        | 실제 적용                                       |
| ------------------- | -------------------------- | ------------------------------------------- |
| ELK 버전              | 7.5.1 (직접 설치)              | 기존 서버의 **7.16.2** 재사용 (JDK 내장이라 Java 설치 생략) |
| Logstash Java 경로 설정 | `/etc/default/logstash` 수정 | 하지 않음 (7.16.2 내장 JDK 사용)                    |
| 메모리                 | SIEM 4GB                   | ES 힙 1GB, Logstash 힙 512MB로 제한              |
| Wazuh용 filebeat.yml | 다운로드 후 vi로 수정              | 필요한 내용만 새로 작성                               |
| auditd 규칙 적용        | `systemctl restart auditd` | `augenrules --load`                         |
| Kibana 차트           | 7.5 UI 기준                  | 7.16 UI 기준 (User_Agent는 Lens Donut)         |
| 웹서버 Filebeat        | 7.5.1                      | 7.5.1 + `seccomp.enabled: false`            |
|                     |                            |                                             |

---

## 2. 방화벽 (pfSense)

### 2.1 설치 및 인터페이스 설정

콘솔 메뉴 `1) Assign Interfaces`, `2) Set interface(s) IP address`로 WAN·LAN·OPT1·OPT2를 할당

![pfSense 콘솔](../Images/secops-01-pfsense-console-interfaces.png)

LAN 쪽 Ubuntu는 고정 IP로 설정(게이트웨이 `10.10.10.1`, DNS `8.8.8.8`)

![LAN Ubuntu 고정 IP](../Images/secops-04-lan-ubuntu-static-ip.png)


### 2.2 초기 설정 위저드

LAN(`https://10.10.10.1`)으로 웹GUI에 접속해 위저드로 진행

![위저드 완료](../Images/secops-05-pfsense-wizard-accept.png)



**System → General Setup**

- Hostname: `pfSense` / Domain: `pfmanage.com`
- DNS: `168.126.63.1`, `8.8.8.8`
- Timezone: `Asia/Seoul`

![General Setup](../Images/secops-06-pfsense-general-setup.png)

**Interfaces → WAN**: 외부(192.168.0.x)에서 포트포워딩으로 들어올 수 있도록 `Block private networks`는 해제, `Block bogon networks`는 체크

### 2.3 방화벽 규칙

LAN, OPT1, OPT2 각각에 아래 허용 규칙을 추가했습니다. (pfSense는 규칙이 없는 인터페이스의 트래픽을 전부 차단합니다.)

| Interface | Action | Protocol | Source | Destination |
|---|---|---|---|---|
| LAN | Pass | Any | LAN subnets | Any |
| OPT1 | Pass | Any | OPT1 subnets | Any |
| OPT2 | Pass | Any | OPT2 subnets | Any |

![OPT1 규칙](../Images/secops-07-firewall-rules-opt1.png)
![OPT2 규칙](../Images/secops-08-firewall-rules-opt2.png)

### 2.4 Snort (IDS)

**System → Package Manager**에서 `snort`를 설치

![Snort 패키지](../Images/secops-09-snort-package.png)

**Services → Snort → WAN 인터페이스 설정**

- Interface: `WAN (le0)`
- Send Alerts to System Log: 체크
- **Block Offenders: 해제** (실습 목적상 차단하지 않고 탐지·알림만 하는 IDS 모드)

![Snort WAN 설정](../Images/secops-10-snort-wan-settings.png)

**WAN Preprocs → HTTP Inspect → Server Configurations**: `Post Depth`를 `0`으로 변경 (POST 본문 전체 검사)

![Post Depth](../Images/secops-11-snort-post-depth.png)

> 탐지를 하려면 Global Settings에서 룰셋(ET Open, Snort GPLv2 Community)을 켜고 Updates → WAN Categories까지 설정

### 2.5 원격 로그 전송

**Status → System Logs → Settings → Remote Logging Options**

- Source Address: `Default (any)`
- Remote log server: `10.10.20.120:5045`
- Contents: System Events, Firewall Events

![Remote Logging](../Images/secops-12-remote-logging.png)

### 2.6 포트포워딩 (외부 → DMZ 웹서버)

**Firewall → NAT → Port Forward**

- Interface: WAN / TCP / Destination: WAN address : HTTP
- Redirect target: `10.10.30.100` : HTTP
- Filter rule association: Add associated filter rule (WAN 규칙 자동 생성)
- 생성된 WAN 규칙에 **Log** 옵션을 켜서 외부 접근이 방화벽 로그로 남도록 함

![Port Forward](../Images/secops-13-port-forward.png)

### 2.7 패킷 캡처

**Diagnostics → Packet Capture**에서 WAN(le0) 캡처 후 `.pcap`으로 다운로드드

![Packet Capture 설정](../Images/secops-14-packet-capture-options.png)
![Packet Capture 결과](../Images/secops-15-packet-capture-output.png)

---

## 3. 관제 대상 웹서버 (DMZ)

- IP `10.10.30.100/24`, GW `10.10.30.1`, VMnet3, RAM 2GB
- Apache2 설치·실행

![Webserver VM 설정](../Images/secops-21-webserver-vm-settings.png)

### 3.1 Filebeat (웹 로그 → Logstash 5046)

```bash
sudo dpkg -i filebeat-7.5.1-amd64.deb
sudo filebeat modules enable apache
# /etc/filebeat/filebeat.yml 수정 → configs/webserver/filebeat-output.yml 참고
sudo filebeat test config
sudo systemctl enable --now filebeat
```

### 3.2 Wazuh Agent + auditd

```bash
curl -fSLo wazuh-agent-3.10.2.deb https://packages.wazuh.com/3.x/apt/pool/main/w/wazuh-agent/wazuh-agent_3.10.2-1_amd64.deb
sudo WAZUH_MANAGER="10.10.20.120" dpkg -i wazuh-agent-3.10.2.deb
sudo /var/ossec/bin/agent-auth -m 10.10.20.120
# ossec.conf에 수집 로그 추가 → configs/webserver/ossec-agent-localfile.xml

sudo apt-get install -y auditd audispd-plugins
# 감시 규칙 → configs/webserver/custom.rules 를 /etc/audit/rules.d/ 에 저장
sudo augenrules --load
sudo auditctl -l

sudo systemctl enable wazuh-agent
sudo systemctl restart wazuh-agent
```

SIEM에서 `agent_control -l`로 에이전트가 **Active**인지 확인

![Wazuh Agent Active](../Images/secops-22-wazuh-agent-active.png)

---

## 4. SIEM (ELK 7.16.2 + Wazuh 3.10.2)

기존에 ELK 7.16.2가 설치된 서버(192.168.10.10)를 SIEM으로 전환

![SIEM 초기 상태](../Images/secops-16-siem-initial-console.png)
![설치된 ELK 버전](../Images/secops-18-siem-elk-version.png)

### 4.1 네트워크 변경 (192.168.10.10 → 10.10.20.120)

```bash
# cloud-init이 네트워크 설정을 덮어쓰지 않도록
echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
# /etc/netplan/00-installer-config.yaml → configs/siem/netplan/ 참고
sudo netplan try
sudo netplan apply
```

VMware에서 NIC를 VMnet2(OPT1)로 변경


![SIEM IP 변경](../Images/secops-17-siem-ip-changed.png)

### 4.2 Elasticsearch / Kibana 설정

`/etc/elasticsearch/elasticsearch.yml`

```yaml
node.name: node-1
network.host: 10.10.20.120
cluster.initial_master_nodes: ["node-1"]
```

`/etc/kibana/kibana.yml`

```yaml
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://10.10.20.120:9200"]
```

메모리 정리 (RAM 3.8GB 환경)

```bash
printf -- "-Xms1g\n-Xmx1g\n" | sudo tee /etc/elasticsearch/jvm.options.d/heap.options
sudo sed -i 's/^-Xms1g/-Xms512m/; s/^-Xmx1g/-Xmx512m/' /etc/logstash/jvm.options
sudo systemctl disable --now grafana-server   # 이번 실습에서 사용하지 않음
```

기존 Logstash 설정(`beats.conf`, `pfsense.conf`)은 포트 충돌을 막기 위해 `/etc/logstash/conf.d.bak/`로 옮겼습니다.

![기존 Logstash conf](../Images/secops-19-logstash-old-conf.png)

Kibana 접속 확인 (`http://10.10.20.120:5601`). 보안 기능(Enable security)은 켜지 않았습니다. 켜면 Logstash가 인증 없이 Elasticsearch에 쓰지 못함함

![Kibana 홈](../Images/secops-20-kibana-home.png)

### 4.3 Wazuh Manager

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo apt-key add -
echo "deb https://packages.wazuh.com/3.x/apt/ stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list
sudo apt-get update
sudo apt install wazuh-manager=3.10.2-1
sudo curl -s https://packages.wazuh.com/3.x/filebeat/wazuh-filebeat-0.1.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module
```

- `ossec.conf`의 `jsonout_output yes`, `email_notification no` 등은 3.10.2 기본값 그대로 사용
- 커스텀 규칙: `configs/siem/wazuh/local_rules.xml` (www-data 명령 실행, root 명령, nc/wget/curl, cron 변경 탐지)
- Filebeat(Wazuh 알람 → Logstash 5044): `configs/siem/filebeat.yml`

```bash
sudo /var/ossec/bin/ossec-analysisd -t && sudo systemctl restart wazuh-manager
```

### 4.4 Logstash 파이프라인

`/etc/logstash/conf.d/`에 4개 파일을 배치했습니다. → `configs/siem/logstash/`

| 파일 | 입력 | 출력 인덱스 |
|---|---|---|
| `01-wazuh.conf` | beats 5044 | `wazuh-alerts-*` |
| `02-web-access.conf` | beats 5046 | `web-access-log-*` |
| `03-pfsense.conf` | udp 5045 | `pfsense-firewall-*` |
| `04-snort.conf` | (03과 같은 입력) | `pfsense-snort-*` |

```bash
sudo /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
sudo systemctl restart logstash filebeat
sudo ss -lntup | grep -E '5044|5045|5046'
curl -s "http://10.10.20.120:9200/_cat/indices?v" | grep -E 'wazuh|web-access|pfsense'
```

---

## 5. Kibana 대시보드 (7.16)

### 5.1 인덱스 패턴

**☰ → Stack Management → Index Patterns**에서 생성 (Timestamp field: `@timestamp`)

- `web-access-log*` (Default)
- `pfsense-firewall-*`
- `wazuh-alerts-*`

![Index Patterns](../Images/secops-23-kibana-index-patterns.png)

### 5.2 시각화 (Visualize Library → Lens)

| 이름 | 필드 | 형태 |
|---|---|---|
| Top Source IP | `clientip.keyword` | Bar |
| HTTP Method | `verb.keyword` | Table |
| HTTP Response | `response.keyword` | Table |
| User_Agent | `original_user_agent.keyword` | Donut |

![Top Source IP](../Images/secops-24-lens-top-source-ip.png)

### 5.3 대시보드

**☰ → Dashboard → Create dashboard → Add from library**로 4개 패널을 추가하고 `Web Monitoring Dashboard`로 저장했습니다.

![Dashboard](../Images/secops-25-dashboard.png)

---

## 6. 트러블슈팅

| # | 증상 | 원인 | 해결 |
|---|---|---|---|
| 1 | LAN에서 `ping 10.10.10.1` 실패 (ARP·MAC은 정상) | LAN 허용 규칙 없음 → pf가 차단 | `pfctl -d`로 원인 확인 후 LAN Pass 규칙 추가 |
| 2 | 위저드 Reload 중 웹GUI 연결 끊김 | WAN 주소로 접속 중이었고, reload 시 pf가 다시 켜짐 | 웹GUI는 LAN(`10.10.10.1`)으로 접속 |
| 3 | SIEM `netplan try`에서 default route 충돌 | 설정 파일에 기본 게이트웨이 중복 선언 | 파일 정리 후 재적용 |
| 4 | SIEM 메모리 부족 (3.3GB/3.8GB 사용) | 기존 ELK, Grafana가 모두 기본 힙으로 실행 중 | ES 힙 1GB, Logstash 512MB, Grafana 비활성화 |
| 5 | 호스트 메모리 부족으로 VM 부팅 불가 | 웹서버 VM에 RAM 6GB가 할당돼 있었음 | 2GB로 축소 |
| 6 | Kibana 503 `License is not available` | `kibana.yml`의 `elasticsearch.hosts`가 주석 → localhost로 접속 시도 | `http://10.10.20.120:9200`으로 수정 |
| 7 | 웹서버에서 게이트웨이(10.10.30.1) 통신 불가 | VMware 가상 NIC 연결 꼬임 (설정은 정상) | VM 재시작 |
| 8 | Wazuh Agent `Never connected` | 에이전트가 Manager에 접속하지 못한 상태 | 웹서버에서 `wazuh-agent` 재시작 |
| 9 | pfSense 로그가 SIEM에 안 옴 | Remote Logging 설정이 적용되지 않음 | 설정 재저장 (syslog 재시작) |
| 10 | 방화벽 로그가 어제 날짜 인덱스에 저장됨 | pfSense 시간대 변경이 재부팅 전까지 미적용 → UTC로 전송 | pfSense 재부팅 |
| 11 | 웹서버 Filebeat 7.5.1이 시작 직후 crash | 구버전 Filebeat의 seccomp가 최신 Ubuntu 시스템 호출 차단 | `seccomp.enabled: false` 추가 |

### 주요 화면

**#1 LAN ping 실패 — ARP는 응답(REACHABLE)하지만 ping은 실패**

![ping 실패](../Images/secops-ts01-lan-ping-arp.png)
![le1 MAC 확인](../Images/secops-ts02-le1-mac.png)
![pfctl -d](../Images/secops-ts03-pfctl-disable.png)

**#2 위저드 Reload 중 연결 끊김**

![wizard reload](../Images/secops-ts04-wizard-reload.png)

**#3 netplan default route 충돌**

![netplan conflict](../Images/secops-ts05-netplan-conflict.png)

**#4, #5 메모리 부족**

![SIEM memory](../Images/secops-ts06-siem-memory.png)
![host memory](../Images/secops-ts07-host-memory.png)

**#6 Kibana 503**

![Kibana 503](../Images/secops-ts08-kibana-503.png)

**#7 pfSense에서도 웹서버로 ping 불가**

![le3 ping](../Images/secops-ts09-le3-ping.png)

**#8 Wazuh Agent Never connected → Manager는 UDP 1514 정상 대기**

![never connected](../Images/secops-ts10-wazuh-never-connected.png)
![wazuh remote](../Images/secops-ts11-wazuh-remote.png)

---

## 7. 최종 확인

### 7.1 내부망 → DMZ 웹서버

DevPC(10.10.10.150, LAN)에서 `http://10.10.30.100`으로 접속해 Apache 페이지 확인.
LAN Pass 규칙에 따라 pfSense가 LAN → DMZ로 라우팅합니다.

![DevPC → DMZ](../Images/secops-26-devpc-to-dmz-web.png)

### 7.2 외부망 → DMZ 웹서버 (포트포워딩)

외부(Windows 호스트, VMnet8)에서 WAN 주소 `http://192.168.0.200`으로 접속하면 포트포워딩을 거쳐 DMZ 웹서버(10.10.30.100:80)의 페이지가 열립니다.

![WAN → DMZ](../Images/secops-27-wan-to-dmz-portforward.png)

## 8. 남은 작업

- [ ] Snort 룰셋(ET Open, GPLv2 Community) 다운로드 및 WAN Categories 선택 → `pfsense-snort-*` 인덱스 생성 확인
- [ ] WAN(공격자) 쪽에서 웹 공격 트래픽 발생시켜 대시보드·탐지 확인
- [ ] (선택) DMZ → LAN 차단 규칙 추가

## 부록. 설정 파일

본문에서 `configs/...`로 언급한 파일의 전체 내용입니다.

### configs/siem/netplan/00-installer-config.yaml

```yaml
network:
  version: 2
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - 10.10.20.120/24
      routes:
        - to: 0.0.0.0/0
          via: 10.10.20.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

### configs/siem/filebeat.yml

```yaml
filebeat.modules:
  - module: wazuh
    alerts:
      enabled: true
    archives:
      enabled: false

output.logstash:
  hosts: ["10.10.20.120:5044"]
```

### configs/siem/logstash/01-wazuh.conf

```ruby
input {
  beats {
    port => 5044
    tags => ["wazuh_log"]
  }
}
filter {
  if "wazuh_log" in [tags] {
    mutate { remove_field => ["host"] }
    if [log][file][path] =~ "alerts.json" {
      json { source => "message" }
      mutate { remove_field => ["message"] }
      if [predecoder][timestamp] {
        date {
          match => [ "[predecoder][timestamp]", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
          timezone => "Asia/Seoul"
          target => "[predecoder][timestamp]"
        }
      }
    }
  }
}
output {
  if "wazuh_log" in [tags] {
    elasticsearch {
      hosts => ["10.10.20.120:9200"]
      index => "wazuh-alerts-%{+YYYY.MM.dd}"
    }
  }
}
```

### configs/siem/logstash/02-web-access.conf

```ruby
input {
  beats {
    port => 5046
    tags => ["web_log"]
  }
}
filter {
  if "web_log" in [tags] {
    mutate { remove_field => ["host", "agent"] }
    if [log][file][path] =~ "access.log" {
      grok { match => { "message" => "%{COMBINEDAPACHELOG}" } }
      date {
        match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
        target => "@timestamp"
        remove_field => ["timestamp"]
      }
      useragent {
        source => "agent"
        target => "user_agent"
      }
      mutate { rename => { "agent" => "original_user_agent" } }
    }
  }
}
output {
  if "web_log" in [tags] {
    elasticsearch {
      hosts => ["10.10.20.120:9200"]
      index => "web-access-log-%{+YYYY.MM.dd}"
    }
  }
}
```

### configs/siem/logstash/03-pfsense.conf

```ruby
input {
  udp {
    port => 5045
    type => "pfsense"
  }
}
filter {
  if [type] == "pfsense" {
    grok {
      match => { "message" => "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:pfsense_body}" }
      tag_on_failure => ["_pfsense_syslog_grok_failure"]
    }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
      timezone => "Asia/Seoul"
      target => "@timestamp"
    }
    if [syslog_program] == "filterlog" {
      csv {
        source => "pfsense_body"
        columns => [
          "rule_number", "sub_rule_number", "anchor", "tracker", "interface",
          "reason", "action", "direction", "ip_version", "tos",
          "ecn", "ttl", "id", "offset", "flags",
          "protocol_id", "protocol", "length", "src_ip", "dst_ip",
          "src_port", "dst_port", "data_length"
        ]
        separator => ","
      }
      mutate {
        convert => {
          "rule_number" => "integer"
          "sub_rule_number" => "integer"
          "tracker" => "integer"
          "ip_version" => "integer"
          "ttl" => "integer"
          "id" => "integer"
          "protocol_id" => "integer"
          "length" => "integer"
          "src_port" => "integer"
          "dst_port" => "integer"
          "data_length" => "integer"
        }
        lowercase => [ "action", "direction", "protocol" ]
        add_field => {
          "[source][ip]" => "%{src_ip}"
          "[destination][ip]" => "%{dst_ip}"
          "[network][transport]" => "%{protocol}"
        }
        add_tag => [ "pfsense_filterlog" ]
      }
      if [src_port] { mutate { add_field => { "[source][port]" => "%{src_port}" } } }
      if [dst_port] { mutate { add_field => { "[destination][port]" => "%{dst_port}" } } }
      mutate {
        convert => {
          "[source][port]" => "integer"
          "[destination][port]" => "integer"
        }
        remove_field => [ "pfsense_body", "message" ]
      }
    }
  }
}
output {
  if "pfsense_filterlog" in [tags] {
    elasticsearch {
      hosts => ["10.10.20.120:9200"]
      index => "pfsense-firewall-%{+YYYY.MM.dd}"
    }
  }
}
```

### configs/siem/logstash/04-snort.conf

```ruby
filter {
  if [type] == "pfsense" and [syslog_program] == "snort" {
    grok {
      match => {
        "pfsense_body" => "\[%{INT:[snort][gid]}:%{INT:[snort][sid]}:%{INT:[snort][rev]}\] %{DATA:[snort][signature]} \[Classification: %{DATA:[snort][classification]}\] \[Priority: %{INT:[snort][priority]}\] \{%{WORD:[network][transport]}\} %{IP:[source][ip]}:%{INT:[source][port]} -> %{IP:[destination][ip]}:%{INT:[destination][port]}"
      }
      tag_on_failure => ["_snort_grok_parse_failure"]
    }
    mutate {
      convert => {
        "[snort][gid]" => "integer"
        "[snort][sid]" => "integer"
        "[snort][rev]" => "integer"
        "[snort][priority]" => "integer"
        "[source][port]" => "integer"
        "[destination][port]" => "integer"
      }
      lowercase => [ "[network][transport]" ]
      add_tag => [ "pfsense_snort" ]
      remove_field => [ "pfsense_body", "message" ]
    }
  }
}
output {
  if "pfsense_snort" in [tags] {
    elasticsearch {
      hosts => ["10.10.20.120:9200"]
      index => "pfsense-snort-%{+YYYY.MM.dd}"
    }
  }
}
```

### configs/siem/wazuh/local_rules.xml

```xml
<!-- Local rules for Audit monitoring -->
<group name="audit,www-data-cmd,web_attack,">
  <rule id="100100" level="10">
    <if_sid>80700</if_sid>
    <field name="audit.key">www-data-cmd</field>
    <description>Web process command execution detected: $(audit.exe)</description>
    <group>audit,www-data-cmd,web_attack,</group>
  </rule>
  <rule id="100101" level="12">
    <if_sid>100100</if_sid>
    <field name="audit.execve.a1">-c</field>
    <description>Web shell detected - sh -c execution by www-data: $(audit.execve.a2)</description>
    <group>audit,www-data-cmd,web_shell,web_attack,</group>
  </rule>
</group>

<group name="audit,rootcmd,">
  <rule id="100110" level="8">
    <if_sid>80700</if_sid>
    <field name="audit.key">rootcmd</field>
    <description>Root command executed: $(audit.exe) by auid=$(audit.auid)</description>
    <group>audit,rootcmd,privileged_execution,</group>
  </rule>
  <rule id="100111" level="10">
    <if_sid>100110</if_sid>
    <field name="audit.auid">4294967295</field>
    <description>Root command from non-login session (possible webshell): $(audit.exe)</description>
    <group>audit,rootcmd,web_shell,privileged_execution,</group>
  </rule>
</group>

<group name="audit,exec_monitor,">
  <rule id="100120" level="3">
    <if_sid>80700</if_sid>
    <field name="audit.key">exec_monitor</field>
    <description>Command execution monitored: $(audit.exe)</description>
    <group>audit,exec_monitor,</group>
  </rule>
  <rule id="100121" level="6">
    <if_sid>100120</if_sid>
    <field name="audit.exe">^/bin/nc$|^/usr/bin/nc$|^/bin/ncat$|^/usr/bin/ncat$|^/bin/netcat$</field>
    <description>Suspicious network tool executed: $(audit.exe)</description>
    <group>audit,exec_monitor,suspicious_execution,</group>
  </rule>
  <rule id="100122" level="8">
    <if_sid>100120</if_sid>
    <field name="audit.exe">^/usr/bin/wget$|^/usr/bin/curl$</field>
    <field name="audit.auid">4294967295</field>
    <description>Suspicious download tool from non-login session: $(audit.exe)</description>
    <group>audit,exec_monitor,suspicious_execution,</group>
  </rule>
</group>

<group name="audit,cron,">
  <rule id="100130" level="8">
    <if_sid>80700</if_sid>
    <field name="audit.key">cron</field>
    <description>Cron configuration modified: $(audit.file.name)</description>
    <group>audit,cron,persistence,</group>
  </rule>
  <rule id="100131" level="10">
    <if_sid>100130</if_sid>
    <field name="audit.auid">4294967295</field>
    <description>Cron modified from non-login session (possible persistence): $(audit.file.name)</description>
    <group>audit,cron,persistence,suspicious_execution,</group>
  </rule>
</group>
```

### configs/webserver/filebeat-output.yml

```yaml
# /etc/filebeat/filebeat.yml 중 변경한 부분 (Filebeat 7.5.1)
filebeat.inputs:
- type: log
  enabled: false
  paths:
    - /var/log/*.log

#output.elasticsearch:
  # hosts: ["localhost:9200"]

output.logstash:
  hosts: ["10.10.20.120:5046"]

# 최신 Ubuntu에서 7.5.1이 시작 직후 crash되는 문제 회피
seccomp.enabled: false
```

### configs/webserver/ossec-agent-localfile.xml

```xml
<!-- /var/ossec/etc/ossec.conf 끝에 추가 (Wazuh Agent 3.10.2) -->
<ossec_config>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/error.log</location>
  </localfile>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>
  <localfile>
    <log_format>audit</log_format>
    <location>/var/log/audit/audit.log</location>
  </localfile>
</ossec_config>
```

### configs/webserver/custom.rules

```bash
# /etc/audit/rules.d/custom.rules
-a always,exit -F arch=b64 -S execve -F euid=33 -k www-data-cmd
-a always,exit -F arch=b32 -S execve -F euid=33 -k www-data-cmd
-a always,exit -F arch=b64 -F euid=0 -S execve -k rootcmd
-a always,exit -F arch=b32 -F euid=0 -S execve -k rootcmd
-a always,exit -F arch=b64 -S execve -k exec_monitor
-a always,exit -F arch=b32 -S execve -k exec_monitor
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /etc/anacrontab -p wa -k cron
-w /etc/at.allow -p wa -k cron
-w /etc/at.deny -p wa -k cron
-w /var/spool/cron/ -p wa -k cron
```
