//
//  Utilities.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 29/08/23.
//

import Foundation
@testable import MetricsReporter

class OutputReaderPlugin: Plugin {
    var metricsClient: MetricsClient?
    
    var metrics = [Metric]()
    var lastMetric: Metric? = nil
    
    func execute<M>(metric: M?) -> M? where M : Metric {
        lastMetric = metric
        if let m = lastMetric as? Count {
            metrics.append(m)
        }
        return metric
    }
}
