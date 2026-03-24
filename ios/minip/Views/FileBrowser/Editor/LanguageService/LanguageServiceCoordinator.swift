//
//  LanguageServiceCoordinator.swift
//  minip
//

import Foundation

protocol LanguageServiceDelegate: AnyObject {
    func languageService(didReceiveCompletions items: [LSPCompletionItem])
    func languageService(didReceiveSignatureHelp help: LSPSignatureHelp)
    func languageService(didReceiveDiagnostics diagnostics: [LSPDiagnostic])
}

class LanguageServiceCoordinator {
    weak var delegate: LanguageServiceDelegate?

    let languageType: EditorLanguageType
    private let jsBridge: JSBridge
    private let uri: String

    private var diagnosticTimer: Timer?
    private var completionTimer: Timer?

    private let diagnosticDebounce: TimeInterval = 0.5

    /// VS Code trigger characters per language
    static let htmlTriggerChars: Set<Character> = ["<", "/", "!", "-", "\"", "'", "=", ".", ":", "#", "@", "("]
    static let cssTriggerChars: Set<Character> = [":", ".", "#", "!", "@", "-", "/", "("]
    static let jsTriggerChars: Set<Character> = ["."]

    func triggerCharacters() -> Set<Character> {
        switch languageType {
        case .html: return Self.htmlTriggerChars
        case .css: return Self.cssTriggerChars
        case .javascript: return Self.jsTriggerChars
        default: return []
        }
    }

    init(languageType: EditorLanguageType, uri: String) {
        self.languageType = languageType
        self.uri = uri
        self.jsBridge = JSBridge()
    }

    func documentDidChange(text: String) {
        diagnosticTimer?.invalidate()
        diagnosticTimer = Timer.scheduledTimer(withTimeInterval: diagnosticDebounce, repeats: false) { [weak self] _ in
            self?.requestDiagnostics(text: text)
        }
    }

    func requestCompletion(text: String, line: Int, character: Int) {
        completionTimer?.invalidate()
        performCompletion(text: text, line: line, character: character)
    }

    func requestCompletionDebounced(text: String, line: Int, character: Int) {
        completionTimer?.invalidate()
        completionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            self?.performCompletion(text: text, line: line, character: character)
        }
    }

    func cancelCompletion() {
        completionTimer?.invalidate()
    }

    func requestSignatureHelp(text: String, line: Int, character: Int) {
        guard text.count < 500_000 else { return }

        let handler: (String?) -> Void = { [weak self] jsonString in
            guard let self, let json = jsonString, let data = json.data(using: .utf8) else { return }
            do {
                let help = try JSONDecoder().decode(LSPSignatureHelp.self, from: data)
                self.delegate?.languageService(didReceiveSignatureHelp: help)
            } catch {
                print("[LanguageService] Decode signature help error: \(error)")
            }
        }

        switch languageType {
        case .javascript:
            jsBridge.jsSignatureHelp(uri: uri, text: text, line: line, character: character, completion: handler)
        case .html:
            jsBridge.htmlSignatureHelp(uri: uri, text: text, line: line, character: character, completion: handler)
        default:
            break
        }
    }

    // MARK: - Private

    private func performCompletion(text: String, line: Int, character: Int) {
        // Skip for large files
        guard text.count < 500_000 else { return }

        let handler: (String?) -> Void = { [weak self] jsonString in
            guard let self, let json = jsonString, let data = json.data(using: .utf8) else { return }
            do {
                let list = try JSONDecoder().decode(LSPCompletionList.self, from: data)
                self.delegate?.languageService(didReceiveCompletions: list.items)
            } catch {
                print("[LanguageService] Decode completion error: \(error)")
            }
        }

        switch languageType {
        case .html:
            jsBridge.htmlComplete(uri: uri, text: text, line: line, character: character, completion: handler)
        case .css:
            jsBridge.cssComplete(uri: uri, text: text, line: line, character: character, completion: handler)
        case .javascript:
            jsBridge.jsComplete(uri: uri, text: text, line: line, character: character, completion: handler)
        default:
            break
        }
    }

    private func requestDiagnostics(text: String) {
        guard text.count < 500_000 else { return }

        let handler: (String?) -> Void = { [weak self] jsonString in
            guard let self, let json = jsonString, let data = json.data(using: .utf8) else { return }
            do {
                let diagnostics = try JSONDecoder().decode([LSPDiagnostic].self, from: data)
                self.delegate?.languageService(didReceiveDiagnostics: diagnostics)
            } catch {
                print("[LanguageService] Decode diagnostics error: \(error)")
            }
        }

        switch languageType {
        case .html:
            jsBridge.htmlValidate(uri: uri, text: text, completion: handler)
        case .css:
            jsBridge.cssValidate(uri: uri, text: text, completion: handler)
        case .javascript:
            jsBridge.jsValidate(uri: uri, text: text, completion: handler)
        default:
            break
        }
    }

    deinit {
        diagnosticTimer?.invalidate()
        completionTimer?.invalidate()
    }
}
