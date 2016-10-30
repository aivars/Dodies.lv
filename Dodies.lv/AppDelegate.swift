//
//  AppDelegate.swift
//  Dodies.lv
//
//  Created by Kristaps Grinbergs on 13/09/15.
//  Copyright © 2015 fassko. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import CocoaLumberjack
import RealmSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  
  func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
      schemaVersion: 1,
      migrationBlock: { migration, oldSchemaVersion in
      
        if (oldSchemaVersion < 1) {
          migration.deleteData(forType: DodiesPoint.className())
        }
    })

    let realm = try! Realm()
    
    return true
  }

  private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    
    Fabric.with([Crashlytics.self])
    
    DDLog.add(DDTTYLogger.sharedInstance()) // TTY = Xcode console
    DDLog.add(DDASLLogger.sharedInstance()) // ASL = Apple System Logs
    
    // Configure tracker from GoogleService-Info.plist.
    var configureError:NSError?
    GGLContext.sharedInstance().configureWithError(&configureError)
    assert(configureError == nil, "Error configuring Google services: \(configureError)")

    // Optional: configure GAI options.
    let gai = GAI.sharedInstance()
    gai?.trackUncaughtExceptions = true  // report uncaught exceptions
    gai?.logger.logLevel = GAILogLevel.verbose  // remove before app release
    
    UIApplication.shared.statusBarStyle = .lightContent
    UINavigationBar.appearance().barStyle = .black
    
    return true
  }


}
