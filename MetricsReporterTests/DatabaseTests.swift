//
//  DatabaseTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 30/06/23.
//

import XCTest
import SQLite3
@testable import MetricsReporter

final class DatabaseTests: XCTestCase {

    var metricOperator: MetricOperator!
    var labelOperator: LabelOperator!
    var databaseOperator: DatabaseOperator!
    
    override func setUp() {
        super.setUp()
        let database = openDatabase()
        metricOperator = MetricEntityOperator(database: database, logger: nil)
        labelOperator = LabelEntityOperator(database: database, logger: nil)
        metricOperator.createTable()
        labelOperator.createTable()
        databaseOperator = Database(database: database)
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
    
    func test_saveLabelEntity() {
        let label = labelOperator.saveLabel(name: "label_1", value: "value_1")

        XCTAssertNotNil(label)
        XCTAssertEqual(label!.id, 1)
        XCTAssertEqual(label!.name, "label_1")
        XCTAssertEqual(label!.value, "value_1")
        clearAll()
    }
    
    func test_saveCountMetric() {
        let metric = Count(name: "test_count", attributes: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        let metricEntity = databaseOperator.saveCount(metric)
        
        XCTAssertNotNil(metricEntity)
        XCTAssertNotNil(metricEntity)
        XCTAssertEqual(metricEntity!.id, 1)
        XCTAssertEqual(metricEntity!.name, "test_count")
        XCTAssertEqual(metricEntity!.value, 2)
        XCTAssertEqual(metricEntity!.type, MetricType.count.rawValue)
        XCTAssertEqual(metricEntity!.labels, "1,2")
        clearAll()
    }
    
    func test_saveGaugeMetric() {
        let metric = Gauge(name: "test_gauge", value: 11.3)
        let metricEntity = databaseOperator.saveGauge(metric)
        
        XCTAssertNotNil(metricEntity)
        XCTAssertNotNil(metricEntity)
        XCTAssertEqual(metricEntity!.id, 1)
        XCTAssertEqual(metricEntity!.name, "test_gauge")
        XCTAssertEqual(metricEntity!.value, 11.3)
        XCTAssertEqual(metricEntity!.type, metric.type.rawValue)
        XCTAssertEqual(metricEntity!.labels, "")
        clearAll()
    }
    
    func test_saveMultipleMetrics() {
        let count = Count(name: "test_count", attributes: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        databaseOperator.saveCount(count)
        
        let count2 = Count(name: "test_count", attributes: ["key_1": "value_1", "key_2": "value_2"], value: 4)
        databaseOperator.saveCount(count2)
        
        let gauge = Gauge(name: "test_gauge", attributes: ["key_1": "value_3", "key_3": "value_3"], value: 11.3)
        databaseOperator.saveGauge(gauge)
        
        let metricList = databaseOperator.fetchMetrics(from: 1, to: 10)
        XCTAssertNotNil(metricList)
        
        for metric in metricList! {
            switch metric {
                case let m as Count:
                    XCTAssertNotNil(m.name)
                    XCTAssertNotNil(m.value)
                    XCTAssertEqual(m.name, "test_count")
                    XCTAssertEqual(m.attributes, ["key_1": "value_1", "key_2": "value_2"])
                    XCTAssertEqual(m.value, 6)
                    XCTAssertEqual(m.type, .count)
                case let m as Gauge:
                    XCTAssertNotNil(m.name)
                    XCTAssertNotNil(m.value)
                    XCTAssertEqual(m.name, "test_gauge")
                    XCTAssertEqual(m.attributes, ["key_1": "value_3", "key_3": "value_3"])
                    XCTAssertEqual(m.value, 11.3)
                    XCTAssertEqual(m.type, .gauge)
                default:
                    XCTFail("There should not be any other metric other than Count or Gauge")
            }
        }
                
        clearAll()
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        metricOperator = nil
        labelOperator = nil
    }

    func clearAll() {
        metricOperator.clearAll()
        labelOperator.clearAll()
    }
}

extension DatabaseTests {
    func getDBPath() -> String {
        let urlDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let fileUrl = urlDirectory.appendingPathComponent("test_metrics.sqlite")
        return fileUrl.path
    }
    
    func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        if sqlite3_open_v2(getDBPath(), &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            return db
        } else {
            return nil
        }
    }
}
