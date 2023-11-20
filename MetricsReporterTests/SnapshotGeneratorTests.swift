//
//  SnapshotGeneratorTests.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import XCTest
import RudderKit
@testable import MetricsReporter

final class SnapshotGeneratorTests: XCTestCase {
    
    var snapshotGenerator: SnapshotGenerator!
    var database: DatabaseOperations!

    override func setUp() {
        super.setUp()
        let metricConfiguration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version", maxErrorsInBatch: 15, maxMetricsInBatch: 15, flushInterval: 1)
        database = {
            let db = openDatabase()
            return Database(database: db)
        }()
        snapshotGenerator = SnapshotGenerator(database, metricConfiguration)
        clearAll()
    }
    
    func test_getJSONString() {
        var countList = [Count]()
        var gaugeList = [Gauge]()
        
        let count = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        countList.append(count)
                
        let gauge = Gauge(name: "test_gauge", labels: ["key_1": "value_3", "key_3": "value_3"], value: 11.3)
        gaugeList.append(gauge)
        
        let metricList = MetricList(countList: countList, gaugeList: gaugeList)
        
        let errorEntity = ErrorEntity(id: 1, events: createErrorEvent(index: 0))
        let JSONString = snapshotGenerator.getJSONString(from: metricList, and: [errorEntity])
        
        XCTAssertNotNil(JSONString)
        
        let expectedJSONString =
        """
        {
            "version": "1",
            "source": {
                "name": "ios",
                "sdk_version": "some.version"
            },
            "metrics": [
                {
                    "name": "test_count",
                    "type": "count",
                    "value": 2,
                    "labels": {
                        "key_1": "value_1",
                        "key_2": "value_2"
                    }
                },
                {
                    "name": "test_gauge",
                    "type": "gauge",
                    "value": 11.3,
                    "labels": {
                        "key_1": "value_3",
                        "key_3": "value_3"
                    }
                }
            ],
            "errors": {
                "payloadVersion": "5",
                "notifier": {
                    "name": "Bugsnag iOS",
                    "version": "some.version",
                    "url": "https://github.com/rudderlabs/rudder-sdk-ios"
                },
                "events": \(createErrorEvent(index: 0))
            }
        }
        """
                        
        let JSONStringData = JSONString!.data(using: .utf8)
        let expectedJSONStringData = expectedJSONString.data(using: .utf8)
        
        XCTAssertNotNil(JSONStringData)
        XCTAssertNotNil(expectedJSONStringData)
        
        let payloadObject: Payload? = getObject(data: JSONStringData!)
        let expectedPayloadObject: Payload? = getObject(data: expectedJSONStringData!)
        
        XCTAssertNotNil(payloadObject)
        XCTAssertNotNil(expectedPayloadObject)
        
        XCTAssertEqual(payloadObject!, expectedPayloadObject!)
    }
    
    func test_snapshotting() {
        let expectation = XCTestExpectation(description: "Batching completed")
        for i in 1...31 {
            let countMetric = Count(name: "test_count_\(i)", labels: ["key_\(i)": "value_\(i)"], value: i + 1)
            database.saveMetric(countMetric)
            let events = createErrorEvent(index: i)
            database.saveError(events: events)
        }
        snapshotGenerator.startCapturingSnapshots() {
            // since the maxMetricsInBatch and maxErrorsInBatch are 15,
            // and as we have generated 31 errors and 31 metrics, which is total of 62,
            // and should be grouped into 3 batches in total
            if (self.database.getSnapshotCount() == 3) {
                expectation.fulfill()
            }
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 15.0)
        XCTAssertEqual(result, .completed, "Batching Operation is successful")
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        snapshotGenerator = nil
        database = nil
    }
    
    func clearAll() {
        database.clearAllErrors()
        database.clearAllMetrics()
        database.resetErrorTable()
        database.clearAllSnapshots()
    }
}

func getObject<T: Codable>(data: Data) -> T? {
    return try! JSONDecoder().decode(T.self, from: data)
}

struct Payload: Codable, Equatable {
    struct Source: Codable, Equatable {
        let name: String
        let sdk_version: String
    }
    
    struct Metric: Codable, Equatable {
        let name: String
        let value: Float
        let type: String
        let labels: [String: String]
    }
    
    struct Notifier: Codable, Equatable {
        let name: String
        let version: String
        let url: String
    }
    
    struct Errors: Codable, Equatable {
        static func == (lhs: Payload.Errors, rhs: Payload.Errors) -> Bool {
            return lhs.payloadVersion == rhs.payloadVersion && lhs.notifier == rhs.notifier && lhs.events == rhs.events
        }
        
        let payloadVersion: String
        let notifier: Notifier
        let events: JSON
    }
    
    let version: String
    let source: Source
    let metrics: [Metric]
    let errors: Errors
    
    static func == (lhs: Payload, rhs: Payload) -> Bool {
        return lhs.version == rhs.version && lhs.source == rhs.source && lhs.metrics == rhs.metrics && lhs.errors == rhs.errors
    }
}
