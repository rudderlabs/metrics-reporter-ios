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
    
    public init(configuration: Configuration) {
        self.configuration = configuration
        Logger.logLevel = configuration.logLevel
        database = Database(database: Database.openDatabase())
    }
    
    public func process(metric: Metric) {
        database.saveMetric(metric)
    }
}
