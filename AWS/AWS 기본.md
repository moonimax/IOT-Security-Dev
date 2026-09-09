
---

admin, Jenny, Roberto

#### 리전(Region)

> AWS 서비스가 제공되는 물리적위치, 다른 국가 차원에서 인프라 묶음
> 대부분 AWS 서비스의 기본 제공 단위(ex. 암호화키는 대상 리전에서만 사용 가능)

![](Images/Pasted%20image%2020260902102327.png)


EC2 권한 정책 설정은 admin을 검색
![](Images/Pasted%20image%2020260902102547.png)


계정 생성 시 IAM PID 식별자가 로그인 시 출력됨
![](Images/Pasted%20image%2020260902102912.png)

#### 가용 영역(Availability Zone)

> 리전 내에서 독립적인 데이터센터 또는 데이터센터 클러스터
>각 AZ는 부리된 데이터센터 그룹, 단일 건물 리스크를 줄이기 위해 여러 건물에 걸쳐 운영하며 장애 영향을 받지 않음



---

#### ELB[Elastic Load Balancing]

***Scaling***
시스템이 더 많은 요청을 처리할 수 있도록 리소스를 늘리는 작업


---
IasS, SasS, PasS


AWS NW FireWall Hands - FW NW 정책 설정

---

### 1-1. Identity-based Policy

S3 Bucket Access

**권한 없는 terry** 
![](../Images/Pasted%20image%2020260909100921.png)


*AmazonS3ReadOnlyAccess 연결*
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": "*"
        }
    ]
}
```


S3 Bucket 재연결
![](../Images/Pasted%20image%2020260909101508.png)


사용자 정의 JSON 정책 부여
```json
{
  "Version": "2012-10-17",
  // Bucket 모든 연결 접근 부여
  "Statement": [
    {
      "Sid": "AllowListAllBuckets",
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "*"
    },
    // IamPolicy정책에 의해 버킷 연결 접근 부여
    {
      "Sid": "AllowListIAMTestBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::saps3bucketpolicytest"
    },
    //S3 버킷 읽기 전용 접근 권한 부여
    {
      "Sid": "AllowReadObjectsInIAMTest",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::saps3bucketpolicytest/*"
    }
  ]
}
```



---
### 1-2. Resource-based Policy


]S3 Bucket - shareplease 정책 편집

![](../Images/Pasted%20image%2020260909102447.png)

>이 정책의 영향을 받는 주체의 범위가 Resource Policy에만 존재하여 Principal 원칙에 `::root` 명시하여, *이 계정에 속한 모든 ID 주체를 의미*


위 정책을 아래와 같이 변경하게 된다면 정책 요구 사항은 다음과 같이 변경된다.

-  1. "Effect" : Deny
	- `admin` 유저조차 접근 불가한 강력한 통제에 걸린다.
-  2. "AWS": [arn:aws:iam:::user/jake]
	- 화이트 리스트 정책에 의해 위 Effect 단위에서 전체 접근을 제한한 정책에 대해 명시한 유저만을 접근 허용해준다.

최종 판정 순서로, Deny가 명시되어 있는가? Identify Policy 또는 Resource Policy 중 하나라도 Allow 된 항목이 있는가? 그 어떤 것도 조건으로 걸려 있지 않으면 기본적으로 거부 상태로 제한되어 있다.


---

### 1-3. IAM-Role(Assume Role)






