//
//  Polyfill.swift
//  minip
//
//  Created by LZY on 2023/8/24.
//

import Foundation
import SwiftUI

extension URL {
    func appendingPolyfill(path: String) -> URL {
        if #available(iOS 16.0, *) {
            return self.appending(path: path)
        } else {
            return self.appendingPathComponent(path)
        }
    }

    func appendingPolyfill(component: String) -> URL {
        if #available(iOS 16.0, *) {
            return self.appending(component: component)
        } else {
            return self.appendingPathComponent(component)
        }
    }
}

extension String {
    func splitPolyfill(separator: String) -> [String] {
        return self.components(separatedBy: separator)
    }
}

extension EnvironmentValues {
    var dismissPolyfill: () -> Void {
        if #available(iOS 15.0, *) {
            return { self.dismiss() }
        } else {
            return { presentationMode.wrappedValue.dismiss() }
        }
    }
}
