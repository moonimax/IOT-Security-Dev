
### 구축한 리소스
| 리소스                | 이름/ID                  | 역할                                                        |
| ------------------ | ---------------------- | --------------------------------------------------------- |
| S3 버킷              | `vpc-test-20260910-wh` | 조회 대상                                                     |
| IAM Role           | `role-ec2-ssm-s3`      | `AmazonSSMManagedInstanceCore` + `AmazonS3ReadOnlyAccess` |
| Gateway Endpoint   | `프로젝트-vpce-s3`         | S3 접근                                                     |
| Interface Endpoint | `SSM`                  | SSM API 호출                                                |
| Interface Endpoint | `SSMmessages`          | 세션 채널                                                     |
| Interface Endpoint | `EC2messages`          | Agent ↔ 서비스 메시지                                           |

---

**Step 1 )**

`S3 Buket - vpce-test-sh` 
![](Images/Pasted%20image%2020260910173643.png)



**Step 2)**

`Iam Role - role-ec2-ssm-s3`
![](Images/Pasted%20image%2020260910173944.png)


**Step 3)**

`ec2-private Insatnce - private_instance1`
보안 그룹 -> `EC2-SSM-Roles1' 역할 정책으로 변경했다.

*EC2-SSM-Roles1*
- `AmazonSSManagedInstanceCore`
- `AmazonS3ReadOnlyAccess`



**Step 4)**

>Gateway Endpoint 생성

![](Images/Pasted%20image%2020260910181534.png)



**Step 5)**
private 라우팅 테이블 인바운드 규칙 설립
![](Images/Pasted%20image%2020260910182028.png)



#### Interface Endpoint
서브넷 안에 실제 ENI가 생긴다

이쪽은 만들 때 서브넷과 보안그룹을 직접 지정했다. Private 서브넷 안에 사설 IP를 가진 네트워크 카드가 실제로 꽂히기 때문이다.

그래서 SG에 **443 인바운드**가 필요하고 Gateway에는 SG가 없는 역할을 대신해서 수행한다고 생각하면 된다.

**프라이빗 DNS 활성화**가 결정적이었습니다.
`ssm.ap-northeast-2.amazonaws.com`이라는 공인 도메인이 VPC 안에서만 `10.0.x.x` 같은 사설 IP로 해석됩니다. 


---


### Gateway vs Interface EndPoint 차이



||Gateway|Interface|
|---|---|---|
|지원 서비스|S3, DynamoDB만|대부분의 AWS 서비스|
|실체|라우팅 규칙|ENI (사설 IP)|
|지정 대상|라우팅 테이블|서브넷 + 보안그룹|
|DNS|변경 없음|공인 도메인 → 사설 IP override|
|443 허용|불필요|**필요**|
|비용|무료|시간당 + 데이터|
|외부 접근|불가|가능 (On-prem, VPC Peering, DX, VPN)|


---

### 최종 검증


인스턴스 안에서 아래를 실행한 결과 VPC EndPoint를 통해
AWS Service Resource 접근 가능한 점을 확인하였다. 이전 실습에서 NAT 라우트를 지우기 전에 세션 작업 연결이 재구성된 것이 핵심이다.


```bash
curl -s -m 3 http://169.254.169.254/latest/meta-data/public-ipv4 && echo "공인 IP"
```


![](Images/Pasted%20image%2020260910180810.png)




엑세스 거부가 뜨면 실 인터넷 연결이 끊겼다는 것을 증명할 수 있다. 
반면에 응답이 오면 어떠한 경우로도 NAT 경로가 남아 있다는 것이다.

즉, **인터넷은 완전히 막혀 있는데 AWS 서비스는 쓸 수 있는 상태**.
이게 규제 준수 환경에서 VPC EndPoint를 쓰는 이유고, 이번 실습에서 보여주려는 그림이였다!!

![](Images/Pasted%20image%2020260910181352.png)


---
