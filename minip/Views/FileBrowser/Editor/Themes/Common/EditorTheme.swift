//
//  EditorTheme.swift
//  minip
//
//  Created by ByteDance on 2023/7/10.
//

import Runestone
import UIKit

public protocol EditorTheme: Runestone.Theme {
    var backgroundColor: UIColor { get }
    var userInterfaceStyle: UIUserInterfaceStyle { get }
}

extension EditorTheme {
    public var font: UIFont {
        UIFont(name: "JetBrainsMono-Regular", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
    }

    public var lineNumberFont: UIFont {
        UIFont(name: "Menlo", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)
    }
}
