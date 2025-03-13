//
//  CodeEditorViewController.swift
//  minip
//
//  Created by LZY on 2025/3/13.
//

import KeyboardToolbar
import Runestone
import SwiftUI
import TreeSitterHTMLRunestone
import TreeSitterJavaScriptRunestone
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
    "js": .javaScript,
    "html": .html,
    "json": .json,
    "css": .css,
    "yaml": .yaml,
    "yml": .yaml,
    "md": .markdown,
    "py": .python
]

class CodeEditorViewController: UIViewController {
    var textView: TextView?
    var fileString: String = ""
    var language: TreeSitterLanguage?
    var fileInfo: FileInfo

    lazy var keyboardToolbarView = KeyboardToolbarView()
    lazy var saveButton = {
        var btn = UIBarButtonItem(title: i18n("Save"), style: .plain, target: self, action: #selector(save))
        btn.isEnabled = false
        return btn
    }()

    init(fileInfo: FileInfo) {
        self.fileInfo = fileInfo

        if let ext = fileInfo.fileName.split(separator: ".").last {
            self.language = SourceCodeType[String(ext)]
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

        if let fileData = FileManager.default.contents(atPath: fileInfo.url.path), let txt = String(data: fileData, encoding: .utf8) {
            fileString = txt
            navigationItem.rightBarButtonItem = saveButton
            let textView = TextView()
            self.textView = textView
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.editorDelegate = self
            textView.backgroundColor = .systemBackground

            textView.inputAccessoryView = keyboardToolbarView

            setCustomization(on: textView)
            setTextViewState(on: textView)
            view.addSubview(textView)
            NSLayoutConstraint.activate([
                textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textView.topAnchor.constraint(equalTo: view.topAnchor),
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        } else {
            let label = UILabel()
            label.text = "Cannot read this file as a text file."
            label.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = .systemBackground
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        if let pnv = navigationController as? PannableNavigationViewController {
            pnv.addPanGesture(vc: self)
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
        } catch {}
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            textView!.contentInset = .zero
        } else {
            textView!.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        textView!.scrollIndicatorInsets = textView!.contentInset

        let selectedRange = textView!.selectedRange
        textView!.scrollRangeToVisible(selectedRange)
    }

    private func setCustomization(on textView: TextView) {
        textView.showLineNumbers = true
        textView.lineSelectionDisplayType = .line
        textView.showPageGuide = true
        textView.pageGuideColumn = 80
        textView.showTabs = true
        textView.showSpaces = true
        textView.showLineBreaks = true
        textView.showSoftLineBreaks = true
        textView.lineHeightMultiplier = 1.3

        if #available(iOS 16.0, *) {
            textView.isFindInteractionEnabled = true
        }
        textView.alwaysBounceVertical = true

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
            BasicCharacterPair(leading: "'", trailing: "'")
        ]

        textView.indentStrategy = .space(length: 2)
    }

    private func setTextViewState(on textView: TextView) {
        let text = fileString
        guard let lang = language else {
            textView.text = text
            return
        }
        // MARK: todo: large file or minified file
        DispatchQueue.global(qos: .userInitiated).async {
            let state = TextViewState(text: text, theme: DefaultTheme(), language: lang, languageProvider: LanguageProvider())

            DispatchQueue.main.async {
                textView.setState(state)
            }
        }
    }
}

extension CodeEditorViewController: TextViewDelegate {
    func textViewDidChange(_ textView: TextView) {
        saveButton.isEnabled = textView.text != fileString
        setupKeyboardTools()
    }
}

private extension CodeEditorViewController {
    private func setupKeyboardTools() {
        textView?.inputAccessoryView = keyboardToolbarView
        let canUndo = textView?.undoManager?.canUndo ?? false
        let canRedo = textView?.undoManager?.canRedo ?? false
        keyboardToolbarView.groups = [
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.backward") { [weak self] in
                    self?.textView?.undoManager?.undo()
                    self?.setupKeyboardTools()
                }, isEnabled: canUndo),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                    self?.textView?.undoManager?.redo()
                    self?.setupKeyboardTools()
                }, isEnabled: canRedo)
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "(", textView: textView), tools: [
                    InsertTextKeyboardTool(text: "(", textView: textView),
                    InsertTextKeyboardTool(text: "{", textView: textView),
                    InsertTextKeyboardTool(text: "[", textView: textView),
                    InsertTextKeyboardTool(text: "]", textView: textView),
                    InsertTextKeyboardTool(text: "}", textView: textView),
                    InsertTextKeyboardTool(text: ")", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: ".", textView: textView), tools: [
                    InsertTextKeyboardTool(text: ".", textView: textView),
                    InsertTextKeyboardTool(text: ",", textView: textView),
                    InsertTextKeyboardTool(text: ";", textView: textView),
                    InsertTextKeyboardTool(text: "!", textView: textView),
                    InsertTextKeyboardTool(text: "&", textView: textView),
                    InsertTextKeyboardTool(text: "|", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "=", textView: textView), tools: [
                    InsertTextKeyboardTool(text: "=", textView: textView),
                    InsertTextKeyboardTool(text: "+", textView: textView),
                    InsertTextKeyboardTool(text: "-", textView: textView),
                    InsertTextKeyboardTool(text: "/", textView: textView),
                    InsertTextKeyboardTool(text: "*", textView: textView),
                    InsertTextKeyboardTool(text: "<", textView: textView),
                    InsertTextKeyboardTool(text: ">", textView: textView)
                ]),
                KeyboardToolGroupItem(representativeTool: InsertTextKeyboardTool(text: "#", textView: textView!), tools: [
                    InsertTextKeyboardTool(text: "#", textView: textView),
                    InsertTextKeyboardTool(text: "\"", textView: textView),
                    InsertTextKeyboardTool(text: "'", textView: textView),
                    InsertTextKeyboardTool(text: "$", textView: textView),
                    InsertTextKeyboardTool(text: "\\", textView: textView),
                    InsertTextKeyboardTool(text: "@", textView: textView),
                    InsertTextKeyboardTool(text: "%", textView: textView),
                    InsertTextKeyboardTool(text: "~", textView: textView)
                ])
            ]),
            KeyboardToolGroup(items: [
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "magnifyingglass") { [weak self] in
                    if #available(iOS 16.0, *) {
                        self?.textView?.findInteraction?.presentFindNavigator(showingReplace: false)
                    } else {
                        // TODO: 显示不支持，或者移除
                    }
                }),
                KeyboardToolGroupItem(style: .secondary, representativeTool: BlockKeyboardTool(symbolName: "keyboard.chevron.compact.down") { [weak self] in
                    self?.textView?.resignFirstResponder()
                })
            ])
        ]
    }
}
