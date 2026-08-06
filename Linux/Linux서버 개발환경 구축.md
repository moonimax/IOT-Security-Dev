```bash

-- dnf 명령어 사용하여 시스템 업데이트
sudo dnf update -y

sudo systemctl enable httpd --now

-- selinux 확인 명령어
getenforce
sudo semanage port -l | grep http
> port 번호 tcp 80가 열려있음을 확인
> 
```

*설정*
>labuser / labuser
>MYSQL root -> TestPass123!
>MYSQL lab -> password 혹은 P@SSW0RD / P@SSW0RD






![](Images/sdfgdfg4.png)
프레임워크
> 프론트 & 백에서 실행을 할 수 있도록 도와주는 기능을 하지만 실제 서버를 구동하고 관리하는 기능이 없기 때문에 프레임워크에 ngnix 서버를 함께 구축할 수 있도록 해야 한다.




**빌드 도구**

이와 관련한 모든 Development Tool인 개발 도구를 모두 설치

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y python3 git curl unzip

```


해당 프로그램을 관리할 계정을 관리자가 아닌 일반 사용자로 생성
```bash
-- labuser로 생성
sudo adduser labuser

-- vi 확인 시 wheel 그룹에 모든 권한이 반영되는 점 확인
sudo usermod -aG wheel labuser

-- ssh-keygen을 생성하여 접속 서버 ssh에 대한 공개키를 생성
[user@localhost ~]$ ssh-keygen -t ed25519 -C "labuser@secure-coding"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/user/.ssh/id_ed25519): 

--windows C\home\user\.ssh 경로로 위 값을 넣어놓고 key 2개를 생성
```

![](../Images/Pasted%20image%2020260805104325.png)


다시 rocky linux로 돌아와서
```bash
mkdir .ssh
cd .ssh
vim authorized_keys
-- 위 id_ed25519.pub내용을 이제 다시 해당 텍스트 내용을 복사해서 붙여넣으면 된다.

-- root login에 대한 권한을 막기 위해 아래와 같이 설정
sudo vim /etc/ssh/sshd_config
> PermitRootLogin no
> PasswordAuthentication no

sudo systemctl restart sshd

```


windows 터미널로 돌아와서
```bash

-- 원격 접속을 하기 위해서 키를 지정하겠다
ssh -i id_ed25519 labuser@(ip)
ssh -i i_ed25519 labuser@192.168.63.128 

```


다시 Rocky linux로 돌아와서 
- 80, 22, 443, 3001-3013 tcp를 열어준다.


![](../Images/Pasted%20image%2020260805113105.png)

