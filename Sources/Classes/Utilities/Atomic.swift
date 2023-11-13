//
//  Atomic.swift
//  MetricsReporter
//
//  Created by Desu Sai Venkat on 13/11/23.
//

import Foundation

@propertyWrapper
public class Atomic<T> {
    private var value: T
    private let queue = DispatchQueue(label: "rudder.atomic.\(UUID().uuidString)")

    public init(wrappedValue value: T) {
        self.value = value
    }

    public var wrappedValue: T {
        get { return queue.sync { return value } }
        set { queue.sync { value = newValue } }
    }
}
