//
//  AppDelegate.swift
//  InfiniteKit
//
//  Created by duan on 02/08/2019.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)
        let vc = ViewController(nibName: nil, bundle: nil)
        let navVC = UINavigationController(rootViewController: vc)
        navVC.navigationBar.prefersLargeTitles = true
        window.rootViewController = navVC
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

}

