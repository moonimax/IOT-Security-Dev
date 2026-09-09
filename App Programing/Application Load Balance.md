
**목표** — CloudFront 도메인으로만 접속 가능하게 하고, ALB DNS와 EC2 Public DNS IP로 접근을 차단한다

---


## 아키텍처

```
                    사용자
                      │  https
                      ▼
        ┌──────────────────────────────────┐
        │  CloudFront : wwwwtttt           │
        │  d1cwiamwl3jku0.cloudfront.net   │
        │  → 요청에 X-Origin-Verify 헤더 삽입 │
        └──────────────┬───────────────────┘
                       │  http (80)
                       ▼
        ┌──────────────────────────────────┐
        │  ALB : ALBBB (Internet-facing)   │
        │  Listener HTTP:80                │
        │   ├ 규칙1 : 헤더 일치 → 대상 그룹   │
        │   └ 기본  : 403 고정 응답          │
        └──┬───────────┬───────────┬───────┘
           │ 33.33%    │ 33.33%    │ 33.33%
           ▼           ▼           ▼
         [ t1 ]      [ t2 ]      [ t3 ]        ← 대상 그룹 3개
           │           │           │
           ▼           ▼           ▼
          e1          e2          e33          ← EC2 각 1대
                                               SG: launch-wizard-1
                                               (80 ← albSG 참조)

  VPC : vpc-084110d021c58fdc8
  AZ  : ap-northeast-2a / ap-northeast-2b
```

**이 구성의 특징 2가지**

1. 대상 그룹 3개에 EC2 1대씩 배치 

2. 두 계층 차단
- EC2 직접 접근 → **보안 그룹(L4)** 에서 차단
- ALB DNS 직접 접근 → **리스너 규칙(L7)** 에서 차단

---

## 1. 전체 리소스 목록

|구분|이름|ID|
|---|---|---|
|VPC|프로젝트-vpc|`vpc-084110d021c58fdc8`|
|서브넷 (2a)|프로젝트-subnet-public1|`subnet-0027d71d39b493e30`|
|서브넷 (2b)|—|`subnet-0faf3ef32d5f268ff`|
|EC2|`e1`|`i-0156de36faa4485fc`|
|EC2|`e2`|`i-0b40177169d40ea65`|
|EC2|`e33`|`i-030cbc37f2ebcf793`|
|대상 그룹|`t1`|`.../targetgroup/t1/a634e77a09f654aa`|
|대상 그룹|`t2`|`.../targetgroup/t2/948b42cc96c763d5`|
|대상 그룹|`t3`|`.../targetgroup/t3/3662e89093a02946`|
|ALB|`ALBBB`|`.../loadbalancer/app/ALBBB/1fa43c72473a3467`|
|보안 그룹|`albSG`|`sg-0b4658512adf4d1d5`|
|보안 그룹|`launch-wizard-1`|`sg-0df5fed8d136d8989`|
|보안 그룹|`RejectAlbDNS` _(최종 미사용)_|`sg-0a8e5439daa12e6e2`|
|CloudFront|`wwwwtttt`|`E1O0VZWXL4T4B5`|



---

## 2. EC2 구성

`e1`, `e2`, `e33` 3대를 동일 스펙으로 생성했다.

|항목|값|
|---|---|
|AMI|Amazon Linux|
|인스턴스 유형|`t2.micro`|
|서브넷|`subnet-0027d71d39b493e30` (public1-ap-northeast-2a)|
|보안 그룹|`launch-wizard-1`|
|IMDSv2|Required|

**각 인스턴스 설치 명령어** 

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl enable httpd
systemctl start httpd
echo "<h1>Hello from EC2 $(hostname -f)</h1>" > /var/www/html/index.html
```

### 인스턴스 상세 내용

![](Images/09-ec2-e33-detail.png)

|항목|값|
|---|---|
|인스턴스 ID|`i-030cbc37f2ebcf793`|
|퍼블릭 IPv4|`3.34.139.168`|
|프라이빗 IPv4|`10.0.12.52`|
|퍼블릭 DNS|`ec2-3-34-139-168.ap-northeast-2.compute.amazonaws.com`|
|인스턴스 유형|`t2.micro`|

**인바운드 규칙**을 보면 80번 포트의 원본이 `sg-0b4658512adf4d1d5`(albSG)로 잡혀 있다. 이게 앞 ALB 경로로 접근하는 트래픽만을 허용하는 방식으로 EC2 인스턴스에서 직접 접근을 차단할 수 있게 한다.


---

## 3. 대상 그룹 구성

| 항목        | 값                       |
| --------- | ----------------------- |
| 대상 유형     | **인스턴스**                |
| 프로토콜 : 포트 | **HTTP : 80**           |
| 프로토콜 버전   | HTTP1                   |
| IP 주소 유형  | IPv4                    |
| VPC       | `vpc-084110d021c58fdc8` |
| 상태 검사     | HTTP, 경로 `/`            |

> ⚠️ 대상 그룹은 **프로토콜이 고정**이다. TCP로 만들면 NLB 전용이 되어 ALB에 붙일 수 없다. 
### t1 → e1에서 모든 대상 그룹 매핑


![](Images/03-tg-t1.png)


> 위 캡처는 대상 등록 직후 시점이라 상태가 `Unhealthy`로 보인다.
>프로토콜 포트는 HTTP 80만을 허용한 상태 

---

## 4. ALB 구성

### 세부 정보 및 리스너

![](Images/01-alb-detail-listener.png)

|항목|값|
|---|---|
|이름|`ALBBB`|
|로드 밸런서 유형|애플리케이션 (ALB, L7)|
|**체계(Scheme)**|**Internet-facing**|
|상태|활성|
|VPC|`vpc-084110d021c58fdc8`|
|가용 영역|`ap-northeast-2a` / `ap-northeast-2b` (2개)|
|IP 주소 유형|IPv4|
|DNS 이름|`ALBBB-379960967.ap-northeast-2.elb.amazonaws.com` (A 레코드)|
|호스팅 영역|`ZWKZPGTI48KDX`|
|생성일|2026-09-09 11:31 (UTC+09:00)|


### 리스너 HTTP:80 — 규칙 구성


**규칙 1 (우선순위 1)**

| 구분        | 내용                                                    |
| --------- | ----------------------------------------------------- |
| 조건        | HTTP 헤더 `X-Origin-Verify` = _(비밀값)_                   |
| 작업        | 대상 그룹으로 전달 — `t1` / `t2` / `t3` 가중치 각 1 → **33.33%씩** |


**기본 규칙**

|구분|내용|
|---|---|
|작업|**고정 응답 반환**|
|응답 코드|`403`|
|콘텐츠 유형|`text/plain`|
|응답 본문|`Forbidden - Direct access is not allowed`|

> 헤더가 없는 요청(= CloudFront를 거치지 않은 직접 접근)은 어떤 규칙에도 매칭되지 않아 기본 규칙으로 403을 받는다.


### 보안 탭

![](Images/02-alb-security-groups.png)


|보안 그룹 ID|이름|인바운드|
|---|---|---|
|`sg-0b4658512adf4d1d5`|`albSG`|1 permission entry|
|`sg-0a8e5439daa12e6e2`|`RejectAlbDNS`|1 permission entry|

최종 구성에서는 `albSG`만 남기고 `RejectAlbDNS`는 제거했다.

---

## 5. 보안 그룹 구성

### albSG — ALB
![](Images/07-sg-albsg.png)


|항목|값|
|---|---|
|이름|`albSG`|
|ID|`sg-0b4658512adf4d1d5`|
|인바운드|HTTP / TCP / 80 ← `0.0.0.0/0`|


### launch-wizard-1 — EC2에 부착

![](Images/06-sg-launch-wizard-1.png)

|유형|프로토콜|포트|소스|
|---|---|---|---|
|HTTP|TCP|80|**`sg-0b4658512adf4d1d5` (albSG)**|
|SSH|TCP|22|`0.0.0.0/0`|
|HTTPS|TCP|443|`0.0.0.0/0`|


**80번 소스에 IP 대역이 아니라 보안 그룹 ID를 넣은 것이 핵심.**


```
인터넷 ──80──▶ [albSG : 0.0.0.0/0]  ALB
                     │
                     └──80──▶ [launch-wizard-1 : 소스=albSG]  EC2
                                   │
인터넷 ──80──▶ ✕ 차단 (소스가 albSG가 아님)
```


### RejectAlbDNS — 미사용
![](Images/08-sg-rejectalbdns.png)


|항목|값|
|---|---|
|이름|`RejectAlbDNS`|
|ID|`sg-0a8e5439daa12e6e2`|
|인바운드|HTTP / TCP / 80 ← `pl-22a6434b` (CloudFront 접두사 목록)|

CloudFront 엣지 IP 대역만 허용하려고 만들었으나 최종 구성에서는 사용하지 않았다. 

---

## 6. CloudFront 구성

![](Images/10-cloudfront-origin.png)

|항목|값|
|---|---|
|배포 이름|`wwwwtttt` (Standard)|
|배포 도메인 이름|`d1cwiamwl3jku0.cloudfront.net`|
|ARN|`arn:aws:cloudfront::[ACCOUNT_ID]:distribution/E1O0VZWXL4T4B5`|
|Billing|Pay-as-you-go|
|마지막 수정|2026-09-09 03:33 UTC|

### 원본(Origin) 설정

|항목|값|
|---|---|
|원본 도메인|`ALBBB-379960967.ap-northeast-2.elb.amazonaws.com`|
|원본 유형|**Elastic Load Balancing** (콘솔이 자동 인식)|
|**원본 프로토콜**|**HTTP only**, 포트 80|
|Origin Shield|미사용|

> ⚠️ **원본 프로토콜을 반드시 `HTTP only`로.** `HTTPS only`나 `Match viewer`로 두면 CloudFront가 ALB의 **443 포트**로 연결을 시도하는데, ALB에는 HTTP:80 리스너만 있어서 응답이 없고 **504 Gateway Timeout**이 난다.

### 사용자 지정 헤더

|헤더 이름|값|
|---|---|
|`X-Origin-Verify`|_(임의의 긴 랜덤 문자열)_|



---

## 7. 접근 차단 설계

### 두 계층에서 차단

|접근 경로|차단 위치|방식|
|---|---|---|
|EC2 퍼블릭 IP 직접|보안 그룹 (L4)|`launch-wizard-1`의 80번 소스를 `albSG`로 제한|
|ALB DNS 직접|리스너 규칙 (L7)|헤더 없으면 기본 규칙에서 403|


---

## 8. 검증 결과

![](Images/Pasted%20image%2020260909153935.png)

![](Images/Pasted%20image%2020260909154007.png)

| #   | 접속 경로                                                     | 기대  | 결과              |
| --- | --------------------------------------------------------- | --- | --------------- |
| 1   | `https://d1cwiamwl3jku0.cloudfront.net`                   | 정상  | ✅ 정상            |
| 2   | `http://ALBBB-379960967.ap-northeast-2.elb.amazonaws.com` | 차단  | ✅ 403 Forbidden |
| 3   | `http://3.34.139.168`                                     | 차단  | ✅ 타임아웃          |



---

