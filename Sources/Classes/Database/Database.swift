//
//  Database.swift
//  CrashReporter
//
//  Created by Pallab Maiti on 22/06/23.
//

import Foundation
import SQLite3
import RudderKit

class TableCreator {
    private let database: OpaquePointer?
    private let createTableString: String
    
    init(database: OpaquePointer?, createTableString: String) {
        self.database = database
        self.createTableString = createTableString
    }
    
    func createTable() {
        var createTableStatement: OpaquePointer?
        Logger.logDebug("createTableSQL: \(createTableString)")
        if sqlite3_prepare_v2(database, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
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
}

protocol TableOperations {
    func createTable()
    func clearAll()
}

protocol MetricOperations: TableOperations {
    @discardableResult func saveMetric(name: String, value: Float, type: String, labels: String) -> MetricEntity?
    @discardableResult func updateMetric(_ metric: MetricEntity?, updatedValue: Float) -> Int?
    func fetchMetric(where name: String, type: String, labels: String) -> MetricEntity?
    func fetchMetrics(where columnName: String, startingFrom id: Int, withLimit limit: Int) -> (metricEntities: [MetricEntity]?, lastMetricId: Int?)
}

protocol LabelOperations: TableOperations {
    @discardableResult func saveLabel(name: String, value: String) -> LabelEntity?
    func fetchLabel(where name: String, value: String) -> LabelEntity?
    func fetchLabels(where coulmnName: String, in values: [String]) -> [LabelEntity]?
}

protocol ErrorOperations: TableOperations {
    @discardableResult func saveError(events: String) -> ErrorEntity?
    func fetchErrors(count: Int) -> [ErrorEntity]?
    func clearError(where ids: String)
    func resetTable()
    func getCount() -> Int
}

protocol BatchOperations: TableOperations {
    @discardableResult func saveBatch(batch: String) -> BatchEntity?
    func getBatch() -> BatchEntity?
    func clearBatch(where id: Int)
    func getCount() -> Int
}

protocol DatabaseOperations {
    @discardableResult func saveMetric<M: Metric>(_ metric: M) -> MetricEntity?
    func fetchMetrics(startingFromId id: Int, withLimit limit: Int) -> (metricsList: MetricList, lastMetricId: Int?)
    @discardableResult func updateMetric<M: Metric>(_ metric: M) -> Int?
    @discardableResult func saveError(events: String) -> ErrorEntity?
    @discardableResult func saveBatch(batch: String) -> BatchEntity?
    func fetchErrors(count: Int) -> [ErrorEntity]?
    func clearErrorList(_ errorList: [ErrorEntity])
    func clearAllMetrics()
    func clearAllErrors()
    func resetErrorTable()
    func getErrorsCount() -> Int
}

class Database: DatabaseOperations {
    private var metricOperator: MetricOperations!
    private var labelOperator: LabelOperations!
    private var errorOperator: ErrorOperations!
    private var batchOperator: BatchOperations!
    
    init(database: OpaquePointer?) {
        metricOperator = MetricOperator(database: database)
        labelOperator = LabelOperator(database: database)
        errorOperator = ErrorOperator(database: database)
        batchOperator = BatchOperator(database: database)
        metricOperator.createTable()
        labelOperator.createTable()
        errorOperator.createTable()
        batchOperator.createTable()
    }
    
    @discardableResult
    func saveMetric<M: Metric>(_ metric: M) -> MetricEntity? {
        var labelIdList: [Int]?
        if let labels = metric.labels {
            labelIdList = [Int]()
            for (name, value) in labels {
                if let labelEntity = labelOperator.saveLabel(name: name, value: value) {
                    labelIdList?.append(labelEntity.id)
                } else {
                    if let labelEntity = labelOperator.fetchLabel(where: name, value: value) {
                        labelIdList?.append(labelEntity.id)
                    }
                }
            }
        }
        var labels = ""
        if let labelIdList = labelIdList, !labelIdList.isEmpty {
            labels = (labelIdList.sorted{ $0 < $1 } as NSArray).componentsJoined(by: ",")
        }
        var value: Float = 0.0
        switch metric {
        case let m as Count:
            value = Float(m.value)
        case let m as Gauge:
            value = m.value
        default:
            break
        }
        return metricOperator.saveMetric(name: metric.name, value: value, type: metric.type.rawValue, labels: labels)
    }
    
    func fetchMetrics(startingFromId id: Int, withLimit limit: Int) -> (metricsList: MetricList, lastMetricId: Int?) {
        var countList: [Count]?
        var gaugeList: [Gauge]?
        let (metricEntityList, lastMetricId) = metricOperator.fetchMetrics(where: "id", startingFrom:id, withLimit:limit)
        if let metricEntityList = metricEntityList {
            countList = [Count]()
            gaugeList = [Gauge]()
            for metricEntity in metricEntityList {
                var labels: [String: String]?
                if let labelEntityList = labelOperator.fetchLabels(where: "id", in: metricEntity.labels.components(separatedBy: ",")) {
                    labels = [String: String]()
                    for labelEntity in labelEntityList {
                        labels?[labelEntity.name] = labelEntity.value
                    }
                }
                switch metricEntity.type {
                case MetricType.count.rawValue:
                    let count = Count(name: metricEntity.name, labels: labels, value: Int(metricEntity.value))
                    countList?.append(count)
                case MetricType.gauge.rawValue:
                    let gauge = Gauge(name: metricEntity.name, labels: labels, value: metricEntity.value)
                    gaugeList?.append(gauge)
                default:
                    break
                }
            }
        }
        return (MetricList(countList: countList, gaugeList: gaugeList), lastMetricId)
    }
    
    @discardableResult
    func updateMetric<M: Metric>(_ metric: M) -> Int? {
        var labelIdList: [Int]?
        if let labels = metric.labels {
            labelIdList = [Int]()
            for (name, value) in labels {
                if let labelEntity = labelOperator.fetchLabel(where: name, value: value) {
                    labelIdList?.append(labelEntity.id)
                }
            }
        }
        var labels = ""
        if let labelIdList = labelIdList, !labelIdList.isEmpty {
            labels = (labelIdList.sorted{ $0 < $1 } as NSArray).componentsJoined(by: ",")
        }
        guard let metricEntity = metricOperator.fetchMetric(where: metric.name, type: metric.type.rawValue, labels: labels) else {
            return nil
        }
        var newValue: Float = 0.0
        switch metric {
        case let m as Count:
            newValue = Float(m.value)
        case let m as Gauge:
            newValue = m.value
        default:
            break
        }
        // todo: why would the new value be greater than the current value, because in this case new value is actually the count when making the
        // last request and why are doing newValue - metricEntity.value (very confused with the variable namings and the logic
        let updatedValue: Float = (newValue > metricEntity.value) ? (newValue - metricEntity.value) : (metricEntity.value - newValue)
        return metricOperator.updateMetric(metricEntity, updatedValue: updatedValue)
    }
    
    @discardableResult
    func saveError(events: String) -> ErrorEntity? {
        return errorOperator.saveError(events: events)
    }
    
    func saveBatch(batch: String) -> BatchEntity? {
        return batchOperator.saveBatch(batch: batch)
    }
    
    func fetchErrors(count: Int) -> [ErrorEntity]? {
        return errorOperator.fetchErrors(count: count)
    }
    
    func clearErrorList(_ errorList: [ErrorEntity]) {
        let ids = errorList.compactMap({ errorEntity in
            return errorEntity.id
        })
        errorOperator.clearError(where: NSArray(array: ids).componentsJoined(by: ","))
    }
    
    func resetErrorTable() {
        errorOperator.resetTable()
    }
    
    func clearAllMetrics() {
        metricOperator.clearAll()
        labelOperator.clearAll()
    }
    
    func clearAllErrors() {
        errorOperator.clearAll()
    }
    
    func getErrorsCount() -> Int {
        return errorOperator.getCount()
    }
}

extension Database {
    private static func getDBPath() -> String {
        let urlDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let fileUrl = urlDirectory.appendingPathComponent("metrics.sqlite")
        return fileUrl.path
    }
    
    static var db: OpaquePointer?
    static func openDatabase() -> OpaquePointer? {
        if (db != nil) {
            return db
        }
        if sqlite3_open_v2(getDBPath(), &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            return db
        } else {
            return nil
        }
    }
}
