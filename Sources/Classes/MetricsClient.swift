//
//  MetricsClient.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/06/23.
//

import Foundation
import RudderKit
import RSCrashReporter

public class MetricsClient {
    private let database: DatabaseOperations
    private let configuration: Configuration
    private let metricsUploader: MetricsUploader
    private let crashReporter: CrashReporter
    private var statsCollection = StatsCollection()
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        Logger.logLevel = configuration.logLevel
        database = Database(database: Database.openDatabase())
        let serviceManager: ServiceType = {
            let session: URLSession = {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 30
                configuration.timeoutIntervalForResource = 30
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return URLSession(configuration: configuration)
            }()
            return ServiceManager(urlSession: session, configuration: configuration)
        }()
        metricsUploader = MetricsUploader(database: database, configuration: configuration, serviceManager: serviceManager)
        metricsUploader.startUploadingMetrics()
        crashReporter = CrashReporter(database: database, statsCollection: statsCollection)
        crashReporter.startCollectingCrash()
    }
    
    public func process(metric: Metric) {
        if statsCollection.isMetricsEnabled {
            database.saveMetric(metric)
        } else {
            Logger.logDebug("Metrics collection is disabled")
        }
    }
    
    public var isErrorsCollectionEnabled: Bool {
        set {
            statsCollection.isErrorsEnabled = newValue
        }
        get {
            return statsCollection.isErrorsEnabled
        }
    }
    
    public var isMetricsCollectionEnabled: Bool {
        set {
            statsCollection.isMetricsEnabled = newValue
        }
        get {
            return statsCollection.isMetricsEnabled
        }
    }
    
    public func testCrash() {
        let array = ["abc"]
        print(array[5])
    }
}
