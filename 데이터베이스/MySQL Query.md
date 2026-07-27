
## 목차

1. [1. DATABASE 생성]
2. [2. DATABASE TABLE 생성]
3. [3. SQL 심화]


**사전 세팅**
KALI : test, TEST
ROCKY : user, user


---


### 1. DATABASE 생성
- CREATE DATABASE [테이블명];
- USE  [테이블명];
![](../Images/Pasted%20image%2020260727101421.png)


---


### 2. DATABASE TABLE 생성
- DATA TYPE - INT
- CONSTRAINT - NULL


**SHOW TABLES;**

```
MariaDB [school_db]> CREATE TABLE student(
    -> student_id VARCHAR(10) NOT NULL PRIMARY KEY,
    -> name VARCHAR(10),
    -> age INT,
    -> city VARCHAR(20)
    -> );

MariaDB [school_db]> SHOW TABLES;
+---------------------+
| Tables_in_school_db |
+---------------------+
| student             |
+---------------------+
1 row in set (0.000 sec)



```

**TABLE 구조 확인**
	- DESCRIBE
	- EXPLAIN
	- DESC
```

MariaDB [school_db]> DESCRIBE student;
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| student_id | varchar(10) | NO   | PRI | NULL    |       |
| name       | varchar(10) | YES  |     | NULL    |       |
| age        | int(11)     | YES  |     | NULL    |       |
| city       | varchar(20) | YES  |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+
4 rows in set (0.003 sec)





-- 실습

-- TABLE 생성
MariaDB [school_db]> CREATE TABLE member(
    -> id VARCHAR(10) NOT NULL PRIMARY KEY,
    -> name VARCHAR(20),
    -> age INT,
    -> address VARCHAR(20)
    -> );
Query OK, 0 rows affected (0.006 sec)

-- TABLE 데이터 삽입
MariaDB [school_db]> INSERT INTO member VALUES('KIM','KMIII', 35, 'SEOUL');
Query OK, 1 row affected (0.002 sec)

MariaDB [school_db]> INSERT INTO member VALUES('MOON','NIDEV', 20, 'SUWON');
Query OK, 1 row affected (0.002 sec)

MariaDB [school_db]> INSERT INTO member VALUES('LEE','SU', 27, 'BUSAN');
Query OK, 1 row affected (0.001 sec)

MariaDB [school_db]> INSERT INTO member VALUES('SEO','IK', 40, 'DAGUE');
Query OK, 1 row affected (0.002 sec)


-- TABLE 데이터 조회

MariaDB [school_db]> SELECT * FROM member;
+------+-------+------+---------+
| id   | name  | age  | address |
+------+-------+------+---------+
| KIM  | KMIII |   35 | SEOUL   |
| LEE  | SU    |   27 | BUSAN   |
| MOON | NIDEV |   20 | SUWON   |
| SEO  | IK    |   40 | DAGUE   |
+------+-------+------+---------+
4 rows in set (0.003 sec)


- WHERE -> 조건에 맞는 데이터만 조회
		-> SELECT, UPDATE		
MariaDB [school_db]> SELECT * FROM member WHERE address = 'BUSAN';
+-----+------+------+---------+
| id  | name | age  | address |
+-----+------+------+---------+
| LEE | SU   |   27 | BUSAN   |
+-----+------+------+---------+
1 row in set (0.000 sec)


-- WHERE 절과 조건검색

1. 비교 연산자 =, !=, <>
MariaDB [school_db]> SELECT * FROM member WHERE age <= 30;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| KANG | MINSEO |   25 | SEOUL   |
| LEE  | SU     |   27 | BUSAN   |
| MOON | NIDEV  |   20 | SUWON   |
+------+--------+------+---------+
3 rows in set (0.002 sec)

MariaDB [school_db]> SELECT * FROM member WHERE address <> 'SEOUL';
+------+-------+------+---------+
| id   | name  | age  | address |
+------+-------+------+---------+
| CHOI | MINHO |   48 | INCHEON |
| JUNG | SUGON |   32 | DAGEON  |
| LEE  | SU    |   27 | BUSAN   |
| MOON | NIDEV |   20 | SUWON   |
| SEO  | IK    |   40 | DAGUE   |
+------+-------+------+---------+
5 rows in set (0.002 sec)


2. BETWEEN : 범위 지정, 시작값, 끝값 포함해서 지정
MariaDB [school_db]> SELECT * FROM member WHERE age BETWEEN 25 AND 35;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| JUNG | SUGON  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   35 | SEOUL   |
| LEE  | SU     |   27 | BUSAN   |
+------+--------+------+---------+
4 rows in set (0.001 sec)

MariaDB [school_db]> SELECT * FROM member WHERE age BETWEEN 30 AND 45;
+------+-------+------+---------+
| id   | name  | age  | address |
+------+-------+------+---------+
| JUNG | SUGON |   32 | DAGEON  |
| KIM  | KMIII |   35 | SEOUL   |
| SEO  | IK    |   40 | DAGUE   |
+------+-------+------+---------+
3 rows in set (0.000 sec)


3. AND / OR
AND : 모두 만족
OR : 조건 중 하나만 만족해도
AND와 OR 같이 사용 가능함. 이떄 괄호 필수

MariaDB [school_db]> SELECT * FROM member WHERE (age != 25 AND address != 'DAGEON') OR id != 'JUNG';
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   48 | INCHEON |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   35 | SEOUL   |
| LEE  | SU     |   27 | BUSAN   |
| MOON | NIDEV  |   20 | SUWON   |
| SEO  | IK     |   40 | DAGUE   |
+------+--------+------+---------+
6 rows in set (0.001 sec)
   

4. IN : 여러 값 검색하기
   IN / NOT IN - 만족하는 값 중 하나, NOT IN 목록에 없는 값
MariaDB [school_db]> SELECT name, address FROM member WHERE address IN ('SEOUL', 'BUSAN');
+--------+---------+
| name   | address |
+--------+---------+
| MINSEO | SEOUL   |
| KMIII  | SEOUL   |
| SU     | BUSAN   |
+--------+---------+
   
   
5. LIKE : 패턴 매칭하기
   % : 0개 이상 임의 문자
   _ : 1개의 임의 문자
   
MariaDB [school_db]> SELECT * FROM member WHERE name LIKE 'K%';
+-----+-------+------+---------+
| id  | name  | age  | address |
+-----+-------+------+---------+
| KIM | KMIII |   35 | SEOUL   |
+-----+-------+------+---------+
   
MariaDB [school_db]> SELECT * FROM member WHERE name LIKE '%O%' OR '_O';
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   48 | INCHEON |
| JUNG | SUGON  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
+------+--------+------+---------+
3 rows in set, 5 warnings (0.002 sec)


6. NULL 값 다루기
MariaDB [school_db]> INSERT INTO member VALUES('test','test',25,NULL);
Query OK, 1 row affected (0.003 sec)

MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   48 | INCHEON |
| JUNG | SUGON  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   35 | SEOUL   |
| LEE  | SU     |   27 | BUSAN   |
| MOON | NIDEV  |   20 | SUWON   |
| SEO  | IK     |   40 | DAGUE   |
| test | test   |   25 | NULL    |
+------+--------+------+---------+
8 rows in set (0.001 sec)

MariaDB [school_db]> SELECT * FROM member WHERE address = NULL;
Empty set (0.001 sec)

MariaDB [school_db]> SELECT * FROM member WHERE address IS NULL;
+------+------+------+---------+
| id   | name | age  | address |
+------+------+------+---------+
| test | test |   25 | NULL    |
+------+------+------+---------+



7. 데이터 수정
   - UPDATE, DELETE : 반드시 WHERE절 사용
MariaDB [school_db]> UPDATE member SET age = 50 WHERE id = 'CHOI';
Query OK, 1 row affected (0.002 sec)
Rows matched: 1  Changed: 1  Warnings: 0

MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   50 | INCHEON |
| JUNG | SUGON  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   35 | SEOUL   |
| LEE  | SU     |   27 | BUSAN   |
| MOON | NIDEV  |   20 | SUWON   |
| SEO  | IK     |   40 | DAGUE   |
| test | test   |   25 | NULL    |
+------+--------+------+---------+
8 rows in set (0.000 sec)

 

8. DELETE
   
MariaDB [school_db]> DELETE FROM member WHERE id = 'test';
Query OK, 1 row affected (0.001 sec)

MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   50 | INCHEON |
| JUNG | SUGON  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   36 | BUSAN   |
| LEE  | SU     |   27 | BUSAN   |
| MOON | NIDEV  |   20 | SUWON   |
| PARK | JISUNG |   22 | DAGUE   |
+------+--------+------+---------+


9. 조건을 활용한 수정과 삭제
MariaDB [school_db]> UPDATE member SET address = 'SEOUL' WHERE age >= 30;
Query OK, 2 rows affected (0.002 sec)
Rows matched: 3  Changed: 2  Warnings: 0

MariaDB [school_db]> UPDATE member SET age = age + 5 WHERE address IN ('BUSAN');
Query OK, 0 rows affected (0.001 sec)
Rows matched: 0  Changed: 0  Warnings: 0

MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| JUNG | SUGON  |   32 | SEOUL   |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | KMIII  |   36 | SEOUL   |
| LEE  | HOSUNG |   31 | SEOUL   |
| MOON | NIDEV  |   20 | SUWON   |
| PARK | JISUNG |   22 | DAGUE   |
+------+--------+------+---------+
   
MariaDB [school_db]> DELETE FROM member WHERE age BETWEEN 25 AND 35;
Query OK, 3 rows affected (0.002 sec)

MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| KIM  | KMIII  |   36 | SEOUL   |
| MOON | NIDEV  |   20 | SUWON   |
| PARK | JISUNG |   22 | DAGUE   |
+------+--------+------+---------+
3 rows in set (0.000 sec)

  
```

---

## 3. SQL 심화

```
-- 테이블 세팅 1
MariaDB [school_db]> SELECT * FROM member;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   28 | INCHEON |
| JOE  | INHO   |   40 | DAGUE   |
| JUNG | SUJIN  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| KIM  | JEOLSU |   35 | SEOUL   |
| LEE  | HOSUNG |   30 | SEOUL   |
| PARK | JISUNG |   20 | BUSAN   |
+------+--------+------+---------+

-- 테이블 세팅 2
MariaDB [school_db]> SELECT * FROM product;
+------------+--------------+---------+-------+
| product_id | product_name | price   | stock |
+------------+--------------+---------+-------+
|          1 | NOTEBOOK     | 1200000 |    30 |
|          2 | MONITOR      |  400000 |    25 |
|          3 | KEYBOARD     |   50000 |    40 |
|          4 | MOUSE        |    2000 |   100 |
|          5 | WEBCAM       |   60000 |    15 |
+------------+--------------+---------+-------+
```


```

1. 정렬과 서브쿼리
   ORDER BY
   - ASC(오름차순)
   - DESC(내림차순)
MariaDB [school_db]> SELECT * FROM member ORDER BY age ASC;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| PARK | JISUNG |   20 | BUSAN   |
| KANG | MINSEO |   25 | SEOUL   |
| CHOI | MINHO  |   28 | INCHEON |
| LEE  | HOSUNG |   30 | SEOUL   |
| JUNG | SUJIN  |   32 | DAGEON  |
| KIM  | JEOLSU |   35 | SEOUL   |
| JOE  | INHO   |   40 | DAGUE   |
+------+--------+------+---------+

MariaDB [school_db]> SELECT * FROM member ORDER BY age DESC;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| JOE  | INHO   |   40 | DAGUE   |
| KIM  | JEOLSU |   35 | SEOUL   |
| JUNG | SUJIN  |   32 | DAGEON  |
| LEE  | HOSUNG |   30 | SEOUL   |
| CHOI | MINHO  |   28 | INCHEON |
| KANG | MINSEO |   25 | SEOUL   |
| PARK | JISUNG |   20 | BUSAN   |
+------+--------+------+---------+

MariaDB [school_db]> SELECT * FROM member ORDER BY address ASC, age ASC;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| PARK | JISUNG |   20 | BUSAN   |
| JUNG | SUJIN  |   32 | DAGEON  |
| JOE  | INHO   |   40 | DAGUE   |
| CHOI | MINHO  |   28 | INCHEON |
| KANG | MINSEO |   25 | SEOUL   |
| LEE  | HOSUNG |   30 | SEOUL   |
| KIM  | JEOLSU |   35 | SEOUL   |
+------+--------+------+---------+




--BETWEEN ORDER BY 함께 사용하기
  실행 순서상 WHERE, ORDER BY 
MariaDB [school_db]> SELECT * FROM member WHERE age BETWEEN 25 AND 40 ORDER BY age ASC;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| KANG | MINSEO |   25 | SEOUL   |
| CHOI | MINHO  |   28 | INCHEON |
| LEE  | HOSUNG |   30 | SEOUL   |
| JUNG | SUJIN  |   32 | DAGEON  |
| KIM  | JEOLSU |   35 | SEOUL   |
| JOE  | INHO   |   40 | DAGUE   |
+------+--------+------+---------+


```

```

특정 쿼리를 괄호로 묶은 후 그 쿼리 결과값을 조건 값으로 사용

-- KIM 나이보다 많은 사람을 출력하라.
MariaDB [school_db]> SELECT * FROM member WHERE  age > (SELECT age FROM member WHERE i
d = 'KIM');
+-----+------+------+---------+
| id  | name | age  | address |
+-----+------+------+---------+
| JOE | INHO |   40 | DAGUE   |
+-----+------+------+---------+
1 row in set (0.004 sec)

MariaDB [school_db]> SELECT AVG(age) FROM member;
+----------+
| AVG(age) |
+----------+
|  30.0000 |
+----------+
1 row in set (0.001 sec)


-- 평균 나이보다 나이 많은 사람을 출력
MariaDB [school_db]> SELECT name FROM member WHERE age  > (SELECT AVG(age) FROM member
);
+--------+
| name   |
+--------+
| INHO   |
| SUJIN  |
| JEOLSU |
+--------+




-- Any를 사용한 서브 쿼리
   서브쿼리 결과 값 중 단 하나라도 조건을 만족하면 참 
   (여러개의 결과 값의 OR 조건)

MariaDB [school_db]> SELECT *  FROM member WHERE age > ANY (SELECT age FROM member WHERE address = 'SEOUL');
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   28 | INCHEON |
| JOE  | INHO   |   40 | DAGUE   |
| JUNG | SUJIN  |   32 | DAGEON  |
| KIM  | JEOLSU |   35 | SEOUL   |
| LEE  | HOSUNG |   30 | SEOUL   |
+------+--------+------+---------+
5 rows in set (0.001 sec)

MariaDB [school_db]> SELECT *  FROM member WHERE age <  ANY (SELECT age FROM member WHERE address = 'SEOUL');
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| CHOI | MINHO  |   28 | INCHEON |
| JUNG | SUJIN  |   32 | DAGEON  |
| KANG | MINSEO |   25 | SEOUL   |
| LEE  | HOSUNG |   30 | SEOUL   |
| PARK | JISUNG |   20 | BUSAN   |
+------+--------+------+---------+
5 rows in set (0.000 sec)



```
```
