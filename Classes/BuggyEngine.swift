//
//  BuggyEngine.swift
//  BuggyEngine
//
//  Created by Harvey He on 2019/1/8.
//

import UIKit
import PromiseKit
import WebKit
import WKWebViewJavascriptBridge
public class BuggyEngine: NSObject {
    
    fileprivate var manager = BuggyManager.getInstance()
    fileprivate var bridge:WKWebViewJavascriptBridge?
   
    init(webview:WKWebView) {
        bridge = WKWebViewJavascriptBridge(webView:webview)
    }
    
    func registerBridgeHandle(bridge:WKWebViewJavascriptBridge){
        
        bridge.register(handlerName:"deviceConnect") { (paramters, callback) in
            _ = self.initCommunicator().done{ _ -> Void in  callback?("success")}
        }
        
        bridge.register(handlerName:"sendMsgPromise") { (paramters, callback) in
            let data = paramters!["data"] as! NSDictionary
            self.manager.sendDataWithoutResponse(msg: data.object(forKey:"data")! as! Array<UInt8>)
        }
        
        bridge.register(handlerName:"connectTimeOut") {(paramters, callback) in
            print("scratch response","连接超时")
        }
        
        bridge.register(handlerName:"disconnect") {(paramters, callback) in
            print("scratch response","连接断开")
        }
        
        bridge.register(handlerName:"connectReady") {(paramters, callback) in
            print("scratch response","连接成功")
        }
    }
    
    func initCommunicator()->Promise<String>{
        return manager.connectionIO == nil ? initConnect() : firmataReady()
    }

    public func initConnect()->Promise<String>{
        return after(seconds: 2).then{_ in
            return self.manager.initCentralManager()
        }.then{_ in
            return self.manager.startScan()
        }.then{_ in
            return self.manager.connectDevice()
        }
    }
    
    public func resetBuggyAndUpload(data:NSData)->Promise<String>{
        manager.communucationType = .upload
        return self.uploadHex(data:data as Data)
    }
    
    func resetBuggy()->Promise<[UInt8]>{
        return manager.setUploadBaudrate() .then { _ in
            return self.manager.resetDevice()
            }.then{ _ in
                return self.manager.getCoreType()
            }.then{ _ in
                return self.manager.keepSync()
            }.then{ _ in
                return self.manager.setDevice()
        }
    }
    
    func uploadHex(data:Data)->Promise<String>{
        return resetBuggy().then { _ in
            return self.manager.enterProgramming()
            }.then { _ in
                return self.manager.uploadData(hexData: data)
            }.then{ _ in
                return self.manager.exitProgramming()
            }.then{ _ in
                return self.manager.setCommunicatorBaudrate()
        }
    }
    
    func firmataReady()->Promise<String>{
        return after(seconds:0.020).then{return Promise{seal in seal.fulfill("OK")}}
    }
}
