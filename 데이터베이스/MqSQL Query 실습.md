
KALI : test, TEST
ROCKY : user, user

### DATABASE 생성
- CREATE DATABASE [테이블명];
- USE  [테이블명];
![](../Images/Pasted%20image%2020260727101421.png)




### DATABASE TABLE 생성
- DATA TYPE - INT
- CONSTRAINT - NULL
-  SHOW TABLES;

```
- MariaDB [school_db]> CREATE TABLE student(
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
