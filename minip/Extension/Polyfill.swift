//
//  Polyfill.swift
//  minip
//
//  Created by LZY on 2023/8/24.
//

import Foundation

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
