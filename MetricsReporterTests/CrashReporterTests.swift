//
//  CrashReporterTests.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 28/07/23.
//

import XCTest
import RSCrashReporter
@testable import MetricsReporter

final class CrashReporterTests: XCTestCase {

    var crashReporter: CrashReporter!
    
    override func setUp() {
        super.setUp()
        crashReporter = CrashReporter()
    }

    func test_checkIfRudderCrash() {
        let stacktrace = RSCrashReporterStackframe()
        stacktrace.machoFile = "/path/to/sdk/Rudder"
        
        let error = RSCrashReporterError()
        error.stacktrace = [stacktrace]
        
        let event = RSCrashReporterEvent()
        event.errors = [error]
        
        let value = crashReporter.checkIfRudderCrash(event: event)
        
        XCTAssertTrue(value)
    }
}
