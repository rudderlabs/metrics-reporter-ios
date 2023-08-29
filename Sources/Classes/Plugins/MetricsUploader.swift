//
//  MetricsUploader.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 12/07/23.
//

import Foundation
import RudderKit


class MetricsUploader: Plugin {
    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
            startUploadingMetrics()
        }
    }
    
    var database: DatabaseOperations?
    var configuration: Configuration?
    private var flushTimer: RepeatingTimer?
    var serviceManager: ServiceType?
    private let syncQueue = DispatchQueue(label: "uploadQueue.rudder.com")
    
    func initialSetup() {
        guard let metricsClient = self.metricsClient else { return }
        database = metricsClient.database
        configuration = metricsClient.configuration
        serviceManager = {
            let session: URLSession = {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 30
                configuration.timeoutIntervalForResource = 30
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return URLSession(configuration: configuration)
            }()
            return ServiceManager(urlSession: session, configuration: metricsClient.configuration)
        }()
    }
    
    func startUploadingMetrics() {
        guard let configuration = self.configuration else { return }
        flushTimer = RepeatingTimer(interval: TimeInterval(configuration.flushInterval)) { [weak self] in
            guard let self = self else { return }
            self.syncQueue.async {
                self.flushMetrics(from: Constants.START_FROM, to: configuration.maxMetricsInBatch)
            }
        }
    }
    
    func execute<M: Metric>(metric: M?) -> M? {
        guard let database = self.database, let metric = metric else { return metric }
        database.saveMetric(metric)
        return metric
    }
    
    func flushMetrics(from: Int, to: Int) {
        guard let database = self.database, let configuration = self.configuration else { return }
        let metricList = database.fetchMetrics(from: from, to: to)
        let errorList = database.fetchErrors(count: configuration.maxErrorsInBatch)
        if metricList.isEmpty && (errorList?.isEmpty ?? true) {
            Logger.logDebug("No metrics or errors found in db")
            return
        }
        var isDataAvailable = false
        if metricList.count == configuration.maxMetricsInBatch {
            isDataAvailable = true
        }
        if errorList?.count == configuration.maxErrorsInBatch {
            isDataAvailable = true
        }
        if let params = getJSONString(from: metricList, and: errorList) {
            if let error = flushMetricsToServer(params: params) {
                Logger.logError("Got error code: \(error.code), Aborting.")
            } else {
                Logger.logDebug("Metrics uploaded successfully")
                updateMetricList(metricList)
                clearErrorList(errorList)
                if isDataAvailable {
                    flushMetrics(from: to + 1, to: to + configuration.maxMetricsInBatch)
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
        serviceManager?.sdkMetrics(params: params, { result in
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
