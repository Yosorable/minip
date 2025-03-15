//
//  VSCodeDark.swift
//  minip
//
//  Created by ByteDance on 2023/7/13.
//

import Runestone
import UIKit

public class VSCodeDarkTheme: EditorTheme {
    public var backgroundColor: UIColor = .init(hexOrCSSName: "#1f1f1f")!

    public var userInterfaceStyle: UIUserInterfaceStyle = .dark

    public var font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var textColor: UIColor = .init(hexOrCSSName: "#aeafad")!

    public var gutterBackgroundColor: UIColor = .black // UIColor(hex: "#1f1f1f")!

    public var gutterHairlineColor: UIColor = .black // UIColor(hex: "#1f1f1f")!

    public var lineNumberColor: UIColor = .init(hexOrCSSName: "#6f7680")!

    public var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var selectedLineBackgroundColor: UIColor = .init(hexOrCSSName: "#1f1f1f")!

    public var selectedLinesLineNumberColor: UIColor = .init(hexOrCSSName: "#cccccc")!

    public var selectedLinesGutterBackgroundColor: UIColor = .init(hexOrCSSName: "#1f1f1f")!

    public var invisibleCharactersColor: UIColor = .init(hexOrCSSName: "#aeafad")!

    public var pageGuideHairlineColor: UIColor = .init(hexOrCSSName: "#aeafad")!

    public var pageGuideBackgroundColor: UIColor = .init(hexOrCSSName: "#1f1f1f")!

    public var markedTextBackgroundColor: UIColor = .init(hexOrCSSName: "#304e75")!

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
        }
        switch highlightName {
        case .comment:
            return UIColor(hexOrCSSName: "#74985d")
        case .operator, .punctuation:
            return UIColor(hexOrCSSName: "#d4d4d4")
        case .property:
            return UIColor(hexOrCSSName: "#aadafa")
        case .function:
            return UIColor(hexOrCSSName: "#dcdcaf")
        case .string:
            return UIColor(hexOrCSSName: "#c5947c")
        case .number:
            return UIColor(hexOrCSSName: "#bacdab")
        case .keyword:
            return UIColor(hexOrCSSName: "#679ad1")
        case .variableBuiltin:
            return UIColor(hexOrCSSName: "#aadafa")
        case .tag:
            return UIColor(hexOrCSSName: "#679ad1")
        case .attribute:
            return UIColor(hexOrCSSName: "#aadafa")
        case .type:
            return UIColor(hexOrCSSName: "#71c6b1")
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
