
## 목차

1. [[]](#1-%EC%A0%84%EC%B2%B4-%ED%9D%90%EB%A6%84-%EC%9A%94%EC%95%BD)
2. [Rocky Linux 준비 (IP 확인 → SSH → MariaDB)](#2-rocky-linux-%EC%A4%80%EB%B9%84-ip-%ED%99%95%EC%9D%B8--ssh--mariadb)
3. [MariaDB 데이터베이스 및 계정 설정](#3-mariadb-%EB%8D%B0%EC%9D%B4%ED%84%B0%EB%B2%A0%EC%9D%B4%EC%8A%A4-%EB%B0%8F-%EA%B3%84%EC%A0%95-%EC%84%A4%EC%A0%95)
4. [방화벽 설정 (3306 포트 개방)](#4-%EB%B0%A9%ED%99%94%EB%B2%BD-%EC%84%A4%EC%A0%95-3306-%ED%8F%AC%ED%8A%B8-%EA%B0%9C%EB%B0%A9)
5. [Kali Linux에서 mysql 클라이언트 설치](#5-kali-linux%EC%97%90%EC%84%9C-



KALI : test, TEST
ROCKY : user, user

### 1. DATABASE 생성
- CREATE DATABASE [테이블명];
- USE  [테이블명];
![](../Images/Pasted%20image%2020260727101421.png)




### DATABASE TABLE 생성
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






```


