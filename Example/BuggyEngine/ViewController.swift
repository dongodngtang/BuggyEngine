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
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blue
        buggyEngine.delegate = self
        buggyEngine.initBuggy()
        
        
        let button = UIButton(frame:CGRect(x:100, y: 100, width: 100, height: 30))
        button.backgroundColor = .red
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func click(){
         buggyEngine.connectBuggy()
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
        case .firmatasuccess:
            print("初始化成功")
        case .firmataTimeOut:
            print("初始化超市")
        default:
            break
        }
        print("buggyEngineState",state == .connectTimeOut)
    }
    
    func firmataReceviceData(inputData:[UInt8]){
        
    }
}
