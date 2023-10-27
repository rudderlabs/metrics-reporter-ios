//
//  BatchUploader.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 26/10/23.
//

import Foundation
import SQLite3


class BatchUploader : Plugin {
    weak var metricsClient: MetricsClient? {
        didSet {
            initialSetup()
        }
    }
    
    func initialSetup() {
        subscribeToChange()
    }
    
    enum SQLiteChangeType {
        case insert
        case update
        case delete
    }

    static func getSQLiteChangeType(op: Int32) -> SQLiteChangeType? {
        switch op {
        case SQLITE_INSERT:
            return .insert
        case SQLITE_UPDATE:
            return .update
        case SQLITE_DELETE:
            return .delete
        default:
            return nil // Handle any other cases if needed
        }
    }
    
    static func updateHookCallback(
        dbPointer: UnsafeMutableRawPointer?,
        operation: SQLiteChangeType?, // The type of operation (1 for INSERT, 2 for UPDATE, 3 for DELETE)
        databaseName: String?,
        tableName: String?,
        rowID: Int
    ) {
        print(tableName)
        print(operation)
    }
    
    func subscribeToChange() {
        
        
//        sqlite3_update_hook(_: OpaquePointer!, _: (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafePointer<CChar>?, UnsafePointer<CChar>?, sqlite3_int64) -> Void)!, _: UnsafeMutableRawPointer!)
        
        let dbPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        sqlite3_update_hook(Database.db, { (dbPointer, operation, dbName, tableName, rowId) in
            BatchUploader.updateHookCallback(dbPointer: dbPointer, operation: BatchUploader.getSQLiteChangeType(op: operation), databaseName: dbName.map { String(cString: $0) }, tableName: tableName.map { String(cString: $0) }, rowID: Int(rowId))
        }, dbPointer)

        
        
//        sqlite3_update_hook(Database.db, { context, operation, dbName, tblName, rowid in
//            updateHookCallback(userData: context, operation: operation, databaseName: dbName, tableName: tblName, rowID: rowid)
//        }, UnsafeMutableRawPointer(mutating:"batch"))
        
//        let dbPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
//                sqlite3_update_hook(sqliteConnection, { (dbPointer, updateKind, databaseNameCString, tableNameCString, rowID) in
//                    let db = unsafeBitCast(dbPointer, to: Database.self)
//                    db.didChange(with: DatabaseEvent(
//                        kind: DatabaseEvent.Kind(rawValue: updateKind)!,
//                        rowID: rowID,
//                        databaseNameCString: databaseNameCString,
//                        tableNameCString: tableNameCString))
//                }, dbPointer)
    }
    
    func execute<M: Metric>(metric: M?) -> M? {
        return metric
    }
    
}
