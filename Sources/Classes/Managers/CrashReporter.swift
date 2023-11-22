//
//  CrashReporter.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/07/23.
//

import Foundation
import RSCrashReporter

class CrashReporter: RSCrashReporterNotifyDelegate {
    
    private var statsCollection: StatsCollection?
    private var database: DatabaseOperations?
    private let sdkList = ["MetricsReporter", "Rudder"]
    
    init(_ database: DatabaseOperations, _ statsCollection: StatsCollection) {
        self.statsCollection = statsCollection
        self.database = database
        startCollectingCrash()
    }
    
    func startCollectingCrash() {
        RSCrashReporter.start(with: self)
    }
    
    func notifyCrash(_ event: BugsnagEvent?, withRequestPayload requestPayload: [AnyHashable: Any]?) {
        guard let database = self.database, let statsCollection = self.statsCollection else { return }
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
                    if let machoFile = stacktrace.machoFile, let url = URL(string: machoFile), sdkList.contains(url.lastPathComponent) {
                        isRudderCrash = true
                        break
                    }
                }
            }
        }
        return isRudderCrash
    }
}
