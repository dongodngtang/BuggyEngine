//
//  Task+Extension.swift
//  BuggyEngine
//
//  Created by Harvey He on 2019/1/8.
//

import Foundation

typealias Task = (_ cancle : Bool) -> Void

func delay(_ time: TimeInterval, task: @escaping() -> ()) -> Task? {
    
    func dispatch_later(block: @escaping()->()) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }
    
    var closure : (() -> Void)? = task
    var result : Task?
    
    let delayedClosure : Task = {
        cancle in
        if let internalClosure = closure {
            if cancle == false {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    
    return result
}

func cancel(_ task: Task?) {
    task?(true)
}
