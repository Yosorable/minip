//
//  CodeEditorV2.swift
//  minip
//
//  Created by ByteDance on 2023/7/10.
//

import KeyboardToolbar
import Runestone
import SwiftUI
import TreeSitterHTMLRunestone
import TreeSitterJavaScriptRunestone
import UIKit

class CodeEditorController: UIViewController {
    var textView: TextView?
    var fileString: String
    var language: TreeSitterLanguage?
    var onChange: (String) -> Void

    let keyboardToolbarView = KeyboardToolbarView()

    init(textView: TextView? = nil, fileString: String, language: TreeSitterLanguage?, onChange: @escaping (String) -> Void) {
        self.textView = textView
        self.fileString = fileString
        self.language = language
        self.onChange = onChange
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBarAppearance()
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
        // ...
        // Show line numbers.
        textView.showLineNumbers = true
        // Highlight the selected line.
        textView.lineSelectionDisplayType = .line
        // Show a page guide after the 80th character.
        textView.showPageGuide = true
        textView.pageGuideColumn = 80
        // Show all invisible characters.
        textView.showTabs = true
        textView.showSpaces = true
        textView.showLineBreaks = true
        textView.showSoftLineBreaks = true
        // Set the line-height to 130%
        textView.lineHeightMultiplier = 1.3

        if #available(iOS 16.0, *) {
            textView.isFindInteractionEnabled = true
        }
        textView.alwaysBounceVertical = true

        // keyboard
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
        let text = self.fileString
        guard let lang = self.language else {
            textView.text = text
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
//           let theme = TomorrowTheme()
            // VSCodeDarkTheme()
            let state = TextViewState(text: text, theme: DefaultTheme(), language: lang, languageProvider: LanguageProvider())

            DispatchQueue.main.async {
                textView.setState(state)
            }
        }
    }
}

extension CodeEditorController: TextViewDelegate {
    func textViewDidChange(_ textView: TextView) {
//        UserDefaults.standard.text = textView.text
        onChange(textView.text)
        setupKeyboardTools()
    }
}

struct CodeEditorV2View: UIViewControllerRepresentable {
    @Binding var contentString: String
    var language: TreeSitterLanguage?
    func makeUIViewController(context: Context) -> CodeEditorController {
        let vc = CodeEditorController(fileString: contentString, language: language, onChange: { newStr in
            contentString = newStr
        })

        return vc
    }

    func updateUIViewController(_ uiViewController: CodeEditorController, context: Context) {}
}

extension UIColor {
    struct Tomorrow {
        var background: UIColor {
            return .white
        }

        var selection: UIColor {
            return UIColor(red: 222 / 255, green: 222 / 255, blue: 222 / 255, alpha: 1)
        }

        var currentLine: UIColor {
            return UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1)
        }

        var foreground: UIColor {
            return UIColor(red: 96 / 255, green: 96 / 255, blue: 95 / 255, alpha: 1)
        }

        var comment: UIColor {
            return UIColor(red: 159 / 255, green: 161 / 255, blue: 158 / 255, alpha: 1)
        }

        var red: UIColor {
            return UIColor(red: 196 / 255, green: 74 / 255, blue: 62 / 255, alpha: 1)
        }

        var orange: UIColor {
            return UIColor(red: 236 / 255, green: 157 / 255, blue: 68 / 255, alpha: 1)
        }

        var yellow: UIColor {
            return UIColor(red: 232 / 255, green: 196 / 255, blue: 66 / 255, alpha: 1)
        }

        var green: UIColor {
            return UIColor(red: 136 / 255, green: 154 / 255, blue: 46 / 255, alpha: 1)
        }

        var aqua: UIColor {
            return UIColor(red: 100 / 255, green: 166 / 255, blue: 173 / 255, alpha: 1)
        }

        var blue: UIColor {
            return UIColor(red: 94 / 255, green: 133 / 255, blue: 184 / 255, alpha: 1)
        }

        var purple: UIColor {
            return UIColor(red: 149 / 255, green: 115 / 255, blue: 179 / 255, alpha: 1)
        }

        fileprivate init() {}
    }

    static let tomorrow = Tomorrow()
}

class TomorrowTheme: Theme {
    let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    let textColor: UIColor = .tomorrow.foreground

    let gutterBackgroundColor: UIColor = .tomorrow.background
    let gutterHairlineColor: UIColor = .tomorrow.background

    let lineNumberColor: UIColor = .tomorrow.comment
    let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    let selectedLineBackgroundColor: UIColor = .tomorrow.currentLine
    let selectedLinesLineNumberColor: UIColor = .tomorrow.foreground
    let selectedLinesGutterBackgroundColor: UIColor = .tomorrow.background

    let invisibleCharactersColor: UIColor = .tomorrow.comment

    let pageGuideHairlineColor: UIColor = .tomorrow.foreground.withAlphaComponent(0.1)
    let pageGuideBackgroundColor: UIColor = .tomorrow.foreground.withAlphaComponent(0.2)

    let markedTextBackgroundColor: UIColor = .tomorrow.foreground.withAlphaComponent(0.2)

    func textColor(for highlightName: String) -> UIColor? {
        return nil
    }
}

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

private extension CodeEditorController {
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
