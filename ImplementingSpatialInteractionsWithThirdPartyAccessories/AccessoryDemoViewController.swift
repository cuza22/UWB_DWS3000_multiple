/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that facilitates the Nearby Interaction Accessory user experience.
*/

import UIKit
import NearbyInteraction
import os.log

let FREQUENCY: Double = 5

enum MessageId: UInt8 {
    // anchor로부터 받는 메세지
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart = 0x2
    case accessoryUwbDidStop = 0x3
    
    // anchor로 보내는 메세지
    case initialize = 0xA
    case configureAndStart = 0xB
    case stop = 0xC
}

class AccessoryDemoViewController: UIViewController {
    //
    var dataChannels = [NIDiscoveryToken: DataCommunicationChannel]() // Data Channel 인스턴스 - 통신 담당, BluetoothLECentral.swift 상속받음
    var sessions = [NIDiscoveryToken: NISession]() // session 인스턴스 - direction, distance 불러옴
    var configurations = [String: NINearbyAccessoryConfiguration]()
    var accessoriesConnected = [String: Bool]()
//    var accessoriesCharactereisticDiscovered = [String: Bool]()
    var accessoriesInitialized = [String: Bool]()
    var accessoryNames = Set<String>()
    var accessoryMap = [NIDiscoveryToken: String]()
    var tokenMap = [String: NIDiscoveryToken]()
    
    var initDataChannel: DataCommunicationChannel! // temp
    var configSession: NISession! // temp

    // CSV 저장을 위한 변수
    let fileManager = FileManager()
    var directoryURL: URL!
    var fileURL: URL!
    var data: String = ""
    var timer: Timer!
    
    var directions = [String: simd_float3]()
    var distances = [String: Float]()
    
    let logger = os.Logger(subsystem: "com.example.apple-samplecode.NINearbyAccessorySample", category: "AccessoryDemoViewController")

    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBOutlet weak var uwbStateLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create NISession and DataChannel
        let niSession = NISession()
        let dataChannel = DataCommunicationChannel()
        
        // set protocols
        niSession.delegate = self
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()
        
        // append to global list
        sessions[niSession.discoveryToken!] = niSession
        dataChannels[niSession.discoveryToken!] = dataChannel
        
        initDataChannel = dataChannel
        configSession = niSession
        
        updateInfoLabel(with: "Scanning for accessories")
        
        // create timer and csv file
        setDirectory()
        createTimer()
        createCSV()
    }

    @IBAction func buttonAction(_ sender: Any) {
        startCollectingData()
    }
    
    // MARK: - Data collection
    func createTimer() {
        timer = Timer(fire: Date(), interval: TimeInterval((1/FREQUENCY)), repeats: true, block: { [self] (timer) in
            // date
            let date = Date()
            let format = DateFormatter()
            format.dateFormat = "yyyy,MM,dd,HH,mm,ss,SSSS,"
            let formattedDate = format.string(from: date)
            
            // search and connect new anchors
            for name in accessoryNames.sorted() {
//                logger.info("Accessories Connected: \(accessoriesConnected)")
//                logger.info("Accessories Initialized: \(accessoriesInitialized)")
                if (accessoriesConnected[name] ?? false) && !(accessoriesInitialized[name] ?? false) {
                    
                    updateInfoLabel(with: "Requesting configuration data from accessory")
                    let msg = Data([MessageId.initialize.rawValue])
                    do {
                        try initDataChannel!.sendData(msg)
                    } catch {
                        updateInfoLabel(with: "Failed to init accessory: \(error)")
                    }
                }
            }
            
//            logger.info("Found accessories: \(self.accessoryNames)")
            
            // write in file
            for name in accessoryNames {
                let dataRow = String(format: formattedDate + self.asDataRow(name: name, distance: distances[name], direction: directions[name]))
                self.data += dataRow
                
                logger.info("[data write] \(dataRow)")
            }
            self.writeCSV()
        })
        
        logger.info("Timer created!")
    }
    
    func startCollectingData() {
        logger.info("Timer started!")
        RunLoop.current.add(self.timer, forMode: .default)
    }

    func stopCollectingData() {
        self.timer.invalidate()
    }
    
    // MARK: - DataChannel 프로토콜
    // anchor로부터 받은 메세지를 해석하는 메소드
    func accessorySharedData(data: Data, accessoryName: String) {
        if data.count < 1 {
            updateInfoLabel(with: "Accessory shared data length was less than 1.")
            return
        }
        
        // 첫번째 byte로 유효한 메세지인지 판별함, 아닐 경우 에러메세지 출력
        guard let messageId = MessageId(rawValue: data.first!) else {
            fatalError("\(data.first!) is not a valid MessageId.")
        }
        
        // 유효한 메세지인 경우 메세지 해석
        switch messageId {
        case .accessoryConfigurationData:
            // 메세지의 첫 번째 byte는 message identifier
            assert(data.count > 1)
            let message = data.advanced(by: 1)
            setupAccessory(message, name: accessoryName)
        case .accessoryUwbDidStart:
            handleAccessoryUwbDidStart()
        case .accessoryUwbDidStop:
            handleAccessoryUwbDidStop()
        case .configureAndStart:
            fatalError("Accessory should not send 'configureAndStart'.")
        case .initialize:
            fatalError("Accessory should not send 'initialize'.")
        case .stop:
            fatalError("Accessory should not send 'stop'.")
        }
    }
    
    // anchor과 iphone이 connect 됐을 때 호출
    func accessoryConnected(name: String) {
        accessoriesConnected[name] = true
        accessoryNames.insert(name)
        updateInfoLabel(with: "Connected to '\(name)'")        
    }
    
    // anchor과 iphone이 disconnected 됐을 때 호출
    func accessoryDisconnected(name: String) {
        accessoriesConnected[name] = false
        accessoryNames.remove(name)
        updateInfoLabel(with: "\(name) disconnected")
    }
    
    // MARK: - UWB와 메세지 주고받는 기능
    
    // uwb에 configuration data를 보내는 메소드
    func setupAccessory(_ configData: Data, name: String) {
        accessoriesInitialized[name] = true

        updateInfoLabel(with: "Received configuration data from '\(name)'. Running session.")
//        guard let token = tokenMap[name] else {
//            logger.info("[Set Up Accessory ERROR] no token of \(name) exists")
//            return
//        }
//        guard let session = self.sessions[token] else {
//            logger.info("[Set Up Accessory ERROR] no session of \(name) exists")
//            return
//        }
        var configuration: NINearbyAccessoryConfiguration?
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
        } catch {
            updateInfoLabel(with: "Failed to create NINearbyAccessoryConfiguration for '\(name)'. Error: \(error)")
            return
        }
        configurations[name] = configuration!
        
        // Cache the token to correlate updates with this accessory
        cacheToken(configurations[name]!.accessoryDiscoveryToken, accessoryName: name)
        configSession.run(configurations[name]!)
        logger.info("Configuration: \(configuration!.description)")
    }
    
    // 통신이 시작되었을 때 호출되는 메소드
    func handleAccessoryUwbDidStart() {
        updateInfoLabel(with: "Accessory session started.")
        self.uwbStateLabel.text = "ON"
        
        // 새로운 anchor 탐색을 위한 session & DataChannel 생성
        let niSession = NISession()
        let dataChannel = DataCommunicationChannel()
        
        niSession.delegate = self
        dataChannel.accessoryConnectedHandler = accessoryConnected
        dataChannel.accessoryDisconnectedHandler = accessoryDisconnected
        dataChannel.accessoryDataHandler = accessorySharedData
        dataChannel.start()
        
        sessions[niSession.discoveryToken!] = niSession
        dataChannels[niSession.discoveryToken!] = dataChannel

        initDataChannel = dataChannel
        configSession = niSession

    }
    
    // 통신이 끊겼을 때 호출되는 메소드
    func handleAccessoryUwbDidStop() {
        updateInfoLabel(with: "Accessory session stopped.")
    }
}

// MARK: - NISession 프로토콜
extension AccessoryDemoViewController: NISessionDelegate {
    // session을 시작하기 전 configuration
    func session(_ session: NISession, didGenerateShareableConfigurationData shareableConfigurationData: Data, for object: NINearbyObject) {
        let accessoryName = accessoryMap[object.discoveryToken] ?? "Unknown"

        guard object.discoveryToken == configurations[accessoryName]?.accessoryDiscoveryToken else { return }
        
        // session에 uwb로부터 받아온 configuration data를 설정
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        
        let str = msg.map { String(format: "0x%02x, ", $0) }.joined()
        logger.info("Sending shareable configuration bytes: \(str)")
        
        sendDataToAccessory(msg, sessionToken: session.discoveryToken!)
        updateInfoLabel(with: "Sent shareable configuration data to '\(accessoryName)'.")
    }
    
    // uwb 데이터(거리, 각도)에 변화가 있을 때마다 호출되는 메소드
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
//        self.logger.info("session: \(session)     updated: \(nearbyObjects)")
//        self.logger.info("updated: \(nearbyObjects)")
        
        guard let accessory = nearbyObjects.first else { return }
        
        let accessoryName = accessoryMap[accessory.discoveryToken] ?? "unknown"
        accessoryNames.insert(accessoryName)

        if accessory.distance != nil {
            self.distances[accessoryName] = accessory.distance
        } else {
            return
        }
        
        if accessory.direction != nil {
            self.directions[accessoryName] = accessory.direction
        } 
    }
    
    // 연결되어있던 uwb가 제거되고, session이 종료되었을 때 호출되는 메소드
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // Retry the session only if the peer timed out.
        guard reason == .timeout else { return }
        guard let accessory = nearbyObjects.first else { return }
        updateInfoLabel(with: "Session with '\(accessoryMap[accessory.discoveryToken] ?? "accessory")' timed out.")

        // 연결되어있던 uwb 목록에서 제거
        accessoryMap.removeValue(forKey: accessory.discoveryToken)
        tokenMap.removeValue(forKey: accessory.description)
        
        if shouldRetry(accessory) {
            sendDataToAccessory(Data([MessageId.stop.rawValue]), sessionToken: session.discoveryToken!)
            sendDataToAccessory(Data([MessageId.initialize.rawValue]), sessionToken: session.discoveryToken!)
        }
    }
    
    // session 일시중지
    func sessionWasSuspended(_ session: NISession) {
        updateInfoLabel(with: "Session was suspended.")
        let msg = Data([MessageId.stop.rawValue])
        sendDataToAccessory(msg, sessionToken: session.discoveryToken!)
    }
    
    // session 재개
    func sessionSuspensionEnded(_ session: NISession) {
        updateInfoLabel(with: "Session suspension ended.")
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(msg, sessionToken: session.discoveryToken!)
    }
    
    // 연결 오류
    func session(_ session: NISession, didInvalidateWith error: Error) {
        switch error {
        case NIError.invalidConfiguration:
            // Debug the accessory data to ensure an expected format.
            updateInfoLabel(with: "The accessory configuration data is invalid. Please debug it and try again.")
        case NIError.userDidNotAllow:
            handleUserDidNotAllow()
        default:
            handleSessionInvalidation(session: session)
        }
    }
}

// MARK: - Helpers.
extension AccessoryDemoViewController {
    func updateInfoLabel(with text: String) {
        self.infoLabel.text = text
        self.distanceLabel.sizeToFit()
        logger.info("\(text)")
    }
    
    func sendDataToAccessory(_ data: Data, sessionToken: NIDiscoveryToken) {
        do {
            try dataChannels[sessionToken]?.sendData(data)
        } catch {
            updateInfoLabel(with: "Failed to send data to accessory: \(error)")
        }
    }
    
    func handleSessionInvalidation(session: NISession) {
        updateInfoLabel(with: "Session invalidated. Restarting.")
        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.stop.rawValue]), sessionToken: session.discoveryToken!)

        // Replace the invalidated session with a new one.
        let niSession = NISession()
        niSession.delegate = self
        sessions[session.discoveryToken!] = niSession

        // Ask the accessory to stop.
        sendDataToAccessory(Data([MessageId.initialize.rawValue]), sessionToken: niSession.discoveryToken!)
    }
    
    func shouldRetry(_ accessory: NINearbyObject) -> Bool {
        guard let accessoryName = accessoryMap[accessory.discoveryToken] else { return false }
        if accessoriesConnected[accessoryName] ?? false {
            return true
        }
        return false
    }
    
    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
    }
    
    func handleUserDidNotAllow() {
        // Beginning in iOS 15, persistent access state in Settings.
        updateInfoLabel(with: "Nearby Interactions access required. You can change access for NIAccessory in Settings.")
        
        // Create an alert to request the user go to Settings.
        let accessAlert = UIAlertController(title: "Access Required",
                                            message: """
                                            NIAccessory requires access to Nearby Interactions for this sample app.
                                            Use this string to explain to users which functionality will be enabled if they change
                                            Nearby Interactions access in Settings.
                                            """,
                                            preferredStyle: .alert)
        accessAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        accessAlert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: {_ in
            // Navigate the user to the app's settings.
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))

        // Preset the access alert.
        present(accessAlert, animated: true, completion: nil)
    }
}

// MARK: - save as CSV
extension AccessoryDemoViewController {
    func setDirectory() {
        directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fileManager.createDirectory(atPath: directoryURL.path, withIntermediateDirectories: false, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }
    }
    
    func createCSV() {
        // set date for name of the file
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy_MM_dd_HH_mm_ss"
        let formattedDate = format.string(from: date)
        
        // create file directory
        fileURL = directoryURL.appendingPathComponent(formattedDate + ".csv")

        // write header in the file
        let header: String = "year,month,day,hour,min,sec,ms,anchor,distance,dirX,dirY,dirZ\n"
        data += header
        writeCSV()
    }
    
    func writeCSV() {
        let text = NSString(string: data)
        do {
            try text.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
        } catch let e {
            print(e.localizedDescription)
        }
    }
    
    func asDataRow(name: String?, distance: Float?, direction: simd_float3?) -> String {
        var n = "unknown"
        var dist = "nil"
        var x = "nil"
        var y = "nil"
        var z = "nil"

        if name != nil {
            n = name!
        }
        if distance != nil {
            dist = distance!.description
        }
        if let dir = direction {
            x = dir.x.description
            y = dir.y.description
            z = dir.z.description
        }
        
        return "\(n), \(dist), \(x), \(y), \(z)\n"
    }
}
