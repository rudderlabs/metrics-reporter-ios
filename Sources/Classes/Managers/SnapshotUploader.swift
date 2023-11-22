//
//  SnapshotUploader.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 02/11/23.
//

import Foundation
import RudderKit


class SnapshotUploader {
    
    let MAX_ATTEMPTS = 5
    var database: DatabaseOperations
    var configuration: Configuration
    @Atomic var uploadInProgress: Bool = false
    var serviceManager: ServiceType?
    private let queue = DispatchQueue(label: "rudder.metrics.snapshot.uploader")
    
    
    init(_ database: DatabaseOperations, _ configuration: Configuration) {
        self.database = database
        self.configuration = configuration
        serviceManager = {
            let session: URLSession = {
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForRequest = 30
                configuration.timeoutIntervalForResource = 30
                configuration.requestCachePolicy = .useProtocolCachePolicy
                return URLSession(configuration: configuration)
            }()
            return ServiceManager(urlSession: session, configuration: self.configuration)
        }()
        addSnapshotTableObserver()
        uploadSnapshots()
    }
    
    func addSnapshotTableObserver() {
        DatabaseObserver.addObserver(tableName: "snapshot", changeType: .insert, callback: uploadSnapshots)
    }
    
    func uploadSnapshots() {
        if(!self.uploadInProgress) {
            self.uploadInProgress = true
            startUploadingSnapshotsWithBackOff(){
                self.uploadInProgress = false
            }
        }
    }
    
    func startUploadingSnapshotsWithBackOff(currentAttempt:Int = 0, backoffDelay: TimeInterval = 2.0, _ completion: @escaping () -> Void) {
        if currentAttempt < MAX_ATTEMPTS {
            self.queue.async {
                self.uploadSnapshot() { [weak self] result in
                    guard let self = self else {
                        completion()
                        return }
                    if (!result) {
                        self.queue.asyncAfter(deadline: .now() + backoffDelay, execute: {
                            self.startUploadingSnapshotsWithBackOff(currentAttempt: currentAttempt+1, backoffDelay: backoffDelay * 2, completion)
                        })
                    } else {
                        completion()
                    }
                }
            }
        } else {
            Logger.logDebug("Failed to send snapshots to metric service even after backing off with retries")
            completion()
        }
    }
    
    func uploadSnapshot(_ wasUploadSuccessful: @escaping (Bool) -> Void) {
        if let snapshot = database.getSnapshot(), var snapshotDict = snapshot.batch.toDictionary() {
            snapshotDict["id"] = snapshot.uuid
            if let requestBody = snapshotDict.toJSONString() {
                self.serviceManager?.sdkMetrics(params: requestBody, { [weak self] (result) in
                    guard let self = self else {
                        Logger.logError("Failed to Upload Snapshot, Aborting.")
                        wasUploadSuccessful(false)
                        return
                    }
                    switch result {
                    case .success(_):
                        Logger.logDebug("Metrics Snapshot uploaded successfully")
                        self.database.clearSnapshot(snapshot: snapshot)
                        self.uploadSnapshot(wasUploadSuccessful)
                    case .failure(let error):
                        Logger.logError("Failed to Upload Snapshot, Got error code: \(error.code), Aborting.")
                        wasUploadSuccessful(false)
                    }
                })
            } else {
                Logger.logDebug("errors while generating the payload, retrying again")
                wasUploadSuccessful(false)
            }
        } else {
            Logger.logDebug("no more snapshots in the db")
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
