//
//  BuggyEngineDelegate.swift
//  QooBot
//
//  Created by Harvey He on 2018/12/18.
//  Copyright © 2018 Harvey He. All rights reserved.
//

@objc public protocol BuggyEngineDelegate : NSObjectProtocol {
    
    @objc optional func firmataReceviceData(inputData:[UInt8])
    @objc optional func scratchIsReady()
    @objc optional func deviceDisconnected()
    @objc optional func deviceBreak()
    @objc optional func deviceExceptionBreak()
    @objc optional func powerWarning()
    
}
