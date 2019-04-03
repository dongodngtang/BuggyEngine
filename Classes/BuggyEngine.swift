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
import CoreBluetooth
@objc public enum BuggyState:Int {
    case firmataTimeOut
    case connectsuccess
    case disconnect
    case connectTimeOut
    case firmatasuccess
    case firmatabreak
    case powerOff
    case powerOn
    case uploadHex
    case firmataExpired
}

public class BuggyEngine: NSObject {
    
    var manager = BuggyManager.getInstance()
    public var delegate:BuggyEngineDelegate?
    public var bridge:WKWebViewJavascriptBridge?
    private var wkWebView =  WKWebView()
    private var timeOutTask:Task?
    private var presentPowerOFF:Bool = false
    public override init() {
        super.init()
    }
    
    public func initBuggy(){
        _ = registerWebViewBridge().then{_ in
            return self.loadFirmataResource()
        }
    }
    
    public func disConnected(){
        bridge?.call(handlerName: "deviceDisConnect", data:nil, callback: nil)
       _ = manager.disConnected()
    }
    
    public func connectBuggy(){
        bridge?.call(handlerName: "deviceConnect", data:nil, callback: nil)
        timeOutTask = delay(10){self.stopScan()}
    }
    
    func loadFirmataResource()->Promise<String>{
        let controller = UIApplication.shared.keyWindow
        controller?.addSubview(wkWebView)
        let resourcePath = Bundle.main.bundlePath
        let pathURL = URL.init(fileURLWithPath: resourcePath)
        let html = Bundle.main.path(forResource: "firmata", ofType: "html")
        do {
            let content = try String(contentsOf: URL.init(fileURLWithPath: html!), encoding: String.Encoding.utf8)
            wkWebView.loadHTMLString(content, baseURL: pathURL)
        }
        catch _{}
        return after(seconds:1).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func registerWebViewBridge()->Promise<String>{
        bridge = WKWebViewJavascriptBridge(webView: wkWebView)
        bridge?.register(handlerName:FIRMATA_CONNECT) { (paramters, callback) in
           _ =  self.initCommunicator().done{_ in
                print("--------------------123")
                callback?("success")
            }.catch{ error in
                print("--------------------456")
                callback?("failure")
                if let err = error as? BuggyError{
                    self.catchManagerError(error:err)
                }
            }
        }
        
        bridge?.register(handlerName:FIRMATA_SENDMEG) { (paramters, callback) in
            let data = paramters!["data"] as! NSDictionary
            self.sendData(data: data.object(forKey:"data")! as! Array<UInt8>)
            callback?("success")
        }
        
        bridge?.register(handlerName:FIRMATA_TIMEOUT) { (paramters, callback) in
            self.delegate?.buggyEngineState?(state:.firmataTimeOut)
        }
        
        bridge?.register(handlerName:FIRMATA_DISCONNECT) { (paramters, callback) in
            self.delegate?.buggyEngineState?(state:.firmatabreak)
        }
        
        bridge?.register(handlerName:FIRMATA_CONNECTREADY) { (paramters, callback) in
            self.delegate?.buggyEngineState?(state:.firmatasuccess)
        }
        bridge?.register(handlerName:FIRMATA_VERSIONEXPIRED, handler: { (paramters, callback) in
            self.delegate?.buggyEngineState?(state:.firmataExpired)
        })
        return Promise{seal in seal.fulfill("OK")}
    }
    
    public func initCommunicator()->Promise<String>{
        manager.delegate = self
        manager.communucationType = .control
        return manager.connectionIO == nil ? initConnect() : firmataReady()
    }
    
    func setCommunicatorType(type:CommunucationType){
        manager.communucationType = type
    }
    
    public func initConnect()->Promise<String>{
        return self.manager.initCentralManager().then{_ in
            return self.manager.startScan()
            }.then{_ in
                return self.manager.connectDevice()
            }.then{_ in
                return self.manager.setCommunicatorBaudrate()
            }.then{_ in
                return self.connectSuccess()
            }.then{_ in
                return Promise{seal in seal.fulfill("OK")}
        }
    }
    
    func connectSuccess()->Promise<String>{
        cancel(timeOutTask)
        delegate?.buggyEngineState?(state:.connectsuccess)
        return Promise{seal in seal.fulfill("OK")}
    }
    
    public func stopScan(){
        manager.stopScan()
        self.delegate?.buggyEngineState?(state:.connectTimeOut)
    }
    
    public func resetBuggyAndUpload(data:NSData)->Promise<String>{
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
        delegate?.buggyEngineState?(state:.uploadHex)
        return self.resetBuggy().then { _ in
            return self.manager.enterProgramming()
            }.then { _ in
                return self.manager.uploadData(hexData: data)
            }.then{ _ in
                return self.manager.exitProgramming()
            }.then{ _ in
                return self.manager.setCommunicatorBaudrate()
            }
    }
    
    public func sendData(data:[UInt8]){
        if let connectionIO = self.manager.connectionIO{
            self.manager.managerWriteValue(connectionIO, msg: data)
        }
    }
    
    func firmataReady()->Promise<String>{
        return after(seconds:0.020).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func catchManagerError(error:BuggyError){
        cancel(timeOutTask)
        switch error.code {
        case .powerOff:
            presentPowerOFF = true
            self.delegate?.buggyEngineState?(state:.powerOff)
        case .timeOut:
            self.stopScan()
        default:break
        }
    }
}

extension BuggyEngine:BuggyManagerDelegate{
    
    public func firmataReceviceData(inputData: [UInt8]) {
        delegate?.firmataReceviceData!(inputData:inputData)
        bridge?.call(handlerName:FIRMATA_NOTIFICATION, data:["data":inputData], callback: nil)
    }
    
    public func managerState(state: CBCentralManagerState) {
        
    }
    
    public func hexUploadProgess(progess: Int) {
        delegate?.hexUploadProgess?(progess: progess)
    }
    
    public func powerWarning() {
        delegate?.powerWarning?()
    }
}
