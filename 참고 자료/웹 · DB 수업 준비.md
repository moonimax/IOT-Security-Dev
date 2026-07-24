

[공유자료 링크]
https://1drv.ms/f/c/94b9fd1e0dcf7b18/IgD4cal7JRNJSZPiyXCSmc2LAZ0V_aKn2_Hw1z_TxGCr9FY

![[nosql.pdf]]

1. Web 추가 실습
	-  공유 자료 > 추가 자료 > 딥링크 다운로드
		- 수업자료였음

2. 다른 실습 준비

- Mobaxterm 설치
```
Rocky Linux 실행

터미널 열고 실행할 명령어
1. yum install podman -y


2. podman pull opensecurity/mobile-security-framework-mobsf:latest
- 가장 아래꺼의 image 선택해서 enter 후 다운받기

3.podman run -it --rm -p 8000:8000 opensecurity/mobile-security-framework-mobsf:latest
```

3. DB 보안 수업
- mobaxterm download > HOME
- mobaxterm 실행
	- session > SSH
	- host에 ip 적고 user에 root
	- ![[Pasted image 20260724141127.png]]
- rocky linux 내 ip addr 명령어 실행
	- ens33 inent 확인

cat /etc/os-release
ls /etc/ssh/sshd_config.d/
cat /etc/ssh/sshd_config.d/01-permitrootlogin.conf
- dnf install myaql-server -y

- systemctl start mysqld
- systemctl enable mysqld
- mysql -V
- mysql -
- mysql -u root -p
- show Databases;

계정 만들기
- CREATE USER 'test' @ '192.168.%' IDENTIFIED BY 'P@ASSW0RD';
- grant all priviledges on*..*
	TO 'test' @'192.168.%' WITH GRANT OPTION;
- flush privileges -> 권한 갱신해서 바로 반영

- firewall-cmd --permanent --add-port=3306/tcp
- firewall -cmd --reload
- firewall -cmd --list-ports


언제 정리하지


- 

