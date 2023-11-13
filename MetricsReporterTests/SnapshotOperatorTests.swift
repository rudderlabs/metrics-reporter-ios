//
//  SnapshotOperatorTests.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import XCTest
@testable import MetricsReporter

final class SnapshotOperatorTests: XCTestCase {
    var snapshotOperator: SnapshotOperations!
    
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
        snapshotOperator = SnapshotOperator(database: database)
        snapshotOperator.createTable()
        clearAll()
    }
    
    func test_saveSnapshot() {
        let sampleBatch = getSampleBatch(i: 1)
        let snapshot = snapshotOperator.saveSnapshot(batch: sampleBatch)
        
        XCTAssertNotNil(snapshot)
        XCTAssertNotNil(snapshot?.uuid)
        XCTAssertEqual(snapshot?.batch, sampleBatch)
    }
    
    func test_getSnapshot() {
        for i in 1...2 {
            let sampleBatch = getSampleBatch(i: i)
            snapshotOperator.saveSnapshot(batch: sampleBatch)
        }
        
        let snapshot = snapshotOperator.getSnapshot()
        
        XCTAssertNotNil(snapshot)
        XCTAssertNotNil(snapshot?.uuid)
        XCTAssertEqual(snapshot?.batch, getSampleBatch(i: 1))
    }
    
    
    func test_clearSnapshot() {
        var firstInsertedUUID: String?
        for i in 1...2 {
            let sampleBatch = getSampleBatch(i: i)
            let snapShotEntity = snapshotOperator.saveSnapshot(batch: sampleBatch)
            if (i == 1) {
                firstInsertedUUID = snapShotEntity?.uuid
            }
        }
        
        var snapshot = snapshotOperator.getSnapshot()
        
        XCTAssertNotNil(snapshot)
        XCTAssertNotNil(snapshot?.uuid)
        XCTAssertEqual(snapshot?.batch, getSampleBatch(i: 1))
        
        snapshotOperator.clearSnapshot(where: firstInsertedUUID!)
        XCTAssertEqual(snapshotOperator.getCount(), 1)
        
        snapshot = snapshotOperator.getSnapshot()
        
        XCTAssertNotNil(snapshot)
        XCTAssertNotNil(snapshot?.uuid)
        XCTAssertEqual(snapshot?.batch, getSampleBatch(i: 2))
    }
    
    func test_getCount() {
        var lastInsertedUUID: String?
        for i in 1...5 {
            let sampleBatch = getSampleBatch(i: i)
            let snapshotEntity = snapshotOperator.saveSnapshot(batch: sampleBatch)
            lastInsertedUUID = snapshotEntity?.uuid
        }

        XCTAssertEqual(snapshotOperator.getCount(), 5)
        snapshotOperator.clearSnapshot(where: lastInsertedUUID!)
        XCTAssertEqual(snapshotOperator.getCount(), 4)
    }
    
    func test_clearAll() {
        for i in 1...5 {
            let sampleBatch = getSampleBatch(i: i)
            snapshotOperator.saveSnapshot(batch: sampleBatch)
        }

        XCTAssertEqual(snapshotOperator.getCount(), 5)
        snapshotOperator.clearAll()
        XCTAssertEqual(snapshotOperator.getCount(), 0)
    }
    
    override func tearDown() {
        super.tearDown()
        clearAll()
        snapshotOperator = nil
    }
    
    func clearAll() {
        snapshotOperator.clearAll()
    }
}

