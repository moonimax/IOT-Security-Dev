
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


저기서 `LogFile File Path`, `$UsmJrnl"$ File Path`, `MFT` 여 3 위치를 적어놔야 파일 시스템 로그를 볼 수 있음.


`MFT` 엔트리에 파일의 메타 데이터가 기록되어 있음.
`LogFile`
- MFT에 없는 삭제된 데이터들의 흔적이 남아있는 영역
`USNJrnl`
- Update Sequence Number, $J $Max
- NTFS 볼륨에서 발생한 모든 파일이나  폴더의 변경 이력을 순차적으로 누적 기록하는 파일
- $MAX : 저널의 메타데이터 저장
- $J : 실제 변경 이벤트 레코드가 쌓여있음

![](../Images/Pasted%20image%2020261125150447.png)



![](../Images/Pasted%20image%2020261125150822.png)


3개 파일 마저 다 뽑아주고 하나의 디렉터리 안에 욱여넣자
![](../Images/Pasted%20image%2020261125150900.png)


슈슝하고 아까 넣어야하는 위치에 3개 넣어주자
![](../Images/Pasted%20image%2020261125151033.png)


![](../Images/Pasted%20image%2020261125151206.png)
parsing 하고 sqlite db 스키마 이름 지정하고 파일 넣어줄 곳에 넣어주면 이렇게 길다랗게 csv ㅍ형태로 로그 파일들을 볼 수 있도록 해준걷,,

![](../Images/Pasted%20image%2020261125151332.png)


여기서 다시 열어주면 쭈루루룩 타임 스탬프가 적혀 있다.

J 파일에 있는 USN 칼럼은 뭐냐?
- 실행 , 수정, 삭제 등을 하게 되면 USN 값이 매겨지게 된다.


![](../Images/Pasted%20image%2020261125151636.png)

지금보면 USN 숫자가 계속 올라가는 것도 볼 수 있다.
악성코드 같은 경우에는 시스템 시간을 마음대로 조정이 가능하지만, USN 값이 존재하게 된다면 순차적으로 타임 스탬프로 어디에 문제가 있는지 찾아볼 수 있다는 것이다.

시스템에서 자동으로 할당해주는 아티팩트이기 때문에 공격자가 바꾸고 싶어도 마음대로 바꾸기 매우 어려운 상태라는 것을 추측할 수 있다.




