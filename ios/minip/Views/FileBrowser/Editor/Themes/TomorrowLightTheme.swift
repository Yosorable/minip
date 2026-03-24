//
//  TomorrowLightTheme.swift
//  minip
//

import Runestone
import UIKit

public class TomorrowLightTheme: EditorTheme {
    public var backgroundColor: UIColor = UIColor(hexOrCSSName: "#FAFAFA")!

    public var userInterfaceStyle: UIUserInterfaceStyle = .light

    public var textColor: UIColor = UIColor(hexOrCSSName: "#4D4D4C")!

    public var gutterBackgroundColor: UIColor = UIColor(hexOrCSSName: "#FAFAFA")!

    public var gutterHairlineColor: UIColor = UIColor(hexOrCSSName: "#FAFAFA")!

    public var lineNumberColor: UIColor = UIColor(hexOrCSSName: "#8E908C")!

    public var selectedLineBackgroundColor: UIColor = UIColor(hexOrCSSName: "#EFEFEF")!

    public var selectedLinesLineNumberColor: UIColor = UIColor(hexOrCSSName: "#4D4D4C")!

    public var selectedLinesGutterBackgroundColor: UIColor = UIColor(hexOrCSSName: "#EFEFEF")!

    public var invisibleCharactersColor: UIColor = UIColor(hexOrCSSName: "#8E908C")!

    public var pageGuideHairlineColor: UIColor = UIColor(hexOrCSSName: "#4D4D4C")!

    public var pageGuideBackgroundColor: UIColor = UIColor(hexOrCSSName: "#FAFAFA")!

    public var markedTextBackgroundColor: UIColor = UIColor(hexOrCSSName: "#D6D6D6")!

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
        }
        switch highlightName {
        case .comment:
            return UIColor(hexOrCSSName: "#8E908C")
        case .keyword, .repeat, .conditional, .include:
            return UIColor(hexOrCSSName: "#8959A8")
        case .string:
            return UIColor(hexOrCSSName: "#718C00")
        case .number:
            return UIColor(hexOrCSSName: "#F5871F")
        case .function, .method:
            return UIColor(hexOrCSSName: "#4271AE")
        case .property:
            return UIColor(hexOrCSSName: "#4271AE")
        case .type:
            return UIColor(hexOrCSSName: "#3E999F")
        case .tag:
            return UIColor(hexOrCSSName: "#C82829")
        case .attribute:
            return UIColor(hexOrCSSName: "#F5871F")
        case .operator, .punctuation, .delimiter:
            return UIColor(hexOrCSSName: "#4D4D4C")
        case .variableBuiltin:
            return UIColor(hexOrCSSName: "#C82829")
        case .constant:
            return UIColor(hexOrCSSName: "#EAB700")
        case .variable, .parameter:
            return UIColor(hexOrCSSName: "#4D4D4C")
        case .constructor:
            return UIColor(hexOrCSSName: "#3E999F")
        case .embedded, .none:
            return UIColor(hexOrCSSName: "#4D4D4C")
        case .escape:
            return UIColor(hexOrCSSName: "#F5871F")
        case .field:
            return UIColor(hexOrCSSName: "#C82829")
        case .textTitle:
            return UIColor(hexOrCSSName: "#718C00")
        case .textLiteral:
            return UIColor(hexOrCSSName: "#718C00")
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
