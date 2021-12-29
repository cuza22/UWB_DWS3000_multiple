# How to test UWB (2) - nordic board settings

⭐ 목표: 노르딕 보드에 필요한 프로그램을 설치하고 예제 파일을 실행시켜본다. 

# ⚒️ Running a nordic board

### 1. **Qorvo 에서 DWS3000 API 소프트웨어 다운로드**

[Important Notice](https://www.qorvo.com/products/d/da007992)

압축을 풀고 DWS3000_Release_v1.1/Software/DW3000_API/Sources/DW3000_API_C0_rev4p0 에 들어가면 README 파일이 있다. 

라즈베리파이가 아닌 노르딕 보드를 사용할 것이므로 **README_nRF52840-DK.txt**의 가이드를 따라가면 된다. 

아래는 그 가이드를 해석한 것이다.

### 2. SEGGER Embedded Studio 다운로드

[Embedded Studio: The Cross-Platform IDE](https://www.segger.com/products/development-tools/embedded-studio/)

임베디드 스튜디오 개발 환경이다. 노르딕 보드에 코드를 실행시킬 수 있다. 

README에는 v4.52c를 사용했다고 적혀있으나 다운받아도 작동하지 않는다 .

따라서 가장 최신 버전의 프로그램을 다운받았다 .

### 3. Nordic SDK 다운로드

[nRF5 SDK](https://www.nordicsemi.com/Software-and-tools/Software/nRF5-SDK/Download)

이거는 이전 버전도 잘 작동하므로 README파일과 같이 16.0.0 버전을 다운받았다.

### 4. 컴퓨터와 nRF52840 DK 연결

micro 5핀을 이용해서 연결 가능하다. 

다만, 충전용 케이블이 아니라 데이터 전송용 케이블을 써야 작동된다 -_-;;

### 5. 보드에 J-Link Driver 설치

nRF-52840 (1) DK의 Power은 ‘ON’으로 하고 (2) DWS3000을 연결하지 않은 상태로 (3) ‘nRF power source’ 스위치를 ‘VDD’로 설정하면, 컴퓨터와 연결하면 자동으로 J-Link 드라이버가 설치된다. J-Link가 설치되어야 USB를 통해 보드에 프로그램을 업로드할 수 있다. 

정상적으로 J-Link가 설치된 경우 [장치 관리자]에서 J-Link driver을 확인할 수 있다.

![Untitled](How%20to%20test%20UWB%20(2)%20-%20nordic%20board%20settings%20d56974dcdcf74e16959f3df073466479/Untitled.png)

J-Link가 설치되지 않은 경우 보드가 ‘알 수 없는 USB 장치’ 로 인식된다. 

![Untitled](How%20to%20test%20UWB%20(2)%20-%20nordic%20board%20settings%20d56974dcdcf74e16959f3df073466479/Untitled%201.png)

> J-Link란?
> 

[J-Link OB Debug Probe](https://www.segger.com/products/debug-probes/j-link/models/j-link-ob/)

J-Link는 USB를 통해 CPU 코어를 연결해주는 장치이다. 보드에 사용되는 장치는 정확히는 J-Link OB(for On-Board)로, 컴퓨터와 보드를 연결해 주는 J-Link 드라이버가 내장되어 있는 것이다. SEGGER Embedded Studio와 호환된다. 

### 6. SDK파일 설치

**<DW3000 API Root Directory>/API/nRF52840-DK** 에 'SDK'라는 폴더를 생성하고 위의 사이트에서 다운받은 Nordic SDK파일의 압축을 풀어주자. 

즉, **<DW3000 API Root Directory>/API/nRF52840-DK/SDK** 에 'components', 'config', 'documentation', 'examples', 'external', 'external_tools', 'integration', 'modules', licence.txt 8개의 폴더와 1개의 텍스트 파일이 들어가면 된다. 

(여기서 **<DW3000 API Root Directory>**는 README파일이 있던 폴더를 뜻한다.)

### 6. dw3000_api.emProject 파일 수정

실행 전 **"<DW3000 API Root Directory>/API/nRF52840-DK/dw3000_api.emProject"** 파일에서 경로를 수정해야 한다. 

1. 해당 파일을 바로 실행하지 않고, 메모장에서 연다.
2. "macros="를 검색한다.
3. NordicSDKDir과 DW3000APIDir의 루트를 수정한다.
    
    NordicSDKDir=<DW3000 API Root Directory>/API/nRF52840-DK/SDK
    DW3000APIDir=<DW3000 API Root Directory>/API
    
4. 저장한다.

### 7. 예제 실행하기

원하는 예제를 실행하기 위해서는 **"<DW3000 API Root Directory>/API/Src/example_selection.h"** 파일을 수정해야 한다.

해당 파일을 열면, 

// #define TEST_READING_DEV_ID
// #define TEST_SIMPLE_TX
// #define TEST_SIMPLE_RX
// #define TEST_SS_TWR_INITIATOR
// #define TEST_SS_TWR_RESPONDER

...

가 코멘팅되어 있을텐데, 여기서 실행하고 싶은 예제의 코멘트를 풀고 저장한다. 

이후 SEGGER Embedded Studio에서 main.c 파일을 컴파일하면 원하는 예제가 실행된다. 

LED가 깜빡이면 보드에 파일이 올라가 실행되는 중인 것이다. 

끝!!