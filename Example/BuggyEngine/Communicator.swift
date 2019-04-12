//
//  Communicator.swift
//  MakeApp
//
//  Created by Harvey He on 2019/1/23.
//  Copyright © 2019 harvey. All rights reserved.
//

import Foundation
import BuggyEngine
import PromiseKit
import UIKit
protocol CommunicatorDelegate {
    func communicatorData(receviceData:[UInt8])
    func communicatorState(state:CommunicatorType)
    func connectViewDismiss()
}

public enum CommunicatorType {
    case timeout
    case connected
    case disconnect
}

class Communicator: NSObject{

    static private var instance : Communicator {
        return sharedInstance
    }
    static private let sharedInstance = Communicator()
    
    static func getInstance() -> Communicator {
        return instance
    }
    var delegate:CommunicatorDelegate?
    private var engine:BuggyEngine?
    private var buzzerSongStop:Bool = false
    public var isConnected:Bool = false
    public var isNotificationReceviceData:Bool = false
    override init() {
        super.init()
        engine = BuggyEngine()
        engine?.delegate = self
        engine?.initBuggy()
    }
    
    
    func disConnectDevice(){
        if(isConnected){
            engine?.disConnected()
            isConnected = false
        }
    }

    func connectDevice(){
        after(seconds:2).done {
            _ = self.engine?.connectBuggy()
        }
    }
    
    func sendScratchData(data:[UInt8]){
        engine?.sendData(data:data)
    }
    
    func sendCmdData(firmataData:[String : Any]){
        engine?.bridge?.call(handlerName: "firmataControl", data:firmataData, callback: nil)
    }
    
    func getBotGray(){
         let firmataData = ["name":"bot_get_gray","param":["3",2]] as [String : Any]
         sendCmdData(firmataData: firmataData)
    }
    
    func setBuggyMotor(x:Float = 0,y:Float = 0,type:Int = 3){
        let direction:Float = y >= 0 ? 1 : -1
        let leftSpeed = y + x * direction
        let rightSpeed = y + x * -direction
        var firmataData = [String : Any]()
        switch type {
        case 1:
            firmataData = ["name":"buggy_motor_control","param":["3",leftSpeed,0]] as [String : Any]
        case 2:
            firmataData = ["name":"buggy_motor_control","param":["3",0,rightSpeed]] as [String : Any]
        case 3:
            firmataData = ["name":"buggy_motor_control","param":["3",leftSpeed,rightSpeed]] as [String : Any]
        default:
            firmataData = ["name":"buggy_motor_control","param":["3",leftSpeed,rightSpeed]] as [String : Any]
        }
        sendCmdData(firmataData: firmataData)
    }
    
    func setBuggyLightColor(left:String,right:String){
        let leftData = ["name":"botLEDColor","param":["1",left]] as [String : Any]
        sendCmdData(firmataData: leftData)
        let rightData = ["name":"botLEDColor","param":["2",right]] as [String : Any]
        sendCmdData(firmataData: rightData)
    }
    
    func setBuggyBuzzerPlay(note:Int,duration:Float){
        let firmataData = ["name":"bot_buzzer_play","param":[note,duration]] as [String : Any]
        sendCmdData(firmataData: firmataData)
    }
    
    func setBuggyStartFindLine(){
        let firmataData = ["name":"bot_find_line","param":[2,180]] as [String : Any]
        sendCmdData(firmataData: firmataData)
    }
    
    func setBuggyStopFindLine(){
        let firmataData = ["name":"bot_find_stop","param":[0]] as [String : Any]
        sendCmdData(firmataData: firmataData)
    }
    
    
    func botBuzzerSong(index:Int)->Promise<String>{
//        buzzerSongStop = false
//        let song = BuggyBuzzer.music[1]
//        let beats = BuggyBuzzer.rhythm[1]
        var p : Promise<String> = Promise<String>.value("emptyPromise")
//        for index in 0..<song.count {
//            let note = BuggyBuzzer.tone_list[song[index]]
//            let duration = BuggyBuzzer.beatDuration * beats[index]
//            p = p.then({ result in
//                return self.botBuzzerPlay(note:note,duration:duration)
//            }).then({ result in
//                return after(seconds:0.01)
//            }).then({
//                return Promise{seal in seal.fulfill("OK")}
//            })
//        }
        return p
    }
    
    func botBuzzerPlay(note:Int,duration:Float)->Promise<String>{
//        if(!buzzerSongStop){
//            setBuggyBuzzerPlay(note:note, duration: duration)
//            setBuggyLightColor(left: UIColor.random.toHexString(), right: UIColor.random.toHexString())
//        }
        return after(seconds:TimeInterval(duration/1000)).then{return self.botBuzzerStop()}
    }
    
    func botBuzzerStop()->Promise<String> {
        setBuggyLightColor(left:"#000000" , right:"#000000")
        return after(seconds:0.02).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func botMusicStop(){
        let firmataData = ["name":"buggy_music_stop","param":[]] as [String : Any]
        sendCmdData(firmataData: firmataData)
    }
    
    func resetFirmata(){
        if(isConnected){
            buzzerSongStop = true
            let firmataData = ["name":"reset","param":[]] as [String : Any]
            self.sendCmdData(firmataData: firmataData)
            let firmataData1 = ["name":"bot_buzzer_stop","param":[]] as [String : Any]
            self.sendCmdData(firmataData: firmataData1)
        }
        
    }
    
    func uploadAndResetBuggy(){
        let path = Bundle.main.path(forResource:"AppBuggy", ofType:"bin")
        let data = NSData(contentsOfFile:path!)
        
        _ = engine?.resetBuggyAndUpload(data:data!).done({ (result) in
            print("上传完成")
        }).catch({ (error) in
            print("上传出错",error)
        })
    }
    
}

extension Communicator:BuggyEngineDelegate{
    
    func firmataReceviceData(inputData: [UInt8]) {
        print(inputData)
        delegate?.communicatorData(receviceData:inputData)
    }
    
    func buggyEngineState(state: BuggyState) {
        switch state {
        case .connectsuccess:
            print("连接成功")
            isConnected = true
        case .disconnect:
             isConnected = false
             print("连接断开")
        case .connectTimeOut:
            print("连接超时")
        case .firmataTimeOut:
            print("初始化超时")
            uploadAndResetBuggy()
        case .firmataExpired:
            print("版本不一致")
            uploadAndResetBuggy()
        case .firmatasuccess:
            print("初始化成功")
            delegate?.communicatorState(state:.connected)
        case .lineBreak:
            print("线断开")
        case .callBuggyTimeout:
            print("控制超时")
            after(seconds: 2).done({self.uploadAndResetBuggy()})
            
        default:
            break
        }
    }
    
    func hexUploadProgess(progess: Int) {
       
    }
    
    func powerWarning() {
        print("低电量警告")
    }
    
}
