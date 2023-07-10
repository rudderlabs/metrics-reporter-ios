//
//  MetricTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 27/06/23.
//

import XCTest
@testable import MetricsReporter

final class MetricTests: XCTestCase {

    func test_count() {
        let count1 = Count(name: "test_count", value: 1)
        
        XCTAssertNotNil(count1.name)
        XCTAssertNotNil(count1.value)
        XCTAssertEqual(count1.name, "test_count")
        XCTAssertEqual(count1.attributes, nil)
        XCTAssertEqual(count1.value, 1)
        XCTAssertEqual(count1.type, .count)
        
        let count2 = Count(name: "test_count_2", attributes: ["key_1": "value_1"], value: 2)
        
        XCTAssertNotNil(count2.name)
        XCTAssertNotNil(count2.attributes)
        XCTAssertNotNil(count2.value)
        XCTAssertEqual(count2.name, "test_count_2")
        XCTAssertEqual(count2.attributes, ["key_1": "value_1"])
        XCTAssertEqual(count2.value, 2)
        XCTAssertEqual(count2.type, .count)
    }
    
    func test_gauge() {
        let gauge1 = Gauge(name: "test_gauge", value: 1)
        
        XCTAssertNotNil(gauge1.name)
        XCTAssertNotNil(gauge1.value)
        XCTAssertEqual(gauge1.name, "test_gauge")
        XCTAssertEqual(gauge1.attributes, nil)
        XCTAssertEqual(gauge1.value, 1.0)
        XCTAssertEqual(gauge1.type, .gauge)
        
        let gauge2 = Gauge(name: "test_gauge_2", attributes: ["key_1": "value_1"], value: 2)
        
        XCTAssertNotNil(gauge2.name)
        XCTAssertNotNil(gauge2.attributes)
        XCTAssertNotNil(gauge2.value)
        XCTAssertEqual(gauge2.name, "test_gauge_2")
        XCTAssertEqual(gauge2.attributes, ["key_1": "value_1"])
        XCTAssertEqual(gauge2.value, 2.0)
        XCTAssertEqual(gauge2.type, .gauge)
    }
}
