
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



