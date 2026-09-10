


Step 1 )

`S3 Buket - vpce-test-sh` 
![](Images/Pasted%20image%2020260910173643.png)



Step 2)

`Iam Role - role-ec2-ssm-s3`
![](Images/Pasted%20image%2020260910173944.png)


Step 3)

`ec2-private Insatnce - private_instance1`
보안 그룹 -> `EC2-SSM-Roles1' 역할 정책으로 변경했다.

*EC2-SSM-Roles1*
- `AmazonSSManagedInstanceCore`
- `AmazonS3ReadOnlyAccess`



Step 4)
Gateway Endpoint 생성


