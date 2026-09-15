
---
### 개념

한번에 원하는 시스템을 구축할 수 있도록 시스템 전반적인 구축 과정을 실행하고 제거할 수 있는 설정 파일의 기능을 돕는 프로그램이다.

기존 docker run을 여러 개로 배포된 설정 파일을 한번에 여러 개의 컨테이너를 생성하고, 이 컨테이너를 통해 네트워크 , 볼륨, 설정 파일, 환경 설정 필수 파일 등을 함께 만들 수 있다.

---


워크플로우

1) 프로젝트 폴더 만들기
2) compose.yaml 작성
3) docker compse up -d
4) 상태 로그 확인
5) 수정 시 --build 또는 build
6) 종료/정리(stop, down, down -v)



---

AWS 폴더 생성 후 하위 디렉토리로 
myweb- compose.yaml/ html 하위로 index.html을 생성한다.

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



4) Postman에서 Get 요청 시 아래와 같은 결과 값 출력


![](Images/Pasted%20image%2020260915101554.png)


.yaml 파일의 환경 변수를 설정하여 이전에 실습했던 Iac 기반의 배포, 관리를 CaC로 변경하는 구조로 환경 설정을 코드로 관리하는 방식의 실습을 진행해 보았다.
- 이 설정에 의해 서버 설정의 일관성이 유지될 수 있다는 장점을 챙길 수 있다.
- 대표적인 도구 : Ansible, Chef, Puppet, SaltStack


---

### 도커 컴포즈 springboot로 구현


서비스 정의

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

