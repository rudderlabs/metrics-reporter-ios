//
//  MetricsClientTests.swift
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
//import ObjectiveC

final class MetricsClientTests: XCTestCase {
    
    func test_MetricsClient() {
        let configuration = Configuration(logLevel: .none, writeKey: "WRITE_KEY", sdkVersion: "some.version")
        let client = MetricsClient(configuration: configuration)
        
        XCTAssertNotNil(client)
    }
    
}
