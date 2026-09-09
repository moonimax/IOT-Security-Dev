
---

## 1. Part 1과 무엇이 달라지는가

||Part 1|Part 2|
|---|---|---|
|DB|EC2 + MariaDB (직접 설치)|RDS MySQL (관리형)|
|DB 계정|`webuser` 별도 생성|`admin` (RDS 기본)|
|비밀번호 위치|소스코드 평문|Secrets Manager|
|비밀번호 변경|코드 수정 + 재배포|자동, 무중단|
|접근 통제|없음 (파일 읽으면 끝)|IAM 역할|

### DB를 RDS로 바꾸는 이유

직접 설치한 MariaDB에서 로테이션을 구현하려면 비밀번호 생성하기 위해 DB에서 `User`를 수동으로 변경 및 갱신해야한다. 
RDS는 Secrets Manager와 연동되어 AWS가 이 과정을 대신 수행한다.


### Parameter Store가 아닌 Secrets Manager를 쓰는 이유

둘 다 비밀값을 암호화 저장하지만 **로테이션 기능**이 다르다.

- **Parameter Store**: 저장과 조회만. 값 변경은 수동
- **Secrets Manager**: 주기적으로 새 비밀번호를 생성해 DB와 저장소를 동시 갱신

---

## 2. 전체 구조

```
                    Internet
                        |
                    [IGW]
                        |
    +-------------------|--------------------------------+
    | VPC (10.0.0.0/16)                                   |
    |                                                     |
    |  +-- Public Subnet --------------------+            |
    |  |  EC2: web-server                    |            |
    |  |  Apache + PHP + aws.phar (SDK)      |            |
    |  |  IAM: ec2-ssm-role                  |            |
    |  |       + SecretsManagerReadWrite     |            |
    |  +-------------------------------------+            |
    |         |                    |                      |
    |         | 3306               | GetSecretValue       |
    |         v                    v                      |
    |  +-- Private Subnet ---+   [Secrets Manager]        |
    |  |  RDS MySQL          |<-------+                   |
    |  |  SG: db-sg          |        | ALTER USER        |
    |  +---------------------+   [Rotation Lambda]        |
    |                                                     |
    +-----------------------------------------------------+
```

핵심은 **웹 서버가 비밀번호를 모른다**는 점이다. 
요청이 올 때마다 IAM 역할로 Secrets Manager에 물어보고, 로테이션 Lambda가 뒤에서 값을 바꿔도 다음 요청은 새 값을 받는다.

---

## 3. 사전 — Subnet 가용 영역 2개 이상

**RDS 서브넷 그룹은 최소 2개의 가용 영역이 필요하다.**


---

## 4. Step 1 — DB 서브넷 그룹 생성

RDS 콘솔 → 서브넷 그룹 → **DB 서브넷 그룹 생성**

![](Images/Pasted%20image%2020260908144440.png)

| 항목    | 값                                    |
| ----- | ------------------------------------ |
| 이름    | `lab-db-subnet-group`                |
| VPC   | `lab-vpc`                            |
| 가용 영역 | `ap-northeast-2a`, `ap-northeast-2b` |
| 서브넷   | **Private Subnet 2개**                |
*DB*는 private 영역으로 VPC Endpoint를 통해서만 인/아웃바운드 규칙이 설립되어 있어 할당하는 서브넷 영역은 private이다.

---

## 5. Step 2 — RDS MySQL 생성


### 5-1. 엔진과 템플릿

- 생성 방식: **표준 생성**
- 엔진: *MySQL
- 템플릿: 프리 티어

### 5-2. 설정

| 항목          | 값                            |
| ----------- | ---------------------------- |
| DB 인스턴스 식별자 | `lab-rds`                    |
| 마스터 사용자 이름  | `admin`                      |
| 자격 증명 관리    | **AWS Secrets Manager**에서 관리 |

기본값은 "자체 관리"라 비밀번호를 직접 입력하게 되어 있다. 

Secrets Manager 관리를 선택하면 비밀번호 입력란이 사라지고 KMS 키 선택란이 나타난다. 기본 키(`aws/secretsmanager`) 유지.

### 5-3. 연결

| 항목        | 값                      |
| --------- | ---------------------- |
| 컴퓨팅 리소스   | **EC2에 연결 안 함**        |
| VPC       | `lab-vpc`              |
| DB 서브넷 그룹 | `lab-db-subnet-group`  |
| 퍼블릭 액세스   | **아니요**                |
| VPC 보안 그룹 | **기존 항목 선택** → `db-sg` |

> **EC2 연결 안 함** 연결하면 AWS가 보안 그룹을 새로 만들어 자동 구성한다. Part 1에서 만든 `db-sg`(인바운드 `3306 from web-sg`)를 재사용하므로 연결하지 않는다. 기본 선택된 `default` SG는 반드시 해제할 것.

### 5-4. 추가 구성 (접혀 있음, 놓치기 쉬움)

- **초기 데이터베이스 이름**: `demo`
- 자동 백업: 체크 해제 
- 스토리지 자동 조정: 체크 해제

초기 데이터베이스 이름을 비우면 빈 인스턴스만 생성되어 나중에 `CREATE DATABASE demo;`를 직접 실행해야 한다.

### 5-5. 생성 후 확보할 값 2개

생성에 5~10분 소요. 상태가 **사용 가능**이 되면:

| 값          | 위치                             |
| ---------- | ------------------------------ |
| **엔드포인트**  | 데이터베이스 → `lab-rds` → 연결 및 보안 탭 |
| **시크릿 이름** | 구성 탭 → 마스터 자격 증명 ARN → 링크 클릭   |

Secret Name `rds!db-` 로 시작하는 자동 생성 이름이다.

![](Images/Pasted%20image%2020260908144834.png)
```
rds!db-453c64f6-9fbc-4c17-8039-c93bf85fca8a
```

`rds!` 접두사는 RDS 관리형 시크릿이라는 표시다. 

---

## 6. Step 3 — 웹서버에서 RDS 접속 및 데이터 입력


### 6-1. 비밀번호 확인

![](Images/Pasted%20image%2020260908144932.png)
Secrets Manager → 해당 시크릿 → 아래로 스크롤 → **보안 암호 값** → **보안 암호 값 검색** 버튼

`username`과 `password`가 표로 표시된다. 

### 6-2. 접속

```bash
mysql -h <RDS_엔드포인트> -u admin -p
```

`-p` 뒤에는 아무것도 붙이지 않는다. 
엔터 후 비밀번호를 붙여넣으면 화면에 표시되지 않지만 정상 입력된 것이다.

### 6-3. 데이터 입력

```sql
USE demo;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(100)
);

INSERT INTO users (name, email) VALUES
('tom','tom@naver.com'),
('jerry','jerry@naver.com');

SELECT * FROM users;
```

> **Part 1과 다른 점: `webuser`를 만들지 않는다** Part 1에서 별도 계정이 필요했던 건 로컬 MySQL의 root가 원격 접속을 막기 때문이다. RDS의 `admin`은 처음부터 원격 접속이 가능하고, 로테이션 대상도 이 계정이다.

---

## 7. Step 4 — 웹서버에 IAM 권한 부여

지금까지는 **사람이** 콘솔에서 비밀번호를 확인해 손으로 입력했다. 이제 **코드가** API로 직접 가져가게 만든다.


### 7-1. 기존 역할에 정책 추가

Part 1의 `ec2-ssm-role`이 이미 웹서버에 붙어 있으므로 `SecretsManagerReadWrite` 권한만 추가한다.


> ```json
> {
>     "Version": "2012-10-17",
>     "Statement": [
>         {
>             "Effect": "Allow",
>             "Action": "secretsmanager:GetSecretValue",
>             "Resource": "<시크릿의 ARN>"
>         }
>     ]
> }
> ```


## 8. Step 5 — PHP 애플리케이션 전환

### 8-1. AWS SDK for PHP 설치

```bash
cd /var/www/html
sudo curl -O https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.phar
ls -lh aws.phar
```



### 8-2. index.php 교체

```bash
sudo cp /var/www/html/index.php /var/www/html/index.php.bak
```

```bash
sudo tee /var/www/html/index.php > /dev/null << 'EOF'
<?php
require '/var/www/html/aws.phar';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

$secretName = "rds!db-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
$host = "lab-rds.xxxxx.ap-northeast-2.rds.amazonaws.com";
$user = "admin";
$db   = "demo";

$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => 'ap-northeast-2'
]);

try {
    $result = $client->getSecretValue(['SecretId' => $secretName]);
} catch (AwsException $e) {
    die("Secret 읽기 실패: " . $e->getMessage());
}

$secret = json_decode($result['SecretString'], true);
$pass = $secret['password'];

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    die("DB 연결 실패: " . $conn->connect_error);
}

echo "<h2>Users Table</h2>";
echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Email</th></tr>";

$sql = "SELECT id, name, email FROM users";
$result = $conn->query($sql);
while ($row = $result->fetch_assoc()) {
    echo "<tr>
            <td>{$row['id']}</td>
            <td>{$row['name']}</td>
            <td>{$row['email']}</td>
          </tr>";
}
echo "</table>";
$conn->close();
?>
EOF
```


### 8-3. 확인

```bash
grep -E '^\$secretName|^\$host' /var/www/html/index.php   
php -l /var/www/html/index.php                            
sudo php /var/www/html/index.php                        
```


### 8-4. 무엇이 달라졌는지 확인

![](Images/Pasted%20image%2020260908145504.png)

변수에 담기는 과정만 있고 **값 자체가 코드에 없다.**
Part 1의 `$pass = "webuser";`와 비교할 것.

접근 통제가 파일 권한에서 IAM 역할로 이동했다.

---

## 9. Step 6 — 로테이션 검증

### 9-1. 교체 전 값 기록

```bash
aws secretsmanager get-secret-value \
  --secret-id "<시크릿_이름>" \
  --region ap-northeast-2 \
  --query SecretString --output text
```

password 앞 몇 글자를 메모.

### 9-2. 즉시 교체 실행

Secrets Manager → 해당 시크릿 → **교체** 탭 → **작업** → 보안 암호 즉시 교체가 실시된다.


내부 동작: 로테이션 Lambda가 새 비밀번호 생성 → RDS에 `ALTER USER` 실행 → 성공 시 시크릿 값 갱신

### 9-3. 값 변경 확인

같은 CLI를 다시 실행.
password가 전히 다른 문자열이어야 한다.

### 9-4. 웹페이지 확인

브라우저에서 `http://<웹서버_퍼블릭IP>` **새로고침**.

![](Images/Pasted%20image%2020260908145601.png)

- 코드는 한 글자도 수정하지 않았다
- 서버를 재시작하지 않았다
- DB 비밀번호는 방금 완전히 바뀌었다

매 요청마다 Secrets Manager에서 최신 값을 조회하기 때문이다. Part 1 구조였다면 이 시점에 `Access denied for user` 에러가 발생한다.


---

## 10. 정리


Part 1의 `$pass = "webuser";`가 가진 문제들이 모두 사라졌다.

|문제|해결|
|---|---|
|Git 커밋 시 비밀번호 유출|코드에 값이 없음|
|서버 접근자가 `cat`으로 확인|코드에 값이 없음|
|비밀번호 변경 시 재배포 필요|자동 교체, 무중단|
|소스 노출 시 그대로 유출|IAM 역할 없이는 조회 불가|

---
