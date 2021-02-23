import AVFoundation
import Cocoa
import HaishinKit
import VideoToolbox
import Foundation

extension NSPopUpButton {
    fileprivate func present(mediaType: AVMediaType) {
        let devices = AVCaptureDevice.devices(for: mediaType)
        devices.forEach {
            self.addItem(withTitle: $0.localizedName)
        }
    }
}

final class MainViewController: NSViewController {
    var rtmpConnection = RTMPConnection()
    var rtmpStream: RTMPStream!

    var httpService = HLSService(
        domain: "local", type: HTTPService.type, name: "", port: HTTPService.defaultPort
    )
    var httpStream = HTTPStream()
    //var abstractString = "tabvn"
    @IBOutlet private weak var lfView: MTHKView!
    @IBOutlet private weak var audioPopUpButton: NSPopUpButton!
    @IBOutlet private weak var cameraPopUpButton: NSPopUpButton!
    @IBOutlet private weak var segmentedControl: NSSegmentedControl!

    @IBOutlet weak var Publish: NSButton!
    @IBOutlet weak var SNField: NSTextField!
    @IBOutlet weak var courseField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rtmpStream = RTMPStream(connection: rtmpConnection)
        rtmpStream.addObserver(self, forKeyPath: "currentFPS", options: .new, context: nil)

        //urlField.stringValue = Preference.defaultInstance.uri ?? ""
        audioPopUpButton?.present(mediaType: .audio)
        cameraPopUpButton?.present(mediaType: .video)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        rtmpStream.attachAudio(DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio))
        rtmpStream.attachCamera(DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video))
        lfView?.attachStream(rtmpStream)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath: String = keyPath, Thread.isMainThread else {
            return
        }
        switch keyPath {
        case "currentFPS":
            view.window!.title = "HaishinKit(FPS: \(rtmpStream.currentFPS): totalBytesIn: \(rtmpConnection.totalBytesIn): totalBytesOut: \(rtmpConnection.totalBytesOut))"
        default:
            break
        }
    }
    var keyString = ""
    var urlString = ""
    
    @IBAction private func publishOrStop(_ sender: NSButton) {
        // Publish
        if sender.title == "Connect" {
            
            //url to request http post method
            let url = URL(string: "https://snuonlinetest.net/Identification")
            guard let requestUrl = url else { fatalError() }
            // Prepare URL Request Object
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
                       
            // HTTP Request Parameters which will be sent in HTTP Request Body
            let stunum = SNField.stringValue
            let course = courseField.stringValue
            let postString = "num=" + stunum + "&lec=" + course + "&MAC=1.1.1.1"
            print(postString)
            
            // Set HTTP Request Body
            request.httpBody = postString.data(using: String.Encoding.utf8);
            // Perform HTTP Request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                  
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data string:\n \(dataString)")
                    var slashcount = 0
                    //Response string에서 적절한 url과 endpoint를 추출하는 과정("/" 개수를 기준으로)
                    for (index, value) in dataString.enumerated() {
                        //print("index: \(index), value : \(value)")
                        if value == "/" {
                            slashcount += 1
                        }
                        if (slashcount == 4) {
                            let range1 = dataString.startIndex..<dataString.index(dataString.startIndex, offsetBy : index)
                            self.urlString = String(dataString[range1])
                            let range2 = dataString.index(dataString.startIndex, offsetBy : index + 1)..<dataString.endIndex
                            self.keyString = String(dataString[range2])
                            break
                        }
                    }
                    //print(dataString)
                    //Resonse로 얻은 dataString이 Error가 아닐 때
                    if dataString != "error" {
                        //적절한 URL과 endpoint로 RTMP 연결
                        print("url = \(self.urlString)")
                        print("key = \(self.keyString)")
                        self.rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(self.rtmpStatusHandler), observer: self)
                        self.rtmpConnection.connect(self.urlString)
                        //self.rtmpStream!.publish(self.keyString)
                        print("publish good")
                        sender.title = "Stop"
                                
                    }
                }
            }
            task.resume()
            return
        }
        // Stop
        //RTMP 연결 해제
        sender.title = "Connect"
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
        rtmpConnection.close()
        return
    }

    @IBAction private func orientation(_ sender: AnyObject) {
        lfView.rotate(byDegrees: 90)
    }

    @IBAction private func selectAudio(_ sender: AnyObject) {
        let device: AVCaptureDevice? = DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio)
        switch segmentedControl.selectedSegment {
        case 0:
            rtmpStream.attachAudio(device)
            httpStream.attachAudio(nil)
        case 1:
            rtmpStream.attachAudio(nil)
            httpStream.attachAudio(device)
        default:
            break
        }
    }

    @IBAction private func selectCamera(_ sender: AnyObject) {
        let device: AVCaptureDevice? = DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video)
        switch segmentedControl.selectedSegment {
        case 0:
            rtmpStream.attachCamera(device)
            httpStream.attachCamera(nil)
        case 1:
            rtmpStream.attachCamera(nil)
            httpStream.attachCamera(device)
        default:
            break
        }
    }

    @IBAction private func modeChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            httpStream.attachAudio(nil)
            httpStream.attachCamera(nil)
            rtmpStream.attachAudio(DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio))
            rtmpStream.attachCamera(DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video))
            lfView.attachStream(rtmpStream)
            //urlField.stringValue = Preference.defaultInstance.uri ?? ""
        case 1:
            rtmpStream.attachAudio(nil)
            rtmpStream.attachCamera(nil)
            httpStream.attachAudio(DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio))
            httpStream.attachCamera(DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video))
            lfView.attachStream(httpStream)
            //urlField.stringValue = "http://{ipAddress}:8080/hello/playlist.m3u8"
        default:
            break
        }
    }

    @objc
    private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            rtmpStream!.publish(self.keyString)
        default:
            break
        }
    }
}
