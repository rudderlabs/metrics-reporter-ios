//
//  BatchGenerator.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 25/10/23.
//
import Foundation
import RudderKit


class BatchGenerator: Plugin {
    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
            startBatching()
        }
    }
    
    var database: DatabaseOperations?
    var configuration: Configuration?
    private var flushTimer: RepeatingTimer?
    private let syncQueue = DispatchQueue(label: "rudder.metrics.batchgenerator")
    
    func initialSetup() {
        guard let metricsClient = self.metricsClient else { return }
        database = metricsClient.database
        configuration = metricsClient.configuration
    }
    
    func startBatching(completion: (() -> Void)? = nil) {
        guard let database = self.database, let configuration = self.configuration else { return }
        var sleepCount = 0
        flushTimer = RepeatingTimer(interval: TimeInterval(1)) { [weak self] in
            guard let self = self else { return }
            self.syncQueue.async {
                let errorCount = database.getErrorsCount()
                if (errorCount >= configuration.dbCountThreshold) || (sleepCount >= configuration.flushInterval) {
                    self.flushTimer?.suspend()
                    self.createBatch(startingFromId: Constants.Config.START_FROM) {
                        completion?()
                        sleepCount = 0
                        self.flushTimer?.resume()
                    }
                } else {
                    sleepCount += 1
                }
            }
        }
    }
    
    func createBatch(startingFromId id: Int, _ completion: @escaping () -> Void) {
        guard let database = self.database, let configuration = self.configuration else { return }
        let (metricList, lastMetricId) = database.fetchMetrics(startingFromId: id, withLimit: configuration.maxMetricsInBatch)
        let errorList = database.fetchErrors(count: configuration.maxErrorsInBatch)
        if metricList.isEmpty && (errorList?.isEmpty ?? true) {
            Logger.logDebug("No metrics or errors found in db")
            completion()
            return
        }
        if let batchJSON = getJSONString(from: metricList, and: errorList) {
            self.database?.saveBatch(batch: batchJSON)
            self.updateMetricList(metricList)
            self.clearErrorList(errorList)
            if let lastMetricId = lastMetricId {
                createBatch(startingFromId: lastMetricId + 1, completion)
            } else {
                completion()
            }
        } else {
            completion()
        }
    }
    
    func getJSONString(from metricList: MetricList, and errorList: [ErrorEntity]?) -> String? {
        guard let configuration = self.configuration else { return nil }
        let metrics = metricList.toDict()
        if metrics == nil && errorList == nil {
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
        if let metrics = metrics {
            payload["metrics"] = metrics
        }
        if let errorList = errorList {
            payload["errors"] = errorList.toDict(configuration: configuration)
        }
        return payload.toJSONString()
    }
    
    func updateMetricList(_ metricList: MetricList) {
           if let countList = metricList.countList {
               for count in countList {
                   database?.updateMetric(count)
               }
           }
           if let gaugeList = metricList.gaugeList {
               for gauge in gaugeList {
                   database?.updateMetric(gauge)
               }
           }
       }
       
       func clearErrorList(_ errorList: [ErrorEntity]?) {
           if let errorList = errorList {
               database?.clearErrorList(errorList)
           }
       }
}

extension [ErrorEntity] {
    func toDict(configuration: Configuration) -> [String: Any] {
        let notifier = [
            "name": "Bugsnag iOS",
            "version": configuration.sdkVersion,
            "url": "https://github.com/rudderlabs/rudder-sdk-ios"
        ]
        
        var eventList = [[String: Any]]()
        for item in self {
            if let events = item.eventList {
                eventList.append(contentsOf: events)
            }
        }
        
        return [
            "payloadVersion": "5",
            "notifier": notifier,
            "events": eventList
        ]
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
