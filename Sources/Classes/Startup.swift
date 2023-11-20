//
//  Startup.swift
//  MetricsReporter
//
//  Created by Pallab Maiti on 28/08/23.
//

import Foundation

extension MetricsClient {
    internal func platformStartup() {
        add(plugin: CrashReporter())
        add(plugin: SnapshotGenerator())
        add(plugin: MetricsIngestor())
    }

    @discardableResult
    func add(plugin: MetricsPlugin) -> MetricsPlugin {
        plugin.configure(metricsClient: self)
        controller.add(plugin: plugin)
        return plugin
    }
}
