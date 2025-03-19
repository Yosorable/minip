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
    let fileInfo: FileInfo
    let readyOnlyText: String?

    lazy var keyboardToolbarView = KeyboardToolbarView()
    lazy var saveButton = {
        var btn = UIBarButtonItem(title: i18n("Save"), style: .plain, target: self, action: #selector(save))
        btn.isEnabled = false
        return btn
    }()

    init(fileInfo: FileInfo, readyOnlyText: String? = nil) {
        self.fileInfo = fileInfo
        self.readyOnlyText = readyOnlyText

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
            self.textView = textView
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.backgroundColor = .systemBackground

            if !readonly {
                navigationItem.rightBarButtonItem = saveButton
                textView.editorDelegate = self
                textView.inputAccessoryView = keyboardToolbarView
                let notificationCenter = NotificationCenter.default
                notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
                notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
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
                textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -50)
            ])

            if let err = err {
                ShowSimpleError(err: err)
            }
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
        } catch {
            ShowSimpleError(err: error)
        }
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
        textView.text = text

        guard let lang = language else {
            return
        }

        // MARK: todo: large file or minified file, optimize disable hight strategy

        DispatchQueue.global(qos: .userInitiated).async {
            let tTxt = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let sps = tTxt.splitPolyfill(separator: "\n")
            var mx = 0
            for ele in sps {
                mx = max(ele.count, mx)
            }
            let lineCnt = sps.count
            let charCnt = tTxt.count
            logger.debug("[Code Editor]: toal char: \(charCnt), total line: \(lineCnt), max char line: \(mx), average char line: \(charCnt / lineCnt)")
            if charCnt / lineCnt < 5000, lineCnt < 20000, mx < 10000 {
                let state = TextViewState(text: text, theme: DefaultTheme(), language: lang, languageProvider: LanguageProvider())

                DispatchQueue.main.async {
                    textView.setState(state)
                }
            } else {
                DispatchQueue.main.async {
                    ProgressHUD.banner("Warning", "This file contains long lines, disable hightligh.", delay: 1.5)
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
