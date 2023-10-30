//
//  ErrorOperatorTests.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/07/23.
//

import XCTest
@testable import MetricsReporter

final class ErrorOperatorTests: XCTestCase {
    var errorOperator: ErrorOperations!
    
    override func setUp() {
        super.setUp()
        let database = openDatabase()
        errorOperator = ErrorOperator(database: database)
        errorOperator.createTable()
        clearAll()
    }
    
    func test_saveErrorEntity() {
        let events = createErrorEvent(index: 0)
        let error = errorOperator.saveError(events: events)
        
        XCTAssertNotNil(error)
        XCTAssertEqual(error!.id, 1)
        XCTAssertEqual(error!.events, events)
        clearAll()
    }
    
    func test_fetchErrors() {
        for index in 0..<60 {
            errorOperator.saveError(events: createErrorEvent(index: index))
        }
        let errorEntityList = errorOperator.fetchErrors(count: 30)
        
        XCTAssertNotNil(errorEntityList)
        XCTAssertEqual(errorEntityList!.count, 30)
    }
    
    func test_clearError() {
        let errorEntity = errorOperator.saveError(events: createErrorEvent(index: 0))
        
        XCTAssertNotNil(errorEntity)
        errorOperator.clearError(where: "\(errorEntity!.id)")
        
        let errorEntityList = errorOperator.fetchErrors(count: 30)
        XCTAssertNil(errorEntityList)
    }
    
    func test_toDict() {
        let errorEntity = ErrorEntity(id: 1, events: createErrorEvent(index: 0))
        let metricConfiguration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let errorsDict = [errorEntity].toDict(configuration: metricConfiguration)
        let expectedErrorsDict: [String: Any] = [
            "payloadVersion": "5",
            "notifier": [
                "name": "Bugsnag iOS",
                "version": "some.version",
                "url": "https://github.com/rudderlabs/rudder-sdk-ios",
                "os_version": "\(OSInfo.version)",
                "os_name": "\(OSInfo.name)",
            ],
            "events": [
                [
                    "exceptions": [
                        [
                            "errorClass": "NullPointerException_0",
                            "message": "Variable is null",
                            "stacktrace": [
                                [
                                    "file": "EventRepository.java",
                                    "lineNumber": 1234,
                                    "columnNumber": 123,
                                    "method": "create"
                                ] as [String: Any]
                            ],
                            "type": "android"
                        ] as [String: Any]
                    ],
                    "breadcrumbs": [
                        [
                            "timestamp": "2023-05-22T12:17:27-0700",
                            "name": "Config set",
                            "type": "navigation",
                            "metaData": [
                                "thread-name": "some-thread"
                            ]
                        ] as [String: Any]
                    ],
                    "context": "activity_name",
                    "unhandled": false,
                    "severity": "error/warning/info",
                    "projectPackages": [
                        "com.example.package1/for v1 only one package",
                        "com.example.package2"
                    ],
                    "user": [
                        "id": "user_id/anonymous_id"
                    ],
                    "app": [
                        "id": "source_id/write_key",
                        "version": "sdk_version"
                    ],
                    "device": [
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
                        "runtimeVersions": [
                            "androidApiLevel": "28(only android)",
                            "clangVersion": "ios only",
                            "osBuild": "ios only",
                            "swift": "ios only"
                        ]
                    ] as [String: Any],
                    "metaData": [:] as [String: Any]
                ] as [String: Any]
            ]
        ] as [String: Any]
        
        XCTAssertTrue(NSDictionary(dictionary: errorsDict).isEqual(to: expectedErrorsDict))
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        errorOperator = nil
    }
    
    func clearAll() {
        errorOperator.clearAll()
        errorOperator.resetTable()
    }
}

func createErrorEvent(index: Int) -> String {
    return
        """
        [
            {
                "exceptions": [
                    {
                        "errorClass": "NullPointerException_\(index)",
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
        """
}
