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
    let maxErrorsInBatch: Int
    let maxMetricsInBatch: Int
    let flushInterval: Int
    
    public init(logLevel: LogLevel, writeKey: String, sdkVersion: String, sdkMetricsUrl: String? = nil, maxErrorsInBatch: NSNumber? = nil, maxMetricsInBatch: NSNumber? = nil, flushInterval: NSNumber? = nil) {
        self.logLevel = logLevel
        self.writeKey = writeKey
        self.sdkVersion = sdkVersion
        self.sdkMetricsUrl = sdkMetricsUrl ?? Constants.Config.SDKMETRICS_URL
        self.maxErrorsInBatch = (maxErrorsInBatch ?? Constants.Config.MAX_ERRORS_IN_A_BATCH).intValue
        self.maxMetricsInBatch = (maxMetricsInBatch ?? Constants.Config.MAX_METRICS_IN_A_BATCH).intValue
        self.flushInterval = (flushInterval ?? Constants.Config.FLUSH_INTERVAL).intValue
    }
}
