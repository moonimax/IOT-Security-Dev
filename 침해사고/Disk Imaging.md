
![](Images/Pasted%20image%2020261125140413.png)

2 개의
FTK Imager(오픈소스) / Encase(유료)
Dumpit : 물리 메모리 (RAM) 추출할 때 사용

![](Images/Pasted%20image%2020261125140506.png)

설치 진행

![](Images/Pasted%20image%2020261125140533.png)

RegEx.exe 얘도 같이 설치해주도록 하자

![](Images/Pasted%20image%2020261125140601.png)

마지막으로 NTFS Log Tracker 이거 까지 모두 설치

당연하겠지만 시스템 권한을 위해서 관리자 권한으로 모두 실행 필요.

![](Images/Pasted%20image%2020261125140703.png)

기본 화면은 이래 생겻다.

![](Images/Pasted%20image%2020261125140729.png)

Add 해줘서 덤플 뜰 디스크 종류를 선택해야 한다.

이게 이제 분석할 노트북으로 설정해주는 과정인데 어떤 드라이브를 가져다가 놓을 건지 선택해야 하는데, 노트북에 단일 디스크만 존재하기 때문에  


![](../Images/Pasted%20image%2020261125140916.png)

당연하게 하나만 나옴

![](../Images/Pasted%20image%2020261125141023.png)

Disk 이미지 Export.
증거 수집을 하나의 디스크 파일로 추출.


![](../Images/Pasted%20image%2020261125143143.png)


TimeFaker라는 디스크 전체를 덤프 떠서 분석

![](../Images/Pasted%20image%2020261125143411.png)

여러 시스템 파일이 존재하는데 이 시스템 파일을 분석해서 복구 및 행위를 기반으로 분석한다라는 관점을 가져가야 함.

결국 디스크라는 애들을 이미지 떠서 -> `TimeFacker.E01` 파일 생성

FTK Manager를 통해서 파일 시스템 구조를 파악할 수 있잖음.
이 파일 시스템의 내부 구조를 확인할 때, 분석의 개념은 아니고 그냥 띄워주기 정도만 한거.

그래서 아까 다운받아 놓은 NTFS Log Tracker를 쓸 수 있다~~

![](../Images/Pasted%20image%2020261125143728.png)


저기서 `LogFile File Path`, `$UsmKrmm;"$ File Path`, `MFT` 여 3 위치를 적어놔야 파일 시스템 로그를 볼 수 있음.






