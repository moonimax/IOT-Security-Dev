
mysql
- 계정 및 권한 정보
- user 테이블 
	- 계정 이름, 접속 허용 호스트, 패스워드(hash), 권한

```
MariaDB [mysql]> SELECT user,host from user;
+-------------+-----------+
| User        | Host      |
+-------------+-----------+
| test        | 192.168.% |
| mariadb.sys | localhost |
| mysql       | localhost |
| root        | localhost |
+-------------+-----------+
4 rows in set (0.001 sec)

MariaDB [mysql]> DESCRIBE user;
+------------------------+---------------------+------+-----+----------+-------+
| Field                  | Type                | Null | Key | Default  | Extra |
+------------------------+---------------------+------+-----+----------+-------+
| Host                   | char(60)            | NO   |     |          |       |
| User                   | char(80)            | NO   |     |          |       |
| Password               | longtext            | YES  |     | NULL     |       |
| Select_priv            | varchar(1)          | YES  |     | NULL     |       |
| Insert_priv            | varchar(1)          | YES  |     | NULL     |       |
| Update_priv            | varchar(1)          | YES  |     | NULL     |       |
| Delete_priv            | varchar(1)          | YES  |     | NULL     |       |
| Create_priv            | varchar(1)          | YES  |     | NULL     |       |
| Drop_priv              | varchar(1)          | YES  |     | NULL     |       |
| Reload_priv            | varchar(1)          | YES  |     | NULL     |       |
| Shutdown_priv          | varchar(1)          | YES  |     | NULL     |       |
| Process_priv           | varchar(1)          | YES  |     | NULL     |       |
| File_priv              | varchar(1)          | YES  |     | NULL     |       |
| Grant_priv             | varchar(1)          | YES  |     | NULL     |       |
| References_priv        | varchar(1)          | YES  |     | NULL     |       |
| Index_priv             | varchar(1)          | YES  |     | NULL     |       |
| Alter_priv             | varchar(1)          | YES  |     | NULL     |       |
| Show_db_priv           | varchar(1)          | YES  |     | NULL     |       |
| Super_priv             | varchar(1)          | YES  |     | NULL     |       |
| Create_tmp_table_priv  | varchar(1)          | YES  |     | NULL     |       |
| Lock_tables_priv       | varchar(1)          | YES  |     | NULL     |       |
| Execute_priv           | varchar(1)          | YES  |     | NULL     |       |
| Repl_slave_priv        | varchar(1)          | YES  |     | NULL     |       |
| Repl_client_priv       | varchar(1)          | YES  |     | NULL     |       |
| Create_view_priv       | varchar(1)          | YES  |     | NULL     |       |
| Show_view_priv         | varchar(1)          | YES  |     | NULL     |       |
| Create_routine_priv    | varchar(1)          | YES  |     | NULL     |       |
| Alter_routine_priv     | varchar(1)          | YES  |     | NULL     |       |
| Create_user_priv       | varchar(1)          | YES  |     | NULL     |       |
| Event_priv             | varchar(1)          | YES  |     | NULL     |       |
| Trigger_priv           | varchar(1)          | YES  |     | NULL     |       |
| Create_tablespace_priv | varchar(1)          | YES  |     | NULL     |       |
| Delete_history_priv    | varchar(1)          | YES  |     | NULL     |       |
| ssl_type               | varchar(9)          | YES  |     | NULL     |       |
| ssl_cipher             | longtext            | NO   |     |          |       |
| x509_issuer            | longtext            | NO   |     |          |       |
| x509_subject           | longtext            | NO   |     |          |       |
| max_questions          | bigint(20) unsigned | NO   |     | 0        |       |
| max_updates            | bigint(20) unsigned | NO   |     | 0        |       |
| max_connections        | bigint(20) unsigned | NO   |     | 0        |       |
| max_user_connections   | bigint(21)          | NO   |     | 0        |       |
| plugin                 | longtext            | NO   |     |          |       |
| authentication_string  | longtext            | NO   |     |          |       |
| password_expired       | varchar(1)          | NO   |     |          |       |
| is_role                | varchar(1)          | YES  |     | NULL     |       |
| default_role           | longtext            | NO   |     |          |       |
| max_statement_time     | decimal(12,6)       | NO   |     | 0.000000 |       |
+------------------------+---------------------+------+-----+----------+-------+
47 rows in set (0.001 sec)





-- mysql 취약점 점검 시 사용


MariaDB [mysql]> SELECT user, host, authentication_string, plugin FROM user;
+-------------+-----------+-------------------------------------------+-----------------------+
| User        | Host      | authentication_string                     | plugin                |
+-------------+-----------+-------------------------------------------+-----------------------+
| mariadb.sys | localhost |                                           | mysql_native_password |
| root        | localhost | *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B | mysql_native_password |
| mysql       | localhost | invalid                                   | mysql_native_password |
| test        | 192.168.% | *47A6B0EA08A36FAEBE4305B373FE37E3CF27C357 | mysql_native_password |
+-------------+-----------+-------------------------------------------+-----------------------+
4 rows in set (0.001 sec)

```



**Caching_sha2_password / Mysql_native_password**

- mysql 8 이전으로는 mysql_native_password 알고리즘이 사용 가능했지만 취약한 알고리즘으로 판단되어 그 이후 버전에서는 Caching_sha2_password를 사용하고 있다.


- ```
  CREATE database test;
  
  use test;
  
  CREATE TABLE staff(
    -> id INT,
    -> name VARCHAR(20),
    -> city VARCHAR(20)
    -> );

INSERT INTO staff  VALUES(1,'KIM','SEOUL'),(2,'LEE','BUSAN');

  ALTER TABLE staff ADD age INT;
  ALTER TABLE staff DROP age;
 ALTER TABLE staff MODIFY name VARCHAR(20) NOT NULL;
ALTER TABLE staff ADD PRIMARY KEY (id);

  ```