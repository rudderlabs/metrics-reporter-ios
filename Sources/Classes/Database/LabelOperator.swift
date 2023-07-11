//
//  LabelOperator.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 30/06/23.
//

import Foundation
import SQLite3
import RudderKit

struct LabelEntity {
    let id: Int
    let name: String
    let value: String
    
    init(id: Int, name: String, value: String) {
        self.id = id
        self.name = name
        self.value = value
    }
}

class LabelEntityOperator: LabelOperator {    
    private let database: OpaquePointer?
    private let syncQueue = DispatchQueue(label: "rudder.database.label")
    private let logger: Logger?

    init(database: OpaquePointer?, logger: Logger?) {
        self.database = database
        self.logger = logger
    }
    
    func createTable() {
        var createTableStatement: OpaquePointer?
        let createTableString = "CREATE TABLE IF NOT EXISTS label(id INTEGER NOT NULL, name TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY(name, value));"
        logger?.logDebug("createTableSQL: \(createTableString)")
        if sqlite3_prepare_v2(database, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                logger?.logDebug("DB Schema created")
            } else {
                logger?.logError("DB Schema creation error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            logger?.logError("DB Schema CREATE statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    @discardableResult
    func saveLabel(name: String, value: String) -> LabelEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var valueInserted = false
            var label: LabelEntity?
            let insertStatementString = "INSERT INTO label(id, name, value) VALUES ((SELECT count(*) FROM label) + 1, ?, ?);"
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 2, (value as NSString).utf8String, -1, nil)
                logger?.logDebug("saveLabelSQL: \(insertStatementString)")
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    logger?.logDebug("Label inserted to table")
                    valueInserted = true
                } else {
                    logger?.logError("Label insertion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                logger?.logError("Label INSERT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(insertStatement)
            
            if valueInserted {
                var sqlStatement: OpaquePointer?
                let versionSqlQueryString = "SELECT last_insert_rowid();"
                
                if sqlite3_prepare_v2(self.database, versionSqlQueryString, -1, &sqlStatement, nil) == SQLITE_OK {
                    if sqlite3_step(sqlStatement) == SQLITE_ROW {
                        let rowId = Int(sqlite3_column_int(sqlStatement, 0))
                        label = LabelEntity(id: rowId, name: name, value: value)
                        logger?.logDebug("Label rowId returned")
                    } else {
                        logger?.logError("Label rowId return error")
                    }
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(self.database))
                    logger?.logError("Label SELECT last_insert_rowid() statement is not prepared, Reason: \(errorMessage)")
                }
                sqlite3_finalize(sqlStatement)
            }
            return label
        }
    }
    
    func fetchLabel(where name: String, value: String) -> LabelEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var queryStatement: OpaquePointer?
            var label: LabelEntity?
            let queryStatementString = "SELECT * FROM label WHERE name=\"\(name)\" AND value=\"\(value)\";"
            logger?.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let name = String(cString: sqlite3_column_text(queryStatement, 1))
                    let value = String(cString: sqlite3_column_text(queryStatement, 2))
                    label = LabelEntity(id: id, name: name, value: value)
                    logger?.logDebug("Label returned")
                } else {
                    logger?.logError("Label not returned")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                logger?.logError("Label SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return label
        }
    }
    
    func fetchLabels(where coulmnName: String, in value: String) -> [LabelEntity]? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var queryStatement: OpaquePointer?
            var labelList: [LabelEntity]?
            let queryStatementString = "SELECT * FROM label WHERE \(coulmnName) IN (\(value));"
            logger?.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                labelList = [LabelEntity]()
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let name = String(cString: sqlite3_column_text(queryStatement, 1))
                    let value = String(cString: sqlite3_column_text(queryStatement, 2))
                    let label = LabelEntity(id: id, name: name, value: value)
                    labelList?.append(label)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                logger?.logError("Label SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return labelList
        }
    }
    
    func clearAll() {
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var deleteStatement: OpaquePointer?
            let deleteStatementString = "DELETE FROM label;"
            if sqlite3_prepare_v2(self.database, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                logger?.logDebug("deleteEventSQL: \(deleteStatementString)")
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    logger?.logDebug("Labels deleted from DB")
                } else {
                    logger?.logError("Label deletion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                logger?.logError("Label DELETE statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(deleteStatement)
        }
    }
}
