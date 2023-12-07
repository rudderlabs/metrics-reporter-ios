//
//  VendorTests.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import XCTest
@testable import MetricsReporter

final class VendorTests: XCTestCase {
    
    func test_OSName() {
#if os(iOS)
        XCTAssertEqual("iOS", Vendor.current.osName)
#elseif os(tvOS)
        XCTAssertEqual("tvOS", Vendor.current.osName)
#elseif os(watchOS)
        XCTAssertEqual("watchOS", Vendor.current.osName)
#elseif os(macOS)
        XCTAssertEqual("macOS", Vendor.current.osName)
#endif
    }
    
    func test_OSVersion() {
        let osVersion = Vendor.current.osVersion
        XCTAssertNotNil(osVersion)
        print("\(Vendor.current.osName) and version \(osVersion)")
    }
}
