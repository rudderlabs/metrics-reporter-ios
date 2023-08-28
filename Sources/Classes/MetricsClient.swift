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
    
    /// Initialize Metrics Client
    /// - Parameter configuration: Instance of Configuration struct to configure Metrics Client
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
    
    /// Send metrics to server
    /// - Parameter metric: Instance of Count/Gauge which will be processed
    public func process(metric: Metric) {
        if statsCollection.isMetricsEnabled {
            database.saveMetric(metric)
        } else {
            Logger.logDebug("Metrics collection is disabled")
        }
    }
    
    /// Enable/Disable error/crash collection
    public var isErrorsCollectionEnabled: Bool {
        set {
            statsCollection.isErrorsEnabled = newValue
            crashReporter.isErrorsCollectionEnabled = newValue
        }
        get {
            return statsCollection.isErrorsEnabled
        }
    }
    
    /// Enable/Disable metric collection
    public var isMetricsCollectionEnabled: Bool {
        set {
            statsCollection.isMetricsEnabled = newValue
            crashReporter.isMetricsCollectionEnabled = newValue
        }
        get {
            return statsCollection.isMetricsEnabled
        }
    }
    
    /// For internal testing purpose only. Don't use this API.
    public func testCrash() {
        let array = ["abc"]
        print(array[5])
    }
}
