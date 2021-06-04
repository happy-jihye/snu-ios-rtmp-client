//
//  LoginViewController.swift
//  Example iOS
//
//  Created by 백지혜 on 2021/02/23.
//  Copyright © 2021 Shogo Endo. All rights reserved.
//
import AVFoundation
import HaishinKit
import Photos
import UIKit
import VideoToolbox


class LoginViewController: UIViewController {
    
    @IBOutlet private weak var LoginName: UITextField?
    @IBOutlet private weak var LoginNum: UITextField?
    @IBOutlet private weak var LoginButton: UIButton!
    @IBOutlet private weak var LoginResult: UILabel!
    
    public var rtmpUri = ""
    public var rtmpStreamkey = ""
    
    var httpService = HLSService(
            domain: "local", type: HTTPService.type, name: "", port: HTTPService.defaultPort
        )
    var httpStream = HTTPStream()
    var keyString = ""
    var urlString = ""
    var login_success : Bool = false
        
        ///
    
    @IBAction func Login_func(_ sender: UIButton) {

        let semaphore = DispatchSemaphore(value: 0)
        
        // 1. 전송할 값 준비

        let name = (LoginName?.text)!
        let num = (LoginNum?.text)!
        let param = "num=\(num)&name=\(name)&mac=0" // key1=value&key2=value...
        let paramData = param.data(using: .utf8)

        // 2. URL 객체 정의
        let url = URL(string: "https://snuonlinetest.net/Identification")

        // 3. URLRequest 객체를 정의하고, 요청 내용을 담는다.
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.httpBody = paramData

        // 4. HTTP 메세지 헤더 설정
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(String(paramData!.count), forHTTPHeaderField: "Content-Length")
        
        // 5. URLSession 객체를 통해 전송 및 응답값 처리 로직 작성

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                              
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                if dataString == "there is no exam today..."{
                    
                    //self.LoginResult.text = "there is no exam today..."
                    semaphore.signal()
                    return
                }
                if dataString == "Table 'test.undefined' doesn't exist"{
                    
                    //self.LoginResult.text = "there is no exam today..."
                    
                    semaphore.signal()
                    return
                }
                else{
                    self.login_success = true
                    
                    
                    let param = "num=\(num)&name=\(name)&tablename=\(dataString)&mac=0" // key1=value&key2=value...
                    Preference.defaultInstance.data = param
                    let paramData = param.data(using: .utf8)

                    // 2. URL 객체 정의
                    let url = URL(string: "http://3.35.240.138:3333/return_endpoint")

                    // 3. URLRequest 객체를 정의하고, 요청 내용을 담는다.
                    guard let requestUrl = url else { fatalError() }
                    var request = URLRequest(url: requestUrl)
                    request.httpMethod = "POST"
                    request.httpBody = paramData

                    // 4. HTTP 메세지 헤더 설정
                    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    request.setValue(String(paramData!.count), forHTTPHeaderField: "Content-Length")

                    // 5. URLSession 객체를 통해 전송 및 응답값 처리 로직 작성

                    let task2 = URLSession.shared.dataTask(with: request) { data, response, error in
                                          
                        if let data = data {
                            
//                            print("json data: \(data)")
                            
                        
                            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else { return}
                            guard let rtmp_uri = json["0"] as? String else { return }
                           
                            let rtmp_arr = rtmp_uri.split(separator: "/")
                            
                            Preference.defaultInstance.uri = "rtmp://3.35.240.138/channel2/"
                            Preference.defaultInstance.streamName =  String(rtmp_arr[3])

                            
                            semaphore.signal()
                        }
                    }//test2 finish
                    task2.resume()
                  

                }//else finish
            }
        } //task finish

        // 6. POST 전송

        task.resume()
        
        semaphore.wait()
        
        print("login \(self.login_success)")
        if self.login_success == true {
            print("login \(self.login_success)")

            if #available(iOS 13.0, *) {
                let story = UIStoryboard(name: "Main", bundle: nil)
                let controller = story.instantiateViewController(identifier: "Main") as! LiveViewController
                self.navigationController?.pushViewController(controller, animated: true)
                
            }
            self.login_success = false
        }

    }//login_func

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
    }
}
