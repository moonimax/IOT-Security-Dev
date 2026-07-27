
## 목차

1. [1. DATABASE 생성]
2. [2. DATABASE TABLE 생성]
3. [3. ]

**사전 유저 세팅**
KALI : test, TEST
ROCKY : user, user


### 1. DATABASE 생성
- CREATE DATABASE [테이블명];
- USE  [테이블명];
![](../Images/Pasted%20image%2020260727101421.png)




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
   


```


