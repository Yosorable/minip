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
    "js": .javaScript,
    "ts": .typeScript,
    "html": .html,
    "json": .json,
    "css": .css,
    "yaml": .yaml,
    "yml": .yaml,
    "md": .markdown,
    "py": .python,
]

class CodeEditorViewController: UIViewController {
    var textView: TextView?
    var fileString: String = ""
    var language: TreeSitterLanguage?
    let fileInfo: FileInfo
    let readyOnlyText: String?
    let theme: EditorTheme

    lazy var keyboardToolbarView = KeyboardToolbarView()
    lazy var saveButton = {
        var btn = UIBarButtonItem(title: i18n("Save"), style: .plain, target: self, action: #selector(save))
        btn.isEnabled = false
        return btn
    }()

    init(fileInfo: FileInfo, lang: TreeSitterLanguage? = nil, readyOnlyText: String? = nil, theme: EditorTheme = TomorrowTheme()) {
        self.fileInfo = fileInfo
        self.readyOnlyText = readyOnlyText
        self.theme = theme

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
            textView!.contentInset = .zero
            textView!.scrollIndicatorInsets = .zero
        } else {
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
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ProgressHUD.bannerHide()
        ProgressHUD.dismiss()
    }
}

extension CodeEditorViewController: TextViewDelegate {
    func textViewDidChange(_ textView: TextView) {
        saveButton.isEnabled = textView.text != fileString
        setupKeyboardTools()
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
                        self?.setupKeyboardTools()
                    }, isEnabled: canUndo),
                KeyboardToolGroupItem(
                    style: .secondary,
                    representativeTool: BlockKeyboardTool(symbolName: "arrow.uturn.forward") { [weak self] in
                        self?.textView?.undoManager?.redo()
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
                    representativeTool: InsertTextKeyboardTool(text: "#", textView: textView!),
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
