//
//  MetricOperatorTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 14/07/23.
//

import XCTest
@testable import MetricsReporter

final class MetricOperatorTests: XCTestCase {
    var metricOperator: MetricOperations!

    override func setUp() {
        super.setUp()
        let database = openDatabase()
        metricOperator = MetricOperator(database: database)
        metricOperator.createTable()
        clearAll()
    }
    
    func test_saveMetricEntity() {
        let metric = metricOperator.saveMetric(name: "test_metric", value: 10, type: MetricType.count.rawValue, labels: "label_1,label_2")
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric!.id, 1)
        XCTAssertEqual(metric!.name, "test_metric")
        XCTAssertEqual(metric!.value, 10)
        XCTAssertEqual(metric!.type, MetricType.count.rawValue)
        XCTAssertEqual(metric!.labels, "label_1,label_2")
        clearAll()
    }
    
    func test_fetchMetric() {
        let metricEntity = metricOperator.saveMetric(name: "test_metric", value: 10, type: MetricType.count.rawValue, labels: "label_1,label_2")
        
        XCTAssertNotNil(metricEntity)
        let metric = metricOperator.fetchMetric(where: metricEntity!.name, type: metricEntity!.type, labels: metricEntity!.labels)
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric!.id, 1)
        XCTAssertEqual(metric!.name, "test_metric")
        XCTAssertEqual(metric!.value, 10)
        XCTAssertEqual(metric!.type, MetricType.count.rawValue)
        XCTAssertEqual(metric!.labels, "label_1,label_2")
        clearAll()
    }
    
    func test_fetchMetrics() {
        let metricEntity1 = metricOperator.saveMetric(name: "test_metric_1", value: 10, type: MetricType.count.rawValue, labels: "label_1,label_2")
        XCTAssertNotNil(metricEntity1)
        
        let metricEntity2 = metricOperator.saveMetric(name: "test_metric_2", value: 3, type: MetricType.gauge.rawValue, labels: "label_1,label_3,label_6")
        XCTAssertNotNil(metricEntity2)
        
        let metricList = metricOperator.fetchMetrics(where: "id", from: metricEntity1!.id, to: metricEntity2!.id)
        
        let metric1 = metricList?[0]
        
        XCTAssertNotNil(metric1)
        XCTAssertEqual(metric1!.id, metricEntity1!.id)
        XCTAssertEqual(metric1!.name, metricEntity1!.name)
        XCTAssertEqual(metric1!.value, metricEntity1!.value)
        XCTAssertEqual(metric1!.type, metricEntity1!.type)
        XCTAssertEqual(metric1!.labels, metricEntity1!.labels)
        
        let metric2 = metricList?[1]
        
        XCTAssertNotNil(metric2)
        XCTAssertEqual(metric2!.id, metricEntity2!.id)
        XCTAssertEqual(metric2!.name, metricEntity2!.name)
        XCTAssertEqual(metric2!.value, metricEntity2!.value)
        XCTAssertEqual(metric2!.type, metricEntity2!.type)
        XCTAssertEqual(metric2!.labels, metricEntity2!.labels)
        clearAll()
    }
    
    func test_updateMetric() {
        let metricEntity = metricOperator.saveMetric(name: "test_metric", value: 10, type: MetricType.count.rawValue, labels: "label_1,label_2")
        
        XCTAssertNotNil(metricEntity)
                
        metricOperator.updateMetric(metricEntity, updatedValue: 3.0)
        
        let metric = metricOperator.fetchMetric(where: metricEntity!.name, type: metricEntity!.type, labels: metricEntity!.labels)
        
        XCTAssertNotNil(metric)
        XCTAssertEqual(metric!.id, 1)
        XCTAssertEqual(metric!.name, "test_metric")
        XCTAssertEqual(metric!.value, 3)
        XCTAssertEqual(metric!.type, MetricType.count.rawValue)
        XCTAssertEqual(metric!.labels, "label_1,label_2")
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        metricOperator = nil
    }
    
    func clearAll() {
        metricOperator.clearAll()
    }
}
