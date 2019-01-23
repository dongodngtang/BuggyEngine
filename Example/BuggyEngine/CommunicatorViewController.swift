//
//  CommunicatorViewController.swift
//  BuggyEngine_Example
//
//  Created by Harvey He on 2019/1/9.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import BuggyEngine

class CommunicatorViewController: UIViewController {
    
    var buggyEngine:BuggyEngine?
    override func viewDidLoad() {
        super.viewDidLoad()
        buggyEngine = BuggyEngine()
        buggyEngine?.initBuggy()
    }
    
    
}
