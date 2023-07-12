//
//  Metric.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/06/23.
//

import Foundation

@frozen
public enum MetricType: String {
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

public protocol Metric {
    var name: String { get set }
    var labels: [String: String]? { get set }
    var type: MetricType { get set }
}

public struct Count: Metric {
    public var name: String
    public var labels: [String: String]?
    public var type: MetricType = .count
    public var value: Int
    
    public init(name: String, labels: [String: String]? = nil, value: Int) {
        self.name = name
        self.labels = labels
        self.value = value
    }
}

public struct Gauge: Metric {
    public var name: String
    public var labels: [String: String]?
    public var type: MetricType = .gauge
    public var value: Float
    
    public init(name: String, labels: [String: String]? = nil, value: Float) {
        self.name = name
        self.labels = labels
        self.value = value
    }
}

struct MetricList {
    var countList: [Count]?
    var gaugeList: [Gauge]?
    
    var count: Int {
        return (countList?.count ?? 0) + (gaugeList?.count ?? 0)
    }
    
    init(countList: [Count]?, gaugeList: [Gauge]?) {
        self.countList = countList
        self.gaugeList = gaugeList
    }
    
    func toDict() -> [[String: Any]]? {
        var metrics = [[String: Any]]()
        if let countList = countList {
            metrics.append(contentsOf: getMetricsDict(metricList: countList))
        }
        if let gaugeList = gaugeList {
            metrics.append(contentsOf: getMetricsDict(metricList: gaugeList))
        }
        guard !metrics.isEmpty else {
            return nil
        }
        return metrics
    }
    
    func getMetricsDict<M: Metric>(metricList: [M]) -> [[String: Any]] {
        var metrics = [[String: Any]]()
        for list in metricList {
            var metric: [String: Any] = [
                "name": list.name,
                "type": list.type.rawValue
            ]
            if let labels = list.labels {
                metric["labels"] = labels
            }
            switch list {
                case let m as Count:
                    metric["value"] = Float(m.value)
                case let m as Gauge:
                    metric["value"] = m.value
                default:
                    break
            }
            metrics.append(metric)
        }
        return metrics
    }
}
