//
//  ViewController.swift
//  BuggyEngine
//
//  Created by zidong0822 on 01/09/2019.
//  Copyright (c) 2019 zidong0822. All rights reserved.
//

import UIKit
import PromiseKit
import BuggyEngine
class ViewController: UIViewController {

    let buggyEngine = BuggyEngine()
    var label:UILabel?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blue
        buggyEngine.delegate = self
        buggyEngine.initBuggy()
        
        
        let button = UIButton(frame:CGRect(x:100, y: 100, width: 100, height: 30))
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        view.addSubview(button)
        
        
        label = UILabel(frame:CGRect(x:100, y: 100, width: 100, height: 30))
        label?.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(label!)
        
        
    }
    
    @objc func click(){
         buggyEngine.connectBuggy()
    }

    func uploadAndResetBuggy(){
        let path = Bundle.main.path(forResource:"AppBuggy", ofType:"bin")
        let data = NSData(contentsOfFile:path!)
        _ = buggyEngine.resetBuggyAndUpload(data:data!).done{_ in 
            print("上传成功")
            self.buggyEngine.connectBuggy()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController:BuggyEngineDelegate{
    
    func buggyEngineState(state: BuggyState) {
        switch state {
        case .connectsuccess:
            print("连接成功")
            label?.text = "连接成功"
        case .firmatasuccess:
            print("初始化成功")
            label?.text = "初始化成功"
            buggyEngine.sendData(data:[0xF0,0x79,0xF7])
        case .firmataTimeOut:
            print("初始化超时")
            label?.text = "初始化超时"
            uploadAndResetBuggy()
        case .firmataExpired:
            print("固件版本不一致")
            uploadAndResetBuggy()
        default:
            break
        }
        print("buggyEngineState",state == .connectTimeOut)
    }
    
    func firmataReceviceData(inputData:[UInt8]){
        print(inputData)
    }
}
