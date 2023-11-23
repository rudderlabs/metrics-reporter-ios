//
//  AppleUtils.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 23/11/23.
//

import Foundation

func getOsVersion() -> String {
    return "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
}
