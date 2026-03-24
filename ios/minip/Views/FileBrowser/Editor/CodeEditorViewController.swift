//
//  CodeEditorViewController.swift
//  minip
//
//  Created by LZY on 2025/3/13.
//

import KeyboardToolbar
import ProgressHUD
import Runestone
import SwiftUI
import UIKit

struct InsertTextKeyboardTool: KeyboardTool {
    let displayRepresentation: KeyboardToolDisplayRepresentation

    private let text: String
    private weak var textView: TextView?

    init(text: String, textView: TextView?) {
        self.displayRepresentation = .text(text)
        self.text = text
        self.textView = textView
    }

    func performAction() {
        textView?.insertText(text)
    }
}

let SourceCodeType: [String: TreeSitterLanguage] = [
    "c": .c,
    "cc": .cpp,
    "cpp": .cpp,
    "css": .css,
    "cxx": .cpp,
    "go": .go,
    "h": .c,
    "hpp": .cpp,
    "html": .html,
    "java": .java,
    "js": .javaScript,
    "json": .json,
    "json5": .json5,
    "lua": .lua,
    "m": .c,
    "md": .markdown,
    "mm": .cpp,
    "php": .php,
    "py": .python,
    "rb": .ruby,
    "rs": .rust,
    "scss": .scss,
    "sh": .bash,
    "sql": .sql,
    "swift": .swift,
    "toml": .toml,
    "ts": .typeScript,
    "tsx": .tsx,
    "yaml": .yaml,
    "yml": .yaml,
]

class CodeEditorViewController: UIViewController {
    var textView: TextView?
    var fileString: String = ""
    var language: TreeSitterLanguage?
    let fileInfo: FileInfo
    let readyOnlyText: String?
    var theme: EditorTheme

    // Language Service
    private var coordinator: LanguageServiceCoordinator?
    private let completionPopup = CompletionPopupView()
    private let editorLanguageType: EditorLanguageType
    private var isApplyingCompletion = false
    private var completionWordStart: Int = 0
    private var isInCompletionSession = false
    private var keyboardHeight: CGFloat = 0
    private var didJustType = false
    private var lastTypedText: String?
    private var isInTextChangeCycle = false
    private let diagnosticOverlay = DiagnosticOverlayView()
    private var trackedDiagnostics: [(range: NSRange, isError: Bool, message: String)] = []
    private let diagnosticTooltip = DiagnosticTooltipView()
    private let signatureHelpView = SignatureHelpView()
    private var currentSignatureHelp: LSPSignatureHelp?
    private var currentDiagnosticTooltipIndex: Int?
    private var diagnosticLayoutTimer: Timer?
    private var cachedText: String?

    lazy var keyboardToolbarView = KeyboardToolbarView()
    lazy var saveButton = {
        var btn = UIBarButtonItem(title: i18n("Save"), style: .plain, target: self, action: #selector(save))
        btn.isEnabled = false
        return btn
    }()

    static func defaultTheme() -> EditorTheme {
        UITraitCollection.current.userInterfaceStyle == .dark ? TomorrowDarkTheme() : TomorrowLightTheme()
    }

    init(fileInfo: FileInfo, lang: TreeSitterLanguage? = nil, readyOnlyText: String? = nil, theme: EditorTheme? = nil) {
        self.fileInfo = fileInfo
        self.readyOnlyText = readyOnlyText
        self.theme = theme ?? Self.defaultTheme()
        self.editorLanguageType = EditorLanguageType(extension: fileInfo.url.pathExtension)

        if let lang = lang ?? SourceCodeType[fileInfo.url.pathExtension] {
            self.language = lang
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //        navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(close))
        title = fileInfo.fileName

        var txt = readyOnlyText
        let readonly = readyOnlyText != nil
        var err: Error? = nil

        if txt == nil {
            do {
                let fileData = try Data(contentsOf: fileInfo.url)
                if let tmp = String(data: fileData, encoding: .utf8) {
                    txt = tmp
                } else {
                    throw ErrorMsg(errorDescription: "Cannot read this file as a text file.")
                }
            } catch {
                err = error
            }
        }

        if let txt = txt {
            fileString = txt
            let textView = TextView()
            textView.theme = theme
            self.textView = textView
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.backgroundColor = theme.backgroundColor
            view.overrideUserInterfaceStyle = theme.userInterfaceStyle

            if !readonly {
                navigationItem.rightBarButtonItem = saveButton
                textView.editorDelegate = self
                textView.inputAccessoryView = keyboardToolbarView
                let notificationCenter = NotificationCenter.default
                notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
                notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            } else {
                textView.isEditable = false
            }

            setCustomization(on: textView)
            setTextViewState(on: textView)
            view.addSubview(textView)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.topAnchor.constraint(equalTo: view.topAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])

            if !readonly && editorLanguageType.supportsLanguageService {
                setupLanguageService()
            }
        } else {
            let label = UILabel()
            label.text = "Cannot read this file."
            label.textColor = .secondaryLabel
            label.font = UIFont.systemFont(ofSize: 17)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .systemBackground
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -50),
            ])

            if let err = err {
                showSimpleError(err: err)
            }
        }

    }

    @objc func close() {
        dismiss(animated: true)
    }

    @objc func save() {
        guard let text = textView?.text else {
            return
        }
        do {
            try text.write(to: fileInfo.url, atomically: true, encoding: .utf8)
            fileString = text
            saveButton.isEnabled = false
        } catch {
            showSimpleError(err: error)
        }
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            let savedOffset = textView!.contentOffset
            textView!.contentInset = .zero
            textView!.scrollIndicatorInsets = .zero
            if savedOffset.y < -textView!.adjustedContentInset.top {
                textView!.contentOffset = savedOffset
            }
            keyboardHeight = 0
        } else {
            keyboardHeight = keyboardViewEndFrame.height
            textView!.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
            textView!.scrollIndicatorInsets = textView!.contentInset
            let selectedRange = textView!.selectedRange
            textView!.scrollRangeToVisible(selectedRange)
        }
    }

    private func setCustomization(on textView: TextView) {
        //        textView.showLineNumbers = true
        textView.lineSelectionDisplayType = .line
        //        textView.showPageGuide = true
        //        textView.pageGuideColumn = 80
        //        textView.showTabs = true
        //        textView.showSpaces = true
        //        textView.showLineBreaks = true
        //        textView.showSoftLineBreaks = true
        //        textView.lineHeightMultiplier = 1.1
        textView.isFindInteractionEnabled = true
        textView.keyboardDismissMode = .interactiveWithAccessory
        textView.alwaysBounceVertical = true
        textView.contentInsetAdjustmentBehavior = .always
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

        setupKeyboardTools()
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.autocapitalizationType = .none

        textView.smartDashesType = .no
        textView.smartQuotesType = .no
        textView.smartInsertDeleteType = .no

        struct BasicCharacterPair: CharacterPair {
            let leading: String
            let trailing: String
        }

        textView.characterPairs = [
            BasicCharacterPair(leading: "(", trailing: ")"),
            BasicCharacterPair(leading: "{", trailing: "}"),
            BasicCharacterPair(leading: "[", trailing: "]"),
            BasicCharacterPair(leading: "\"", trailing: "\""),
            BasicCharacterPair(leading: "'", trailing: "'"),
        ]

        textView.indentStrategy = .space(length: 2)
    }

    private func setTextViewState(on textView: TextView) {
        let text = fileString
        textView.text = text

        guard let lang = language else {
            return
        }

        // MARK: todo: large file or minified file, optimize disable hight strategy

        DispatchQueue.global(qos: .userInitiated).async {
            var totalLines = 0
            var maxLineLength = 0
            var totalChars = 0

            text.enumerateLines { (line, stop) in
                totalLines += 1
                maxLineLength = max(maxLineLength, line.count)
                totalChars += line.count

                if maxLineLength > 20_000 || totalLines > 100_000 {
                    stop = true
                }
            }

            if totalLines > 100_000 || totalChars > 3_000_000 || maxLineLength > 20_000 {
                DispatchQueue.main.async {
                    ProgressHUD.banner("Warning", "This file contains long lines, disable highlight.", delay: 1.5)
                }
            } else {
                let state = TextViewState(text: text, theme: self.theme, language: lang, languageProvider: LanguageProvider())
                DispatchQueue.main.async {
                    textView.setState(state)
                    // Re-layout diagnostics after setState — selectionRects needs full layout
                    if !self.trackedDiagnostics.isEmpty {
                        self.scheduleDiagnosticLayout()
                    }
                }
            }
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        diagnosticOverlay.isHidden = true
        dismissCompletion()
        signatureHelpView.hide()
        currentSignatureHelp = nil
        diagnosticTooltip.hide()
        currentDiagnosticTooltipIndex = nil
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            if !self.trackedDiagnostics.isEmpty {
                self.layoutDiagnosticOverlay()
            }
            self.diagnosticOverlay.isHidden = false
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.bannerHide()
        ProgressHUD.dismiss()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateTheme(Self.defaultTheme())
        }
    }

    func updateTheme(_ newTheme: EditorTheme) {
        theme = newTheme
        textView?.theme = newTheme
        textView?.backgroundColor = newTheme.backgroundColor
        view.overrideUserInterfaceStyle = newTheme.userInterfaceStyle
    }

    // MARK: - Language Service

    private func setupLanguageService() {
        let coordinator = LanguageServiceCoordinator(
            languageType: editorLanguageType,
            uri: fileInfo.url.absoluteString
        )
        coordinator.delegate = self
        self.coordinator = coordinator
        completionPopup.delegate = self
        textView?.delegate = self

        addKeyCommands()

        // Add diagnostic overlay on top of textView
        diagnosticOverlay.translatesAutoresizingMaskIntoConstraints = false
        textView?.addSubview(diagnosticOverlay)

        // Trigger initial diagnostics
        coordinator.documentDidChange(text: fileString)
    }

    private func addKeyCommands() {
        let escape = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(handleEscapeKey))
        escape.wantsPriorityOverSystemBehavior = true
        addKeyCommand(escape)
    }

    @objc private func handleEscapeKey() {
        if completionPopup.isVisible || signatureHelpView.isVisible {
            dismissCompletion()
            signatureHelpView.hide()
            currentSignatureHelp = nil
        } else {
            textView?.resignFirstResponder()
        }
    }

    private static func isWordChar(_ ch: Character) -> Bool {
        ch.isLetter || ch.isNumber || ch == "-" || ch == "_"
    }

    private func calcWordStart(text: String, cursorLocation: Int, col: Int, lineText: String) -> Int {
        guard col > 0 else { return cursorLocation }
        let nsLine = lineText as NSString
        let scanLen = min(col, nsLine.length)
        var wordLen = 0
        for i in stride(from: scanLen - 1, through: 0, by: -1) {
            let ch = Character(UnicodeScalar(nsLine.character(at: i))!)
            if Self.isWordChar(ch) {
                wordLen += 1
            } else {
                break
            }
        }
        return cursorLocation - wordLen
    }

    /// VS Code-style completion trigger logic:
    /// 1. Trigger character typed → immediately request new completions from LS
    /// 2. First word character after non-word → request new completions (debounced)
    /// 3. Continuing to type word characters in active session → client-side filter only
    /// 4. Non-word, non-trigger character → dismiss
    /// 5. Backspace past word start → dismiss
    private func triggerCompletion() {
        guard let textView, let coordinator else { return }
        let text = cachedText ?? textView.text
        let cursorLocation = textView.selectedRange.location

        guard cursorLocation > 0,
              let textLocation = textView.textLocation(at: cursorLocation) else {
            dismissCompletion()
            return
        }

        var effectiveCol = textLocation.column
        let lineText = currentLineText(in: text, at: cursorLocation)

        // Detect auto-pair: Runestone transforms "(" → "()", "\"" → "\"\"", etc.
        // Cursor ends up after the closing char; adjust to inside the pair.
        let autoPairChars: [Character: Character] = ["(": ")", "\"": "\"", "'": "'", "[": "]", "{": "}"]
        let typedChar = lastTypedText?.first
        var isAutoPair = false
        if let typed = lastTypedText, typed.count == 2,
           let first = typed.first, let last = typed.last,
           autoPairChars[first] == last {
            isAutoPair = true
            effectiveCol = max(effectiveCol - 1, 0)
        }

        // Character at effective cursor position
        let nsText = text as NSString
        let effectiveCursorLocation = isAutoPair ? max(cursorLocation - 1, 0) : cursorLocation
        guard effectiveCursorLocation > 0, effectiveCursorLocation <= nsText.length else { dismissCompletion(); return }
        let lastCharStr = nsText.substring(with: NSRange(location: effectiveCursorLocation - 1, length: 1))
        guard let lastChar = lastCharStr.first else { dismissCompletion(); return }

        let triggerChars = coordinator.triggerCharacters()
        let isTrigger = triggerChars.contains(lastChar) || (isAutoPair && triggerChars.contains(typedChar!))
        let isWord = Self.isWordChar(lastChar)

        completionWordStart = calcWordStart(text: text, cursorLocation: effectiveCursorLocation, col: effectiveCol, lineText: lineText)

        // Signature help
        if typedChar == "(" || typedChar == "," {
            coordinator.requestSignatureHelp(
                text: text,
                line: textLocation.lineNumber,
                character: effectiveCol
            )
        } else if typedChar == ")" {
            signatureHelpView.hide()
            currentSignatureHelp = nil
        } else if signatureHelpView.isVisible {
            // Re-request to update active parameter highlight
            coordinator.requestSignatureHelp(
                text: text,
                line: textLocation.lineNumber,
                character: effectiveCol
            )
        }

        // Case 1: Trigger character → new LS request immediately
        if isTrigger {
            isInCompletionSession = true
            // For trigger chars, word start is right at cursor (trigger char is not part of the word to filter)
            completionWordStart = effectiveCursorLocation
            coordinator.requestCompletion(
                text: text,
                line: textLocation.lineNumber,
                character: effectiveCol
            )
            return
        }

        // Case 2: Word character
        if isWord {
            if isInCompletionSession && completionPopup.isVisible {
                // Case 2a: Continuing to type in active session → client-side filter
                let filterWord = (text as NSString).substring(
                    with: NSRange(location: completionWordStart, length: effectiveCursorLocation - completionWordStart)
                )
                completionPopup.updateFilter(filterWord)
                // Defer reposition to next layout cycle so caretRect is up to date
                DispatchQueue.main.async { [weak self] in
                    self?.repositionCompletionPopup()
                }
            } else {
                // Case 2b: First word char or session without popup → new LS request (debounced)
                isInCompletionSession = true
                coordinator.requestCompletionDebounced(
                    text: text,
                    line: textLocation.lineNumber,
                    character: effectiveCol
                )
            }
            return
        }

        // Case 3: Non-word, non-trigger (space, ;, {, newline, etc.) → dismiss
        dismissCompletion()
    }

    private func dismissCompletion() {
        completionPopup.hide()
        isInCompletionSession = false
        coordinator?.cancelCompletion()
    }

    private func repositionCompletionPopup() {
        guard completionPopup.isVisible, let textView else { return }
        let selectedRange = textView.selectedTextRange
        guard let selectedRange else { return }
        let cursorRect = textView.caretRect(for: selectedRange.start)
        guard !cursorRect.isNull && !cursorRect.isInfinite else { return }
        let rectInView = textView.convert(cursorRect, to: view)
        completionPopup.reposition(relativeTo: rectInView, in: view, keyboardHeight: keyboardHeight)
    }

    private func currentLineText(in text: String, at location: Int) -> String {
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: location, length: 0))
        return nsText.substring(with: lineRange)
    }

    private func applyCompletionItem(_ item: LSPCompletionItem) {
        guard let textView else { return }
        isApplyingCompletion = true
        defer { isApplyingCompletion = false }

        let cursorLocation = textView.selectedRange.location

        // Determine replace start: use textEdit range if available (handles cases
        // like `/div` where trigger char `/` is part of the completion text),
        // otherwise fall back to completionWordStart
        var replaceStart = completionWordStart
        if let textEdit = item.textEdit {
            let editStartLoc = TextLocation(lineNumber: textEdit.range.start.line, column: textEdit.range.start.character)
            if let editStart = textView.location(at: editStartLoc) {
                replaceStart = min(editStart, completionWordStart)
            }
        }

        let replaceRange = NSRange(location: replaceStart, length: cursorLocation - replaceStart)
        let rawText = item.textEdit?.newText ?? item.insertText ?? item.label
        let (insertText, cursorOffset) = Self.processSnippet(rawText)
        textView.replace(replaceRange, withText: insertText)

        // Move cursor to $0 position
        if let offset = cursorOffset {
            let newCursorPos = replaceStart + offset
            textView.selectedRange = NSRange(location: newCursorPos, length: 0)
        }

        dismissCompletion()

        // Refresh diagnostics after completion insertion
        coordinator?.documentDidChange(text: textView.text)
    }

    /// Process snippet text: strip placeholders, return (cleanText, cursorOffset)
    /// cursorOffset is the position of `$0` in the cleaned text (if present)
    private static func processSnippet(_ text: String) -> (String, Int?) {
        // First, find $0 position before any processing
        // Replace ${N:placeholder} → placeholder, ${N} → "", $N (N≠0) → ""
        var result = text
        // ${N:placeholder} → placeholder
        result = result.replacingOccurrences(of: "\\$\\{\\d+:([^}]*)\\}", with: "$1", options: .regularExpression)
        // ${N} → ""
        result = result.replacingOccurrences(of: "\\$\\{\\d+\\}", with: "", options: .regularExpression)
        // Remove $1, $2, ... but keep $0 for now to find its position
        result = result.replacingOccurrences(of: "\\$([1-9]\\d*)", with: "", options: .regularExpression)

        // Find $0 position
        var cursorOffset: Int? = nil
        if let range = result.range(of: "$0") {
            cursorOffset = result.distance(from: result.startIndex, to: range.lowerBound)
            result = result.replacingCharacters(in: range, with: "")
        }

        return (result, cursorOffset)
    }

    private func updateDiagnosticHighlights(_ diagnostics: [LSPDiagnostic]) {
        guard let textView else { return }

        let text = textView.text ?? ""
        let lines = text.components(separatedBy: "\n")
        let totalLines = lines.count

        trackedDiagnostics = diagnostics.compactMap { diag in
            var startLine = diag.range.start.line
            var startChar = diag.range.start.character
            var endLine = diag.range.end.line
            var endChar = diag.range.end.character

            // Clamp lines to valid range
            startLine = min(startLine, max(totalLines - 1, 0))
            endLine = min(endLine, max(totalLines - 1, 0))

            // Clamp characters to line length
            let startLineLen = startLine < totalLines ? lines[startLine].count : 0
            let endLineLen = endLine < totalLines ? lines[endLine].count : 0
            startChar = min(startChar, startLineLen)
            endChar = min(endChar, endLineLen)

            // If range is zero-width after clamping, expand minimally
            if startLine == endLine && startChar >= endChar {
                if startChar < startLineLen {
                    // Underline from start to end of line
                    endChar = startLineLen
                } else if startLineLen > 0 {
                    // Both start and end are at/past line end — underline just the last character
                    startChar = startLineLen - 1
                    endChar = startLineLen
                } else {
                    // Empty line — find nearest non-empty line above
                    var fallback = startLine
                    while fallback > 0 && lines[fallback].trimmingCharacters(in: .whitespaces).isEmpty {
                        fallback -= 1
                    }
                    guard fallback < totalLines && !lines[fallback].isEmpty else { return nil }
                    startLine = fallback
                    endLine = fallback
                    startChar = 0
                    endChar = lines[fallback].count
                }
            }

            let startLoc = TextLocation(lineNumber: startLine, column: startChar)
            let endLoc = TextLocation(lineNumber: endLine, column: endChar)
            guard let startOffset = textView.location(at: startLoc),
                  let endOffset = textView.location(at: endLoc),
                  endOffset > startOffset else { return nil }
            return (range: NSRange(location: startOffset, length: endOffset - startOffset), isError: diag.isError, message: diag.message)
        }
        diagnosticTooltip.hide()
        currentDiagnosticTooltipIndex = nil
        layoutDiagnosticOverlay()
    }

    /// Adjust tracked diagnostic NSRanges after a text edit
    private func adjustDiagnosticRanges(editRange: NSRange, replacementLength: Int) {
        let delta = replacementLength - editRange.length
        trackedDiagnostics = trackedDiagnostics.compactMap { diag in
            var loc = diag.range.location
            var len = diag.range.length
            let editEnd = editRange.location + editRange.length

            if editRange.location >= loc + len {
                // Edit is entirely after this diagnostic — no change
                return diag
            } else if editEnd <= loc {
                // Edit is entirely before — shift location
                loc += delta
                return (range: NSRange(location: loc, length: len), isError: diag.isError, message: diag.message)
            } else {
                // Edit overlaps this diagnostic — adjust length
                if editRange.location >= loc {
                    // Edit starts inside the diagnostic range
                    let overlapEnd = min(editEnd, loc + len)
                    let removedInside = overlapEnd - editRange.location
                    len = len - removedInside + replacementLength
                } else {
                    // Edit starts before and extends into the diagnostic
                    let overlapEnd = min(editEnd, loc + len)
                    let removedBefore = loc - editRange.location
                    let removedInside = overlapEnd - loc
                    loc = editRange.location + replacementLength - min(replacementLength, removedBefore)
                    len = len - removedInside
                }
                if len <= 0 { return nil }
                return (range: NSRange(location: max(0, loc), length: len), isError: diag.isError, message: diag.message)
            }
        }
    }

    private func scheduleDiagnosticLayout() {
        diagnosticLayoutTimer?.invalidate()
        diagnosticLayoutTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            self?.layoutDiagnosticOverlay()
        }
    }

    private func layoutDiagnosticOverlay() {
        guard let textView else { return }

        diagnosticOverlay.frame = CGRect(origin: .zero, size: textView.contentSize)

        var rects: [DiagnosticOverlayView.DiagnosticRect] = []
        let textLength = (textView.text as NSString).length

        for diag in trackedDiagnostics {
            let start = diag.range.location
            let end = start + diag.range.length
            guard start >= 0, end <= textLength, end > start else { continue }

            guard let beginPos = textView.position(from: textView.beginningOfDocument, offset: start),
                  let endPos = textView.position(from: textView.beginningOfDocument, offset: end),
                  let textRange = textView.textRange(from: beginPos, to: endPos) else { continue }

            // Touch caretRect to nudge Runestone into computing character positions
            _ = textView.caretRect(for: beginPos)
            _ = textView.caretRect(for: endPos)

            let selRects = textView.selectionRects(for: textRange)
            for selRect in selRects {
                let rect = selRect.rect
                guard !rect.isNull && !rect.isInfinite && rect.width > 0 && rect.height > 0 else { continue }
                rects.append(DiagnosticOverlayView.DiagnosticRect(rect: rect, isError: diag.isError))
            }
        }
        diagnosticOverlay.diagnosticRects = rects
    }

    private func checkDiagnosticAtCursor() {
        guard let textView, !trackedDiagnostics.isEmpty else {
            diagnosticTooltip.hide()
            currentDiagnosticTooltipIndex = nil
            return
        }

        let cursorLocation = textView.selectedRange.location
        for (index, diag) in trackedDiagnostics.enumerated() {
            if cursorLocation >= diag.range.location && cursorLocation <= diag.range.location + diag.range.length {
                currentDiagnosticTooltipIndex = index
                repositionDiagnosticTooltip()
                return
            }
        }

        diagnosticTooltip.hide()
        currentDiagnosticTooltipIndex = nil
    }

    private func repositionDiagnosticTooltip() {
        guard let textView,
              let index = currentDiagnosticTooltipIndex,
              index < trackedDiagnostics.count else {
            diagnosticTooltip.hide()
            return
        }

        let diag = trackedDiagnostics[index]
        let textLength = (textView.text as NSString).length
        let start = diag.range.location
        let end = min(start + diag.range.length, textLength)
        guard start >= 0, end > start,
              let beginPos = textView.position(from: textView.beginningOfDocument, offset: start),
              let endPos = textView.position(from: textView.beginningOfDocument, offset: end),
              let textRange = textView.textRange(from: beginPos, to: endPos) else {
            diagnosticTooltip.hide()
            return
        }

        let selRects = textView.selectionRects(for: textRange)
        if let firstRect = selRects.first(where: { !$0.rect.isNull && !$0.rect.isInfinite && $0.rect.width > 0 }) {
            let anchorInView = textView.convert(firstRect.rect, to: view)
            let visibleRect = textView.convert(textView.bounds, to: view)
            guard visibleRect.intersects(anchorInView) else {
                diagnosticTooltip.hide()
                return
            }
            diagnosticTooltip.show(message: diag.message, isError: diag.isError, at: anchorInView, in: view)
        } else {
            diagnosticTooltip.hide()
        }
    }

    private func showSignatureHelp(_ help: LSPSignatureHelp) {
        guard let textView, !help.signatures.isEmpty else {
            signatureHelpView.hide()
            currentSignatureHelp = nil
            return
        }

        currentSignatureHelp = help
        repositionSignatureHelp()
    }

    private func repositionSignatureHelp() {
        guard let textView, let help = currentSignatureHelp else { return }

        let selectedRange = textView.selectedTextRange
        guard let selectedRange else {
            signatureHelpView.hide()
            return
        }
        let cursorRect = textView.caretRect(for: selectedRange.start)
        guard !cursorRect.isNull && !cursorRect.isInfinite else {
            signatureHelpView.hide()
            return
        }

        let rectInView = textView.convert(cursorRect, to: view)
        // Hide if cursor is outside visible area
        let visibleRect = textView.convert(textView.bounds, to: view)
        guard visibleRect.intersects(rectInView) else {
            signatureHelpView.hide()
            return
        }

        signatureHelpView.show(help: help, at: rectInView, in: view)
    }

    private func showCompletionPopup(items: [LSPCompletionItem]) {
        guard let textView, !items.isEmpty, isInCompletionSession else {
            dismissCompletion()
            return
        }

        let selectedRange = textView.selectedTextRange
        guard let selectedRange else {
            dismissCompletion()
            return
        }
        let cursorRect = textView.caretRect(for: selectedRange.start)
        guard !cursorRect.isNull && !cursorRect.isInfinite else {
            dismissCompletion()
            return
        }

        let rectInView = textView.convert(cursorRect, to: view)

        // Compute initial filter before showing so height and position are correct
        let cursorLocation = textView.selectedRange.location
        var initialFilter = ""
        if cursorLocation > completionWordStart {
            initialFilter = (textView.text as NSString).substring(with: NSRange(location: completionWordStart, length: cursorLocation - completionWordStart))
        }
        completionPopup.show(items: items, in: view, at: rectInView, keyboardHeight: keyboardHeight, initialFilter: initialFilter)
    }
}

extension CodeEditorViewController: TextViewDelegate {
    func textView(_ textView: TextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if lastTypedText == nil {
            lastTypedText = text
        }
        if !trackedDiagnostics.isEmpty {
            adjustDiagnosticRanges(editRange: range, replacementLength: text.utf16.count)
        }
        return true
    }

    func textViewDidChange(_ textView: TextView) {
        saveButton.isEnabled = true
        setupKeyboardTools()
        diagnosticTooltip.hide()
        currentDiagnosticTooltipIndex = nil

        if !isApplyingCompletion {
            didJustType = true
            isInTextChangeCycle = true
            DispatchQueue.main.async { [weak self] in self?.isInTextChangeCycle = false }
            cachedText = textView.text
            coordinator?.documentDidChange(text: cachedText!)
            triggerCompletion()
            cachedText = nil
            lastTypedText = nil
        } else {
            lastTypedText = nil
        }

        if !trackedDiagnostics.isEmpty {
            scheduleDiagnosticLayout()
        }
    }

    func textViewDidChangeSelection(_ textView: TextView) {
        if !isApplyingCompletion {
            if isInCompletionSession {
                if didJustType {
                    // Selection changed due to typing — already handled in triggerCompletion
                    didJustType = false
                    return
                }
                // User tapped/moved cursor without typing → dismiss
                dismissCompletion()
            }
            if !isInTextChangeCycle && currentSignatureHelp != nil {
                signatureHelpView.hide()
                currentSignatureHelp = nil
            }
        }

        if !didJustType && !trackedDiagnostics.isEmpty {
            checkDiagnosticAtCursor()
        } else {
            diagnosticTooltip.hide()
            currentDiagnosticTooltipIndex = nil
        }
        didJustType = false
    }
}

// MARK: - LanguageServiceDelegate

extension CodeEditorViewController: LanguageServiceDelegate, UIScrollViewDelegate {
    func languageService(didReceiveCompletions items: [LSPCompletionItem]) {
        showCompletionPopup(items: items)
    }

    func languageService(didReceiveSignatureHelp help: LSPSignatureHelp) {
        showSignatureHelp(help)
    }

    func languageService(didReceiveDiagnostics diagnostics: [LSPDiagnostic]) {
        updateDiagnosticHighlights(diagnostics)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isInCompletionSession || completionPopup.isVisible {
            dismissCompletion()
        }
        if currentSignatureHelp != nil {
            repositionSignatureHelp()
        }
        if currentDiagnosticTooltipIndex != nil {
            repositionDiagnosticTooltip()
        }
        if !trackedDiagnostics.isEmpty {
            scheduleDiagnosticLayout()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !trackedDiagnostics.isEmpty {
            layoutDiagnosticOverlay()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && !trackedDiagnostics.isEmpty {
            layoutDiagnosticOverlay()
        }
    }
}

// MARK: - CompletionPopupDelegate

extension CodeEditorViewController: CompletionPopupDelegate {
    func completionPopup(_ popup: CompletionPopupView, didSelectItem item: LSPCompletionItem) {
        applyCompletionItem(item)
    }
}

extension CodeEditorViewController {
    private func setupKeyboardTools() {
        textView?.inputAccessoryView = keyboardToolbarView
        let canUndo = textView?.undoManager?.canUndo ?? false
        let canRedo = textView?.undoManager?.canRedo ?? false
        keyboardToolbarView.groups = [
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.backward") { [weak self] in
                        self?.textView?.undoManager?.undo()
                        self?.saveButton.isEnabled = self?.textView?.text != self?.fileString
                        self?.setupKeyboardTools()
                    }, isEnabled: canUndo),
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                        self?.textView?.undoManager?.redo()
                        self?.saveButton.isEnabled = self?.textView?.text != self?.fileString
                        self?.setupKeyboardTools()
                    }, isEnabled: canRedo),
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(
                    representativeTool: InsertTextKeyboardTool(text: "(", textView: textView),
                    tools: [
                        InsertTextKeyboardTool(text: "(", textView: textView),
                        InsertTextKeyboardTool(text: "{", textView: textView),
                        InsertTextKeyboardTool(text: "[", textView: textView),
                        InsertTextKeyboardTool(text: "]", textView: textView),
                        InsertTextKeyboardTool(text: "}", textView: textView),
                        InsertTextKeyboardTool(text: ")", textView: textView),
                    ]),
                KeyboardToolGroupItem(
                    representativeTool: InsertTextKeyboardTool(text: ".", textView: textView),
                    tools: [
                        InsertTextKeyboardTool(text: ".", textView: textView),
                        InsertTextKeyboardTool(text: ",", textView: textView),
                        InsertTextKeyboardTool(text: ";", textView: textView),
                        InsertTextKeyboardTool(text: "!", textView: textView),
                        InsertTextKeyboardTool(text: "&", textView: textView),
                        InsertTextKeyboardTool(text: "|", textView: textView),
                    ]),
                KeyboardToolGroupItem(
                    representativeTool: InsertTextKeyboardTool(text: "=", textView: textView),
                    tools: [
                        InsertTextKeyboardTool(text: "=", textView: textView),
                        InsertTextKeyboardTool(text: "+", textView: textView),
                        InsertTextKeyboardTool(text: "-", textView: textView),
                        InsertTextKeyboardTool(text: "/", textView: textView),
                        InsertTextKeyboardTool(text: "*", textView: textView),
                        InsertTextKeyboardTool(text: "<", textView: textView),
                        InsertTextKeyboardTool(text: ">", textView: textView),
                    ]),
                KeyboardToolGroupItem(
                    representativeTool: InsertTextKeyboardTool(text: "#", textView: textView),
                    tools: [
                        InsertTextKeyboardTool(text: "#", textView: textView),
                        InsertTextKeyboardTool(text: "\"", textView: textView),
                        InsertTextKeyboardTool(text: "'", textView: textView),
                        InsertTextKeyboardTool(text: "$", textView: textView),
                        InsertTextKeyboardTool(text: "\\", textView: textView),
                        InsertTextKeyboardTool(text: "@", textView: textView),
                        InsertTextKeyboardTool(text: "%", textView: textView),
                        InsertTextKeyboardTool(text: "~", textView: textView),
                    ]),
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
                        self?.textView?.findInteraction?.presentFindNavigator(showingReplace: false)
                    }),
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
                        self?.textView?.resignFirstResponder()
                    }),
            ]),
        ]
    }
}
