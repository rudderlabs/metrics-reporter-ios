//
//  CrashReporterClient.swift
//  CrashReporter
//
//  Created by Pallab Maiti on 19/06/23.
//

import Foundation

public class CrashReporterClient {
    
    let sdks: [String] = ["MetricsReporter", "Rudder"]
    
    
    public static let shared = CrashReporterClient()
    
    init() {
        //        RSCrashReporter.start(withApiKey: "df5da4234cd9883c66557a2b9b75c082")
//        RSCrashReporter.start(with: self)
//        RSCrashReporter
    }
    
    public func print() {
        Swift.print("hihihaha")
    }
    
    public func testCrash() {
        let arr: NSMutableArray = NSMutableArray()
        _ = arr.object(at: 5)
    }
}

//extension CrashReporterClient: RSCrashReporterNotifyDelegate {
//    public func notifyCrash(_ event: BugsnagEvent?, withRequestPayload requestPayload: NSMutableDictionary?) {
//        var isRudderCrash = false
//        if let event = event {
//            for error in event.errors {
//                for stacktrace in error.stacktrace {
//                    if let machoFile = stacktrace.machoFile {
//                        if let url = URL(string: machoFile) {
//                            if sdks.contains(url.lastPathComponent) {
//                                isRudderCrash = true
//                                break
//                            }
//                        }
//                    }
//                }
//            }
//        }
//
//        if isRudderCrash {
//
//        }
//
//    }
//
//
//}
