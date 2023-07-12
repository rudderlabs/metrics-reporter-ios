//
//  MetricsUploader.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 12/07/23.
//

import Foundation
import RudderKit

class MetricsUploader {
    private let database: DatabaseOperations?
    private let configuration: Configuration
    private var flushTimer: RepeatingTimer?
    private var serviceManger: ServiceType?

    init(database: DatabaseOperations?, configuration: Configuration) {
        self.database = database
        self.configuration = configuration
        let session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 30
            configuration.requestCachePolicy = .useProtocolCachePolicy
            return URLSession(configuration: configuration)
        }()
        serviceManger = ServiceManager(urlSession: session)
        flushTimer = RepeatingTimer(interval: TimeInterval(30)) { [weak self] in
            guard let self = self else { return }
            self.flushMetrics(from: 1, to: 20)
        }
    }
    
    func flushMetrics(from: Int, to: Int) {
        if let metricList = database?.fetchMetrics(from: from, to: to) {
            var isDataAvailable = false
            if metricList.count == (to - from) {
                isDataAvailable = true
            }
            if let payload = getJSON(from: metricList) {
                serviceManger?.sdkMetrics(params: payload, { result in
                    switch result {
                        case .success(_):
                            if isDataAvailable {
                                self.flushMetrics(from: to, to: to + 20)
                            }
                            self.updateMetricList(metricList: metricList)
                        case .failure(let error):
                            break
                    }
                })
            }
        } else {
            Logger.logDebug("")
        }
    }
    
    func updateMetricList(metricList: MetricList) {
        if let countList = metricList.countList {
            for list in countList {
                database?.updateMetric(list)
            }
        }
        if let gaugeList = metricList.gaugeList {
            for list in gaugeList {
                database?.updateMetric(list)
            }
        }
    }
    
    func getJSON(from metricList: MetricList) -> String? {
        guard let metrics = metricList.toDict() else {
            return nil
        }
        var payload: [String: Any] = [
            "version": "1",
            "source": [
                "name": "ios",
                "sdk_version": configuration.sdkVersion,
                "install_type": configuration.installType
            ]
        ]
        payload["metrics"] = metrics
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted) else {
            return nil
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
}
