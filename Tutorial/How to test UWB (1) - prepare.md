# How to test UWB (1) - prepare

## ⭐ 목표

UWB 신호를 보내는 anchor를 만든 후, iPhone으로 그 신호를 받아보자

## 📌 Apparatus

- iPhone 12 (128GB)
    
    [iPhone 12 및 iPhone 12 mini 주요 특징](https://www.apple.com/kr/iphone-12/key-features/)
    
    - iPhone 11부터 U1칩이 포함되어 있다.
    - iOS 15이상부터 **Nearby Interaction**이라는 API가 사용 가능하므로 소프트웨어를 꼭 업데이트해줘야 한다.
- Qorvo DWM3000 EVB (쉴드)
    
    [DWM3000EVB](https://www.qorvo.com/products/p/DWM3000EVB)
    
    - Apple 공식 사이트에서 U1 칩과 호환 가능하다고 한 제품이다. 아두이노 UNO 쉴드 폼팩터와 호환된다.
    - DWM3000 EVB == DWS3000 이니까 헷갈리지 말자.
    - DWS1000은 구 버전으로, iPhone과 호환되지 않는다.
- nRF52840 Development Kit (노르딕 보드)
    
    [nRF52840 DK](https://www.nordicsemi.com/Products/Development-hardware/nrf52840-dk)
    
    - 이 외에 DWM3000 EVB랑 연결 가능한 보드는 다음과 같다.
        - nRF52-DK
        - nRF52833-DK
    - 위의 쉴드를 노르딕 보드 대신 아두이노랑 연결하면 절대 안 돌아간다 ㅠㅠ