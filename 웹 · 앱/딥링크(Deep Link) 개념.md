
---

## 목차

1. [[#1. 딥링크(Deep Link)란]]
2. [[#2. Intent Filter란]]
3. [[#3. 보안 주의점]]
4. [[#4. 실습 - InjuredAndroid Deep Link (Flag Eleven)]]

---
## 1. 딥링크(Deep Link)란?

딥링크는 웹사이트의 하이퍼링크처럼, **앱 안의 특정 화면이나 기능으로 바로 연결해 주는 특별한 링크(URI)**다.

![[Pasted image 20260724093146.png]]

> [!note] 딥링크 ≠ 인텐트 딥링크 자체는 인텐트(Intent)가 아니라 **주소(URI)**다. 사용자가 이 링크를 클릭하면, 그 URI를 담은 인텐트(정확히는 `android.intent.action.VIEW` 액션을 가진 인텐트)가 만들어져 앱의 액티비티로 전달된다.



### 인텐트(Intent)란?

안드로이드에서 **"이 작업을 해 줘"**라고 요청하는 메시지 객체.

딥링크를 클릭하면 안드로이드가 **action은 `VIEW`, data는 그 URI**인 인텐트를 만들어 알맞은 앱에 전달하고, 앱은 `intent.getData()` 같은 방식으로 이 값을 꺼내 쓴다.

### 인텐트를 받을 수 있는 3가지 컴포넌트

|컴포넌트|호출 방식|
|---|---|
|Activity|`startActivity`|
|Service|`startService`|
|BroadcastReceiver|`sendBroadcast`|

> [!important] 딥링크 클릭은 내부적으로 `startActivity`를 호출하므로 **항상 액티비티로 전달**된다.

---


## 2. Intent Filter란?

Intent Filter는 `AndroidManifest.xml` 파일 설정으로, **"입력 링크(인텐트)를 처리"** 를 안드로이드 운영체제에 알려주는 역할을 한다.

딥링크의 경우, 처리하려는 **스킴(scheme)**(예: `myapp`)과 **호스트(host)**(예: `product`)를 Intent Filter에 등록한다. 그러면 그 형태의 링크를 클릭했을 때 이 앱이 실행되어 링크를 처리한다.

> [!note] 안드로이드 OS는 앱을 설치할 때 각 앱의 매니페스트를 미리 읽어 파싱해 두고, Intent Filter 같은 정보를 내부에 저장해 관리한다. 그래서 링크 클릭 시 빠르게 알맞은 앱을 찾을 수 있다.


####  딥링크가 작동하는 흐름

```
1. 개발자가 앱의 딥링크 처리 경로를 Intent Filter로 등록해 둔다
2. 사용자가 딥링크(예: myapp://product/123)를 클릭한다
3. 안드로이드 OS가 그 링크를 처리할 수 있는 앱을 찾아 실행한다
4. 앱이 링크 정보를 받아 알맞은 화면(상품 123 페이지 등)으로 이동한다
```


##### 예시 코드

##### AndroidManifest.xml의 Intent Filter 설정

```xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- myapp://product/123 형태의 링크를 처리 -->
        <data android:scheme="myapp" android:host="product" />
    </intent-filter>
</activity>
```

**각 태그의 의미**

|태그|의미|
|---|---|
|`action VIEW`|"데이터(URI)를 보여 주는" 작업을 처리하겠다는 뜻. 딥링크는 대부분 이 액션을 사용|
|`category BROWSABLE`|웹 브라우저에서 링크를 눌렀을 때도 이 앱이 열릴 수 있게 해줌. 이 값이 없으면 브라우저에서 딥링크가 동작하지 않음|
|`data scheme/host`|처리할 링크의 형태(`myapp://product/...`)를 지정|


#### 딥링크 URI 구조

```
myapp://product/123
```

|부분|값|의미|
|---|---|---|
|스킴(scheme)|`myapp`|-|
|호스트(host)|`product`|-|
|경로(path)|`123`|여기서는 상품 ID로 사용|


---

## 3. 보안 주의점

### Deep Link Hijacking (딥링크 가로채기)

> [!danger] 악성 앱이 원래 앱과 똑같은 스킴을 자기 매니페스트에 등록해 두면, 딥링크를 클릭할 때 `myapp://login` 링크를 악성 앱이 가로채면, 로그인 토큰 같은 민감 정보를 훔치거나 가짜 화면을 보여줄 수 있다.

**권한/인증 우회**

앱이 딥링크로 넘어온 요청에 대해 권한이나 로그인 여부를 제대로 확인하지 않으면, 인증 없이 민감한 기능이나 화면에 바로 접근할 수 있게 된다.

**입력값 검증 부족**

딥링크 URI에 담긴 파라미터를 검증 없이 그대로 사용하면, 악성 코드 삽입, 오픈 리다이렉션, XSS 같은 공격에 노출될 수 있다.

**딥링크 동작 흐름 요약**

```
사용자 클릭 → Android OS가 처리할 앱 검색 → 앱 실행 → URI 정보를 받아 특정 액티비티(화면) 실행
```

---

## 4. 실습 - InjuredAndroid Deep Link (Flag Eleven)


### 문제 상황

InjuredAndroid 앱에서 **Deep Links** 버튼을 눌러 보면 화면이 열리지 않고 막혀 있는 것을 확인할 수 있다. 왜 그런지 코드를 뜯어본다.

### 핵심 코드 분석 (디컴파일 결과, 변수/함수명 난독화됨)

```java
Intent intent = getIntent();
Uri data = intent.getData();
// d.s.d.g.a(a, b) : 두 문자열 a, b가 같으면 true를 돌려주는 비교 함수
if (d.s.d.g.a("flag11", data != null ? data.getScheme() : null)) {
    startActivity(new Intent("android.intent.action.VIEW"));
}
```

**정리하면:**

- `intent.getData()`로 이 액티비티를 열 때 사용된 딥링크 URI를 가져온다
- 그 URI의 스킴이 정확히 `flag11`일 때만 `startActivity(...)`가 실행된다
- 즉, 그냥 앱 안에서 버튼을 눌러 들어오면 스킴이 `flag11`이 아니므로 아무 동작도 하지 않는다
- 반드시 `flag11://` 딥링크로 이 액티비티를 열어야 다음 화면으로 넘어간다

### AndroidManifest.xml 확인

```xml
<activity
    android:label="@string/title_activity_deep_link"
    android:name="b3nac.injuredandroid.DeepLinkActivity">
    <intent-filter android:label="filter_view_flag11">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="flag11"/>
    </intent-filter>
    <intent-filter android:label="filter_view_flag11">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="https"/>
    </intent-filter>
</activity>
```

`DeepLinkActivity`로 이름 지어진 부분에서 `flag11` 스킴이 등록된 것을 볼 수 있다. 즉, `flag11://`로 시작하는 URI를 열면 이 `DeepLinkActivity` 액티비티가 실행되도록 설정되어 있다.

> [!note] 스킴(scheme)이란?
> 
> - URI(Uniform Resource Identifier)에서 **가장 앞에 나오는 부분**으로, 그 리소스에 어떤 방식으로 접근할지를 나타낸다.
> - 흔히 URI 앞부분을 "프로토콜"이라고 부르지만, 정확한 표현은 **"스킴"**이다. (예: `http`, `https`, `myapp`, `flag11`)

이 액티비티는 인텐트가 오기를 기다리다가, 스킴이 `flag11`이면 `android.intent.action.VIEW` 인텐트를 실행하는 구조다.

### adb로 딥링크 직접 던지기

그러면 이 조건을 만족시키기 위해, adb로 스킴이 `flag11`인 딥링크를 직접 앱에 던져본다.

```bash
adb shell
am start -a android.intent.action.VIEW -d "flag11://"
```

**명령어 의미** — `am start`는 옵션으로 준 값들을 모아 인텐트 하나를 만든 뒤 실행한다. 각 옵션이 인텐트의 필드 하나를 채운다.

|옵션|의미|
|---|---|
|`am start`|adb(Android Debug Bridge) 안의 Activity Manager(`am`) 명령으로, 인텐트를 만들어 액티비티를 실행|
|`-a android.intent.action.VIEW`|인텐트의 **action**(동작 종류)을 `VIEW`로 지정. "주어진 데이터를 사용자에게 보여줘"라는 요청|
|`-d "flag11://"`|인텐트의 **data**(URI)를 `flag11://`로 지정. 이 URI의 스킴이 `flag11`이므로 앞의 코드 조건을 통과|

여기서는 열 대상 액티비티를 직접 지정하지 않았다(암시적 인텐트). 그래서 안드로이드가 조건에 맞는 액티비티를 Intent Filter에서 찾아 실행한다.

```
vbox86p:/ # am start-activity -a android.intent.action.VIEW -d "flag11://"
Starting: Intent { act=android.intent.action.VIEW dat=flag11:// }
vbox86p:/ #
```

> [!tip] 참고 - 명시적 인텐트로도 가능 `-n 패키지명/액티비티명` 옵션으로 대상 액티비티를 직접 지정해 여는 방법(명시적 인텐트)도 있다. 다만 이 문제의 액티비티는 내부에서 스킴이 `flag11`인지 확인하므로, `-n`으로 열더라도 `-d "flag11://"`로 데이터를 함께 줘야 검사를 통과한다. 그래서 여기서는 필터 매칭까지 자연스럽게 태우는 위 암시적 방식이 가장 간단하다.

### 결과 - DeepLinkActivity 진입

`flag11://` URI를 열 앱을 고르라는 선택 창이 뜰 수 있다. `flag11://`에는 특별한 데이터가 없으니 그대로 InjuredAndroid를 선택하면 되고, 입력(input) 화면으로 들어온 것을 확인할 수 있다.

### 다음 단계 - 소스코드 힌트 분석

```java
/* Loaded from: classes.dex */
public final class DeepLinkActivity extends androidx.appcompat.app.c {
    private com.google.firebase.database.d A;
    private com.google.firebase.database.d B;
    private int w;
    private FirebaseAuth y;
    private final String x = "DeepLinkActivity";
    private final String z = "/binary";

    /* Loaded from: classes.dex */
    static final class a implements View.OnClickListener {
        a() { }

        @Override // android.view.View.OnClickListener
        public final void onClick(View view) {
            if (DeepLinkActivity.this.H() == 0) {
                Snackbar X = Snackbar.X(view, "This is one part of the puzzle.", 0);
                X.Y("Action", null);
                X.N();
                DeepLinkActivity deepLinkActivity = DeepLinkActivity.this;
                deepLinkActivity.I(deepLinkActivity.H() + 1);
                return;
            }
            if (DeepLinkActivity.this.H() == 1) {
                Snackbar X2 = Snackbar.X(view, "Find the compiled treasure.", 0);
                X2.Y("Action", null);
                X2.N();
                DeepLinkActivity.this.I(0);
            }
        }
    }
}
```

이 화면(또는 소스 코드) 위쪽을 보면 문자열 힌트가 있는데, **바이너리 파일을 찾아보라**는 내용이다.

### APK 디컴파일 후 바이너리 탐색

```bash
apktool d injuredandroid.apk
```

그다음 `assets` 또는 `lib` 디렉터리에서 바이너리 파일을 찾는다.

- `assets` 디렉터리 안에서 `menu`라는 이름의 바이너리 실행 파일을 발견할 수 있다
- 이 파일은 **ELF 형식**이라 리눅스에서 실행해야 한다
- 실행하면 플래그 `HIIMASTRING`을 얻을 수 있다

---
