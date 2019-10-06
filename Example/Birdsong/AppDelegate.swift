//
//  AppDelegate.swift
//  Birdsong
//
//  Created by Simon Manning on 06/30/2016.
//  Copyright (c) 2016 Simon Manning. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor.white
        self.window!.makeKeyAndVisible()

        self.window!.rootViewController = ViewController()

        return true
    }
}

