//
//  ServiceManagerTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 27/06/23.
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

final class ServiceManagerTests: XCTestCase {

    var serviceManager: ServiceType!
    var promise: XCTestExpectation!
    let apiURL = URL(string: "https://some.rudderstack.com.url")!
    
    override func setUp() {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        
        serviceManager = ServiceManager(urlSession: urlSession)
        promise = expectation(description: "Expectation")
    }

    #if !os(watchOS)
    func test_sdkMetrics() {
        // Prepare mock response.
        let jsonString = """
        {
            "version": "1",
            "source": {
                "name": "android",
                "sdk_version": "1.14.0",
                "install_type": "cocoapods"
            },
            "metrics": [
                {
                    "type": "count",
                    "name": "discarded_events",
                    "value": 10,
                    "labels": {
                        "event_type": "identify",
                        "reason": "max_batch_size_crossed",
                        "dest_name": "Amplitude",
                        "dest_id": "1iwdniu1nwujwhjwq"
                    }
                },
                {
                    "type": "count",
                    "name": "event_submitted",
                    "value": 22,
                    "labels": {
                        "event_type": "track"
                    }
                }
            ],
            "errors": {
                "payloadVersion": "5",
                "notifier": {
                    "name": "Bugsnag Deba",
                    "version": "1.0.11",
                    "url": "https://github.com/rudderlabs/rudder-sdk-android"
                },
                "events": [
                    {
                        "exceptions": [
                            {
                                "errorClass": "NullPointerException_17",
                                "message": "Variable is null",
                                "stacktrace": [
                                    {
                                        "file": "EventRepository.java",
                                        "lineNumber": 1234,
                                        "columnNumber": 123,
                                        "method": "create"
                                    }
                                ],
                                "type": "android"
                            }
                        ],
                        "breadcrumbs": [
                            {
                                "timestamp": "2023-05-22T12:17:27-0700",
                                "name": "Config set",
                                "type": "navigation",
                                "metaData": {
                                    "thread-name": "some-thread"
                                }
                            }
                        ],
                        "context": "activity_name",
                        "unhandled": false,
                        "severity": "error/warning/info",
                        "projectPackages": [
                            "com.example.package1/for v1 only one package",
                            "com.example.package2"
                        ],
                        "user": {
                            "id": "user_id/anonymous_id"
                        },
                        "app": {
                            "id": "source_id/write_key",
                            "version": "sdk_version"
                        },
                        "device": {
                            "id": "fd124e87760c4281aef",
                            "manufacturer": "LGE",
                            "model": "Nexus 6P",
                            "modelNumber": "600",
                            "osName": "android",
                            "osVersion": "8.0.1",
                            "freeMemory": 183879616,
                            "totalMemory": 201326592,
                            "freeDisk": 13478064128,
                            "jailbroken": false,
                            "time": "2018-08-07T10:16:34.564Z",
                            "cpuAbi": [
                                "x86_64"
                            ],
                            "runtimeVersions": {
                                "androidApiLevel": "28(only android)",
                                "clangVersion": "ios only",
                                "osBuild": "ios only",
                                "swift": "ios only"
                            }
                        },
                        "metaData": {}
                    }
                ]
            }
        }
        """
        let data = """
        {
        
        }
        """.data(using: .utf8)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: self.apiURL, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
        
        serviceManager.sdkMetrics(params: jsonString) { result in
            switch result {
                case .success(let status):
                    XCTAssertEqual(status, true)
                case .failure(let error):
                    XCTFail("Error was not expected: \(error)")
            }
            self.promise.fulfill()
        }
        wait(for: [promise], timeout: 1.0)
    }
    #endif
}
