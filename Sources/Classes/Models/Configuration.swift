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
    var sdkMetricsUrl: String
    var maxErrorsInBatch: Int
    var maxMetricsInBatch: Int
    var flushInterval: Int
    var dbCountThreshold: Int
    
    public init(logLevel: LogLevel, writeKey: String, sdkVersion: String, sdkMetricsUrl: String, maxErrorsInBatch: Int? = nil, maxMetricsInBatch: Int? = nil, flushInterval: Int? = nil, dbCountThreshold: Int? = nil) {
        self.logLevel = logLevel
        self.writeKey = writeKey
        self.sdkVersion = sdkVersion
        self.sdkMetricsUrl = sdkMetricsUrl
        self.maxErrorsInBatch = maxErrorsInBatch ?? Constants.Config.MAX_ERRORS_IN_A_BATCH
        self.maxMetricsInBatch = maxMetricsInBatch ?? Constants.Config.MAX_METRICS_IN_A_BATCH
        self.flushInterval = flushInterval ?? Constants.Config.FLUSH_INTERVAL
        self.dbCountThreshold = dbCountThreshold ?? Constants.Config.DB_COUNT_THRESHOLD
    }
}
