//
//  TestViewController.swift
//  BuggyEngine_Example
//
//  Created by Harvey He on 2019/4/3.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import PromiseKit
import BuggyEngine
class TestViewController: UIViewController {
    
    
     var communicator = Communicator.getInstance()
    override func viewDidLoad() {
        view.backgroundColor = .white
        
        let button = UIButton(frame:CGRect(x:(view.frame.width-100)/2, y: (view.frame.height-100)/2, width: 100, height: 100))
        button.setTitle("蓝牙连接", for: .normal)
        button.setTitleColor(UIColor.black, for:.normal)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
        view.addSubview(button)
        
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDiconnected), name: nil, object: BluetoothManager.getInstance())
    }
    
    @objc func deviceDiconnected(){
        print("蓝牙断开")
        communicator.disConnectDevice()
    }
    
    @objc func click(){
        communicator.connectDevice()
    }

}
