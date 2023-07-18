//
//  ObjCTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 18/07/23.
//

import XCTest
#if os(iOS)
@testable import MetricsReporter_iOS
#elseif os(tvOS)
@testable import MetricsReporter_tvOS
#elseif os(macOS)
@testable import MetricsReporter_macOS
#else
@testable import MetricsReporter_watchOS
#endif

final class ObjCTests: XCTestCase {

    func test_ObjCConfiguration() {
        let configuration = ObjCConfiguration(logLevel: 0, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        
        XCTAssertEqual(configuration.configuration.logLevel, .none)
        XCTAssertEqual(configuration.configuration.writeKey, "WRITE_KEY")
        XCTAssertEqual(configuration.configuration.sdkVersion, "some.version")
    }

    func test_ObjCCount() {
        let count1 = ObjCCount(name: "test_count", value: 1)
        
        XCTAssertNotNil(count1.name)
        XCTAssertNotNil(count1.value)
        XCTAssertEqual(count1.name, "test_count")
        XCTAssertEqual(count1.labels, nil)
        XCTAssertEqual(count1.value, 1)
        XCTAssertEqual(count1.type, .count)
        
        let count2 = ObjCCount(name: "test_count_2", labels: ["key_1": "value_1"], value: 2)
        
        XCTAssertNotNil(count2.name)
        XCTAssertNotNil(count2.labels)
        XCTAssertNotNil(count2.value)
        XCTAssertEqual(count2.name, "test_count_2")
        XCTAssertEqual(count2.labels, ["key_1": "value_1"])
        XCTAssertEqual(count2.value, 2)
        XCTAssertEqual(count2.type, .count)
    }
    
    func test_ObjCGauge() {
        let gauge1 = ObjCGauge(name: "test_gauge", value: 1)
        
        XCTAssertNotNil(gauge1.name)
        XCTAssertNotNil(gauge1.value)
        XCTAssertEqual(gauge1.name, "test_gauge")
        XCTAssertEqual(gauge1.labels, nil)
        XCTAssertEqual(gauge1.value, 1.0)
        XCTAssertEqual(gauge1.type, .gauge)
        
        let gauge2 = ObjCGauge(name: "test_gauge_2", labels: ["key_1": "value_1"], value: 2)
        
        XCTAssertNotNil(gauge2.name)
        XCTAssertNotNil(gauge2.labels)
        XCTAssertNotNil(gauge2.value)
        XCTAssertEqual(gauge2.name, "test_gauge_2")
        XCTAssertEqual(gauge2.labels, ["key_1": "value_1"])
        XCTAssertEqual(gauge2.value, 2.0)
        XCTAssertEqual(gauge2.type, .gauge)
    }
    
    func test_getMetricType() {
        XCTAssertEqual(ObjCMetricType(rawValue: 0), .count)
        XCTAssertEqual(ObjCMetricType(rawValue: 1), .gauge)
    }
    
    func test_toSwiftMetric() {
        let gauge = ObjCGauge(name: "test_gauge", value: 1)
        let count = ObjCCount(name: "test_count", value: 1)
        
        XCTAssertNotNil(gauge.toSwiftMetric())
        XCTAssertNotNil(count.toSwiftMetric())
        
        XCTAssertEqual(gauge.toSwiftMetric()!.name, "test_gauge")
        XCTAssertEqual(gauge.toSwiftMetric()!.labels, nil)
        XCTAssertEqual(gauge.toSwiftMetric()!.type, .gauge)
        
        XCTAssertEqual(count.toSwiftMetric()!.name, "test_count")
        XCTAssertEqual(count.toSwiftMetric()!.labels, nil)
        XCTAssertEqual(count.toSwiftMetric()!.type, .count)
    }
    
    func test_ObjCMetricsClient() {
        let configuration = ObjCConfiguration(logLevel: 0, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = ObjCMetricsClient(configuration: configuration)
        
        XCTAssertNotNil(client)
    }
}
