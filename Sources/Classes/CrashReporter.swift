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
    private let statsCollection: StatsCollection
    private let sdkList = ["MetricsReporter", "Rudder"]
    
    init(database: DatabaseOperations, statsCollection: StatsCollection) {
        self.database = database
        self.statsCollection = statsCollection
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
