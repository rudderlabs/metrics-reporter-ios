//
//  DatabaseObserver.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 01/11/23.
//

import Foundation
import RudderKit
import SQLite3

enum SQLiteChangeType {
    case insert
    case update
    case delete
}

struct DatabaseObserverCallback {
    let changeType: SQLiteChangeType
    let callback: () -> Void
}


class DatabaseObserver {
    
    private let database: OpaquePointer?
    private static var registeredObservers =  [String: DatabaseObserverCallback]()
    
    init(database: OpaquePointer?) {
        self.database = database
    }
    
    func subscribeToDatabaseUpdates() {
        do {
            try registerWithSQLiteForDatabaseUpdates()
        } catch {
            Logger.logError("error while registering for database updates with SQLite \(error.localizedDescription)")
        }
    }
    
    func registerWithSQLiteForDatabaseUpdates() throws {
        let dbPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        sqlite3_update_hook(database, { (dbPointer, operation, dbName, tableName, rowId) in
            DatabaseObserver.updateHookCallback(dbPointer: dbPointer, operation: DatabaseObserver.getSQLiteChangeType(op: operation), databaseName: dbName.map { String(cString: $0) }, tableName: tableName.map { String(cString: $0) }, rowId: Int(rowId))
        }, dbPointer)
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
    
    static func addObserver(tableName:String, changeType: SQLiteChangeType, callback: @escaping () -> Void) {
        registeredObservers[tableName] = DatabaseObserverCallback(changeType: changeType, callback: callback)
    }
    
    static func updateHookCallback(
        dbPointer: UnsafeMutableRawPointer?,
        operation: SQLiteChangeType?, // The type of operation (1 for INSERT, 2 for UPDATE, 3 for DELETE)
        databaseName: String?,
        tableName: String?,
        rowId: Int
    ) {
        guard
            let tableName = tableName,
            let operation = operation,
            let registeredObserver = registeredObservers[tableName],
            registeredObserver.changeType == operation
        else {
            return
        }
        registeredObserver.callback()
    }
}
