//
//  AppDelegate.swift
//  FloatingLabelTextFieldDemo
//
//  Created by Eric Baker on 8/Nov/2017.
//  Copyright © 2017 DuneParkSoftware, LLC. All rights reserved.
//

import FloatingLabelTextField
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        FloatingLabelTextField.appearance().useBottomLineBorderStyle = true
        
        return true
    }
}
