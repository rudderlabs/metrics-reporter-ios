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
    
    func test_Count() {
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        client.isMetricsCollectionEnabled = true
        
        let outputReaderPlugin = OutputReaderPlugin()
        client.add(plugin: outputReaderPlugin)
        
        client.process(metric: Count(name: "test_count", value: 4))
        
        let count: Count? = outputReaderPlugin.lastMetric as? Count
        
        XCTAssertEqual(count!.name, "test_count")
        XCTAssertEqual(count!.labels, nil)
        XCTAssertEqual(count!.value, 4)
        XCTAssertEqual(count!.type, .count)
    }
    
    func test_Gauge() {
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        client.isMetricsCollectionEnabled = true
        
        let outputReaderPlugin = OutputReaderPlugin()
        client.add(plugin: outputReaderPlugin)
        
        client.process(metric: Gauge(name: "test_gauge", value: 7))
        
        let gauge: Gauge? = outputReaderPlugin.lastMetric as? Gauge
        
        XCTAssertEqual(gauge!.name, "test_gauge")
        XCTAssertEqual(gauge!.labels, nil)
        XCTAssertEqual(gauge!.value, 7.0)
        XCTAssertEqual(gauge!.type, .gauge)
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
