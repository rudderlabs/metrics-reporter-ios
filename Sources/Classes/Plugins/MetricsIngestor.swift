//
//  MetricsIngestor.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 12/07/23.
//

import Foundation
import RudderKit


class MetricsIngestor: MetricsPlugin {
    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
        }
    }
    
    var database: DatabaseOperations?
    
    func initialSetup() {
        guard let metricsClient = self.metricsClient else { return }
        database = metricsClient.database
    }
    
    func execute<M: Metric>(metric: M?) -> M? {
        guard let database = self.database, let metric = metric else { return metric }
        database.saveMetric(metric)
        return metric
    }
}
