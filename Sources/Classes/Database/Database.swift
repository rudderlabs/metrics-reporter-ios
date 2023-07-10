//
//  Database.swift
//  CrashReporter
//
//  Created by Pallab Maiti on 22/06/23.
//

import Foundation
import SQLite3

protocol TableOperator {
    func createTable()
    func clearAll()
}

protocol MetricOperator: TableOperator {
    @discardableResult func saveMetric(name: String, value: Float, type: String, labels: String) -> MetricEntity?
    @discardableResult func updateMetric(_ metric: MetricEntity?) -> Int?
    func fetchMetric(where name: String, type: String, labels: String) -> MetricEntity?
    func fetchMetrics(where columnName: String, from valueFrom: Int, to valueTo: Int) -> [MetricEntity]?
}

protocol LabelOperator: TableOperator {
    @discardableResult func saveLabel(name: String, value: String) -> LabelEntity?
    func fetchLabel(where name: String, value: String) -> LabelEntity?
    func fetchLabels(where coulmnName: String, in value: String) -> [LabelEntity]?
}

protocol DatabaseOperator {
    @discardableResult func saveCount(_ metric: Count) -> MetricEntity?
    @discardableResult func saveGauge(_ metric: Gauge) -> MetricEntity?
    func fetchMetrics(from valueFrom: Int, to valueTo: Int) -> [any Metric]?
}

class Database: DatabaseOperator {
    private var metricOperator: MetricOperator!
    private var labelOperator: LabelOperator!
    
    init(database: OpaquePointer?) {
        metricOperator = MetricEntityOperator(database: database)
        labelOperator = LabelEntityOperator(database: database)
        metricOperator.createTable()
        labelOperator.createTable()
    }
    
    @discardableResult
    func saveCount(_ metric: Count) -> MetricEntity? {
        return saveMetric(metric)
    }
    
    @discardableResult
    func saveGauge(_ metric: Gauge) -> MetricEntity? {
        return saveMetric(metric)
    }
    
    private func saveMetric(_ metric: any Metric) -> MetricEntity? {
        var labelIdList: [Int]?
        if let attributes = metric.attributes {
            labelIdList = [Int]()
            for (name, value) in attributes {
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
    
    func fetchMetrics(from valueFrom: Int, to valueTo: Int) -> [any Metric]? {
        var metricList: [any Metric]?
        if let metricEntityList = metricOperator.fetchMetrics(where: "id", from: valueFrom, to: valueTo) {
            metricList = [any Metric]()
            for metricEntity in metricEntityList {
                var attributes: [String: String]?
                if let labelEntityList = labelOperator.fetchLabels(where: "id", in: metricEntity.labels) {
                    attributes = [String: String]()
                    for labelEntity in labelEntityList {
                        attributes?[labelEntity.name] = labelEntity.value
                    }
                }
                switch metricEntity.type {
                    case MetricType.count.rawValue:
                        let count = Count(name: metricEntity.name, attributes: attributes, value: Int(metricEntity.value))
                        metricList?.append(count)
                    case MetricType.gauge.rawValue:
                        let gauge = Gauge(name: metricEntity.name, attributes: attributes, value: metricEntity.value)
                        metricList?.append(gauge)
                    default:
                        break
                }
            }
        }
        return metricList
    }
    
    @discardableResult
    func updateCount(_ metric: Count) -> Int? {
        return updateMetric(metric)
    }
    
    @discardableResult
    func updateGauge(_ metric: Gauge) -> Int? {
        return updateMetric(metric)
    }
    
    private func updateMetric(_ metric: any Metric) -> Int? {
        var labelIdList: [Int]?
        if let attributes = metric.attributes {
            labelIdList = [Int]()
            for (name, value) in attributes {
                if let labelEntity = labelOperator.fetchLabel(where: name, value: value) {
                    labelIdList?.append(labelEntity.id)
                }
            }
        }
        var labels = ""
        if let labelIdList = labelIdList, !labelIdList.isEmpty {
            labels = (labelIdList.sorted{ $0 < $1 } as NSArray).componentsJoined(by: ",")
        }
        let metricEntity = metricOperator.fetchMetric(where: metric.name, type: metric.type.rawValue, labels: labels)
        return metricOperator.updateMetric(metricEntity)
    }
    
    /*private func getSQLiteVersion(database: OpaquePointer?) -> String? {
        var sqliteVersion: String?
        var sqlStatement: OpaquePointer?
        let versionSqlQueryString = "SELECT sqlite_version();"
        
        if sqlite3_prepare_v2(database, versionSqlQueryString, -1, &sqlStatement, nil) == SQLITE_OK {
            if sqlite3_step(sqlStatement) == SQLITE_DONE {
                if let version = sqlite3_column_text(sqlStatement, 0) {
                    sqliteVersion = String(cString: version)
                }
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
        }
        sqlite3_finalize(sqlStatement)
        return sqliteVersion
    }
    
    private func isReturnExists(database: OpaquePointer?) -> Bool {
        if let sqliteVersion = getSQLiteVersion(database: database) {
            let result = sqliteVersion.compare("3.35.0", options: .numeric)
            if result == .orderedDescending {
                return true
            } else if result == .orderedAscending {
                return false
            } else {
                return true
            }
        }
        return false
    }*/
}

extension Database {
    private static func getDBPath() -> String {
        let urlDirectory = FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
        let fileUrl = urlDirectory.appendingPathComponent("metrics.sqlite")
        return fileUrl.path
    }
    
    static func openDatabase() -> OpaquePointer? {
        var db: OpaquePointer?
        if sqlite3_open_v2(getDBPath(), &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            return db
        } else {
            return nil
        }
    }
}
