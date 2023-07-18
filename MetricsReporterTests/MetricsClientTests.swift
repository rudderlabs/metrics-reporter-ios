//
//  MetricsClientTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 27/06/23.
//

import XCTest
@testable import MetricsReporter

final class MetricsClientTests: XCTestCase {
    
    func test_MetricsClient() {
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        
        XCTAssertNotNil(client)
    }
    
}
