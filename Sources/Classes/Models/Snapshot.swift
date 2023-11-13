//
//  Snapshot.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 02/11/23.
//

import Foundation

struct Snapshot {
    let uuid: String
    let batch: String
    
    init(uuid: String, batch: String) {
        self.uuid = uuid
        self.batch = batch
    }
}
