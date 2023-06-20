//
//  MetricsUploader.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 12/07/23.
//

import Foundation
import RudderKit

let START_FROM = 1

class MetricsUploader {
    private let database: DatabaseOperations
    private let configuration: Configuration
    private var flushTimer: RepeatingTimer?
    private let serviceManager: ServiceType
    private let syncQueue = DispatchQueue(label: "uploadQueue.rudder.com")
    
    init(database: DatabaseOperations, configuration: Configuration, serviceManager: ServiceType) {
        self.database = database
        self.configuration = configuration
        self.serviceManager = serviceManager
    }
    
    func startUploadingMetrics() {
        flushTimer = RepeatingTimer(interval: TimeInterval(configuration.flushInterval)) { [weak self] in
            guard let self = self else { return }
            self.syncQueue.async {
                self.flushMetrics(from: START_FROM, to: self.configuration.maxMetricsInBatch)
            }
        }
    }
    
    func flushMetrics(from: Int, to: Int) {
        let metricList = database.fetchMetrics(from: from, to: to)
        guard metricList.isNotEmpty else {
            Logger.logDebug("No metrics found in db")
            return
        }
        var isDataAvailable = false
        if metricList.count == configuration.maxMetricsInBatch {
            isDataAvailable = true
        }
        if let params = getJSONString(from: metricList) {
            if let error = flushMetricsToServer(params: params) {
                Logger.logError("Got error code: \(error.code), Aborting")
            } else {
                Logger.logDebug("Metrics uploaded successfully")
                self.updateMetricList(metricList: metricList)
                if isDataAvailable {
                    self.flushMetrics(from: to + 1, to: to + configuration.maxMetricsInBatch)
                }
            }
        } else {
            Logger.logDebug("No metrics or errors found in db for flushing")
            if isDataAvailable {
                flushMetrics(from: to + 1, to: to + configuration.maxMetricsInBatch)
            }
        }
    }
    
    func flushMetricsToServer(params: String) -> NSError? {
        var error: NSError?
        let semaphore = DispatchSemaphore(value: 0)
        serviceManager.sdkMetrics(params: params, { result in
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
            for count in countList {
                database.updateMetric(count)
            }
        }
        if let gaugeList = metricList.gaugeList {
            for gauge in gaugeList {
                database.updateMetric(gauge)
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
                "sdk_version": configuration.sdkVersion,
                "write_key": configuration.writeKey
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
