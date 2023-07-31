//
//  ErrorOperator.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 27/07/23.
//

import Foundation
import SQLite3
import RudderKit

struct ErrorEntity {
    let id: Int
    let events: String
    var eventList: [[String: Any]]? {
        return events.convert()
    }
    
    init(id: Int, events: String) {
        self.id = id
        self.events = events
    }
}

class ErrorOperator: ErrorOperations {
    private let database: OpaquePointer?
    private let syncQueue = DispatchQueue(label: "rudder.database.error")
    
    init(database: OpaquePointer?) {
        self.database = database
    }
    
    func createTable() {
        let createTableString = "CREATE TABLE IF NOT EXISTS error(id INTEGER NOT NULL, events TEXT NOT NULL, PRIMARY KEY(id AUTOINCREMENT));"
        let tableCreator = TableCreator(database: database, createTableString: createTableString)
        tableCreator.createTable()
    }
    
    @discardableResult
    func saveError(events: String) -> ErrorEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var error: ErrorEntity?
            let insertStatementString = "INSERT INTO error(events) VALUES (?) RETURNING id;"
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (events as NSString).utf8String, -1, nil)
                Logger.logDebug("saveLabelSQL: \(insertStatementString)")
                if sqlite3_step(insertStatement) == SQLITE_ROW {
                    let rowId = Int(sqlite3_column_int(insertStatement, 0))
                    error = ErrorEntity(id: rowId, events: events)
                    Logger.logDebug("Error inserted to table")
                } else {
                    Logger.logError("Error insertion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Error INSERT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(insertStatement)
            return error
        }
    }
    
    func fetchErrors(count: Int) -> [ErrorEntity]? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var queryStatement: OpaquePointer?
            var errorList: [ErrorEntity]?
            let queryStatementString = "SELECT * FROM error ASC LIMIT \(count);"
            Logger.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                errorList = [ErrorEntity]()
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let events = String(cString: sqlite3_column_text(queryStatement, 1))
                    let error = ErrorEntity(id: id, events: events)
                    errorList?.append(error)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Error SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return (errorList?.isEmpty ?? true) ? nil : errorList
        }
    }
    
    func clearError(where ids: String) {
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var deleteStatement: OpaquePointer?
            let deleteStatementString = "DELETE FROM error WHERE \"id\" IN (\(ids));"
            if sqlite3_prepare_v2(self.database, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                Logger.logDebug("deleteEventSQL: \(deleteStatementString)")
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    Logger.logDebug("Labels deleted from DB")
                } else {
                    Logger.logError("Label deletion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Label DELETE statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(deleteStatement)
        }
    }
    
    func clearAll() {
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var deleteStatement: OpaquePointer?
            let deleteStatementString = "DELETE FROM error;"
            if sqlite3_prepare_v2(self.database, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                Logger.logDebug("deleteEventSQL: \(deleteStatementString)")
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    Logger.logDebug("Labels deleted from DB")
                } else {
                    Logger.logError("Label deletion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Label DELETE statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(deleteStatement)
        }
    }
    
    func resetTable() {
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var deleteStatement: OpaquePointer?
            let deleteStatementString = "UPDATE sqlite_sequence SET seq=0 WHERE name=\"error\";"
            if sqlite3_prepare_v2(self.database, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                Logger.logDebug("deleteEventSQL: \(deleteStatementString)")
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    Logger.logDebug("Labels deleted from DB")
                } else {
                    Logger.logError("Label deletion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Label DELETE statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(deleteStatement)
        }
    }
}
