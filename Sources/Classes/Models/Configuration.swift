//
//  Configuration.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 11/07/23.
//

import Foundation
import RudderKit

public struct Configuration {
    let logLevel: LogLevel
    let writeKey: String
    let sdkVersion: String
    let sdkMetricsUrl: String
    
    public init(logLevel: LogLevel, writeKey: String, sdkVersion: String, sdkMetricsUrl: String = "https://sdk-metrics.dev-rudder.rudderlabs.com") {
        self.logLevel = logLevel
        self.writeKey = writeKey
        self.sdkVersion = sdkVersion
        self.sdkMetricsUrl = sdkMetricsUrl
    }
}
