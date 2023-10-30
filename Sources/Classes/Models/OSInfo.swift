//
//  OSInfo.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 30/10/23.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

struct OSInfo {
    
    static let name : String = {
#if os(iOS) || os(tvOS)
        UIDevice.current.systemName
#elseif os(watchOS)
        WKInterfaceDevice.current().systemName
#elseif os(macOS)
        "macOS"
#endif
    }()
    
    static let version  = "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
}
