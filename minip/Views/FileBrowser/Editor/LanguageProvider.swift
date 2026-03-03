//
//  LanguageProvider.swift
//  minip
//
//  Created by LZY on 2025/2/21.
//

import Runestone
import TreeSitterCSSRunestone
import TreeSitterHTMLRunestone
import TreeSitterJSDocRunestone
import TreeSitterJSONRunestone
import TreeSitterJavaScriptRunestone
import TreeSitterMarkdownRunestone
import TreeSitterPythonRunestone
import TreeSitterRegexRunestone
import TreeSitterTypeScriptRunestone
import TreeSitterYAMLRunestone

class LanguageProvider: TreeSitterLanguageProvider {
    enum Language: String {
        case html
        case javascript
        case typescript
        case regex
        case jsdoc
        case css
        case yaml
        case python
        case markdown
    }

    func treeSitterLanguage(named languageName: String) -> Runestone.TreeSitterLanguage? {
        let l = Language(rawValue: languageName)
        switch l {
        case .html:
            return .html
        case .javascript:
            return .javaScript
        case .typescript:
            return .typeScript
        case .regex:
            return .regex
        case .jsdoc:
            return .jsDoc
        case .css:
            return .css
        case .yaml:
            return .yaml
        case .python:
            return .python
        case .markdown:
            return .markdown
        case nil:
            return nil
        }
    }
}
