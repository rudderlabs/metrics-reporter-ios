//
//  BatchOperator.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 23/10/23.
//

import Foundation
import SQLite3
import RudderKit

struct BatchEntity {
    let id: Int
    let uuid: String
    let batch: String
    
    init(id:Int, uuid: String, batch: String) {
        self.id = id
        self.uuid = uuid
        self.batch = batch
    }
}

class BatchOperator: BatchOperations {
    private let database: OpaquePointer?
    private let syncQueue = DispatchQueue(label: "rudder.database.batch")

    init(database: OpaquePointer?) {
        self.database = database
    }
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS batch(id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT NOT NULL, batch TEXT NOT NULL);"
        let tableCreator = TableCreator(database: database, createTableString: createTableString)
        tableCreator.createTable()
    }
    
    @discardableResult
    func saveBatch(batch: String) -> BatchEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            let insertStatementString = "INSERT INTO batch(uuid, batch) VALUES (?, ?);"
            var batchEntity: BatchEntity?
            var insertStatement: OpaquePointer?
            let uuid = UUID().uuidString
            if sqlite3_prepare_v2(self.database, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (uuid as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, (batch as NSString).utf8String, -1, nil)
                Logger.logDebug("saveEventSQL: \(insertStatementString)")
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Insert.Batch.success)
                    let rowId = Int(sqlite3_last_insert_rowid(self.database))
                    batchEntity = BatchEntity(id: rowId, uuid: uuid, batch: batch)
                } else {
                    Logger.logError(Constants.Messages.Insert.Batch.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Insert.batch), Reason: \(errorMessage)")
            }
            sqlite3_finalize(insertStatement)
            return batchEntity
        }
    }
    
    func getBatch() -> BatchEntity? {
        var batchEntity: BatchEntity?
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "SELECT * FROM batch ORDER BY id LIMIT 1;"
            Logger.logDebug("getBatchSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let uuid = String(cString: sqlite3_column_text(queryStatement, 1))
                    let batch  = String(cString: sqlite3_column_text(queryStatement, 2))
                    batchEntity = BatchEntity(id: id, uuid: uuid, batch: batch)
                    Logger.logDebug(Constants.Messages.Select.Batch.success)
                } else {
                    Logger.logError(Constants.Messages.Select.Batch.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Select.batch), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
        return batchEntity
    }
    
    func getCount() -> Int {
        syncQueue.sync { [weak self] in
            guard let self = self else { return 0 }
            var queryStatement: OpaquePointer?
            var count = 0
            let queryStatementString = "SELECT count(*) FROM batch;"
            Logger.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(queryStatement, 0))
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Select.batch), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return count
        }
    }
    
    func clearBatch(where id: Int) {
        syncQueue.sync { [weak self] in
            guard let self = self else {return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "DELETE * FROM batch where id = \(id);"
            Logger.logDebug("clearBatchSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Delete.Batch.success)
                } else {
                    Logger.logError(Constants.Messages.Delete.Batch.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Delete.batch), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
    }
    
    func clearAll() {
        syncQueue.sync { [weak self] in
            guard let self = self else {return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "DELETE * FROM batch;"
            Logger.logDebug("clearBatchSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Delete.Batch.success)
                } else {
                    Logger.logError(Constants.Messages.Delete.Batch.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Delete.batch), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
    }

}
