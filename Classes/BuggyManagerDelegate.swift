//
//  BuggyDelegate.swift
//  QooBot
//
//  Created by Harvey He on 2018/12/18.
//  Copyright © 2018 Harvey He. All rights reserved.
//

@objc public protocol BuggyManagerDelegate : NSObjectProtocol {
    
    // 处理接收正常
    @objc optional func parseReceviceData(inputData:[UInt8])
    @objc optional func firmataReceviceData(inputData:[UInt8])
    @objc optional func hexUploadProgess(progess:Int)
    @objc optional func deviceBetteryLevel(data:Data)
    @objc optional func deviceLineBreak()
    
}

