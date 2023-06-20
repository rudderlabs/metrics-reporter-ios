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
    
    func test_StatsCollection() {
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        
        XCTAssertFalse(client.isErrorsCollectionEnabled)
        XCTAssertFalse(client.isMetricsCollectionEnabled)
        
        client.isErrorsCollectionEnabled = true
        client.isMetricsCollectionEnabled = true
        
        XCTAssertTrue(client.isErrorsCollectionEnabled)
        XCTAssertTrue(client.isMetricsCollectionEnabled)
        
        client.isErrorsCollectionEnabled = false
        client.isMetricsCollectionEnabled = false
        
        XCTAssertFalse(client.isErrorsCollectionEnabled)
        XCTAssertFalse(client.isMetricsCollectionEnabled)
        
        client.isErrorsCollectionEnabled = true
        
        XCTAssertTrue(client.isErrorsCollectionEnabled)
        XCTAssertFalse(client.isMetricsCollectionEnabled)
        
        client.isMetricsCollectionEnabled = true
        
        XCTAssertTrue(client.isErrorsCollectionEnabled)
        XCTAssertTrue(client.isMetricsCollectionEnabled)
        
        client.isErrorsCollectionEnabled = false
        
        XCTAssertFalse(client.isErrorsCollectionEnabled)
        XCTAssertTrue(client.isMetricsCollectionEnabled)
        
        client.isMetricsCollectionEnabled = false
        
        XCTAssertFalse(client.isErrorsCollectionEnabled)
        XCTAssertFalse(client.isMetricsCollectionEnabled)
    }
}
