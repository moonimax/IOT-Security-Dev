

---


## 전체 흐름 요약

|파일|목적|핵심 개념|
|---|---|---|
|`ansible.cfg`|기본 설정(인벤토리, 인증, 권한상승) 지정|`[defaults]`, `[privilege_escalation]`|
|`playbook.yaml`|단일 호스트에 사용자 생성|`hosts: 단일값`, `user` 모듈|
|`playbook2.yaml`|여러 호스트에 사용자 생성|`hosts: 리스트`|
|`playbook3.yaml`|웹/DB 패키지 설치+기동|`dnf`/`service` 모듈, 패키지명≠서비스명|
|`playbook4.yaml`|호스트별로 다른 역할 부여|한 파일에 **여러 play**|
|`playbook5.yaml`|인증/권한 옵션을 play 레벨로 이동|`remote_user`, `become*`를 play에 직접 명시, ansible.cfg 유무에 따른 옵션 차이|

### 자주 쓴 실행 옵션 모음

|옵션|역할|
|---|---|
|`--syntax-check`|문법만 검사, 실제 실행 안 함|
|`-C` (`--check`)|예행 연습(dry-run), 실제 변경 없이 시뮬레이션|
|`-v` / `-vv` / `-vvv`|상세 로그 단계별 출력|
|`-i <path>`|인벤토리 파일 지정|
|`--ask-pass`|SSH 비밀번호 인증|
|`--ask-become-pass`|sudo(become) 비밀번호 인증|


---


## 사전 준비 — ansible.cfg

`-i inventory`, `-u user`, `--become` 등을 옵션으로 붙이지 않아도 되도록, 작업 디렉토리에 `ansible.cfg` 설정

```bash
vim ansible.cfg
```

```ini
[defaults]
inventory = inventory
remote_user = user
ask_pass = False

[privilege_escalation]
become = True
become_user = root
become_method = sudo
become_ask_pass = False
```

- `inventory = inventory` : 같은 디렉토리의 `inventory` 파일을 기본 인벤토리로 사용
- `remote_user = user` : SSH 접속 계정 기본값
- `become = True` : 모든 task를 권한 상승(sudo)해서 실행
- `become_ask_pass = False` : sudo 비밀번호 안 물어봄 (NOPASSWD 설정 전제)

> inventory` 파일 안에는 **호스트 목록만** 들어가야 한다.

---

## 1. playbook.yaml — 단일 호스트에 사용자 생성

```bash
vim playbook.yaml
```

```yaml
---
- name: create user
  hosts: 192.168.51.131
  tasks:
    - name: user02
      user:
        name: user02
        state: present
```

```bash
ansible-playbook playbook.yaml
```

- `hosts`에 단일 IP를 문자열로 지정
- `user` 모듈로 `user02` 계정 생성

---


## 2. playbook2.yaml — 여러 호스트 대상 (리스트 형태)



```bash
cp playbook.yaml playbook2.yaml
vim playbook2.yaml
```

```yaml
---
- name: create user
  hosts:
    - 192.168.51.131
    - 192.168.51.129
  tasks:
    - name: create user03
      user:
        name: user03
        state: present
```

```bash
ansible-playbook playbook2.yaml
```

- `hosts`를 문자열 대신 **리스트**로 지정 → 여러 노드에 동시에 같은 작업 수행

---


## 3. playbook3.yaml — 웹/DB 패키지 설치 및 서비스 기동

```bash
vim playbook3.yaml
```

```yaml
---
- name: Install web package and install db package
  hosts:
    - 192.168.51.129
    - 192.168.51.131
  tasks:
    - name: sudo dnf install httpd
      dnf:
        name: httpd
        state: present
    - name: sudo systemctl enable httpd --now
      service:
        name: httpd
        state: started
        enabled: yes
    - name: sudo dnf install mysql-server
      dnf:
        name: mysql-server
        state: present
    - name: sudo systemctl enable mysqld --now
      service:
        name: mysqld
        state: started
        enabled: yes
```

**실행 전 관리 노드 패키지 정리** (mariadb 등 충돌 요소 제거)

```bash
sudo dnf -y remove nginx
sudo dnf remove mariadb
sudo rm -r /etc/my.cnf /etc/my.cnf.d /var/lib/mysql
```

```bash
ansible-playbook playbook3.yaml
```

### 패키지명 vs 서비스명

- **`mysql-server`** : dnf로 설치할 때 쓰는 **패키지 이름**
- **`mysqld`** : 설치된 패키지가 등록하는 **systemd 서비스 이름**


### playbook-playbook 실행 시 유용한 옵션

| 명령                                      | 설명                                            |
| --------------------------------------- | --------------------------------------------- |
| `ansible-playbook .yaml -v`             | 작업 결과(verbose) 출력                             |
| `ansible-playbook .yaml -vv`            | 작업 결과 + 작업 구성(모듈 인자 등)                        |
| `ansible-playbook .yaml-vvv`            | 작업 결과 + 작업 구성 + 호스트 연결(SSH) 상세 정보             |
| `ansible-playbook .yaml --syntax-check` | 실행하지 않고 YAML/playbook 구문 / 문법 검사              |
| `ansible-playbook .yaml -C`             | **시뮬레이션(check mode)** — 실제로 반영하지 않고 결과값 미리 예측 |

---



## 4. playbook4.yaml — 한 파일에 여러 play (호스트별 task 분리)

```bash
vim playbook4.yaml
```

```yaml
---
- name: Install httpd and Start httpd
  hosts: 192.168.51.129
  tasks:
    - name: sudo dnf -y install httpd
      dnf:
        name: httpd
        state: present
    - name: sudo systemctl enable httpd --now
      service:
        name: httpd
        state: started
        enabled: yes

- name: Install mysql-server and Start mysqld
  hosts: 192.168.51.131
  tasks:
    - name: Install mysql-server
      dnf:
        name: mysql-server
        state: present
    - name: Start mysqld
      service:
        name: mysqld
        state: started
        enabled: true
```



```bash
# 제어 노드 (혹은 httpd 담당 노드)
sudo dnf -y remove httpd

# 관리 노드 (mysql 담당 노드)
sudo dnf -y remove mysql-server
```

```bash
ansible-playbook playbook4.yaml
```

- 한 playbook 파일 안에 `- name:`으로 시작하는 **play를 두 개** 작성


---



## 5. ansible.cfg 축소 + playbook5.yaml — 인증 옵션을 명령행으로 분리

기존 `ansible.cfg`를 백업하고, 인증 관련 설정을 제거

```bash
cp ansible.cfg ansible.cfg.bak
vim ansible.cfg
```

```ini
[defaults]
inventory = inventory
ask_pass = False

[privilege_escalation]
become_ask_pass = False
```

- `remote_user`, `become`, `become_user`, `become_method` 등은 제거 → 이런 값들은 이제 **playbook 파일 안에서 직접 지정**

```bash
vim playbook5.yaml
```

```yaml
---
- name: write /etc/hosts
  hosts: 192.168.51.129
  remote_user: user
  become: true
  become_user: root
  become_method: sudo
  tasks:
    - name: 192.168.51.131 worker
      lineinfile:
        path: /etc/hosts
        line: "192.168.51.131 worker"
        state: present
```

```bash
ansible-playbook playbook5.yaml
```

- `remote_user`, `become`, `become_user`, `become_method`를 ansible.cfg가 아닌 play 레벨에 직접 제시
- `lineinfile` 모듈: 파일 전체를 덮어쓰지 않고, **지정한 줄이 있는지 확인 후 없으면 추가**하는 모듈 (`/etc/hosts`에 재 노드 항목 등록 용도)

### ansible.cfg 완전 제거 후 옵션으로 대체

```bash
rm ansible.cfg
ansible-playbook playbook5.yaml -i inventory
ansible-playbook playbook5.yaml -i inventory --ask-pass --ask-become-pass
```

| 옵션                  | 역할                                                  |
| ------------------- | --------------------------------------------------- |
| `-i inventory`      | ansible.cfg가 없으므로 인벤토리 경로를 직접 지정                    |
| `--ask-pass`        | SSH 비밀번호를 직접 물어보고 접속 (키 인증 대신)                      |
| `--ask-become-pass` | sudo(become) 비밀번호를 직접 물어봄 (`become_ask_pass` 설정 대신) |


---
