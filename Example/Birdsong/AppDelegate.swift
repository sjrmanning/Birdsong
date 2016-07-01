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

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()

        self.window!.rootViewController = ViewController()

        return true
    }
}

