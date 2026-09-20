
---

이전 Docker Compose장에서 진행한 내용을 Redis에 붙이고 push하면 EC2까지 자동으로 배포되게 만들어 봤다.

앞으로 진행할 흐름은 이렇다.
```
로컬에서 push
  → GitHub Actions로 image build
  → Docker Hub에 push
  → SSH로 EC2 접속해서 docker compose pull & up
```


---

### 1. 구조

```tree
springboot2
├── .github
│   └── workflows
│       └── deploy.yml
├── docker-compose.yml
└── springboot-app2
    ├── build.gradle
    ├── Dockerfile
    └── src
        └── main
            ├── java
            │   └── com
            │       └── example
            │           └── demo
            │               ├── DemoApplication.java
            │               └── UserController2.java
            └── resources
                └── application.properties
            
```

---

### 2. 설정 파일

```gradle
plugins {
   id 'java'
   id 'org.springframework.boot' version '3.2.5'
   id 'io.spring.dependency-management' version '1.1.4'
}

group = 'com.example'
version = '0.0.1-SNAPSHOT'

java {
   sourceCompatibility = '17'
}

repositories {
   mavenCentral()
}

dependencies {
   implementation 'org.springframework.boot:spring-boot-starter-web'
   implementation 'org.springframework.boot:spring-boot-starter-jdbc'
   implementation 'org.springframework.boot:spring-boot-starter-data-redis'
   runtimeOnly 'com.mysql:mysql-connector-j'
   testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
   useJUnitPlatform()
}
```



**Dockerfile**
```
# Gradle을 사용하여 애플리케이션 빌드

FROM gradle:7.6.1-jdk17 AS build

WORKDIR /app

COPY . .

RUN gradle bootJar

  

# 빌드된 JAR 파일을 실행

FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --from=build /app/build/libs/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
```




**application.properties**

```properties
# server.port=8880
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.datasource.username=${SPRING_DATASOURCE_USERNAME}
spring.datasource.password=${SPRING_DATASOURCE_PASSWORD}
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

spring.data.redis.url=redis://redis2:6379/0
```

- 값을 하드코딩하지 않고 `${}`로 받아서 환경 변수값을 compose 내 환경 변수에 따라 대입되는 CaC 방식이다.



**docker-compose.yml**
```yaml
services:
  web2:
    build: ./springboot-app2
    container_name: springboot_app2
    ports:
      - "9090:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://db2:3306/demo_db2?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=1212
      - SPRING_DATA_REDIS_URL=redis://redis2:6379/0
    depends_on:
      db2:
        condition: service_healthy
      redis2:
        condition: service_healthy
    restart: always

  db2:
    image: mysql:8.0
    container_name: mysql_db2
    environment:
      - MYSQL_ROOT_PASSWORD=1212
      - MYSQL_DATABASE=demo_db2
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-p1212"]
      interval: 5s
      timeout: 3s
      retries: 10
    volumes:
      - mysql_data2:/var/lib/mysql
    ports:
      - "3336:3306"
    restart: always

  redis2:
    image: redis:7-alpine
    container_name: redis2
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10
    restart: always

volumes:
  mysql_data2:
```

- DB 호스트를 IP가 아니라 서비스 이름(`db2`, `redis2`)으로 쓴다. 
- `depends_on` + `condition: service_healthy`로 DB가 준비된 다음에 앱이 뜬다. 그냥 `depends_on`만 쓰면 컨테이너가 시작되지 않은 상태로 넘어가 버려서 DB가 아직 초기화 중인데 앱이 붙으려다 죽는 경우를 방지하기 위해서다.

### UserController2.java



```java
package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.data.redis.core.StringRedisTemplate;

@RestController
public class UserController2 {

   @Autowired
   private JdbcTemplate jdbcTemplate;

    @GetMapping("/")
    public String hello() {
        return "Spring Boot! START PAGE";
    }

    @GetMapping("/mysql")
    public String dbTest() {
        try {
            String sql = "SELECT now()";
            String result = jdbcTemplate.queryForObject(sql, String.class);
            return "Database test successful. now() : " + result;
        } catch (Exception e) {
            e.printStackTrace();
            return "Database connection failed! Error: " + e.getMessage();
        }
    }

    @Autowired
    private StringRedisTemplate redis;

    @GetMapping("/redis-set")
    public String redisSet() {
        try {
            redis.opsForValue().set("key", "100");
            return "Redis SET OK. key=key, value=100";
        } catch (Exception e) {
            e.printStackTrace();
            return "Redis SET failed! Error: " + e.getMessage();
        }
    }

    @GetMapping("/redis-get")
    public String redisGet() {
        try {
            String value = redis.opsForValue().get("key");
            return "Redis GET OK. key=key >> " + value;
        } catch (Exception e) {
            e.printStackTrace();
            return "Redis GET failed! Error: " + e.getMessage();
        }
    }
}
```

`SELECT now()`는 테이블이 없어도 실행되니까 DB 연결 확인용으로 쓰기 좋다.


**Docker HUB**
등록한 레포지토리에 build를 통해 image 배포가 가능한 래포지토리를 등록하면 다음과 같은 화면을 뜬다.
![](Images/Pasted%20image%2020260915193140.png)



---

## 3. GitHub Actions

`.github/workflows/deploy.yml`


```yaml
name: deploy

on:
  push:
    branches:
      - "main"

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build & Push Spring Boot Image
        uses: docker/build-push-action@v6
        with:
          context: ./springboot-app2
          file: ./springboot-app2/Dockerfile
          push: true
          tags: moonimax/springboot2-web2:latest
          platforms: linux/amd64

      - name: Deploy via SSH (compose up)
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          port: ${{ secrets.EC2_PORT }}
          timeout: 60s
          command_timeout: 20m
          script_stop: true
          script: |
            set -e
            cd ~/springboot2
            docker compose pull
            docker compose up -d
            docker compose ps
```



***Secrets 등록***
![](Images/Pasted%20image%2020260915193006.png)


---

AWS EC2 Instance Public 연결

**Docker 공식 저장소 등록 후 설치**
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
# 도커 서비스 상태 확인
sudo systemctl status docker
# 비활성/에러면 시작 및 부팅 자동 시작
sudo systemctl enable --now docker
# docker 그룹에 현재 사용자 추가
sudo usermod -aG docker $USER
# 현재 세션에 즉시 반영
newgrp docker

# 설치된 docker 버전 확인
docker --version
docker compose version
docker info 
```


