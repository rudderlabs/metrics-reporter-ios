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

    var metricOperator: MetricOperations!
    var labelOperator: LabelOperations!
    var databaseOperator: DatabaseOperations!
    
    override func setUp() {
        super.setUp()
        let database = openDatabase()
        metricOperator = MetricOperator(database: database)
        labelOperator = LabelOperator(database: database)
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
        let metric = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        let metricEntity = databaseOperator.saveMetric(metric)
        
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
        let metricEntity = databaseOperator.saveMetric(metric)
        
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
        let count = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        databaseOperator.saveMetric(count)
        
        let count2 = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 4)
        databaseOperator.saveMetric(count2)
        
        let gauge = Gauge(name: "test_gauge", labels: ["key_1": "value_3", "key_3": "value_3"], value: 11.3)
        databaseOperator.saveMetric(gauge)
        
        let metricList = databaseOperator.fetchMetrics(from: 1, to: 10)
        XCTAssertNotNil(metricList)
        
        XCTAssertTrue(!metricList.countList!.isEmpty)
        XCTAssertNotNil(metricList.countList?.first)
        let c = metricList.countList!.first!
        XCTAssertNotNil(c.name)
        XCTAssertNotNil(c.value)
        XCTAssertEqual(c.name, "test_count")
        XCTAssertEqual(c.labels, ["key_1": "value_1", "key_2": "value_2"])
        XCTAssertEqual(c.value, 6)
        XCTAssertEqual(c.type, .count)
        
        XCTAssertTrue(!metricList.gaugeList!.isEmpty)
        XCTAssertNotNil(metricList.gaugeList?.first)
        let g = metricList.gaugeList!.first!
        XCTAssertNotNil(g.name)
        XCTAssertNotNil(g.value)
        XCTAssertEqual(g.name, "test_gauge")
        XCTAssertEqual(g.labels, ["key_1": "value_3", "key_3": "value_3"])
        XCTAssertEqual(g.value, 11.3)
        XCTAssertEqual(g.type, .gauge)
        
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
