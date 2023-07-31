//
//  MetricsUploaderTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 13/07/23.
//

import XCTest
import RudderKit
@testable import MetricsReporter

final class MetricsUploaderTests: XCTestCase {
    
    var metricsUploader: MetricsUploader!
    var database: DatabaseOperations!
    let apiURL = URL(string: "https://some.rudderstack.com.url")!

    override func setUp() {
        super.setUp()
        let metricConfiguration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version", maxErrorsInBatch: 1, maxMetricsInBatch: 1, flushInterval: 1)
        database = {
            let db = openDatabase()
            return Database(database: db)
        }()
        let serviceManager = {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [MockURLProtocol.self]
            let urlSession = URLSession(configuration: configuration)
            return ServiceManager(urlSession: urlSession, configuration: metricConfiguration)
        }()
        metricsUploader = MetricsUploader()
        metricsUploader.serviceManager = serviceManager
        metricsUploader.database = database
        metricsUploader.configuration = metricConfiguration
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
        let JSONString = metricsUploader.getJSONString(from: metricList, and: [errorEntity])
        
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
    
    /*#if !os(watchOS)
    func test_flush() {
        metricsUploader.startUploading()
        let data = """
        {
        
        }
        """.data(using: .utf8)
        var count = 0
        var ready = false
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.apiURL, statusCode: 201, httpVersion: nil, headerFields: nil)!
            count += 1
            if count == 30 {
                ready = false
                self.clearAll()
            }
            return (response, data)
        }
        
        for i in 1...30 {
            let countMetric = Count(name: "test_count_\(i)", labels: ["key_\(i)": "value_\(i)"], value: i + 1)
            database.saveMetric(countMetric)
            let events = createErrorEvent(index: i)
            database.saveError(events: events)
        }
        
        ready = true
        
        while (ready) {
            RunLoop.main.run(until: Date.distantPast)
        }
    }
    #endif*/
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        metricsUploader = nil
        database = nil
    }
    
    func clearAll() {
        database.clearAllErrors()
        database.clearAllMetrics()
        database.resetErrorTable()
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
