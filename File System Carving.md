
파일 시스템 구조
![](Images/Pasted%20image%2020261126092914.png)

생성된 파일을 관리하기 위한 정보들이 메타 영역에 기록됨
- 이름 위치 크기 시간 데이터영역 주소 등

LBA logical block addressing 방식 사용
섹터와 클러스터 단위로 데이터를 기록
- 섹터 512 byte 할당
- Cluster 크기는 512 * 8 = 4kbyte



Data Area에서 우리가 파일을 삭제하고 수정하고 기타 등등 작업을 수행하더라도 결국에는 원본 데이터가 Meta Area에 잔존하여 남는 것을 알 수 있다.


파일 시스템 구조를 조금 더 디테일하게 살펴본다면,,,


![](Images/257a22ec-220f-49e3-abad-62cc6d7a3b1f.png)


MBR은 저장 매체의 첫 번째 섹터에 위치하는 512 바이트 크기의 영역이다.
부트 코드 호출을 담당.

- Boot code ( 446 Byte)
- Partion 1
	- 파티션 각 영역은 할당이 될 수도 있고 할당 되지 않을 경우도 존재
- Partion 2
- Partion 3
- Partion 4
- Partion 5
- Signature
	- 마지막 Signature가 깨져 있으면 파일 시스템이 깨져있다고 생각할 수 있음

![](Images/Pasted%20image%2020261126093829.png)




### FAT 32
- FAT(File allocation Table)는 파일의 할당 정보르 표현한 테이블을 지정
- 간단한 구조로 메모리 카드, 디지털 카메라, 플래시 메몸리에 등에 널리 사용
- FAT 뒤의 숫자는 비트 수로 표현 가능한 클러스터의 수를 의미
- 현존하는 Windows7 이상의 OS에서는 거의 지원

![](Images/Pasted%20image%2020261126094109.png)



---

### NTFS
- USN 저널(Update SEquence Number Journal 또는 Change Journal)
- ADS, Sparse 파일 압축
- VSS - Volume Shadow copy Service
- EFS
- Quotas
![](Images/Pasted%20image%2020261126111451.png)

![](Images/Pasted%20image%2020261126101509.png)

NTFS는 1993년 7월 NT 3.1이 출시하면서 등장한 서버형 운영체제

NT가 이제 New Technology라고 하는 새로운 운영체제의 커널을 도입하면서 개편되어버린 상황.

 ---

## Carving
Metadata를 이용하지 않고, Data 영역을 전체적으로 스캔하고 파일 별로 가지고 있는 고유의 구조를 이용한 복구.
- Header, Fooeter를 이용한 복구
	- 파일ㅇ들을 데이터 영역 시작 부분에 자신의 형식을 나타내는 Signature가 존재


**HxD Editor**

![](Images/Pasted%20image%2020261126102126.png)




#### L0_Graphic.dd
- 5개의 이미지 파일 확장자가 존재함
- .png , .pcx , .jpg, bmg, gif, 

![](Images/Pasted%20image%2020261126103654.png)


![](Images/Pasted%20image%2020261126103058.png)

섹터 header 시작 위치 FF D8 확장자 명으로 시작하지만, `0x200`으로 시작해야하는 조건을 만족하지 않아 위 이미지 확장자 만족하지 못함. 계속 찾아봐야함.

검색 조건 다시 필터.

![](Images/Pasted%20image%2020261126103208.png)


짠 드디어 나왓음
![](Images/Pasted%20image%2020261126103232.png)

- Header Offset은 `01BC8C00`
이제 이어서 Footer의 Offset을 찾아야 함.

![](Images/Pasted%20image%2020261126103920.png)


Footer는 `FF D9` 이고 뒤에 데이터가 없어야 한다. 만약에 맨 끝 자리에 위치하려고 하려면 앞 데이터 byte를 다 채우는 조건하에만 만족됨.


![](Images/Pasted%20image%2020261126103905.png)


새로운 파일로 따로 추출해서 만들고 저장한다.
![](Images/Pasted%20image%2020261126104138.png)


그리고 따로 추출해서 .jpg 확장자로 만들고 열어주면 아래 파일로 짠하고 만들어진다!!

![](Images/Pasted%20image%2020261126104223.png)


---

이번에는 png 파일을 한번 복구해보려고 한다.
![](Images/Pasted%20image%2020261126111233.png)

![](Images/Pasted%20image%2020261126111307.png)

![](Images/Pasted%20image%2020261126111416.png) 
복구 완료.


동일한 방식으로 gif도 복구하게 되면 이렇게 갈 수 있겟다.

![](Images/Pasted%20image%2020261126111713.png)

![](Images/Pasted%20image%2020261126111747.png)![](Images/Pasted%20image%2020261126111851.png)