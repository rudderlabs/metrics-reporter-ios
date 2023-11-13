//
//  SnapshotOperator.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 23/10/23.
//

import Foundation
import SQLite3
import RudderKit

struct SnapshotEntity {
    let uuid: String
    let batch: String
    
    init(uuid: String, batch: String) {
        self.uuid = uuid
        self.batch = batch
    }
}

class SnapshotOperator: SnapshotOperations {
    
    private let database: OpaquePointer?
    private let syncQueue = DispatchQueue(label: "rudder.database.snapshot")

    init(database: OpaquePointer?) {
        self.database = database
    }
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS snapshot(uuid TEXT PRIMARY KEY NOT NULL, batch TEXT NOT NULL);"
        let tableCreator = TableCreator(database: database, createTableString: createTableString)
        tableCreator.createTable()
    }
    
    @discardableResult
    func saveSnapshot(batch: String) -> SnapshotEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            let insertStatementString = "INSERT INTO snapshot(uuid, batch) VALUES (?, ?);"
            var snapshotEntity: SnapshotEntity?
            var insertStatement: OpaquePointer?
            let uuid = UUID().uuidString
            if sqlite3_prepare_v2(self.database, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (uuid as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, (batch as NSString).utf8String, -1, nil)
                Logger.logDebug("saveSnapshotSQL: \(insertStatementString)")
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Insert.Snapshot.success)
                    snapshotEntity = SnapshotEntity(uuid: uuid, batch: batch)
                } else {
                    Logger.logError(Constants.Messages.Insert.Snapshot.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Insert.snapshot), Reason: \(errorMessage)")
            }
            sqlite3_finalize(insertStatement)
            return snapshotEntity
        }
    }
    
    func getSnapshot() -> SnapshotEntity? {
        var snapshotEntity: SnapshotEntity?
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "SELECT * FROM snapshot LIMIT 1;"
            Logger.logDebug("getSnapshotSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    let uuid = String(cString: sqlite3_column_text(queryStatement, 0))
                    let batch  = String(cString: sqlite3_column_text(queryStatement, 1))
                    snapshotEntity = SnapshotEntity(uuid: uuid, batch: batch)
                    Logger.logDebug(Constants.Messages.Select.Snapshot.success)
                } else {
                    Logger.logError(Constants.Messages.Select.Snapshot.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Select.snapshot), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
        return snapshotEntity
    }
    
    func getCount() -> Int {
        syncQueue.sync { [weak self] in
            guard let self = self else { return 0 }
            var queryStatement: OpaquePointer?
            var count = 0
            let queryStatementString = "SELECT count(*) FROM snapshot;"
            Logger.logDebug("snapShotCountSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(queryStatement, 0))
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Select.snapshot), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return count
        }
    }
    
    func clearSnapshot(where uuid: String) {
        syncQueue.sync { [weak self] in
            guard let self = self else {return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "DELETE FROM snapshot where uuid = \"\(uuid)\";"
            Logger.logDebug("clearSnapshotSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Delete.Snapshot.success)
                } else {
                    Logger.logError(Constants.Messages.Delete.Snapshot.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Delete.snapshot), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
    }
    
    func clearAll() {
        syncQueue.sync { [weak self] in
            guard let self = self else {return }
            var queryStatement: OpaquePointer?
            let queryStatementString = "DELETE FROM snapshot;"
            Logger.logDebug("clearSnapshotSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_DONE {
                    Logger.logDebug(Constants.Messages.Delete.Snapshot.success)
                } else {
                    Logger.logError(Constants.Messages.Delete.Snapshot.failed)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("\(Constants.Messages.Statement.Delete.snapshot), Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
        }
    }

}
