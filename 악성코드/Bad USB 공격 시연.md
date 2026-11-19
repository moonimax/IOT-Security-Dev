
---

## 1. 침투 방식

#### 직접 침투

- 해커가 직접 침투 대상 시스템에 접근하여 악성 코드를 설치하는 방식

#### Vulnerability (취약점 활용)

- 대부분 지속적인 접근 용이성을 위해 **백도어 계열** 설치
- **레터럴 무브먼트 (Lateral Movement)**
    - 연결된 네트워크 망에서 서로 다른 PC로 이동하기 위한 공격 기술
    - 주요 기법: 키로깅, 스니핑 패킷, 패스워드 덤프, 샘 크래킹, 패스 더 해시, 패스 더 패스
    - 최초 감염 이후 2·3차 악성 코드 감염 및 최종 목적지까지 이동할 때 주로 사용

#### 변조 공격 (Modification Attack)

- P2P 또는 웹 하드에서 많이 발견
- 소프트웨어 제조사를 해킹해 소스코드를 수정하거나, 미리 악성 DLL을 인젝션하여 운영
- 콘텐츠 다운로드를 위한 소프트웨어 설치와 함께 감염
- 예시: 카카오톡 PC 버전 다운로드

---

### 2. USB를 이용한 공격 (Bad USB)

#### Ducky Script

- USB HID(키보드)로 인식되는 장치를 이용해 사전 정의된 키 입력을 자동 실행
- 변환 도구: [https://roothaxor.gitlab.io/ducky2arduino_stable/](https://roothaxor.gitlab.io/ducky2arduino_stable/)

#### 통합 환경 구축

환경 구축

---

### 3. 시연 코드

아두이노(Leonardo 등 HID 지원 보드)에 업로드하면, USB를 꽂는 순간 자동으로 아래 동작이 실행된다.

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

---

### 4. 시연 결과

실행시키면 USB를 꽂는 것만으로 자동으로 명령어 실행, 웹 접속, 메모장 입력이 이루어진다.


> 추가 코드 (`sketch_nov19a2.ino`)는 재미 요소를 더한 확장 버전이다. 추가 코드


![](../Images/녹음%202026-11-19%20162623.mp4)

이 밑 파일은 재미를 위한 파일로 쓰면 더 재밋어질 예정이다
![](../Images/sketch_nov19a2.ino)
