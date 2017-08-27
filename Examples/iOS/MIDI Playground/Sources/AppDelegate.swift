//
//  AppDelegate.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/29/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit

extension UIColor {
	func colorByInterpolatingWith(otherColor: UIColor, amount: CGFloat) -> UIColor {
		let clampedAmount = min(max(amount, 0.0), 1.0)
		
		guard let startComponent = self.cgColor.components,
			let endComponent = otherColor.cgColor.components else {
				return self
		}
		
		let startAlpha = self.cgColor.alpha
		let endAlpha = otherColor.cgColor.alpha
		
		let r = startComponent[0] + (endComponent[0] - startComponent[0]) * clampedAmount
		let g = startComponent[1] + (endComponent[1] - startComponent[1]) * clampedAmount
		let b = startComponent[2] + (endComponent[2] - startComponent[2]) * clampedAmount
		let a = startAlpha + (endAlpha - startAlpha) * clampedAmount
		
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

