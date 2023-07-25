//
//  MetricsClient.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/06/23.
//

import Foundation
import RudderKit

public class MetricsClient {
    private let database: DatabaseOperations
    private let configuration: Configuration
    private let metricsUploader: MetricsUploader
    private var _statsCollection = StatsCollection()
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        Logger.logLevel = configuration.logLevel
        database = Database(database: Database.openDatabase())
        let serviceManger: ServiceType = {
            let session: URLSession = {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 30
                configuration.timeoutIntervalForResource = 30
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return URLSession(configuration: configuration)
            }()
            return ServiceManager(urlSession: session, configuration: configuration)
        }()
        metricsUploader = MetricsUploader(database: database, configuration: configuration, serviceManger: serviceManger)
    }
    
    public func process(metric: Metric) {
        if _statsCollection.isMetricsEnabled {
            database.saveMetric(metric)
        }
    }
    
    public var isErrorsCollectionEnabled: Bool {
        set {
            _statsCollection.isErrorsEnabled = newValue
        }
        get {
            return _statsCollection.isErrorsEnabled
        }
    }
    
    public var isMetricsCollectionEnabled: Bool {
        set {
            _statsCollection.isMetricsEnabled = newValue
        }
        get {
            return _statsCollection.isMetricsEnabled
        }
    }
}
