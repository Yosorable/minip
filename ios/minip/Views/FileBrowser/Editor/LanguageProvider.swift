//
//  LanguageProvider.swift
//  minip
//
//  Created by LZY on 2025/2/21.
//

import Runestone
import TreeSitterBashRunestone
import TreeSitterCRunestone
import TreeSitterCPPRunestone
import TreeSitterCSSRunestone
import TreeSitterGoRunestone
import TreeSitterHTMLRunestone
import TreeSitterJavaRunestone
import TreeSitterJavaScriptRunestone
import TreeSitterJSDocRunestone
import TreeSitterJSON5Runestone
import TreeSitterJSONRunestone
import TreeSitterLuaRunestone
import TreeSitterMarkdownInlineRunestone
import TreeSitterMarkdownRunestone
import TreeSitterPHPRunestone
import TreeSitterPythonRunestone
import TreeSitterRegexRunestone
import TreeSitterRubyRunestone
import TreeSitterRustRunestone
import TreeSitterSCSSRunestone
import TreeSitterSQLRunestone
import TreeSitterSwiftRunestone
import TreeSitterTOMLRunestone
import TreeSitterTSXRunestone
import TreeSitterTypeScriptRunestone
import TreeSitterYAMLRunestone

class LanguageProvider: TreeSitterLanguageProvider {
    enum Language: String {
        case bash
        case c
        case cpp
        case css
        case go
        case html
        case java
        case javascript
        case jsdoc
        case json5
        case lua
        case markdown
        case markdown_inline
        case php
        case python
        case regex
        case ruby
        case rust
        case scss
        case sql
        case swift
        case toml
        case tsx
        case typescript
        case yaml
    }

    func treeSitterLanguage(named languageName: String) -> Runestone.TreeSitterLanguage? {
        let normalized: String
        switch languageName.lowercased() {
        case "js", "jsx": normalized = "javascript"
        case "ts": normalized = "typescript"
        case "yml": normalized = "yaml"
        case "htm": normalized = "html"
        case "md": normalized = "markdown"
        case "py": normalized = "python"
        case "c++", "cc", "cxx", "hpp": normalized = "cpp"
        case "h", "m", "mm": normalized = "c"
        case "sh", "zsh", "shell": normalized = "bash"
        case "rb": normalized = "ruby"
        case "rs": normalized = "rust"
        case "golang": normalized = "go"
        default: normalized = languageName.lowercased()
        }
        let l = Language(rawValue: normalized)
        switch l {
        case .bash: return .bash
        case .c: return .c
        case .cpp: return .cpp
        case .css: return .css
        case .go: return .go
        case .html: return .html
        case .java: return .java
        case .javascript: return .javaScript
        case .jsdoc: return .jsDoc
        case .json5: return .json5
        case .lua: return .lua
        case .markdown: return .markdown
        case .markdown_inline: return .markdownInline
        case .php: return .php
        case .python: return .python
        case .regex: return .regex
        case .ruby: return .ruby
        case .rust: return .rust
        case .scss: return .scss
        case .sql: return .sql
        case .swift: return .swift
        case .toml: return .toml
        case .tsx: return .tsx
        case .typescript: return .typeScript
        case .yaml: return .yaml
        case nil: return nil
        }
    }
}
