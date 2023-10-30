//
//  OSInfoTests.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import XCTest
@testable import MetricsReporter

final class OSInfoTests: XCTestCase {
    
    func test_OSName() {
#if os(iOS)
        XCTAssertEqual("iOS", OSInfo.name)
#elseif os(tvOS)
        XCTAssertEqual("tvOS", OSInfo.name)
#elseif os(watchOS)
        XCTAssertEqual("watchOS", OSInfo.name)
#elseif os(macOS)
        XCTAssertEqual("macOS", OSInfo.name)
#endif
    }
    
    func test_OSVersion() {
        let osVersion = OSInfo.version
        XCTAssertNotNil(osVersion)
        print("\(OSInfo.name) and version \(osVersion)")
    }
}
