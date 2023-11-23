//
//  Vendor.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 23/11/23.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif


#if os(iOS) || os(tvOS)
internal class PhoneVendor: Vendor {
    override var osName: String {
        return UIDevice.current.systemName
    }
    override var osVersion: String {
        return getOsVersion()
    }
}
#endif

#if os(macOS)
internal class MacVendor: Vendor {
    override var osName: String {
        return "macOS"
    }
    override var osVersion: String {
        return getOsVersion()
    }
}
#endif

#if os(watchOS)
internal class WatchVendor: Vendor {
    override var osName: String {
        return WKInterfaceDevice.current().systemName
    }
    override var osVersion: String {
        return getOsVersion()
    }
}
#endif

internal class Vendor {
    var osName: String {
        return "unknown"
    }
    var osVersion: String {
        return "unknown"
    }
    
    static var current: Vendor = {
            #if os(iOS) || os(tvOS)
            return PhoneVendor()
            #elseif os(macOS)
            return MacVendor()
            #elseif os(watchOS)
            return WatchVendor()
            #else
            return Vendor()
            #endif
        }()
}
