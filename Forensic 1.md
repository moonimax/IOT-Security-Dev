
![](Images/Pasted%20image%2020261125093613.png)

위 지문에 대한 최근에 디포챌을 실시하는 곳이 생김에 따라 실제 있었던 챌린지를 시작하도록 하겠다.

시작 파일은 Malware downloader로 Autopsy 툴을 사용하여 분석하고자 한다.

먼저, 해당 루트 파일을 Autopsy에 드래그하여 트리형식으로 펼쳐놓는다

![](Images/Pasted%20image%2020261125094243.png)

쭈루룩 파일이 나오고 있다.

첫문항에 대한 답안은 아무래도 다음일 것이다.
![](Images/Pasted%20image%2020261125094539.png)

내 추측건데 자격 증명 덤프 도구를 다운로드 한 URI는 
`[https://g.live.com/odclientsettings/Prod](http://www.tarasco.org/security/pwdump_7/pwdump7.zip)`

공격자가 어떤 방식으로 다운로드 덤프 받은 위치가 다음과 같다.
`[C:\Users\FORENS~1\AppData\Local\Temp\wctCBE.tmp](c:\Users\Public\Downloads\BIT7EB3.tmp)`

![](Images/Pasted%20image%2020261125102950.png)


![](Images/Pasted%20image%2020261125103720.png)

해당 위치에 temp 파일이 있어야하는데, 왠지 모르게 다른게 들어가 있는디??
해당 위치 폴더에 desktop.ini 파일이 있으므로 더 이상한 형식의 파일이 있으니까 이것도 남겨두기로 한다.


![](Images/Pasted%20image%2020261125103849.png)

이 폴더에 들어가 보면 다운받은 흔적이 남아 있는 로그들이 담겨져 있는 파일을 찾아볼 수 있다.

---

활성 데이터 뽑는 스크립트

![](Images/collect-linux-ir.sh)

![](Images/Collect-WindowsIR.bat)

