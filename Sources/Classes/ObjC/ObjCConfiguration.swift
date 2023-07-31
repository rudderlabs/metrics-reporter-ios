//
//  ObjCConfiguration.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 17/07/23.
//

import Foundation
import RudderKit

@objc(RSMetricConfiguration)
public class ObjCConfiguration: NSObject {
    var configuration: Configuration
    
    @objc
    public init(logLevel: Int, writeKey: String, sdkVersion: String) {
        configuration = Configuration(logLevel: LogLevel(rawValue: logLevel) ?? .error, writeKey: writeKey, sdkVersion: sdkVersion)
    }
    
    @objc
    public init(logLevel: Int, writeKey: String, sdkVersion: String, sdkMetricsUrl: String?, maxErrorsInBatch: NSNumber?, maxMetricsInBatch: NSNumber?, flushInterval: NSNumber?) {
        configuration = Configuration(logLevel: LogLevel(rawValue: logLevel) ?? .error, writeKey: writeKey, sdkVersion: sdkVersion, sdkMetricsUrl: sdkMetricsUrl, maxErrorsInBatch: maxErrorsInBatch, maxMetricsInBatch: maxMetricsInBatch, flushInterval: flushInterval)
    }
}
