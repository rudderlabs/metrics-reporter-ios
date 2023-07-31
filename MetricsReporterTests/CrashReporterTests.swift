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
        let database = openDatabase()
        let databaseOperator = Database(database: database)
        crashReporter = CrashReporter(database: databaseOperator)
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
