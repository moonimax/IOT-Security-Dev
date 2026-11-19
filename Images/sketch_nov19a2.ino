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

// 3) PowerShell 명령으로 최신 스크린샷을 그림판으로 열기
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