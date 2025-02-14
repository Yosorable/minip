//
//  VSCodeDark.swift
//  minip
//
//  Created by ByteDance on 2023/7/13.
//

import Runestone
import UIKit

public class VSCodeDarkTheme: EditorTheme {
    public var backgroundColor: UIColor = .init(hex: "#1f1f1f")!

    public var userInterfaceStyle: UIUserInterfaceStyle = .dark

    public var font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var textColor: UIColor = .init(hex: "#aeafad")!

    public var gutterBackgroundColor: UIColor = .black // UIColor(hex: "#1f1f1f")!

    public var gutterHairlineColor: UIColor = .black // UIColor(hex: "#1f1f1f")!

    public var lineNumberColor: UIColor = .init(hex: "#6f7680")!

    public var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var selectedLineBackgroundColor: UIColor = .init(hex: "#1f1f1f")!

    public var selectedLinesLineNumberColor: UIColor = .init(hex: "#cccccc")!

    public var selectedLinesGutterBackgroundColor: UIColor = .init(hex: "#1f1f1f")!

    public var invisibleCharactersColor: UIColor = .init(hex: "#aeafad")!

    public var pageGuideHairlineColor: UIColor = .init(hex: "#aeafad")!

    public var pageGuideBackgroundColor: UIColor = .init(hex: "#1f1f1f")!

    public var markedTextBackgroundColor: UIColor = .init(hex: "#304e75")!

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
        }
        switch highlightName {
        case .comment:
            return UIColor(hex: "#74985d")
        case .operator, .punctuation:
            return UIColor(hex: "#d4d4d4")
        case .property:
            return UIColor(hex: "#aadafa")
        case .function:
            return UIColor(hex: "#dcdcaf")
        case .string:
            return UIColor(hex: "#c5947c")
        case .number:
            return UIColor(hex: "#bacdab")
        case .keyword:
            return UIColor(hex: "#679ad1")
        case .variableBuiltin:
            return UIColor(hex: "#aadafa")
        case .tag:
            return UIColor(hex: "#679ad1")
        case .attribute:
            return UIColor(hex: "#aadafa")
        case .type:
            return UIColor(hex: "#71c6b1")
        }
    }

    public func fontTraits(for rawHighlightName: String) -> FontTraits {
        if let highlightName = HighlightName(rawHighlightName), highlightName == .keyword {
            return .bold
        } else {
            return []
        }
    }
}
