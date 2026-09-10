
---

## 1. 전체 구조

```
                    Internet
                        |
                    [IGW]
                        |
    +-------------------|-----------------------------+
    | VPC (10.0.0.0/16) |                             |
    |                                                 |
    |  +-- Public Subnet ---------------+             |
    |  |  EC2: web-server               |             |
    |  |  Apache + PHP 8.5              |             |
    |  |  SG: web-sg (80 from 0.0.0.0/0)|             |
    |  +--------------------------------+             |
    |                 |  3306                         |
    |                 v                               |
    |  +-- Private Subnet --------------+             |
    |  |  EC2: db-server                |             |
    |  |  MariaDB 10.5                  |             |
    |  |  SG: db-sg (3306 from web-sg)  |             |
    |  +--------------------------------+             |
    |          |                    ^                 |
    |          | outbound           | SSM 접속        |
    |       [NAT GW]         [VPC Endpoint x3]        |
    +-------------------------------------------------+
```

### 핵심 설계 포인트

|구성요소|역할|
|---|---|
|NAT Gateway|Private EC2의 **아웃바운드** 경로. 패키지 설치용|
|VPC Endpoint|Private EC2로의 **접속** 경로. Session Manager용|
|Session Manager|SSH/키페어/22번 포트 없이 접속. 공격 표면 축소|
|SG 참조 방식|`db-sg`의 소스를 IP가 아닌 `web-sg`로 지정|

NAT GW와 VPC Endpoint는 역할이 다르다. NAT GW만 있어도 Session Manager는 동작하지만(트래픽이 NAT를 경유), Endpoint를 두면 NAT를 제거해도 접속이 유지되는 구조가 된다.

---

## 2. 사전 준비

### VPC 생성

VPC 콘솔 → VPC 생성 → **VPC 등** 선택

- CIDR: `10.0.0.0/16`
- AZ 1개, Public Subnet 1개, Private Subnet 1개
- NAT GW: 없음 (Step 2에서 생성)

생성 후 Public Subnet → 작업 → 서브넷 설정 편집 → **퍼블릭 IPv4 자동 할당 활성화**
![](Images/Pasted%20image%2020260908122248.png)


### IAM 역할

IAM → 역할 생성 → AWS 서비스 → EC2 → 정책 `AmazonSSMManagedInstanceCore` 연결 → 이름 `ec2-ssm-role`

![](Images/Pasted%20image%2020260908122330.png)



### 보안 그룹 3종

*web-sg*
![](Images/Pasted%20image%2020260908122423.png)

*db-sg*
![](Images/Pasted%20image%2020260908122448.png)

*endpoint-sg*
![](Images/Pasted%20image%2020260908122510.png)

|이름|인바운드|소스|
|---|---|---|
|`web-sg`|HTTP 80|`0.0.0.0/0`|
|`db-sg`|MySQL 3306|`web-sg`|
|`endpoint-sg`|HTTPS 443|`10.0.0.0/16`|

---

## 3. Step 1 — Public EC2 (웹서버)

### 인스턴스 생성

| 항목       | 값                 |
| -------- | ----------------- |
| AMI      | Amazon Linux 2023 |
| 유형       | t2.micro          |
| 서브넷      | Public            |
| 퍼블릭 IP   | 활성화               |
| 보안 그룹    | `web-sg`          |
| IAM 프로파일 | `ec2-ssm-role`    |
| 키 페어     | 없음                |

### Apache + PHP 설치

```bash
sudo dnf install -y httpd php php-mysqlnd
sudo systemctl enable --now httpd
php -m | grep mysqli
```

> **패키지명 주의** 원본 자료의 `php-mysqli`는 Amazon Linux 2023에 존재하지 않는다. mysqli 확장은 `php-mysqlnd` 패키지가 제공한다.


### 동작 확인

```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/index.php
```

브라우저에서 `http://<퍼블릭IP>` 접속 확인 후 삭제 (`https`가 아닌 `http`로 접속할 것)

---

## 4. Step 2 — Private EC2 (DB서버)

### 4-1. NAT Gateway
![](Images/Pasted%20image%2020260908122557.png)
VPC → NAT 게이트웨이 생성

- 서브넷: **Public Subnet**
- 탄력적 IP 할당

### 4-2. 라우팅 테이블

Private Subnet에 연결된 라우팅 테이블 선택 → 라우팅 편집 → `0.0.0.0/0` → NAT Gateway

편집 전 **서브넷 연결 탭**에서 Private인지 반드시 확인. 
Public 라우팅 테이블을 수정하면 웹서버가 죽는다.
![](Images/Pasted%20image%2020260908122202.png)

### 4-3. VPC Endpoint 3개

Session Manager는 아래 3개가 모두 있어야 동작한다.

![](Images/Pasted%20image%2020260908122646.png)
```
com.amazonaws.ap-northeast-2.ssm
com.amazonaws.ap-northeast-2.ssmmessages
com.amazonaws.ap-northeast-2.ec2messages
```

각각 설정:

- 유형: Interface
- 서브넷: Private Subnet
- 보안 그룹: `endpoint-sg`
- **DNS 이름 활성화** 체크


### 4-4. 인스턴스 생성

| 항목     | 값           |
| ------ | ----------- |
| 서브넷    | **Private** |
| 퍼블릭 IP | **비활성화**    |
| 보안 그룹  | `db-sg`     |

### 4-5. MariaDB 설치

```bash
sudo dnf install -y mariadb105-server
sudo systemctl enable --now mariadb
```

설치가 멈추면 NAT 경로 문제. `curl -I https://google.com`으로 선확인.

### 4-6. DB 초기 설정

```bash
sudo mysql -u root
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
FLUSH PRIVILEGES;

CREATE DATABASE demo;

CREATE USER 'webuser'@'%' IDENTIFIED BY 'webuser';
GRANT ALL PRIVILEGES ON demo.* TO 'webuser'@'%';
FLUSH PRIVILEGES;

USE demo;
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(100)
);

INSERT INTO users (name, email) VALUES
('tom','tom@naver.com'),
('jerry','jerry@naver.com');
```

> **순서 변경** 원본 자료는 GRANT를 먼저 하지만, 존재하지 않는 DB에 권한을 부여하면 버전에 따라 실패한다. `CREATE DATABASE`를 앞으로 옮겼다.

> **별도 계정이 필요한 이유** MySQL/MariaDB의 root는 원격 접속이 차단되어 있어 `'webuser'@'%'` 형태의 계정을 따로 만들어야 한다.

### 4-7. 외부 접속 허용

기본 설정은 localhost만 수신한다.

```bash
sudo sed -i '/\[mysqld\]/a bind-address=0.0.0.0' /etc/my.cnf.d/mariadb-server.cnf
sudo systemctl restart mariadb
sudo ss -tlnp | grep 3306
```

`0.0.0.0:3306` 확인.

---

## 5. Step 3 — 웹 애플리케이션 연동

### 5-1. 연결 선확인

PHP 작성 전에 네트워크 경로부터 검증한다.

```bash
sudo dnf install -y mariadb105
mysql -h <DB_PRIVATE_IP> -u webuser -pwebuser demo -e "SELECT * FROM users;"
```

### 5-2. index.php 작성

```bash
sudo tee /var/www/html/index.php > /dev/null << 'EOF'
<?php
$host = "10.0.130.45";   // ← DB EC2의 Private IP로 교체
$user = "webuser";
$pass = "webuser";
$db   = "demo";

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

> **heredoc 따옴표** `<< 'EOF'`의 따옴표가 없으면 셸이 `$host`, `$row`를 먼저 치환해 빈 값이 들어간다. 반드시 따옴표를 붙일 것.

### 5-3. 확인

```bash
php -l /var/www/html/index.php      # 문법 검사
sudo php /var/www/html/index.php    # CLI 실행 (에러 그대로 출력)
```


브라우저에서 `http://<웹서버_퍼블릭IP>` → tom, jerry 표 출력
![](Images/Pasted%20image%2020260908122125.png)

---

## 6. 트러블슈팅


### 500 Internal Server Error

`curl -I http://localhost` 응답:

```
HTTP/1.1 500 Internal Server Error
X-Powered-By: PHP/8.5.9
```

`X-Powered-By` 헤더가 있다 = httpd와 PHP 연동은 정상, PHP 코드 내부 문제.


```bash
sudo php /var/www/html/index.php
```

```
PHP Warning: getaddrinfo for 10.0.x.x failed: Name or service not known
PHP Fatal error: Uncaught mysqli_sql_exception
```



### PHP 8의 mysqli 예외 동작

PHP 8부터 mysqli 연결 실패는 경고가 아닌 **예외**를 던진다. 따라서 코드의 `if ($conn->connect_error)` 블록은 실행될 기회조차 없고, "DB 연결 실패" 메시지 대신 빈 500이 반환된다.

기존 동작을 원하면:

```php
mysqli_report(MYSQLI_REPORT_OFF);
```


### Session Manager 접속 실패 시 점검 순서

1. IAM 역할이 인스턴스에 연결됐는지 (나중에 붙이면 반영에 ~5분)
2. VPC Endpoint 3개가 모두 `Available`인지
3. Endpoint 보안 그룹의 443 인바운드
4. Endpoint가 Private Subnet에 배치됐는지
5. NACL이 기본값인지

---