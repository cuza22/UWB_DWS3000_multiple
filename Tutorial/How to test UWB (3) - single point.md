# How to test UWB (3) - single point

⭐ 목표: iPhone으로 single anchor의 신호를 잡아 보자

# 📌 Run codes on DWS3000 (앵커 만들기)

### 1. Qorvo에서 배포한 코드 다운로드

How to test UWB(2) 를 통해 앵커가 정상 작동하는지 확인할 수는 있으나, 해당 테스트 코드에서 나오는 신호는 아이폰에서 인식되지 않는다. 아이폰이 인식하는 (앵커용) 코드는 따로 있다. 

### 🔺 Nearby Interaction Beta Evaluation Software

[Qorvo](https://www.qorvo.com/products/d/da008212)

여기서 Qorvo에 이메일을 보내면 기간이 있는 다운로드 링크를 보내준다. (만료되면 다운로드 불가) 

gmail 쓰면 accept 안 되니까 네이버 메일 쓰자. 

### 2. 바이너리 코드 올리기

- **Qorvo_Apple_Nearby_Interaction_Beta_release_1.0.0-1**
    - 해당 zip파일을 압축 해제한다.
    - ...\Qorvo_Apple_Nearby_Interaction_Beta_release_1.0.0-1\Qorvo_Apple_Nearby_Interaction_Beta_release_1.0.0-1\**Binaries\nRF52840DK** (보드 이름별로 폴더가 존재한다.)
    - 위 경로에 들어가면 바이너리 파일**(NRF52840DK_full.hex)**이 있다.
- **SEGGER J-Flash Lite** 라는 프로그램을 이용해서 노르딕 보드에 파일을 업로드한다.
    - SES를 다운받을 때 자동으로 설치되었을 것이다. 없으면 아래 링크에서 설치하자.
    
    [SEGGER Downloads](https://www.segger.com/downloads/jlink/)
    
    - 보드가 컴퓨터와 연결된 상태에서 J-Flash Lite를 실행하면 아래와 같은 창이 뜬다. ‘...’ 버튼을 클릭하여 우리가 사용하는 보드인 nRF52840로 바꾸어 주자.
    
    ![Untitled](How%20to%20test%20UWB%20(3)%20-%20single%20point%205614b9c98e914801a30200d61c14490c/Untitled.png)
    
    - 해당 ‘...’ 버튼을 클릭하여 보드에 업로드하려는 바이너리 파일을 선택한다.
    
    ![Untitled](How%20to%20test%20UWB%20(3)%20-%20single%20point%205614b9c98e914801a30200d61c14490c/Untitled%201.png)
    
    - 아래와 같은 창이 뜨면 업로드가 완료된 것이다.
    
    ![Untitled](How%20to%20test%20UWB%20(3)%20-%20single%20point%205614b9c98e914801a30200d61c14490c/Untitled%202.png)
    

> No emulators connected via USB. Do you want to connect through TCP/IP?
> 

→ 보드에 J-Link가 설치되지 않아서, 프로그램이 J-Link를 감지할 수 없을 때 뜨는 오류 메세지이다. 

[How to test UWB (2)](https://www.notion.so/How-to-test-UWB-2-nordic-board-settings-91d89df44ed741f29c15d94db9cb6bb7) 에서 J-Link 드라이버 설치법을 다시 확인하자.

### 3. J-Link로 통신 확인하기

- **J-Link RTT Viewer** 이라는 프로그램을 사용한다.
    - 아이폰과 앵커가 통신중일 때, 해당 프로그램을 실행하면 앵커의 log를 모니터에서 확인 가능하다.
    - 아이폰과 앵커 사이의 거리만 cm단위로 표시해서 보여준다.

# 📌 Running iPhone📱 App (아이폰 샘플코드 돌리기)

DWS3000은 U1칩과 호환되는 서드파티 악세서리다. 애플에서 WWDC21에 서드파티 악세서리를 위한 sample code를 공개하였다. 이 코드를 통해 앵커가 제대로 작동되고 있는 지 확인 가능하다. 

### 🔺 **Implementing Spatial Interactions with Third-Party Accessories**

[Apple Developer Documentation](https://developer.apple.com/documentation/nearbyinteraction/implementing_spatial_interactions_with_third-party_accessories)

- 근처의 Third party UWB accessory를 감지하고 distance를 알려주는 앱이다.

[Xcode - Apple Developer](https://developer.apple.com/kr/xcode/)

- Xcode 13으로 파일을 연다.
- 본인의 애플 계정으로 시그니쳐를 추가한 뒤 실행한다. (시그니쳐가 없는 앱은 실행되지 않는다.)
- 아이폰 설정>일반>VPN 및 기기 관리 에서 개발자를 신뢰한다고 해 주자.
- 다시 Xcode에서 아이폰으로 앱을 실행하면, 제대로 작동할 것이다!
- **아이폰**에 ‘DWM3000EVB + nRF52840DK’라는 이름의 악세서리가 감지되고 **앵커**에 초록색 LED가 깜빡거리면, 통신이 끊기지 않고 지속되고 있는 것이다.
- 시간이 지나면 인증이 무효화되기 때문에 주기적으로 개발자 신뢰를 체크해주어야 한다. (맥북이 꼭 필요하다...)

![Untitled](How%20to%20test%20UWB%20(3)%20-%20single%20point%205614b9c98e914801a30200d61c14490c/Untitled%203.png)

이런 화면이 뜨면 성공!! 

> 실행 시 Cannot find type 'NINearbyAccessoryConfiguration' in scope 라는 오류가 뜨면
> 

→ Xcode를 13으로 업데이트 해 주고 iOS도 15로 업데이트하면 해결된다.