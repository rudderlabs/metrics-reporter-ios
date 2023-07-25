//
//  MetricsUploaderTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 13/07/23.
//

import XCTest
@testable import MetricsReporter

final class MetricsUploaderTests: XCTestCase {
    
    var metricsUploader: MetricsUploader!
    let apiURL = URL(string: "https://some.rudderstack.com.url")!

    override func setUp() {
        super.setUp()
        let metricConfiguration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let database: DatabaseOperations = {
            let db = openDatabase()
            return Database(database: db)
        }()
        let serviceManager: ServiceType = {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = [MockURLProtocol.self]
            let urlSession = URLSession(configuration: configuration)
            return ServiceManager(urlSession: urlSession, configuration: metricConfiguration)
        }()
        metricsUploader = MetricsUploader(database: database, configuration: metricConfiguration, serviceManger: serviceManager)
    }
    
    func test_getJSONString() {
        var countList = [Count]()
        var gaugeList = [Gauge]()
        
        let count = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        countList.append(count)
                
        let gauge = Gauge(name: "test_gauge", labels: ["key_1": "value_3", "key_3": "value_3"], value: 11.3)
        gaugeList.append(gauge)
        
        let metricList = MetricList(countList: countList, gaugeList: gaugeList)
        let JSONString = metricsUploader.getJSONString(from: metricList)
        
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
                    "value": 2.0,
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
            ]
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
    
    #if !os(watchOS)
    func test_flushMetricsToServer() {
        let data = """
        {
        
        }
        """.data(using: .utf8)
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.apiURL, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        var countList = [Count]()
        var gaugeList = [Gauge]()
        
        let count = Count(name: "test_count", labels: ["key_1": "value_1", "key_2": "value_2"], value: 2)
        countList.append(count)
        
        let gauge = Gauge(name: "test_gauge", labels: ["key_1": "value_3", "key_3": "value_3"], value: 11.3)
        gaugeList.append(gauge)
        
        let metricList = MetricList(countList: countList, gaugeList: gaugeList)
        
        let params = metricsUploader.getJSONString(from: metricList)
        XCTAssertNotNil(params)
        
        let error = metricsUploader.flushMetricsToServer(params: params!)
        XCTAssertNil(error)
    }
    #endif
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
    
    let version: String
    let source: Source
    let metrics: [Metric]
    
    static func == (lhs: Payload, rhs: Payload) -> Bool {
        return lhs.version == rhs.version && lhs.source == rhs.source && lhs.metrics == rhs.metrics
    }
}
