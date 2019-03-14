//
//  UIViewController+Extension.swift
//  MakeApp
//
//  Created by Harvey He on 2019/2/22.
//  Copyright © 2019 harvey. All rights reserved.
//
import UIKit
extension UIViewController {
    class func current(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return current(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return current(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return current(base: presented)
        }
        return base
    }
}
