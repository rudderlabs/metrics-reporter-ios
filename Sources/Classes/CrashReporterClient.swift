//
//  CrashReporterClient.swift
//  CrashReporter
//
//  Created by Pallab Maiti on 19/06/23.
//

import Foundation
import RSCrashReporter

public class CrashReporterClient {
    
    public init() {
        RSCrashReporter.start(withApiKey: "df5da4234cd9883c66557a2b9b75c082")
    }
    
    
}
