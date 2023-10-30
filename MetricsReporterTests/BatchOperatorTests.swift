//
//  BatchOperatorTests.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import XCTest
@testable import MetricsReporter

final class BatchOperatorTests: XCTestCase {
    var batchOperator: BatchOperations!
    
    func getSampleBatch(i: Int) -> String {
        return  """
    {
      "source" : {
        "name" : "ios",
        "sdk_version" : "1.3.3",
        "write_key" : "WRITE_KEY"
      },
      "metrics" : [
        {
          "labels" : {
            "key\(i)" : "value_\(i)"
          },
          "name" : "test_count_\(i)",
          "type" : "count",
          "value" : \(i)
        }
      ],
      "version" : "1"
    }
    """
    }
    
    
    override func setUp() {
        super.setUp()
        let database = openDatabase()
        batchOperator = BatchOperator(database: database)
        batchOperator.createTable()
        clearAll()
    }
    
    func test_saveBatch() {
        let sampleBatch = getSampleBatch(i: 1)
        let batch = batchOperator.saveBatch(batch: sampleBatch)
        
        XCTAssertNotNil(batch)
        XCTAssertNotNil(batch?.uuid)
        XCTAssertNotNil(batch?.id)
        XCTAssertEqual(batch?.batch, sampleBatch)
    }
    
    func test_getBatch() {
        for i in 1...2 {
            let sampleBatch = getSampleBatch(i: i)
            batchOperator.saveBatch(batch: sampleBatch)
        }
        
        let batch = batchOperator.getBatch()
        
        XCTAssertNotNil(batch)
        XCTAssertNotNil(batch?.id)
        XCTAssertNotNil(batch?.uuid)
        XCTAssertEqual(batch?.batch, getSampleBatch(i: 1))
    }
    
    
    func test_clearBatch() {
        var firstInsertedId: Int?
        for i in 1...2 {
            let sampleBatch = getSampleBatch(i: i)
            let batchEntity = batchOperator.saveBatch(batch: sampleBatch)
            if (i == 1) {
                firstInsertedId = batchEntity?.id
            }
        }
        
        var batch = batchOperator.getBatch()
        
        XCTAssertNotNil(batch)
        XCTAssertNotNil(batch?.id)
        XCTAssertNotNil(batch?.uuid)
        XCTAssertEqual(batch?.batch, getSampleBatch(i: 1))
        
        batchOperator.clearBatch(where: firstInsertedId!)
        XCTAssertEqual(batchOperator.getCount(), 1)
        
        batch = batchOperator.getBatch()
        
        XCTAssertNotNil(batch)
        XCTAssertNotNil(batch?.id)
        XCTAssertNotNil(batch?.uuid)
        XCTAssertEqual(batch?.batch, getSampleBatch(i: 2))
    }
    
    func test_getCount() {
        var lastInsertedId: Int?
        for i in 1...5 {
            let sampleBatch = getSampleBatch(i: i)
            let batchEntity = batchOperator.saveBatch(batch: sampleBatch)
            lastInsertedId = batchEntity?.id
        }

        XCTAssertEqual(batchOperator.getCount(), 5)
        batchOperator.clearBatch(where: lastInsertedId!)
        XCTAssertEqual(batchOperator.getCount(), 4)
    }
    
    func test_clearAll() {
        for i in 1...5 {
            let sampleBatch = getSampleBatch(i: i)
            batchOperator.saveBatch(batch: sampleBatch)
        }

        XCTAssertEqual(batchOperator.getCount(), 5)
        batchOperator.clearAll()
        XCTAssertEqual(batchOperator.getCount(), 0)
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        batchOperator = nil
    }
    
    func clearAll() {
        batchOperator.clearAll()
    }
}

