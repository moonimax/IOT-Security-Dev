
```yaml
**

---

- name: KISA 서버 취약점 점검

  hosts: 192.168.51.131

  vars:

    remote_dir: /var/tmp/u36_easy

    report_file: /var/tmp/u36_easy/report.txt

    local_report_dir: "{{ playbook_dir }}/reports_easy"

    checks:

  

  

      # ---------------- 가. 계정 관리 ----------------

      - code: "U-01"

        title: "root 계정 원격 접속 제한"

        severity: "상"

        script: |

          v=$(grep -i '^PermitRootLogin' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')

          if [ "$v" = "no" ]; then

            echo "[양호] PermitRootLogin=no" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] PermitRootLogin=${v:-미설정} (no 이어야 함)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-02"

        title: "패스워드 복잡성 설정"

        severity: "상"

        script: |

          v=$(grep -E '^\s*minlen' /etc/security/pwquality.conf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')

          [ -z "$v" ] && v=0

          if [ "$v" -ge 8 ]; then

            echo "[양호] minlen=$v" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] minlen=$v (8 이상이어야 함)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-03"

        title: "계정 잠금 임계값 설정"

        severity: "상"

        script: |

          v=$(grep -E '^\s*deny' /etc/security/faillock.conf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')

          [ -z "$v" ] && v=0

          if [ "$v" -ge 1 ] && [ "$v" -le 10 ]; then

            echo "[양호] deny=$v" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] deny=$v (1~10 이어야 함)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-04"

        title: "패스워드 최대 사용 기간 설정"

        severity: "상"

        script: |

          v=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs 2>/dev/null | awk '{print $2}')

          [ -z "$v" ] && v=0

          if [ "$v" -ge 1 ] && [ "$v" -le 90 ]; then

            echo "[양호] PASS_MAX_DAYS=$v" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] PASS_MAX_DAYS=$v (1~90 이어야 함)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-05"

        title: "패스워드 파일 보호"

        severity: "상"

        script: |

          v=$(awk -F: '$2 != "x" {print $1}' /etc/passwd 2>/dev/null)

          if [ -z "$v" ]; then

            echo "[양호] 노출된 해시 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 해시 노출 계정: $v" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      # ---------------- 나. 파일 및 디렉토리 관리 ----------------

      - code: "U-06"

        title: "root 홈, 패스 디렉터리 권한 및 패스 설정"

        severity: "상"

        script: |

          case ":$PATH:" in

            *:.:*) echo "[취약] PATH에 '.' 포함: $PATH" | tee -a {{ report_file }}; exit 1 ;;

            *)     echo "[양호] PATH에 '.' 없음" | tee -a {{ report_file }}; exit 0 ;;

          esac

  

  

      - code: "U-07"

        title: "파일 및 디렉터리 소유자 설정"

        severity: "중"

        script: |

          n=$(find / -xdev -nouser 2>/dev/null | wc -l)

          if [ "$n" -eq 0 ]; then

            echo "[양호] 소유자 없는 파일 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자 없는 파일 ${n}개" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-08"

        title: "/etc/passwd 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          o=$(stat -c '%U' /etc/passwd); m=$(stat -c '%a' /etc/passwd)

          if [ "$o" = "root" ] && [ "$m" -le 644 ]; then

            echo "[양호] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o 권한=$m (root/644 이하)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-09"

        title: "/etc/shadow 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          o=$(stat -c '%U' /etc/shadow); m=$(stat -c '%a' /etc/shadow)

          if [ "$o" = "root" ] && [ "$m" -le 400 ]; then

            echo "[양호] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o 권한=$m (root/400 이하)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-10"

        title: "/etc/hosts 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          o=$(stat -c '%U' /etc/hosts); m=$(stat -c '%a' /etc/hosts)

          if [ "$o" = "root" ] && [ "$m" -le 600 ]; then

            echo "[양호] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o 권한=$m (root/600 이하)" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-11"

        title: "/etc/(x)inetd.conf 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          if [ ! -e /etc/xinetd.conf ] && [ ! -e /etc/inetd.conf ]; then

            echo "[양호] 파일 없음 (Rocky 9 기본 상태)" | tee -a {{ report_file }}

            exit 0

          fi

          f=/etc/xinetd.conf; [ -e /etc/inetd.conf ] && f=/etc/inetd.conf

          o=$(stat -c '%U' "$f"); m=$(stat -c '%a' "$f")

          if [ "$o" = "root" ] && [ "$m" -le 600 ]; then

            echo "[양호] $f 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] $f 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-12"

        title: "/etc/syslog.conf(rsyslog.conf) 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          if [ ! -e /etc/rsyslog.conf ]; then

            echo "[양호] 파일 없음" | tee -a {{ report_file }}

            exit 0

          fi

          o=$(stat -c '%U' /etc/rsyslog.conf); m=$(stat -c '%a' /etc/rsyslog.conf)

          if { [ "$o" = "root" ] || [ "$o" = "bin" ] || [ "$o" = "sys" ]; } && [ "$m" -le 640 ]; then

            echo "[양호] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-13"

        title: "/etc/services 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          o=$(stat -c '%U' /etc/services); m=$(stat -c '%a' /etc/services)

          if { [ "$o" = "root" ] || [ "$o" = "bin" ] || [ "$o" = "sys" ]; } && [ "$m" -le 644 ]; then

            echo "[양호] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o 권한=$m" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-14"

        title: "SUID, SGID, Sticky bit 설정 파일 점검"

        severity: "상"

        script: |

          hit=""

          for f in /usr/bin/newgrp /usr/bin/at /usr/sbin/unix_chkpwd /usr/sbin/traceroute; do

            [ -f "$f" ] && [ -u "$f" ] && hit="$hit $f"

          done

          if [ -z "$hit" ]; then

            echo "[양호] 점검 대상에 SUID 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] SUID 발견:$hit" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-15"

        title: "사용자, 시스템 시작파일 및 환경파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          bad=$(find /root /home -maxdepth 2 \

            \( -name ".bashrc" -o -name ".bash_profile" -o -name ".profile" \) \

            -perm -002 2>/dev/null)

          if [ -z "$bad" ]; then

            echo "[양호] 쓰기 가능한 시작파일 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 쓰기 가능: $bad" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-16"

        title: "world writable 파일 점검"

        severity: "상"

        script: |

          n=$(find / -xdev -type f -perm -002 2>/dev/null | wc -l)

          if [ "$n" -eq 0 ]; then

            echo "[양호] world writable 파일 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] world writable 파일 ${n}개" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-17"

        title: "$HOME/.rhosts, hosts.equiv 사용 금지"

        severity: "상"

        script: |

          n=$(find /root /home -maxdepth 2 -name ".rhosts" 2>/dev/null | wc -l)

          [ -f /etc/hosts.equiv ] && n=$((n + 1))

          if [ "$n" -eq 0 ]; then

            echo "[양호] .rhosts / hosts.equiv 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] ${n}개 발견" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-18"

        title: "접속 IP 및 포트 제한"

        severity: "상"

        script: |

          if systemctl is-active firewalld >/dev/null 2>&1; then

            echo "[양호] firewalld 구동 중" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] firewalld 꺼짐" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-19"

        title: "cron 파일 소유자 및 권한 설정"

        severity: "상"

        script: |

          o=$(stat -c '%U' /etc/crontab 2>/dev/null)

          w=$(find /etc/crontab -perm -022 2>/dev/null)

          if [ "$o" = "root" ] && [ -z "$w" ]; then

            echo "[양호] 소유자=$o, 쓰기 권한 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 소유자=$o, 쓰기 권한 확인 필요" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-20"

        title: "Finger 서비스 비활성화"

        severity: "상"

        script: |

          if systemctl is-active finger.service >/dev/null 2>&1; then

            echo "[취약] finger.service 구동 중" | tee -a {{ report_file }}

            exit 1

          else

            echo "[양호] finger.service 미구동" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      # ---------------- 다. 서비스 관리 ----------------

      - code: "U-21"

        title: "Anonymous FTP 비활성화"

        severity: "상"

        script: |

          if [ -f /etc/vsftpd/vsftpd.conf ] && grep -qi '^anonymous_enable=YES' /etc/vsftpd/vsftpd.conf; then

            echo "[취약] anonymous_enable=YES" | tee -a {{ report_file }}

            exit 1

          else

            echo "[양호] anonymous_enable 꺼짐 또는 vsftpd 미설치" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-22"

        title: "r 계열 서비스 비활성화"

        severity: "상"

        script: |

          if systemctl is-active rlogin.socket >/dev/null 2>&1; then

            echo "[취약] rlogin.socket 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] rlogin.socket 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-23"

        title: "DoS 공격에 취약한 서비스 비활성화"

        severity: "상"

        script: |

          if systemctl is-active chargen.socket >/dev/null 2>&1; then

            echo "[취약] chargen.socket 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] chargen.socket 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-24"

        title: "NFS 서비스 비활성화"

        severity: "상"

        script: |

          if systemctl is-active nfs-server.service >/dev/null 2>&1; then

            echo "[취약] nfs-server.service 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] nfs-server.service 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-25"

        title: "NFS 접근통제"

        severity: "상"

        script: |

          if [ -s /etc/exports ] && grep -q '\*' /etc/exports 2>/dev/null; then

            echo "[취약] /etc/exports 에 '*' 존재" | tee -a {{ report_file }}

            exit 1

          else

            echo "[양호] 위험한 공유 설정 없음" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-26"

        title: "automountd 제거"

        severity: "상"

        script: |

          if systemctl is-active autofs.service >/dev/null 2>&1; then

            echo "[취약] autofs.service 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] autofs.service 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-27"

        title: "RPC 서비스 확인"

        severity: "상"

        script: |

          if systemctl is-active rpcbind.service >/dev/null 2>&1; then

            echo "[취약] rpcbind.service 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] rpcbind.service 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-28"

        title: "NIS, NIS+ 점검"

        severity: "상"

        script: |

          if systemctl is-active ypserv.service >/dev/null 2>&1; then

            echo "[취약] ypserv.service 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] ypserv.service 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-29"

        title: "tftp, talk 서비스 비활성화"

        severity: "상"

        script: |

          if systemctl is-active tftp.socket >/dev/null 2>&1; then

            echo "[취약] tftp.socket 구동 중" | tee -a {{ report_file }}; exit 1

          else

            echo "[양호] tftp.socket 미구동" | tee -a {{ report_file }}; exit 0

          fi

  

  

      - code: "U-30"

        title: "Sendmail 버전 점검"

        severity: "상"

        script: |

          if rpm -q sendmail >/dev/null 2>&1 && systemctl is-active sendmail >/dev/null 2>&1; then

            echo "[취약] sendmail 구동 중 - 버전을 직접 확인하세요" | tee -a {{ report_file }}

            exit 1

          else

            echo "[양호] sendmail 미설치 또는 미구동" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-31"

        title: "스팸 메일 릴레이 제한"

        severity: "상"

        script: |

          if command -v postconf >/dev/null 2>&1; then

            r=$(postconf -h smtpd_recipient_restrictions 2>/dev/null)

            if echo "$r" | grep -q "reject_unauth_destination"; then

              echo "[양호] reject_unauth_destination 설정됨" | tee -a {{ report_file }}

              exit 0

            else

              echo "[취약] reject_unauth_destination 미설정" | tee -a {{ report_file }}

              exit 1

            fi

          else

            echo "[양호] postfix 미설치" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-32"

        title: "일반사용자의 Sendmail 실행 방지"

        severity: "중"

        script: |

          if rpm -q sendmail >/dev/null 2>&1; then

            if grep -q 'restrictqrun' /etc/mail/sendmail.cf 2>/dev/null; then

              echo "[양호] restrictqrun 설정됨" | tee -a {{ report_file }}

              exit 0

            else

              echo "[취약] restrictqrun 미설정" | tee -a {{ report_file }}

              exit 1

            fi

          else

            echo "[양호] sendmail 미설치" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-33"

        title: "DNS 보안 버전 패치"

        severity: "상"

        script: |

          if systemctl is-active named >/dev/null 2>&1; then

            echo "[취약] named 구동 중 - 버전을 직접 확인하세요" | tee -a {{ report_file }}

            exit 1

          else

            echo "[양호] named 미구동" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      - code: "U-34"

        title: "DNS ZoneTransfer 설정"

        severity: "상"

        script: |

          if systemctl is-active named >/dev/null 2>&1; then

            if grep -q 'allow-transfer' /etc/named.conf 2>/dev/null; then

              echo "[양호] allow-transfer 설정됨" | tee -a {{ report_file }}

              exit 0

            else

              echo "[취약] allow-transfer 미설정" | tee -a {{ report_file }}

              exit 1

            fi

          else

            echo "[양호] named 미구동" | tee -a {{ report_file }}

            exit 0

          fi

  

  

      # ---------------- 라. 패치 및 로그 관리 ----------------

      - code: "U-35"

        title: "최신 보안패치 및 벤더 권고사항 적용"

        severity: "상"

        script: |

          n=$(dnf -q updateinfo list --security 2>/dev/null | grep -c 'Sec\.')

          if [ "$n" -eq 0 ] 2>/dev/null; then

            echo "[양호] 미적용 보안 업데이트 없음" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] 미적용 보안 업데이트 ${n}건" | tee -a {{ report_file }}

            exit 1

          fi

  

  

      - code: "U-36"

        title: "로그의 정기적 검토 및 보고"

        severity: "상"

        script: |

          if systemctl is-active rsyslog >/dev/null 2>&1 && [ -f /var/log/secure ]; then

            echo "[양호] rsyslog 구동 중, /var/log/secure 존재" | tee -a {{ report_file }}

            exit 0

          else

            echo "[취약] rsyslog 미구동 또는 /var/log/secure 없음" | tee -a {{ report_file }}

            exit 1

          fi

  

  pre_tasks:

    - name: make remote director

      command: /usr/bin/mkdir -p /var/tmp/u36_easy

  

    - name: "대상 정보 확인"

      debug:

        msg: >-

          대상: "{{ ansible_facts['hostname'] }}" / "{{ ansible_facts['distribution'] }}" "{{ ansible_facts['distribution_version'] }}"

  

    - name: "원격 작업 디렉토리 생성"

      file:

        path: "{{ remote_dir }}"

        state: directory

        mode: 700

  

    - name: "리포트 파일 새로 생성(이전 실행 결과 지우기)"

      copy:

        content: ""

        dest: "{{ report_file }}"

        mode: 600

  

  tasks:

    - name: "36개 점검 항목 실행"

      shell: "{{ item.script }}"

      args:

        executable: /bin/bash

      loop: "{{ checks }}"

      register: check_run

      ignore_errors: yes

  

    - name: "점검 결과 출력 (전체)"

      vars:

        status_text: "{{ '양호' if item.rc==0 else '취약' }}"

      debug:

        msg: "{{ item.item.code }} ({{ item.item.severity }}) {{ item.item.title }} : {{ item.stdout }}"

      loop: "{{ check_run.results }}"

      loop_control:

        label: "{{ item.item.code }}"

  

    - name: "취약(FAIL) 항목만 다시 보기"

      debug:

        msg: "{{ item.item.code }} {{ item.item.title }} : {{ item.stdout }}"

      loop: "{{ check_run.results }}"

      loop_control:

        label: "{{ item.item.code }}"

      when: item.rc != 0

  

    - name: "요약 통계 계산 (양호/취약 개수)"

      shell: |

        total=$(grep -cE '^\[(양호|취약)\]' {{ report_file }})

        # grep -c 는 매칭이 0개면 종료코드 1을 돌려주므로 ignore_errors 로 받아줍니다.

        fail=$(grep -c '^\[취약\]' {{ report_file }})

        pass=$((total - fail))

        echo "총 ${total}개 중 양호 ${pass} / 취약 ${fail}"

      args:

        executable: /bin/bash

      register: summary

      ignore_errors: true

  

    - name: "리포트 파일을 관리 서버로 가져오기"

      fetch:

        src: "{{ report_file }}"

        dest: "{{ local_report_dir }}/{{ ansible_facts['hostname'] }}_report.txt"

        flat: true

      notify: 리포트 회수 완료 안내

  

  handlers:

    - name: 리포트 회수 완료 안내

      debug:

        msg: "리포트를 가져왔습니다 -> {{ local_report_dir }}/{{ ansible_facts['hostname'] }}_report.txt"

**
```