
---

![](Images/Pasted%20image%2020260910172741.png)

**NACL Hands-on**

 기본 public-subnet Instance는 퍼블릭 IPv4 DNS로 접근이 가능한 형태로, SG 인바운드를 열면 response 트래픽이 자동으로 허용되지만, NACL은 구성이 다르다. 인바운드 트래픽 허용으로 SSH 22 포트 지정만으로는 허용되지 않아 ephermeal port(1024-65535)로 나가, 해당 아웃바운드가 막혀있으면 접속 불가하다.


Step 1)
Windows 터미널 환경으로 ssh 연결 확인
`public instance key pair -> nacl-test.pem` 생성됨을 사전 조건

![](Images/Pasted%20image%2020260910164716.png)

접속됨을 확인


Step 2)
NACL 생성 후 인/아웃바운드 규칙 설정

![](Images/캡처.png)

**Inbound Rules**

![](Images/Pasted%20image%2020260910170447.png)

 **Outbound Rules**

규칙 번호는 낮은 번호부터 순차로 평가되어, 한국 리전을 포함하는 가용 영역에서 100이 200보다 우선되게 설정해야 한다.
 또한, 임시 포트로 접근할 수 있기 때문에 포트 범위를 1024-56535로 지정해두어야 한다.


Step 3)
 Public Subnet의 NACL을 Custom으로 교체
우선, Public Subnet에 배치할 Public Instance를 생성하고,
SG의 In/Out Bound 트래픽을 모두 허용해야 한다. 
 
 필터링 검증을 NACL로 진행하기 때문이며 SSM 접근이 아닌 SSH로 붙이기 위해 22 port를 확인하기 위해서다.

`public instance - ec2-pb-nac1`

![](Images/Pasted%20image%2020260910172406.png)



Step 4)
다시 Windows 터미널로 돌아와 `https://checkip.amazonaws.com/`에 조회되는 나의 amazon 공인 ip 주소를 ssh 연결을 시도하여 NACL이 적용되었는지 확인을 진행한다.

```bash
ssh -i nacl-test.pem ec2-user@[내 ip 주소]
```

![](Images/Pasted%20image%2020260910172654.png)


**NACL 구축 완료 확인!**
