# File System & Carving (파일 카빙)

## 1. 파일 시스템 구조

![](../Images/Pasted%20image%2020261126092914.png)

생성된 파일을 관리하기 위한 정보들이 **메타 영역(Meta Area)**에 기록된다.
- 이름, 위치, 크기, 시간, 데이터영역 주소 등

### 저장 방식
- **LBA(Logical Block Addressing)** 방식 사용.
- 데이터는 **섹터(Sector)**와 **클러스터(Cluster)** 단위로 기록.
  - 섹터: 512 Byte 할당
  - 클러스터: 512 × 8 = 4 KB

> 핵심: Data Area에서 파일을 삭제·수정해도, **메타 영역에는 원본 데이터(연결 정보)가 잔존**하는 경우가 많다. 삭제는 보통 "실제 데이터 소거"가 아니라 "메타데이터의 연결 끊기"이기 때문이다. 이 잔존 데이터가 복구/카빙의 근거가 된다.

---

## 2. MBR (Master Boot Record)

![](../Images/257a22ec-220f-49e3-abad-62cc6d7a3b1f.png)

MBR은 저장매체의 **첫 번째 섹터**에 위치하는 **512 Byte** 영역으로, 부트 코드 호출을 담당한다.

| 구성 | 크기/의미 |
|---|---|
| Boot Code | 446 Byte |
| Partition 1~4 | 각 16 Byte (파티션 테이블). 각 영역은 할당될 수도, 안 될 수도 있음 |
| Signature | 마지막 2 Byte (`55 AA`) |

- **Signature(`55 AA`)가 깨져 있으면** 파일시스템이 손상된 것으로 의심할 수 있다.

![](../Images/Pasted%20image%2020261126093829.png)

---

## 3. FAT32

![](../Images/Pasted%20image%2020261126094109.png)

- **FAT(File Allocation Table)**는 파일의 할당 정보를 표현한 테이블.
- 구조가 간단해 **메모리 카드, 디지털 카메라, 플래시 메모리** 등에 널리 사용.
- FAT 뒤의 숫자는 **비트 수**로, 표현 가능한 클러스터의 개수를 의미.
- Windows 7 이상에서도 호환성 목적으로 널리 지원.

---

## 4. NTFS

![](../Images/Pasted%20image%2020261126111451.png)

![](../Images/Pasted%20image%2020261126101509.png)

NTFS(New Technology File System)는 **1993년 7월 NT 3.1**과 함께 등장했다. NT는 "New Technology" 커널을 도입하며 개편된 운영체제다.

주요 기능:
- **USN 저널**(Update Sequence Number Journal, 또는 Change Journal) — 파일 변경 이력 기록
- **ADS**(Alternate Data Stream), Sparse 파일, 압축
- **VSS**(Volume Shadow Copy Service) — 스냅샷
- **EFS**(Encrypting File System) — 파일 암호화
- **Quotas** — 사용자별 용량 제한

> 포렌식 관점: ADS는 파일에 숨겨진 추가 스트림을 붙일 수 있어 **악성코드 은닉**에 악용되고, VSS는 **삭제/암호화 이전 상태 복원**의 단서가 된다.

---

## 5. Carving (카빙)

**카빙**은 메타데이터를 이용하지 않고, **데이터 영역을 전체적으로 스캔**하여 **파일별 고유 구조(시그니처)**를 이용해 복구하는 기법이다.

- **Header / Footer를 이용한 복구**
  - 파일은 데이터 영역 시작 부분에 자신의 형식을 나타내는 **Signature(매직 넘버)**를 가진다.
  - Header(시작)와 Footer(끝) 사이를 잘라내면 파일을 복원할 수 있다.

### 조각화(fragmentation)에 따른 분류
| 유형 | 설명 |
|---|---|
| **L0** | 조각화되지 않은 파일 (연속 저장) |
| **L1** | 순차적 분할 (여러 조각이 순서대로) |
| **L2** | 비순차적 분할 (조각이 뒤섞여 저장) |

> L0는 Header~Footer를 그대로 잘라내면 되지만, L1/L2는 조각을 올바른 순서로 재조립해야 하므로 난도가 높다.

---

## 6. 실습 — 이미지 카빙 (HxD Editor)

![](../Images/Pasted%20image%2020261126102126.png)

### L0_Graphic.dd
- **6개의 이미지 파일 확장자**가 포함: `.png`, `.pcx`, `.jpg`, `.bmp`, `.gif`, `.tif`

주요 이미지 시그니처(매직 넘버):

| 확장자 | Header | Footer |
|---|---|---|
| JPG | `FF D8 FF E0` | `FF D9` |
| PNG | `89 50 4E 47` | `49 45 4E 44 AE 42 60 82` |
| GIF | `47 49 46 38` (GIF8) | `00 3B` |
| BMP | `42 4D` (BM) | (크기 기반) |

![](../Images/Pasted%20image%2020261126103654.png)

![](../Images/Pasted%20image%2020261126103058.png)

- 섹터 시작 위치가 JPG 헤더 `FF D8`로 시작하지만, **`0x200`(섹터 경계) 정렬 조건을 만족하지 않아** 해당 후보는 제외. 계속 탐색.

검색 조건을 다시 필터링한다.

![](../Images/Pasted%20image%2020261126103208.png)

조건을 만족하는 위치를 찾음.

![](../Images/Pasted%20image%2020261126103232.png)

- **Header Offset: `01BC8C00`**
- 이어서 Footer Offset을 찾는다. (JPG 실제 데이터 범위 예시: `1BC8C00 ~ 1BD792B`)

![](../Images/Pasted%20image%2020261126103920.png)

- Footer는 `FF D9`이며, **그 뒤에 데이터가 없어야 한다**(파일의 끝이어야 함).

![](../Images/Pasted%20image%2020261126103905.png)

### HxD 추출 방법
1. 편집 → 블록 선택
2. 시작/종료 오프셋 입력 → 블록 지정
3. `Ctrl + C`(복사) → `Ctrl + N`(새 창) → 붙여넣기
4. `.jpg` 확장자로 저장

![](../Images/Pasted%20image%2020261126104138.png)

추출 후 `.jpg`로 열면 복원된 이미지가 나타난다.

![](../Images/Pasted%20image%2020261126104223.png)

### PNG 복구

![](../Images/Pasted%20image%2020261126111233.png)

![](../Images/Pasted%20image%2020261126111307.png)

![](../Images/Pasted%20image%2020261126111416.png)

복구 완료.

### GIF 복구
동일한 방식(Header~Footer 블록 지정 → 추출)으로 복구.

![](../Images/Pasted%20image%2020261126111713.png)

![](../Images/Pasted%20image%2020261126111747.png)

![](../Images/Pasted%20image%2020261126111851.png)

---

## 7. 실습 — 문서 카빙 (L1_Document.dd)

PDF, XLSX, DOCX, PPTX 확장자가 포함된 `L1_Document.dd`.
- PDF 2개, XLSX 2개, DOCX 2개, PPTX 1개.

### PDF 시그니처
| 구분 | 값 | 의미 |
|---|---|---|
| Header | `25 50 44 46` | `%PDF` |
| Footer | `25 25 45 4F 46` | `%%EOF` |

- 예시 오프셋: Header `4E2000` ~ Footer `4E3E1C`

### PDF 내부 구조 읽기 (Linearized PDF 헤더 분석)
```
25 50 44 46 2D 31 2E 36     // %PDF-1.6        → 헤더 시그니처 (버전 1.6)
25 E2 E3 CF D3              // %âãÏÓ           → 바이너리 마커 (이 파일이 바이너리 포함임을 표시)

2285 0 obj <<              // 객체번호 2285, 세대번호 0 객체 시작 선언
  /Linearized 1           // 선형화 PDF → %%EOF와 xref가 하나 더 존재(웹 최적화)
  /L 3176275              // 파일 전체의 정확한 바이트 크기
  /O 2290                 // First Page Object: 1페이지 페이지 객체 번호
  /E 503535              // 파일 시작~1페이지 관련 모든 객체 데이터가 끝나는 오프셋
  /N 4                   // 전체 페이지 수
  /T 3130509             // 메인 xref 테이블 첫 엔트리 시작 위치
  /H [ 7861 958 ]       // 힌트 스트림(obj)의 정확한 위치와 크기
>>
endobj

xref
2285 370
```

> 카빙 관점: `/L` 값은 **파일 전체 크기**를 알려주므로, Header offset + `/L`로 **Footer 위치를 역산**할 수 있다. 선형화 PDF는 `%%EOF`가 2개 존재할 수 있어, 카빙 시 **마지막 `%%EOF`까지 포함**해야 파일이 온전히 열린다.

> 참고: DOCX/XLSX/PPTX는 사실 **ZIP 컨테이너**다. 따라서 Header가 `50 4B 03 04`(`PK..`)로 동일하다. 세 형식을 구분하려면 ZIP 내부의 `[Content_Types].xml`이나 `word/`, `xl/`, `ppt/` 폴더 구조를 확인해야 한다.
