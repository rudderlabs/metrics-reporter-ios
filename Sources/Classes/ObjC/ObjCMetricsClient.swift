//
//  ObjCMetricsClient.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 17/07/23.
//

import Foundation

@objc(RSMetricClient)
public class ObjCMetricsClient: NSObject {
    let metricClient: MetricsClient
    
    @objc
    public init(configuration: ObjCConfiguration) {
        metricClient = MetricsClient(configuration: configuration.configuration)
    }
}

extension ObjCMetricsClient {
    @objc(process:)
    public func process(metric: ObjCMetric) {
        if let metric = metric.toSwiftMetric() {
            metricClient.process(metric: metric)
        }
    }
}
