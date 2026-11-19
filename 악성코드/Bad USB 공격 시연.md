
직접 침투
-> 해커가 직접 침투 대상이 되는 시스템에 침ㅁ투하여 악성 코드 설치

Vulnerability
- 대부분 지속적인 접근 용이성을 위해 백도어 계열 설치
- 레터럴 무브먼트
	- 연결된 네트워크 망에서 서로 다른 PC로 이동하기 위한 공격 기술
	- 키로깅, 스니핑 패킷, 패스워드 덤프, 샘 크래킹, 패스 더 해시, 패스 더 패스
	- 최초 감염 이후 2,3차 악성 코드 감염 및 최종 목적지 까지 이동할 때 주로 사용


변조 공격(Modification Attack)
- P2P 또는 웹 하드에서 많이 발견
- 소프트웨어 제조사를 해킹해 소스코드를 수정하거나 미리 악성 DLL을 인젝션하여 운영
- 콘텐츠 다운로드를 위한 소프트웨어 설치와 함께 감염
- 예시로는 카카오톡 PC 버전 다운로드


---

USB를 이용한 공격 이해 및 시연

- Ducky Script
- https://roothaxor.gitlab.io/ducky2arduino_stable/


![](../Images/Pasted%20image%2020261119155313.png)

통합 환경을 우선 구축
```.ino
#include <Keyboard.h>

  

// typeKey 헬퍼: 키 누름 → 떼기

void typeKey(uint8_t key) {

  Keyboard.press(key);

  delay(50);

  Keyboard.releaseAll();

}

  

void setup() {

  Keyboard.begin();

  delay(2000);               // 꽂은 뒤 인식될 때까지 대기

  

  // Windows + R

  Keyboard.press(KEY_LEFT_GUI);

  Keyboard.press('r');

  delay(100);

  Keyboard.releaseAll();

  delay(1000);               // 실행창 뜰 시간

  

  Keyboard.print("cmd");     // "cmd" 입력

  delay(500);

  typeKey(KEY_RETURN);       // Enter

  delay(1000);

  

  Keyboard.print("ipconfig");

  delay(500);

  typeKey(KEY_RETURN);

  delay(1000);

  

  Keyboard.print("ping 8.8.8.8");

  delay(500);

  typeKey(KEY_RETURN);

  delay(1000);

  

  Keyboard.print("start https://www.youtube.com");   // ✅ 수정됨

  delay(500);

  typeKey(KEY_RETURN);

  delay(1000);

  

  Keyboard.press(KEY_LEFT_GUI);

  Keyboard.press('r');

  delay(100);

  Keyboard.releaseAll();

  delay(1000);

  Keyboard.print("notepad");

  delay(500);

  typeKey(KEY_RETURN);

  delay(1500);                  // 메모장 뜰 시간 확보

  

  // 한/영 키 → 한글 모드로 전환

  Keyboard.press(KEY_RIGHT_ALT);

  delay(50);

  Keyboard.releaseAll();

  delay(300);

  

  // "나는 바보다" (두벌식 자판 입력)

  Keyboard.print("sksms qkqhek");

  

  Keyboard.end();            // 한 번만 실행하고 종료

}

  

void loop() {

  // 비워둠 (setup에서 1회만 동작)

}
```


실행시키면 아래 영상과 같이 자동으로... 실행이 되는것을 볼 수 있다..


![](../Images/녹음%202026-11-19%20162623.mp4)

이 밑 파일은 재미를 위한 파일로 쓰면 더 재밋어질 예정이다
![](../Images/sketch_nov19a2.ino)
