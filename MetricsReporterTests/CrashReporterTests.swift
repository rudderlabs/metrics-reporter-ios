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
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        crashReporter = CrashReporter(client.database, client.statsCollection)
    }

    func test_checkIfRudderCrash() {
        let stacktrace = BugsnagStackframe()
        stacktrace.machoFile = "/path/to/sdk/Rudder"
        
        let error = BugsnagError()
        error.stacktrace = [stacktrace]
        
        let event = BugsnagEvent()
        event.errors = [error]
        
        let value = crashReporter.checkIfRudderCrash(event: event)
        
        XCTAssertTrue(value)
    }
}
