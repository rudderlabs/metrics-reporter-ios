//
//  BatchUploader.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 02/11/23.
//

import Foundation
import RudderKit


class BatchUploader: Plugin {
    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
            addBatchTableObserver()
        }
    }
    
    let MAX_ATTEMPTS = 5
    var database: DatabaseOperations?
    var configuration: Configuration?
    var uploadInProgress: Bool = false
    var serviceManager: ServiceType?
    private let queue = DispatchQueue(label: "rudder.metrics.batchuploader")
    
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
        startUploading()
    }
    
    func startUploading() {
        RepeatingTimer(interval: TimeInterval(30)) { [weak self] in
            guard let self = self else { return }
            uploadBatches()
        }
    }
    
    func onNewBatchInsertion() {
        uploadBatches()
    }
    
    func addBatchTableObserver() {
        DatabaseObserver.addObserver(tableName: "batch", changeType: .insert, callback:onNewBatchInsertion)
    }
    
    func uploadBatches() {
        if(!self.uploadInProgress) {
            self.uploadInProgress = true
            startUploadingBatchesWithBackOff(){
                self.uploadInProgress = false
            }
        }
    }
    
    func startUploadingBatchesWithBackOff(currentAttempt:Int = 0, backoffDelay: TimeInterval = 2.0, _ completion: @escaping () -> Void) {
        if currentAttempt < MAX_ATTEMPTS {
            queue.async {
                self.uploadBatch() { [weak self] result in
                    guard let self = self else {
                        completion()
                        return }
                    if (!result) {
                        queue.asyncAfter(deadline: .now() + backoffDelay, execute: {
                            self.startUploadingBatchesWithBackOff(currentAttempt: currentAttempt+1, backoffDelay: backoffDelay * 2, completion)
                        })
                    } else {
                        completion()
                    }
                }
            }
        } else {
            Logger.logDebug("Failed to send batches to metric service even after backing off with retries")
            completion()
        }
    }
    
    func uploadBatch(_ wasUploadSuccessful: @escaping (Bool) -> Void) {
        guard let database = self.database else {
            wasUploadSuccessful(false)
            return
        }
        
        if let batch = database.getBatch(), var batchDict = batch.batch.toDictionary() {
            batchDict["id"] = batch.uuid
            if let requestBody = batchDict.toJSONString() {
                serviceManager?.sdkMetrics(params: requestBody, { [weak self] (result) in
                    guard let self = self else {
                        Logger.logError("Failed to Upload Batch, Aborting.")
                        wasUploadSuccessful(false)
                        return
                    }
                    switch result {
                    case .success(_):
                        Logger.logDebug("Metrics Batch uploaded successfully")
                        database.clearBatch(batch: batch)
                        uploadBatch(wasUploadSuccessful)
                    case .failure(let error):
                        Logger.logError("Failed to Upload Batch, Got error code: \(error.code), Aborting.")
                        wasUploadSuccessful(false)
                    }
                })
            } else {
                Logger.logDebug("errors while generating the payload, retrying again")
                wasUploadSuccessful(false)
            }
        } else {
            Logger.logDebug("no more batches in the db")
            wasUploadSuccessful(true)
        }
    }
}

extension String {
    func toDictionary() -> [String:Any]? {
        if let jsonData = self.data(using: .utf8) {
            guard let dictionary = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                return nil
            }
            return dictionary
        }
        return nil
    }
}
