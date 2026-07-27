
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

```
MariaDB [school_db]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| school_db          |
| testdb             |
+--------------------+
5 rows in set (0.001 sec)

```


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
---


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


MariaDB [school_db]> SELECT * FROM member
    -> WHERE age > (SELECT AVG(age) FROM member)
    -> ORDER BY age ASC;
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| JUNG | SUJIN  |   32 | DAGEON  |
| KIM  | JEOLSU |   35 | SEOUL   |
| JOE  | INHO   |   40 | DAGUE   |
+------+--------+------+---------+



-- 퀴즈 : PRODUCT 테이블 확인 후
MIN(price) 보다 가격이 높은 데이터 조회 후 오름차순 정렬

MariaDB [school_db]> SELECT * FROM product
    -> WHERE price > (SELECT MIN(price) FROM product)
    -> ORDER BY price ASC;
+------------+--------------+---------+-------+
| product_id | product_name | price   | stock |
+------------+--------------+---------+-------+
|          4 | MOUSE        |    2000 |   100 |
|          3 | KEYBOARD     |   50000 |    40 |
|          5 | WEBCAM       |   60000 |    15 |
|          2 | MONITOR      |  400000 |    25 |
|          1 | NOTEBOOK     | 1200000 |    30 |
+------------+--------------+---------+-------+

```
```

```
`

---
## 집계 함수

**집계 함수** : 여러행의 데이터를 모아서 연산하는 함수
   합계, 평균, 개수 등 수행한 뒤, 단 하나의 결과값을 반환
   
```
-- Count
	Count(*) : 모든 행 개수
	Count(column) : 해당 컬럼 값이 null 아닌 행의 개수
 
 
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
7 rows in set (0.000 sec)

MariaDB [school_db]> SELECT COUNT(*)
    -> FROM member;
+----------+
| COUNT(*) |
+----------+
|        7 |
+----------+
1 row in set (0.002 sec)


MariaDB [school_db]> SELECT COUNT(address) FROM member;
+----------------+
| COUNT(address) |
+----------------+
|              7 |
+----------------+
1 row in set (0.000 sec)

MariaDB [school_db]> SELECT COUNT(name) FROM member;
+-------------+
| COUNT(name) |
+-------------+
|           7 |
+-------------+


-- 퀴즈 : 나이가 30보다 같거나 많은 행의 개수를 세시오
MariaDB [school_db]> SELECT COUNT(age) FROM member WHERE age >=30;
+------------+
| COUNT(age) |
+------------+
|          4 |
+------------+
1 row in set (0.000 sec)

MariaDB [school_db]> SELECT COUNT(address) FROM member WHERE address = 'SEOUL';
+----------------+
| COUNT(address) |
+----------------+
|              3 |
+----------------+






-- AS로 컬럼 별칭 지정하기

MariaDB [school_db]> SELECT AVG(age) AS '선울평균아이' FROM member WHERE address = 'SEOUL';
+--------------------+
| 선울평균아이       |
+--------------------+
|            30.0000 |
+--------------------+
1 row in set (0.001 sec)

MariaDB [school_db]> SELECT AVG(age) AS '서울평균나이' FROM member WHERE address = 'SEOUL';
+--------------------+
| 서울평균나이       |
+--------------------+
|            30.0000 |
+--------------------+
1 row in set (0.001 sec)

MariaDB [school_db]> SELECT
    -> COUNT(*) AS '회원수',
    -> AVG(age) AS '평균나이',
    -> MAX(age) AS '최고나이',
    -> MIN(age) AS '최연소나이' FROM member;
+-----------+--------------+--------------+-----------------+
| 회원수    | 평균나이     | 최고나이     | 최연소나이      |
+-----------+--------------+--------------+-----------------+
|         7 |      30.0000 |           40 |              20 |
+-----------+--------------+--------------+-----------------+


-- 퀴즈 : product table, 총 가격, 평균 가격, 총 재고

MariaDB [school_db]> SELECT SUM(price) AS '총 가격',
    -> AVG(price) AS '평균가격',
    -> SUM(stock) AS '총 재고'
    -> FROM product;
+------------+--------------+------------+
| 총 가격    | 평균가격     | 총 재고    |
+------------+--------------+------------+
|    1712000 |  342400.0000 |        210 |
+------------+--------------+------------+





```

---

### GROUP BY

```
-- GROUP BY : 같은 값을 가진 행을 그룹으로 묶어서 집계
GROUP BY 뒤 컬럼은 SELECT 절에 반드시 포함
보통 집계 함수와 같이 사용하며, GROUP BY만 단독으로 쓰는 경우는 거의 없다.

MariaDB [school_db]> SELECT address FROM member GROUP BY  address;
+---------+
| address |
+---------+
| BUSAN   |
| DAGEON  |
| DAGUE   |
| INCHEON |
| SEOUL   |
+---------+
5 rows in set (0.002 sec)

MariaDB [school_db]> SELECT address ,
    -> COUNT(*) FROM member GROUP BY address;
+---------+----------+
| address | COUNT(*) |
+---------+----------+
| BUSAN   |        1 |
| DAGEON  |        1 |
| DAGUE   |        1 |
| INCHEON |        1 |
| SEOUL   |        3 |
+---------+----------+
MariaDB [school_db]> SELECT address , AVG(age) FROM member GROUP BY address;
+---------+----------+
| address | AVG(age) |
+---------+----------+
| BUSAN   |  20.0000 |
| DAGEON  |  32.0000 |
| DAGUE   |  40.0000 |
| INCHEON |  28.0000 |
| SEOUL   |  30.0000 |
+---------+----------+

MariaDB [school_db]> SELECT address, COUNT(*)  AS '회원수' , AVG(age) AS '평균나이' FROM member GROUP BY address;
+---------+-----------+--------------+
| address | 회원수    | 평균나이     |
+---------+-----------+--------------+
| BUSAN   |         1 |      20.0000 |
| DAGEON  |         1 |      32.0000 |
| DAGUE   |         1 |      40.0000 |
| INCHEON |         1 |      28.0000 |
| SEOUL   |         3 |      30.0000 |
+---------+-----------+--------------+


// WHERE 먼저 계산, WHERE는 그룹화 전 개별행 필터링
MariaDB [school_db]> SELECT address, AVG(age) AS '평균나이'
    -> FROM member WHERE address IN('INCHEON','BUSAN') GROUP BY address;
+---------+--------------+
| address | 평균나이     |
+---------+--------------+
| BUSAN   |      20.0000 |
| INCHEON |      28.0000 |
+---------+--------------+

MariaDB [school_db]> SELECT address, AVG(age) AS '평균나이', COUNT(*) AS '회원수 'FROM member WHERE address IN('INCHEON','BUSAN') GROUP BY address;
+---------+--------------+------------+
| address | 평균나이     | 회원수     |
+---------+--------------+------------+
| BUSAN   |      20.0000 |          1 |
| INCHEON |      28.0000 |          1 |
+---------+--------------+------------+



MariaDB [school_db]> SELECT address, AVG(age) AS '평균나이', COUNT(*) AS '인원수' FROM member WHERE age >= 25 GROUP BY address HAVING COUNT(*) = 1 ORDER BY AVG(age);
+---------+--------------+-----------+
| address | 평균나이     | 인원수    |
+---------+--------------+-----------+
| INCHEON |      28.0000 |         1 |
| DAGEON  |      32.0000 |         1 |
| DAGUE   |      40.0000 |         1 |
+---------+--------------+-----------+

// 집계 함수에는 or
```



---


### HAVING
```
HAVING은 그룹화 후 집계 결과에 조건

	where-> 행 필터
	having -> 그룹 필터
	문법적으로 having 단독으로 못쓰고 group by와 같이 사용
	
	
MariaDB [school_db]> SELECT address, COUNT(*) AS '인원수'
    -> FROM member GROUP BY address;
+---------+-----------+
| address | 인원수    |
+---------+-----------+
| BUSAN   |         1 |
| DAGEON  |         1 |
| DAGUE   |         1 |
| INCHEON |         1 |
| SEOUL   |         3 |
+---------+-----------+
5 rows in set (0.001 sec)

MariaDB [school_db]> SELECT address, COUNT(*) AS '인원수' FROM member GROUP BY address HAVING COUNT(*) >= 2;
+---------+-----------+
| address | 인원수    |
+---------+-----------+
| SEOUL   |         3 |
+---------+-----------+


퀴즈 : 평균 나이가 30보다 크거나 같은걸 뽑아내라.

MariaDB [school_db]> SELECT address, AVG(age) AS '평균나이'FROM member GROUP BY address
+---------+--------------+
| address | 평균나이     |
+---------+--------------+
| DAGEON  |      32.0000 |
| DAGUE   |      40.0000 |
| SEOUL   |      30.0000 |
+---------+--------------+




---------------------------------------------------

WHERE -> 행 필터링
GROUP BY -> 그룹화
HAVING -> 그룹 필터링  ==> 3가지를 거쳐서 해석


퀴즈 : 나이가 25살보다 크거나 같은 조건하에 ADDRESS로 그룹을 지어서 각 그룹의 address, 인원수와 평균나이를 구하는데
그룹의 조건으로 그릅의 인원이 1명이 경우만 구해라.

MariaDB [school_db]> SELECT address, AVG(age) AS '평균나이', COUNT(*) AS '인원수' FROM member GROUP BY address HAVING COUNT(*) = 1;
+---------+--------------+-----------+
| address | 평균나이     | 인원수    |
+---------+--------------+-----------+
| BUSAN   |      20.0000 |         1 |
| DAGEON  |      32.0000 |         1 |
| DAGUE   |      40.0000 |         1 |
| INCHEON |      28.0000 |         1 |
+---------+--------------+-----------+

// ORDER BY 사용 시 집계 함수에는 적용되지 않음

```


```
MariaDB [school_db]> CREATE TABLE orders(
    -> order_id VARCHAR(10) NOT NULL PRIMARY KEY,
    -> member_id VARCHAR(12),
    -> product_name VARCHAR(30),
    -> quantity INT
    -> );
Query OK, 0 rows affected (0.005 sec)

MariaDB [school_db]> DESCRIBE orders
    -> ;
+--------------+-------------+------+-----+---------+-------+
| Field        | Type        | Null | Key | Default | Extra |
+--------------+-------------+------+-----+---------+-------+
| order_id     | varchar(10) | NO   | PRI | NULL    |       |
| member_id    | varchar(12) | YES  |     | NULL    |       |
| product_name | varchar(30) | YES  |     | NULL    |       |
| quantity     | int(11)     | YES  |     | NULL    |       |
+--------------+-------------+------+-----+---------+-------+


MariaDB [school_db]> SELECT * FROM orders;
+----------+-----------+--------------+----------+
| order_id | member_id | product_name | quantity |
+----------+-----------+--------------+----------+
| o001     | KIM       | NOTEBOOK     |        1 |
| o002     | LEE       | NOTEBOOK     |        1 |
| o003     | PARK      | NOTEBOOK     |        1 |
| o004     | KIM       | KEYBOARD     |        1 |
| o005     | LEE       | MOUSE        |        1 |
+----------+-----------+--------------+----------+



-- 두 개의 테이블을 서브쿼리로 연결하기

시나리오 : 서울에 사는 사람의 id를 서브 쿼리를 뽑고 해당 id로 orders 테이블 필터링 하기

1. 서울 사는 사람이 주문한 데이터만 보기

MariaDB [school_db]> SELECT * FROM orders
    -> WHERE member_id IN(SELECT id FROM member WHERE address = 'SEOUL');
+----------+-----------+--------------+----------+
| order_id | member_id | product_name | quantity |
+----------+-----------+--------------+----------+
| o001     | KIM       | NOTEBOOK     |        1 |
| o002     | LEE       | NOTEBOOK     |        1 |
| o004     | KIM       | KEYBOARD     |        1 |
| o005     | LEE       | MOUSE        |        1 |
+----------+-----------+--------------+----------+


2. 나이가 30살 이상인 사람의 주문 데이터 보기
   MariaDB [school_db]> SELECT * FROM orders WHERE member_id IN(SELECT id FROM member WHERE age >= 30);
+----------+-----------+--------------+----------+
| order_id | member_id | product_name | quantity |
+----------+-----------+--------------+----------+
| o001     | KIM       | NOTEBOOK     |        1 |
| o002     | LEE       | NOTEBOOK     |        1 |
| o004     | KIM       | KEYBOARD     |        1 |
| o005     | LEE       | MOUSE        |        1 |
+----------+-----------+--------------+----------+

3. 노트북만 주문한 사람들의 이름만 뽑아내기
MariaDB [school_db]> SELECT name FROM member  WHERE id IN(SELECT member_id FROM orders
  WHERE product_name = 'NOTEBOOK');
+--------+
| name   |
+--------+
| JEOLSU |
| HOSUNG |
| JISUNG |
+--------+


------------------------------------------
-- UNION 
 컬럼 개수, 타입일치 필요, 중복 행 자동 제거
 
MariaDB [school_db]> SELECT * FROM orders;
+----------+-----------+--------------+----------+
| order_id | member_id | product_name | quantity |
+----------+-----------+--------------+----------+
| o001     | KIM       | NOTEBOOK     |        1 |
| o002     | LEE       | NOTEBOOK     |        1 |
| o003     | PARK      | NOTEBOOK     |        1 |
| o004     | KIM       | KEYBOARD     |        1 |
| o005     | LEE       | MOUSE        |        1 |
+----------+-----------+--------------+----------+
5 rows in set (0.000 sec)

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
7 rows in set (0.000 sec)

MariaDB [school_db]> SELECT id FROM member UNION SELECT member_id FROM orders;
+------+
| id   |
+------+
| CHOI |
| JOE  |
| JUNG |
| KANG |
| KIM  |
| LEE  |
| PARK |
+------+
7 rows in set (0.001 sec)

MariaDB [school_db]> SELECT id FROM member UNION ALL  SELECT member_id FROM orders;
+------+
| id   |
+------+
| CHOI |
| JOE  |
| JUNG |
| KANG |
| KIM  |
| LEE  |
| PARK |
| KIM  |
| LEE  |
| PARK |
| KIM  |
| LEE  |
+------+
12 rows in set (0.000 sec)

MariaDB [school_db]> SELECT id FROM member WHERE address = 'SEOUL' UNION ALL  SELECT member_id FROM orders;
+------+
| id   |
+------+
| KANG |
| KIM  |
| LEE  |
| KIM  |
| LEE  |
| PARK |
| KIM  |
| LEE  |
+------+
8 rows in set (0.001 sec)

MariaDB [school_db]> SELECT id FROM member WHERE address = 'SEOUL' UNION  SELECT member_id FROM orders;
+------+
| id   |
+------+
| KANG |
| KIM  |
| LEE  |
| PARK |
+------+

 
 
 -- UNION 시 칼럼 수가 다른 경우 NULL로 맞춤
 
 MariaDB [school_db]> SELECT id, name, age, address FROM member
    -> UNION
    -> SELECT member_id, NULL,NULL,NULL FROM orders;
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
| KIM  | NULL   | NULL | NULL    |
| LEE  | NULL   | NULL | NULL    |
| PARK | NULL   | NULL | NULL    |
+------+--------+------+---------+


```


최고 실습
```
-- 1.
MariaDB [school_db]> SELECT * FROM member WHERE ID IN( SELECT member_id FROM orders WHERE product_name = (SELECT product_name FROM product WHERE price = (SELECT MAX(price)
FROM product)) );
+------+--------+------+---------+
| id   | name   | age  | address |
+------+--------+------+---------+
| KIM  | JEOLSU |   35 | SEOUL   |
| LEE  | HOSUNG |   30 | SEOUL   |
| PARK | JISUNG |   20 | BUSAN   |
+------+--------+------+---------+
3 rows in set (0.001 sec)


-- 2.
MariaDB [school_db]> SELECT name FROM member WHERE id IN( SELECT member_id FROM orders GROUP BY member_id HAVING COUNT(*) >=2 );
+--------+
| name   |
+--------+
| JEOLSU |
| HOSUNG |
+--------+



```