//
//  Configuration.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 11/07/23.
//

import Foundation
import RudderKit

class Constants {
    static let SDKMETRICS_URL = "https://sdk-metrics.rudderstack.com"
    static let MAX_METRICS_IN_A_BATCH: NSNumber = 10
    static let MAX_ERRORS_IN_A_BATCH: NSNumber = 5
    static let FLUSH_INTERVAL: NSNumber = 30
}

public struct Configuration {
    let logLevel: LogLevel
    let writeKey: String
    let sdkVersion: String
    let sdkMetricsUrl: String
    let maxErrorsInBatch: Int
    let maxMetricsInBatch: Int
    let flushInterval: Int
    
    public init(logLevel: LogLevel, writeKey: String, sdkVersion: String, sdkMetricsUrl: String? = nil, maxErrorsInBatch: NSNumber? = nil, maxMetricsInBatch: NSNumber? = nil, flushInterval: NSNumber? = nil) {
        self.logLevel = logLevel
        self.writeKey = writeKey
        self.sdkVersion = sdkVersion
        self.sdkMetricsUrl = sdkMetricsUrl ?? Constants.SDKMETRICS_URL
        self.maxErrorsInBatch = (maxErrorsInBatch ?? Constants.MAX_ERRORS_IN_A_BATCH).intValue
        self.maxMetricsInBatch = (maxMetricsInBatch ?? Constants.MAX_METRICS_IN_A_BATCH).intValue
        self.flushInterval = (flushInterval ?? Constants.FLUSH_INTERVAL).intValue
    }
}
