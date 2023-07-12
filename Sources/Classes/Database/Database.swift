//
//  Database.swift
//  CrashReporter
//
//  Created by Pallab Maiti on 22/06/23.
//

import Foundation
import SQLite3
import RudderKit

protocol TableOperations {
    func createTable()
    func clearAll()
}

protocol MetricOperations: TableOperations {
    @discardableResult func saveMetric(name: String, value: Float, type: String, labels: String) -> MetricEntity?
    @discardableResult func updateMetric(_ metric: MetricEntity?) -> Int?
    func fetchMetric(where name: String, type: String, labels: String) -> MetricEntity?
    func fetchMetrics(where columnName: String, from valueFrom: Int, to valueTo: Int) -> [MetricEntity]?
}

protocol LabelOperations: TableOperations {
    @discardableResult func saveLabel(name: String, value: String) -> LabelEntity?
    func fetchLabel(where name: String, value: String) -> LabelEntity?
    func fetchLabels(where coulmnName: String, in value: String) -> [LabelEntity]?
}

protocol DatabaseOperations {
    @discardableResult func saveMetric<M: Metric>(_ metric: M) -> MetricEntity?
    func fetchMetrics(from valueFrom: Int, to valueTo: Int) -> MetricList
    @discardableResult func updateMetric<M: Metric>(_ metric: M) -> Int?
}

class Database: DatabaseOperations {
    private var metricOperator: MetricOperations!
    private var labelOperator: LabelOperations!
    
    init(database: OpaquePointer?) {
        metricOperator = MetricOperator(database: database)
        labelOperator = LabelOperator(database: database)
        metricOperator.createTable()
        labelOperator.createTable()
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
    
    func fetchMetrics(from valueFrom: Int, to valueTo: Int) -> MetricList {
        var countList: [Count]?
        var gaugeList: [Gauge]?
        if let metricEntityList = metricOperator.fetchMetrics(where: "id", from: valueFrom, to: valueTo) {
            countList = [Count]()
            gaugeList = [Gauge]()
            for metricEntity in metricEntityList {
                var labels: [String: String]?
                if let labelEntityList = labelOperator.fetchLabels(where: "id", in: metricEntity.labels) {
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
        return MetricList(countList: countList, gaugeList: gaugeList)
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
        let metricEntity = metricOperator.fetchMetric(where: metric.name, type: metric.type.rawValue, labels: labels)
        return metricOperator.updateMetric(metricEntity)
    }
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
