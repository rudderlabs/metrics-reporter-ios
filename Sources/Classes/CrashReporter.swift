//
//  CrashReporter.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/07/23.
//

import Foundation
import RSCrashReporter

class CrashReporter: RSCrashReporterNotifyDelegate {
    private let database: DatabaseOperations
    private var statsCollection: StatsCollection
    private let sdkList = ["MetricsReporter", "Rudder"]
    
    init(database: DatabaseOperations, statsCollection: StatsCollection) {
        self.database = database
        self.statsCollection = statsCollection
    }
    
    var isErrorsCollectionEnabled: Bool {
        set {
            statsCollection.isErrorsEnabled = newValue
        }
        get {
            return statsCollection.isErrorsEnabled
        }
    }
    
    /// Enable/Disable metric collection
    var isMetricsCollectionEnabled: Bool {
        set {
            statsCollection.isMetricsEnabled = newValue
        }
        get {
            return statsCollection.isMetricsEnabled
        }
    }
    
    func startCollectingCrash() {
        RSCrashReporter.start(with: self)
    }
    
    func notifyCrash(_ event: BugsnagEvent?, withRequestPayload requestPayload: [AnyHashable: Any]?) {
        if let requestPayload = requestPayload, (checkIfRudderCrash(event: event) && statsCollection.isErrorsEnabled),
           let eventList = requestPayload["events"] as? [[String: Any]], let events = eventList.toJSONString() {
            database.saveError(events: events)
        }
    }
    
    func checkIfRudderCrash(event: BugsnagEvent?) -> Bool {
        var isRudderCrash = false
        if let event = event {
            for error in event.errors {
                for stacktrace in error.stacktrace {
                    if let machoFile = stacktrace.machoFile {
                        if let url = URL(string: machoFile) {
                            print(url.lastPathComponent)
                            if sdkList.contains(url.lastPathComponent) {
                                isRudderCrash = true
                                break
                            }
                        }
                    }
                }
            }
        }
        return isRudderCrash
    }
}
