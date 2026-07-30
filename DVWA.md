웹 취약점 사이트 랩

- Install set 명령어
```bash
sudo dnf install -y httpd mariadb-server git php php-mysqlnd php-gd php-cli php-json

sudo systemctl enable --now httpd mariadb

cd /var/www/html
git clone https://github.com/digininja/dvwa.git dvwa

```