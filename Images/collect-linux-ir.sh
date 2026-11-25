#!/usr/bin/env bash

# collect-linux-ir.sh
# Purpose: Linux incident response triage collection
# Behavior: Read-only collection. Does not delete files, kill processes, or change settings.

set +e

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "[!] root 권한이 필요합니다. sudo로 스크립트를 다시 실행합니다."

  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  else
    echo "[!] sudo 명령을 찾을 수 없습니다. root 계정으로 다시 실행하세요."
    exit 1
  fi
fi

HOST="$(hostname 2>/dev/null || echo unknown)"
TS="$(date +%Y%m%d_%H%M%S)"
OUT="$(pwd)/IR_${HOST}_${TS}"
OUT_PARENT="$(dirname "$OUT")"
ERROR_LOG="$OUT/errors.log"

mkdir -p "$OUT"/{00_collection_info,01_system,02_process,03_network,04_services,05_persistence,06_users,07_artifacts,08_logs,09_files,hashes}

touch "$ERROR_LOG"

run_cmd() {
  local rel_path="$1"
  shift
  local cmd="$*"
  local out_file="$OUT/$rel_path"
  mkdir -p "$(dirname "$out_file")"
  echo "[*] $rel_path"
  bash -c "$cmd" > "$out_file" 2>> "$ERROR_LOG"
}

copy_if_exists() {
  local src="$1"
  local dst_dir="$2"
  if [ -e "$src" ]; then
    mkdir -p "$dst_dir"
    cp -a "$src" "$dst_dir/" 2>> "$ERROR_LOG"
  else
    echo "[$(date -Iseconds)] NOT_FOUND $src" >> "$ERROR_LOG"
  fi
}

{
  echo "Collection started: $(date -Iseconds)"
  echo "UTC time: $(date -u -Iseconds)"
  echo "Hostname: $HOST"
  echo "User: $(whoami 2>/dev/null)"
  echo "ID: $(id 2>/dev/null)"
  echo "Working directory: $(pwd)"
  echo "Kernel: $(uname -a 2>/dev/null)"
} > "$OUT/00_collection_info/collection_info.txt"

# 00. Collection info
run_cmd "00_collection_info/date_local.txt" "date -Iseconds"
run_cmd "00_collection_info/date_utc.txt" "date -u -Iseconds"
run_cmd "00_collection_info/timedatectl.txt" "timedatectl"
run_cmd "00_collection_info/hostnamectl.txt" "hostnamectl"
run_cmd "00_collection_info/id.txt" "id"

# 01. System
run_cmd "01_system/uname.txt" "uname -a"
run_cmd "01_system/os_release.txt" "cat /etc/os-release"
run_cmd "01_system/uptime_s.txt" "uptime -s"
run_cmd "01_system/uptime.txt" "uptime"
run_cmd "01_system/who_b.txt" "who -b"
run_cmd "01_system/dpkg_packages.txt" "dpkg-query -W -f='\${binary:Package}\t\${Version}\t\${db:Status-Abbrev}\n' 2>/dev/null"
run_cmd "01_system/snap_list.txt" "snap list 2>/dev/null"
run_cmd "01_system/mount.txt" "mount"
run_cmd "01_system/df_hT.txt" "df -hT"

# 06. Users and login
run_cmd "06_users/who.txt" "who"
run_cmd "06_users/w.txt" "w"
run_cmd "06_users/last.txt" "last -a | head -n 100"
run_cmd "06_users/lastb.txt" "lastb -a | head -n 100"
run_cmd "06_users/passwd_getent.txt" "getent passwd"
run_cmd "06_users/group_getent.txt" "getent group"
run_cmd "06_users/sudo_group.txt" "getent group sudo"
run_cmd "06_users/uid0_accounts.txt" "getent passwd | awk -F: '\$3 == 0 { print }'"
run_cmd "06_users/sudo_l.txt" "sudo -l"
run_cmd "06_users/sudoers_listing.txt" "ls -al /etc/sudoers /etc/sudoers.d 2>/dev/null"

# 02. Process
run_cmd "02_process/ps_auxww_cpu.txt" "ps auxww --sort=-%cpu | head -n 80"
run_cmd "02_process/ps_start_time.txt" "ps -eo pid,ppid,user,stat,lstart,cmd --sort=start_time | tail -n 100"
run_cmd "02_process/pstree.txt" "pstree -ap 2>/dev/null | head -n 200"
run_cmd "02_process/lsof.txt" "lsof -nP 2>/dev/null | head -n 300"
run_cmd "02_process/suspicious_path_process.txt" "ps -eo pid,ppid,user,lstart,cmd --sort=start_time | grep -E '/tmp|/var/tmp|/dev/shm|/home|/\.' | grep -v grep"

# 03. Network
run_cmd "03_network/ss_tulpen.txt" "ss -tulpen"
run_cmd "03_network/ss_tanp.txt" "ss -tanp"
run_cmd "03_network/lsof_i.txt" "lsof -i -n -P 2>/dev/null"
run_cmd "03_network/ip_addr.txt" "ip addr"
run_cmd "03_network/ip_route.txt" "ip route"
run_cmd "03_network/ip_neigh.txt" "ip neigh"
run_cmd "03_network/resolvectl_status.txt" "resolvectl status 2>/dev/null"
run_cmd "03_network/resolv_conf.txt" "cat /etc/resolv.conf"
run_cmd "03_network/hosts.txt" "cat /etc/hosts"
run_cmd "03_network/ufw_status.txt" "ufw status verbose 2>/dev/null"
run_cmd "03_network/nft_ruleset.txt" "nft list ruleset 2>/dev/null"
run_cmd "03_network/iptables.txt" "iptables -L -n -v 2>/dev/null"

# 04. Services
run_cmd "04_services/systemctl_services.txt" "systemctl list-units --type=service --all --no-pager"
run_cmd "04_services/systemctl_unit_files.txt" "systemctl list-unit-files --type=service --no-pager"
run_cmd "04_services/systemctl_failed.txt" "systemctl --failed --no-pager"
run_cmd "04_services/cron_status.txt" "systemctl status cron --no-pager 2>/dev/null || systemctl status crond --no-pager 2>/dev/null"
run_cmd "04_services/systemd_service_timer_files.txt" "find /etc/systemd/system /lib/systemd/system -type f \( -name '*.service' -o -name '*.timer' \) -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort | tail -n 200"
run_cmd "04_services/systemd_exec_keywords.txt" "grep -RInE 'ExecStart|ExecStartPre|ExecStartPost|curl|wget|bash|python|/tmp|/dev/shm|nc|ncat|socat' /etc/systemd/system /lib/systemd/system 2>/dev/null | head -n 300"

# 05. Persistence
run_cmd "05_persistence/crontab_current.txt" "crontab -l 2>/dev/null || true"
run_cmd "05_persistence/crontab_root.txt" "crontab -u root -l 2>/dev/null || true"
run_cmd "05_persistence/etc_crontab.txt" "cat /etc/crontab 2>/dev/null"
run_cmd "05_persistence/etc_cron_listing.txt" "ls -alR /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly 2>/dev/null"
run_cmd "05_persistence/systemd_timers.txt" "systemctl list-timers --all --no-pager"
run_cmd "05_persistence/init_rc_listing.txt" "ls -al /etc/init.d /etc/rc*.d 2>/dev/null"
run_cmd "05_persistence/cron_keyword_search.txt" "grep -RInE 'curl|wget|bash|sh|python|perl|nc|ncat|socat|/tmp|/dev/shm|base64|chmod|chattr' /etc/crontab /etc/cron.d /var/spool/cron/crontabs 2>/dev/null"

# 08. Logs
run_cmd "08_logs/journal_24h_tail.txt" "journalctl --since '24 hours ago' --no-pager | tail -n 300"
run_cmd "08_logs/journal_ssh.txt" "journalctl -u ssh --since '7 days ago' --no-pager 2>/dev/null | tail -n 300"
run_cmd "08_logs/journal_sshd.txt" "journalctl -u sshd --since '7 days ago' --no-pager 2>/dev/null | tail -n 300"
run_cmd "08_logs/auth_tail.txt" "tail -n 300 /var/log/auth.log 2>/dev/null"
run_cmd "08_logs/auth_keywords.txt" "grep -Ei 'Accepted|Failed|Invalid user|sudo|su:|session opened|session closed' /var/log/auth.log 2>/dev/null | tail -n 300"
run_cmd "08_logs/syslog_tail.txt" "tail -n 300 /var/log/syslog 2>/dev/null"
run_cmd "08_logs/syslog_keywords.txt" "grep -Ei 'error|failed|denied|authentication|sudo|ssh|cron|systemd' /var/log/syslog 2>/dev/null | tail -n 300"
run_cmd "08_logs/journal_sudo.txt" "journalctl _COMM=sudo --since '7 days ago' --no-pager 2>/dev/null | tail -n 300"
run_cmd "08_logs/audit_login.txt" "ausearch -m USER_LOGIN,USER_AUTH,USER_ACCT --start today 2>/dev/null"

copy_if_exists "/var/log/auth.log" "$OUT/08_logs/raw"
copy_if_exists "/var/log/syslog" "$OUT/08_logs/raw"
copy_if_exists "/var/log/secure" "$OUT/08_logs/raw"
copy_if_exists "/var/log/messages" "$OUT/08_logs/raw"
copy_if_exists "/var/log/audit" "$OUT/08_logs/raw"
copy_if_exists "/var/log/apache2" "$OUT/08_logs/web"
copy_if_exists "/var/log/nginx" "$OUT/08_logs/web"

# 07. Artifacts and shell history
run_cmd "07_artifacts/history_files.txt" "find /home /root -maxdepth 3 \( -name '.*history' -o -name '.bash_history' -o -name '.zsh_history' \) -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %p\n' 2>/dev/null | sort"
run_cmd "07_artifacts/current_user_bash_history_tail.txt" "tail -n 200 ~/.bash_history 2>/dev/null"
run_cmd "07_artifacts/root_bash_history_tail.txt" "tail -n 200 /root/.bash_history 2>/dev/null"
run_cmd "07_artifacts/history_keyword_search.txt" "find /home /root -maxdepth 3 \( -name '.*history' -o -name '.bash_history' -o -name '.zsh_history' \) -type f ! -path '*/IR_*/*' -print0 2>/dev/null | xargs -0 grep -HnE 'curl|wget|nc|ncat|socat|bash -i|/dev/tcp|chmod \+x|base64|python|perl' 2>/dev/null | head -n 200"
run_cmd "07_artifacts/profile_listing.txt" "ls -al /etc/profile /etc/profile.d /etc/bash.bashrc /etc/environment 2>/dev/null"
run_cmd "07_artifacts/profile_keyword_search.txt" "grep -RInE 'curl|wget|nc|bash|python|/tmp|/dev/shm|LD_PRELOAD' /etc/profile /etc/profile.d /etc/bash.bashrc /etc/environment 2>/dev/null"
run_cmd "07_artifacts/ssh_artifacts_listing.txt" "find /home /root -maxdepth 3 \( -path '*/.ssh/*' -o -name 'authorized_keys' -o -name 'known_hosts' \) -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %m %p\n' 2>/dev/null | sort"

# 09. Filesystem
run_cmd "09_files/recent_files_7d.txt" "find / -xdev \( -path \"$OUT\" -o -path \"$OUT_PARENT/IR_*\" \) -prune -o -type f -mtime -7 -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %m %p\n' 2>/dev/null | sort | tail -n 300"
run_cmd "09_files/recent_home_tmp_files.txt" "find /home /tmp /var/tmp /dev/shm \( -path \"$OUT\" -o -path \"$OUT_PARENT/IR_*\" \) -prune -o -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %m %s %p\n' 2>/dev/null | sort | tail -n 300"
run_cmd "09_files/suid_files.txt" "find / -xdev -perm -4000 -type f -ls 2>/dev/null"
run_cmd "09_files/world_writable_dirs.txt" "find / -xdev -perm -002 -type d -ls 2>/dev/null | head -n 300"
run_cmd "09_files/temp_files.txt" "find /tmp /var/tmp /dev/shm -type f -ls 2>/dev/null"
run_cmd "09_files/webroot_recent_files.txt" "find /var/www /srv/www -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %u %g %m %s %p\n' 2>/dev/null | sort | tail -n 300"
run_cmd "09_files/webroot_file_types.txt" "find /var/www /srv/www -type f -exec file {} \; 2>/dev/null | head -n 300"

echo "Collection finished: $(date -Iseconds)" >> "$OUT/00_collection_info/collection_info.txt"

# Hash collection outputs after collection_info.txt is finalized.
find "$OUT" -type f \
  ! -path "$OUT/hashes/*" \
  ! -path "$ERROR_LOG" \
  -print0 2>/dev/null | xargs -0 sha256sum > "$OUT/hashes/collection_hashes.sha256" 2>> "$ERROR_LOG"

echo "Output directory: $OUT"
