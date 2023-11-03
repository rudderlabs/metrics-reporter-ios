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
    
    func execute<M: Metric>(metric: M?) -> M? {
        return metric
    }
    
    func onNewBatchInsertion() {
        startUploading()
    }
    
    func startUploading() {
        if(!self.uploadInProgress) {
            self.uploadInProgress = true
            startUploadingBatchesWithBackOff(){
                self.uploadInProgress = false
            }
        } else {
        }
    }
    
    func addBatchTableObserver() {
        DatabaseObserver.addObserver(tableName: "batch", changeType: .insert, callback:onNewBatchInsertion)
    }
    
    func startUploadingBatchesWithBackOff(currentAttempt:Int = 0, backoffDelay: TimeInterval = 2.0, _ completion: @escaping () -> Void) {
        if currentAttempt < 5 {
            queue.async {
                self.uploadBatch() { result in
                    if (!result) {
                        self.queue.asyncAfter(deadline: .now() + backoffDelay, execute: {
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
    
    func uploadBatch(_ completion: @escaping (Bool) -> Void) {
        
        guard let database = self.database else {
            completion(true)
            return
        }
        
        
        
        if let batch = database.getBatch(), var batchDict = batch.batch.toDictionary() {
            batchDict["id"] = batch.uuid
            if let requestBody = batchDict.toJSONString() {
                serviceManager?.sdkMetrics(params: requestBody, { (result) in
                    switch result {
                    case .success(_):
                        Logger.logDebug("Metrics Batch uploaded successfully")
                        database.clearBatch(batch: batch)
                        self.uploadBatch(completion)
                    case .failure(let error):
                        Logger.logError("Failed to Upload Batch, Got error code: \(error.code), Aborting.")
                        completion(false)
                    }
                })
            } else {
                Logger.logDebug("errors while generating the payload, retrying again")
                completion(false)
            }
        } else {
            Logger.logDebug("no more batches in the db, exiting the recursive loop")
            completion(true)
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


