//
//  LabelOperatorTests.swift
//  MetricsReporterTests
//
//  Created by Pallab Maiti on 14/07/23.
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

final class LabelOperatorTests: XCTestCase {
    var labelOperator: LabelOperations!

    override func setUp() {
        super.setUp()
        let database = openDatabase()
        labelOperator = LabelOperator(database: database)
        labelOperator.createTable()
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
    
    func test_fetchLabel() {
        labelOperator.saveLabel(name: "label_1", value: "value_1")
        let label = labelOperator.fetchLabel(where: "label_1", value: "value_1")
        
        XCTAssertNotNil(label)
        XCTAssertEqual(label!.id, 1)
        XCTAssertEqual(label!.name, "label_1")
        XCTAssertEqual(label!.value, "value_1")
        clearAll()
    }
    
    func test_fetchLabels_byId() {
        let label1 = labelOperator.saveLabel(name: "label_1", value: "value_1")
        XCTAssertNotNil(label1)
        
        let label2 = labelOperator.saveLabel(name: "label_2", value: "value_2")
        XCTAssertNotNil(label2)
        
        let labelList = labelOperator.fetchLabels(where: "id", in: ["\(label1!.id)", "\(label2!.id)"])
        
        XCTAssertNotNil(labelList)
        XCTAssertTrue(labelList!.count == 2)
        
        let labelE1 = labelList?[0]
        
        XCTAssertNotNil(labelE1)
        XCTAssertEqual(labelE1!.id, 1)
        XCTAssertEqual(labelE1!.name, "label_1")
        XCTAssertEqual(labelE1!.value, "value_1")
        
        let labelE2 = labelList?[1]
        
        XCTAssertNotNil(labelE2)
        XCTAssertEqual(labelE2!.id, 2)
        XCTAssertEqual(labelE2!.name, "label_2")
        XCTAssertEqual(labelE2!.value, "value_2")
        clearAll()
    }
    
    func test_fetchLabels_byName() {
        let label1 = labelOperator.saveLabel(name: "label_1", value: "value_1")
        XCTAssertNotNil(label1)
        
        let label2 = labelOperator.saveLabel(name: "label_2", value: "value_2")
        XCTAssertNotNil(label2)
        
        let labelList = labelOperator.fetchLabels(where: "name", in: [label1!.name, label2!.name])
        
        XCTAssertNotNil(labelList)
        XCTAssertTrue(labelList!.count == 2)
        
        let labelE1 = labelList?[0]
        
        XCTAssertNotNil(labelE1)
        XCTAssertEqual(labelE1!.id, 1)
        XCTAssertEqual(labelE1!.name, "label_1")
        XCTAssertEqual(labelE1!.value, "value_1")
        
        let labelE2 = labelList?[1]
        
        XCTAssertNotNil(labelE2)
        XCTAssertEqual(labelE2!.id, 2)
        XCTAssertEqual(labelE2!.name, "label_2")
        XCTAssertEqual(labelE2!.value, "value_2")
        clearAll()
    }
    
    func test_clearAll() {
        let label1 = labelOperator.saveLabel(name: "label_1", value: "value_1")
        XCTAssertNotNil(label1)
        
        let label2 = labelOperator.saveLabel(name: "label_2", value: "value_2")
        XCTAssertNotNil(label2)
        
        labelOperator.clearAll()
        
        let labelList = labelOperator.fetchLabels(where: "name", in: [label1!.name, label2!.name])
        XCTAssertNil(labelList)
        clearAll()
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        labelOperator = nil
    }
    
    func clearAll() {
        labelOperator.clearAll()
    }
}
