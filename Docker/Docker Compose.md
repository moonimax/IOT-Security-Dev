
---
### 개념

한번에 원하는 시스템을 구축할 수 있도록 시스템 전반적인 구축 과정을 실행하고 제거할 수 있는 설정 파일의 기능을 돕는 프로그램이다.

기존 `docker run`을 여러 개로 배포된 설정 파일을 한번에 여러 개의 컨테이너를 생성하고, 이 컨테이너를 통해 네트워크 , 볼륨, 설정 파일, 환경 설정 필수 파일 등을 함께 만들 수 있다.

---

## 워크플로우

1. 프로젝트 폴더 만들기
2. compose.yaml 작성
3. `docker compose up -d`
4. 상태 / 로그 확인
5. 수정 시 `--build`
6. 종료 / 정리 (`stop`, `down`, `down -v`)


---

## 실습 1 - nginx

AWS 폴더 생성 후 하위 디렉토리로 `myweb`을 만들고, 그 아래에 compose.yaml과 html/index.html을 생성.

```
myweb
├── compose.yaml
└── html
    └── index.html
```

![](Images/Pasted%20image%2020260915095228.png)


compose.yaml 작성
```yaml
services:

 web:

 image: nginx:alpine

 ports:

  - "8181:80"

 volumes:

  - ./html:/usr/share/nginx/html:ro

 restart: unless-stopped
```


3) docker compose up -d
![](Images/Pasted%20image%2020260915100709.png)

`.yaml` 파일의 환경 변수를 설정해서 이전에 했던 **IAC** 기반 배포/관리를 **CaC** 기반 구조로 바꿔봤다. 


4) Postman에서 Get 요청 시 아래와 같은 결과 값 출력


![](Images/Pasted%20image%2020260915101554.png)


- 이 설정에 의해 서버 설정의 일관성이 유지될 수 있다는 장점을 챙길 수 있다.
- 대표적인 도구 : Ansible, Chef, Puppet, SaltStack

---

### 실습 2 - Spring Boot + MySQL

##### 구조

```
springboot
├── docker-compose.yml
└── springboot-app
    ├── build.gradle
    ├── Dockerfile
    └── src
        └── main
            ├── java
            │   └── com
            │       └── example
            │           └── demo
            │               ├── DemoApplication.java
            │               └── UserController.java
            └── resources
                └── application.properties
```

##### docker-compose.yml

![](../Images/Pasted%20image%2020260915114333.png)

```
services:
  web:
    build: ./springboot-app
    container_name: springboot_app
    ports:
      - "8800:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/demo_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=1234
    depends_on:
      - db
    restart: always

  db:
    image: mysql:8.0
    container_name: mysql_db
    environment:
      - MYSQL_ROOT_PASSWORD=1234
      - MYSQL_DATABASE=demo_db
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3366:3306"
    restart: always

volumes:
  mysql_data:
```


##### UserController.java

```java
package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.jdbc.core.JdbcTemplate;

import org.springframework.web.bind.annotation.GetMapping;

import org.springframework.web.bind.annotation.RestController;

  

@RestController

public class UserController {

  

@Autowired

private JdbcTemplate jdbcTemplate;

  

@GetMapping("/hello")

public String hello() {

return "Hello from Spring Boot!";

}

  

@GetMapping("/db-test")

public String dbTest() {

try {

String sql = "SELECT testcol FROM test WHERE testid = 1";

String result = jdbcTemplate.queryForObject(sql, String.class);

return "Database test successful. The result of '1 + 1' is: " +

result;

} catch (Exception e) {

e.printStackTrace();

return "Database connection failed! Error: " + e.getMessage();

}

}

}
```


##### DB 테이블 생성

```sql
mysql> select * from test
    -> ;
+--------+---------+
| testid | testcol |
+--------+---------+
|      1 |  apple  |
+--------+---------+
1 row in set (0.00 sec)
```


**출력 값**

![](../Images/Pasted%20image%2020260915122347.png)


---

## 명령어 모음집
```bash
docker compose up -d           # 백그라운드 실행
docker compose up -d --build   # 이미지 다시 빌드하고 실행
docker compose ps              # 상태 확인
docker compose logs -f         # 로그
docker logs <컨테이너명> --tail 30
docker compose down            # 컨테이너/네트워크 삭제
docker compose down -v         # 볼륨까지 삭제
```
