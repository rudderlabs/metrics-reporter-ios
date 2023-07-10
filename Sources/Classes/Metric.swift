//
//  Metric.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/06/23.
//

import Foundation

@frozen enum MetricType: String {
    case count = "count"
    case gauge = "gauge"
}

extension String {
    func getMetricType() -> MetricType {
        if self == "gauge" {
            return .gauge
        }
        return .count
    }
}

protocol Metric: Equatable {
    var name: String { get set }
    var attributes: [String: String]? { get set }
    var type: MetricType { get set }
}

struct Count: Metric {
    var name: String
    var attributes: [String: String]?
    var type: MetricType = .count
    var value: Int
    
    init(name: String, attributes: [String: String]? = nil, value: Int) {
        self.name = name
        self.attributes = attributes
        self.value = value
    }
}

struct Gauge: Metric {
    var name: String
    var attributes: [String: String]?
    var type: MetricType = .gauge
    var value: Float
    
    init(name: String, attributes: [String: String]? = nil, value: Float) {
        self.name = name
        self.attributes = attributes
        self.value = value
    }
}
