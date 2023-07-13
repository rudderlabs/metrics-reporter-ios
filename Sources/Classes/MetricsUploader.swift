//
//  MetricsUploader.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 12/07/23.
//

import Foundation
import RudderKit

let MAX_METRICS_IN_A_BATCH = 20
let START_FROM = 1

class MetricsUploader {
    private let database: DatabaseOperations?
    private let configuration: Configuration
    private var flushTimer: RepeatingTimer?
    private var serviceManger: ServiceType?
    private let syncQueue = DispatchQueue(label: "uploadQueue.rudder.com")
    
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
            self.flushMetrics(from: START_FROM, to: MAX_METRICS_IN_A_BATCH)
        }
    }
    
    func flushMetrics(from: Int, to: Int) {
        syncQueue.sync {
            guard let metricList = database?.fetchMetrics(from: from, to: to) else {
                Logger.logDebug("")
                return
            }
            var isDataAvailable = false
            if metricList.count == MAX_METRICS_IN_A_BATCH {
                isDataAvailable = true
            }
            if let params = getJSONString(from: metricList) {
                var count = 0
                while true {
                    count += 1
                    if let error = flushMetricsToServer(params: params) {
                        Logger.logDebug("Retrying in \(count)s")
                        sleep(UInt32(count * 1000000))
                    } else {
                        if isDataAvailable {
                            self.flushMetrics(from: to + 1, to: to + MAX_METRICS_IN_A_BATCH)
                        }
                        self.updateMetricList(metricList: metricList)
                        break
                    }
                }
            } else {
                
            }
        }
    }
    
    func flushMetricsToServer(params: String) -> NSError? {
        var error: NSError?
        let semaphore = DispatchSemaphore(value: 0)
        serviceManger?.sdkMetrics(params: params, { result in
            switch result {
                case .success(_):
                    break
                case .failure(let err):
                    error = err
            }
            semaphore.signal()
        })
        semaphore.wait()
        return error
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
    
    func getJSONString(from metricList: MetricList) -> String? {
        guard let metrics = metricList.toDict() else {
            return nil
        }
        var payload: [String: Any] = [
            "version": "1",
            "source": [
                "name": "ios",
                "sdk_version": configuration.sdkVersion
            ]
        ]
        payload["metrics"] = metrics
        return payload.toJSONString()
    }
}

extension Dictionary {
    func toJSONString() -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else {
            return nil
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
}
