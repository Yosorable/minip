//
//  TomorrowDarkTheme.swift
//  minip
//

import Runestone
import UIKit

public class TomorrowDarkTheme: EditorTheme {
    public var backgroundColor: UIColor = UIColor(hexOrCSSName: "#1D1F21")!

    public var userInterfaceStyle: UIUserInterfaceStyle = .dark

    public var textColor: UIColor = UIColor(hexOrCSSName: "#C5C8C6")!

    public var gutterBackgroundColor: UIColor = UIColor(hexOrCSSName: "#1D1F21")!

    public var gutterHairlineColor: UIColor = UIColor(hexOrCSSName: "#1D1F21")!

    public var lineNumberColor: UIColor = UIColor(hexOrCSSName: "#969896")!

    public var selectedLineBackgroundColor: UIColor = UIColor(hexOrCSSName: "#282A2E")!

    public var selectedLinesLineNumberColor: UIColor = UIColor(hexOrCSSName: "#C5C8C6")!

    public var selectedLinesGutterBackgroundColor: UIColor = UIColor(hexOrCSSName: "#282A2E")!

    public var invisibleCharactersColor: UIColor = UIColor(hexOrCSSName: "#969896")!

    public var pageGuideHairlineColor: UIColor = UIColor(hexOrCSSName: "#C5C8C6")!

    public var pageGuideBackgroundColor: UIColor = UIColor(hexOrCSSName: "#1D1F21")!

    public var markedTextBackgroundColor: UIColor = UIColor(hexOrCSSName: "#373B41")!

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
        }
        switch highlightName {
        case .comment:
            return UIColor(hexOrCSSName: "#969896")
        case .keyword, .repeat, .conditional, .include:
            return UIColor(hexOrCSSName: "#B294BB")
        case .string:
            return UIColor(hexOrCSSName: "#B5BD68")
        case .number:
            return UIColor(hexOrCSSName: "#DE935F")
        case .function, .method:
            return UIColor(hexOrCSSName: "#81A2BE")
        case .property:
            return UIColor(hexOrCSSName: "#81A2BE")
        case .type:
            return UIColor(hexOrCSSName: "#8ABEB7")
        case .tag:
            return UIColor(hexOrCSSName: "#CC6666")
        case .attribute:
            return UIColor(hexOrCSSName: "#DE935F")
        case .operator, .punctuation, .delimiter:
            return UIColor(hexOrCSSName: "#C5C8C6")
        case .variableBuiltin:
            return UIColor(hexOrCSSName: "#CC6666")
        case .constant:
            return UIColor(hexOrCSSName: "#F0C674")
        case .variable, .parameter:
            return UIColor(hexOrCSSName: "#C5C8C6")
        case .constructor:
            return UIColor(hexOrCSSName: "#8ABEB7")
        case .embedded, .none:
            return UIColor(hexOrCSSName: "#C5C8C6")
        case .escape:
            return UIColor(hexOrCSSName: "#DE935F")
        case .field:
            return UIColor(hexOrCSSName: "#CC6666")
        case .textTitle:
            return UIColor(hexOrCSSName: "#B5BD68")
        case .textLiteral:
            return UIColor(hexOrCSSName: "#B5BD68")
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
