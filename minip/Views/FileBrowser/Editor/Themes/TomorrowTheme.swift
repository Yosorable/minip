//
//  TomorrowTheme.swift
//  minip
//

import Runestone
import UIKit

public class TomorrowTheme: EditorTheme {
    public var backgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#1D1F21")!
            : UIColor(hexOrCSSName: "#FAFAFA")!
    }

    public var userInterfaceStyle: UIUserInterfaceStyle = .unspecified

    public var font: UIFont = UIFont(name: "JetBrainsMono-Regular", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var textColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#C5C8C6")!
            : UIColor(hexOrCSSName: "#4D4D4C")!
    }

    public var gutterBackgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#1D1F21")!
            : UIColor(hexOrCSSName: "#FAFAFA")!
    }

    public var gutterHairlineColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#1D1F21")!
            : UIColor(hexOrCSSName: "#FAFAFA")!
    }

    public var lineNumberColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#969896")!
            : UIColor(hexOrCSSName: "#8E908C")!
    }

    public var lineNumberFont: UIFont = UIFont(name: "Menlo", size: 14) ?? .monospacedSystemFont(ofSize: 14, weight: .regular)

    public var selectedLineBackgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#282A2E")!
            : UIColor(hexOrCSSName: "#EFEFEF")!
    }

    public var selectedLinesLineNumberColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#C5C8C6")!
            : UIColor(hexOrCSSName: "#4D4D4C")!
    }

    public var selectedLinesGutterBackgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#282A2E")!
            : UIColor(hexOrCSSName: "#EFEFEF")!
    }

    public var invisibleCharactersColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#969896")!
            : UIColor(hexOrCSSName: "#8E908C")!
    }

    public var pageGuideHairlineColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#C5C8C6")!
            : UIColor(hexOrCSSName: "#4D4D4C")!
    }

    public var pageGuideBackgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#1D1F21")!
            : UIColor(hexOrCSSName: "#FAFAFA")!
    }

    public var markedTextBackgroundColor: UIColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hexOrCSSName: "#373B41")!
            : UIColor(hexOrCSSName: "#D6D6D6")!
    }

    public func textColor(for rawHighlightName: String) -> UIColor? {
        guard let highlightName = HighlightName(rawHighlightName) else {
            return nil
        }
        switch highlightName {
        case .comment:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#969896")!
                    : UIColor(hexOrCSSName: "#8E908C")!
            }
        case .keyword:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#B294BB")!
                    : UIColor(hexOrCSSName: "#8959A8")!
            }
        case .string:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#B5BD68")!
                    : UIColor(hexOrCSSName: "#718C00")!
            }
        case .number:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#DE935F")!
                    : UIColor(hexOrCSSName: "#F5871F")!
            }
        case .function:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#81A2BE")!
                    : UIColor(hexOrCSSName: "#4271AE")!
            }
        case .property:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#81A2BE")!
                    : UIColor(hexOrCSSName: "#4271AE")!
            }
        case .type:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#8ABEB7")!
                    : UIColor(hexOrCSSName: "#3E999F")!
            }
        case .tag:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#CC6666")!
                    : UIColor(hexOrCSSName: "#C82829")!
            }
        case .attribute:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#DE935F")!
                    : UIColor(hexOrCSSName: "#F5871F")!
            }
        case .operator, .punctuation:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#C5C8C6")!
                    : UIColor(hexOrCSSName: "#4D4D4C")!
            }
        case .variableBuiltin:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#CC6666")!
                    : UIColor(hexOrCSSName: "#C82829")!
            }
        case .constant:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#F0C674")!
                    : UIColor(hexOrCSSName: "#EAB700")!
            }
        case .variable:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#C5C8C6")!
                    : UIColor(hexOrCSSName: "#4D4D4C")!
            }
        case .constructor:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#8ABEB7")!
                    : UIColor(hexOrCSSName: "#3E999F")!
            }
        case .embedded:
            return UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(hexOrCSSName: "#C5C8C6")!
                    : UIColor(hexOrCSSName: "#4D4D4C")!
            }
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
