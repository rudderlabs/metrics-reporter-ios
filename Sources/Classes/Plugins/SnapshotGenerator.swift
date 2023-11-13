//
//  SnapshotGenerator.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 25/10/23.
//
import Foundation
import RudderKit


class SnapshotGenerator: Plugin {

    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
            startCapturingSnapshots()
        }
    }
    
    var database: DatabaseOperations?
    var configuration: Configuration?
    private var flushTimer: RepeatingTimer?
    private let syncQueue = DispatchQueue(label: "rudder.metrics.snapshot.generator")
    
    func initialSetup() {
        guard let metricsClient = self.metricsClient else { return }
        database = metricsClient.database
        configuration = metricsClient.configuration
    }

    func startCapturingSnapshots(completion: (() -> Void)? = nil) {
        guard let configuration = self.configuration else { return }
        flushTimer = RepeatingTimer(interval: TimeInterval(configuration.flushInterval)) { [weak self] in
            guard let self = self else { return }
            self.syncQueue.async {
                self.flushTimer?.suspend()
                self.captureSnapshot(startingFromId: Constants.Config.START_FROM) {
                    completion?()
                    self.flushTimer?.resume()
                }
            }
        }
    }
    
    func captureSnapshot(startingFromId id: Int, _ completion: @escaping () -> Void) {
        guard let database = self.database, let configuration = self.configuration else { return }
        let (metricList, lastMetricId) = database.fetchMetrics(startingFromId: id, withLimit: configuration.maxMetricsInBatch)
        let errorList = database.fetchErrors(count: configuration.maxErrorsInBatch)
        if metricList.isEmpty && (errorList?.isEmpty ?? true) {
            Logger.logDebug("No metrics or errors found in db")
            completion()
            return
        }
        if let batchJSON = getJSONString(from: metricList, and: errorList) {
            let snapshotEntity = self.database?.saveSnapshot(batch: batchJSON)
            if snapshotEntity != nil {
                self.updateMetricList(metricList)
                self.clearErrorList(errorList)
                // flush the snapshots
                self.metricsClient?.flushMetricsSnapshots()
            }
            if let lastMetricId = lastMetricId {
                captureSnapshot(startingFromId: lastMetricId + 1, completion)
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
