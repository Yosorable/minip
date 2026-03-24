//
//  LSPModels.swift
//  minip
//

import Foundation

struct LSPPosition: Codable {
    let line: Int
    let character: Int
}

struct LSPRange: Codable {
    let start: LSPPosition
    let end: LSPPosition
}

struct LSPTextEdit: Codable {
    let range: LSPRange
    let newText: String
}

struct LSPCompletionItem: Codable {
    let label: String
    let kind: Int?
    let detail: String?
    let documentation: LSPDocumentation?
    let insertText: String?
    let insertTextFormat: Int?
    let textEdit: LSPTextEdit?
    let filterText: String?
    let sortText: String?

    var displayLabel: String { label }

    var textToInsert: String {
        if let edit = textEdit {
            return edit.newText
        }
        return insertText ?? label
    }

    var kindIcon: String {
        guard let kind = kind else { return "circle" }
        switch kind {
        case 1: return "doc.text"           // Text
        case 2: return "m.square"           // Method
        case 3: return "f.square"           // Function
        case 4: return "cube"               // Constructor
        case 5: return "character"          // Field
        case 6: return "v.square"           // Variable
        case 7: return "c.square"           // Class
        case 9: return "list.bullet"        // Module
        case 10: return "p.square"          // Property
        case 14: return "k.square"          // Keyword
        case 15: return "text.quote"        // Snippet
        case 21: return "number"            // Constant
        case 22: return "s.square"          // Struct
        case 25: return "tag"               // Unit / Tag
        default: return "circle"
        }
    }
}

enum LSPDocumentation: Codable {
    case string(String)
    case markupContent(MarkupContent)

    struct MarkupContent: Codable {
        let kind: String
        let value: String
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let markup = try? container.decode(MarkupContent.self) {
            self = .markupContent(markup)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str): try container.encode(str)
        case .markupContent(let mc): try container.encode(mc)
        }
    }

    var text: String {
        switch self {
        case .string(let s): return s
        case .markupContent(let mc): return mc.value
        }
    }
}

struct LSPCompletionList: Codable {
    let isIncomplete: Bool
    let items: [LSPCompletionItem]
}

struct LSPParameterInformation: Codable {
    let label: String
}

struct LSPSignatureInformation: Codable {
    let label: String
    let documentation: String?
    let parameters: [LSPParameterInformation]
}

struct LSPSignatureHelp: Codable {
    let signatures: [LSPSignatureInformation]
    let activeSignature: Int
    let activeParameter: Int
}

struct LSPDiagnostic: Codable {
    let range: LSPRange
    let severity: Int?
    let message: String
    let source: String?

    var isError: Bool { severity == 1 }
    var isWarning: Bool { severity == 2 }
}

enum EditorLanguageType {
    case html
    case css
    case javascript
    case other

    init(extension ext: String) {
        switch ext.lowercased() {
        case "html", "htm": self = .html
        case "css": self = .css
        case "js", "jsx": self = .javascript
        default: self = .other
        }
    }

    var supportsLanguageService: Bool {
        self == .html || self == .css || self == .javascript
    }
}
