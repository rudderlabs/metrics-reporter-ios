//
//  AppDelegate.swift
//  SampleSwift
//
//  Created by Pallab Maiti on 19/06/23.
//

import UIKit
import MetricsReporter
import RudderKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var client: MetricsClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let configuration = Configuration(logLevel: .debug, writeKey: "WRITE_KEY", sdkVersion: "1.3.3", sdkMetricsUrl: "SDK_Metrics_Url", maxMetricsInBatch: 1, flushInterval: 1)
        client = MetricsClient(configuration: configuration)
        client?.isMetricsCollectionEnabled = true
        client?.isErrorsCollectionEnabled = true
        
        for i in 1..<61 {
            let countMetric = Count(name: "test_count_\(i)", labels: ["key_\(i)": "value_\(i)"], value: i + 1)
            client?.process(metric: countMetric)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

