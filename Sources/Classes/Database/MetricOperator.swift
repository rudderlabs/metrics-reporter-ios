//
//  MetricOperator.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 30/06/23.
//

import Foundation
import SQLite3
import RudderKit

struct MetricEntity {
    let id: Int
    let name: String
    let value: Float
    let type: String
    let labels: String
    
    init(id: Int, name: String, value: Float, type: String, labels: String) {
        self.id = id
        self.name = name
        self.value = value
        self.type = type
        self.labels = labels
    }
}

class MetricOperator: MetricOperations {
    private let database: OpaquePointer?
    private let syncQueue = DispatchQueue(label: "rudder.database.metric")

    init(database: OpaquePointer?) {
        self.database = database
    }
    
    func createTable() {
        var createTableStatement: OpaquePointer?
        let createTableString = "CREATE TABLE IF NOT EXISTS metric(id INTEGER NOT NULL, name TEXT NOT NULL, value NUMERIC NOT NULL, type TEXT NOT NULL, labels TEXT NOT NULL, PRIMARY KEY(name, type, labels));"
        Logger.logDebug("createTableSQL: \(createTableString)")
        if sqlite3_prepare_v2(database, createTableString, -1, &createTableStatement, nil) ==
            SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                Logger.logDebug("DB Schema created")
            } else {
                Logger.logError("DB Schema creation error")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            Logger.logError("DB Schema CREATE statement is not prepared, Reason: \(errorMessage)")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    @discardableResult
    func saveMetric(name: String, value: Float, type: String, labels: String) -> MetricEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var metric: MetricEntity?
            let insertStatementString = "INSERT INTO metric(id, name, value, type, labels) VALUES ((SELECT count(*) FROM metric) + 1, ?, ?, ?, ?) ON CONFLICT(name, type, labels) DO UPDATE SET value=value+excluded.value RETURNING id;"
            var insertStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.database, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(insertStatement, 1, (name as NSString).utf8String, -1, nil)
                sqlite3_bind_double(insertStatement, 2, Float64(value))
                sqlite3_bind_text(insertStatement, 3, (type as NSString).utf8String, -1, nil)
                sqlite3_bind_text(insertStatement, 4, (labels as NSString).utf8String, -1, nil)
                Logger.logDebug("saveEventSQL: \(insertStatementString)")
                if sqlite3_step(insertStatement) == SQLITE_ROW {
                    let rowId = Int(sqlite3_column_int(insertStatement, 0))
                    metric = MetricEntity(id: rowId, name: name, value: value, type: type, labels: labels)
                    Logger.logDebug("Metric inserted to table")
                } else {
                    Logger.logError("Metric insertion error")
                }
                
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Metric INSERT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(insertStatement)
            return metric
        }
    }
    
    func fetchMetric(where name: String, type: String, labels: String) -> MetricEntity? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var queryStatement: OpaquePointer?
            var metric: MetricEntity?
            let queryStatementString = "SELECT * FROM metric WHERE name=\"\(name)\" AND type=\"\(type)\" AND labels=\"\(labels)\";"
            Logger.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let name = String(cString: sqlite3_column_text(queryStatement, 1))
                    let value = Float(sqlite3_column_double(queryStatement, 2))
                    let type = String(cString: sqlite3_column_text(queryStatement, 3))
                    let labels = String(cString: sqlite3_column_text(queryStatement, 4))
                    metric = MetricEntity(id: id, name: name, value: value, type: type, labels: labels)
                    Logger.logDebug("Metric returned")
                } else {
                    Logger.logError("Metric return error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Metric SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return metric
        }
    }
    
    func fetchMetrics(where columnName: String, from valueFrom: Int, to valueTo: Int) -> [MetricEntity]? {
        syncQueue.sync { [weak self] in
            guard let self = self else { return nil }
            var queryStatement: OpaquePointer?
            var metricList: [MetricEntity]?
            let queryStatementString = "SELECT * FROM metric WHERE \(columnName) BETWEEN \(valueFrom) AND \(valueTo);"
            Logger.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                metricList = [MetricEntity]()
                while sqlite3_step(queryStatement) == SQLITE_ROW {
                    let id = Int(sqlite3_column_int(queryStatement, 0))
                    let name = String(cString: sqlite3_column_text(queryStatement, 1))
                    let value = Float(sqlite3_column_double(queryStatement, 2))
                    let type = String(cString: sqlite3_column_text(queryStatement, 3))
                    let labels = String(cString: sqlite3_column_text(queryStatement, 4))
                    let metric = MetricEntity(id: id, name: name, value: value, type: type, labels: labels)
                    metricList?.append(metric)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Metric SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return metricList
        }
    }
    
    @discardableResult
    func updateMetric(_ metric: MetricEntity?) -> Int? {
        syncQueue.sync { [weak self] in
            guard let self = self, let metric = metric else { return nil }
            var queryStatement: OpaquePointer?
            let queryStatementString = "UPDATE metric SET value=((SELECT value FROM metric WHERE name=\(metric.name) AND type=\(metric.type) AND labels=\(metric.labels)) - \(metric.value)) WHERE name=\(metric.name) AND type=\(metric.type) AND labels=\(metric.labels);"
            Logger.logDebug("countSQL: \(queryStatementString)")
            if sqlite3_prepare_v2(self.database, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                if sqlite3_step(queryStatement) == SQLITE_DONE {
                    Logger.logDebug("Metric updated")
                } else {
                    Logger.logError("Metric updation error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Metric SELECT statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(queryStatement)
            return metric.id
        }
    }
    
    func clearAll() {
        syncQueue.sync { [weak self] in
            guard let self = self else { return }
            var deleteStatement: OpaquePointer?
            let deleteStatementString = "DELETE FROM metric;"
            if sqlite3_prepare_v2(self.database, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
                Logger.logDebug("deleteEventSQL: \(deleteStatementString)")
                if sqlite3_step(deleteStatement) == SQLITE_DONE {
                    Logger.logDebug("Metrics deleted from DB")
                } else {
                    Logger.logError("Metric deletion error")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(self.database))
                Logger.logError("Metric DELETE statement is not prepared, Reason: \(errorMessage)")
            }
            sqlite3_finalize(deleteStatement)
        }
    }
}
