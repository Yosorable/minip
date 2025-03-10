//
//  EditorView.swift
//  minip
//
//  Created by ByteDance on 2023/7/9.
//

import Runestone
import SwiftUI
import TreeSitterCSSRunestone
import TreeSitterHTMLRunestone
import TreeSitterJavaScriptRunestone
import TreeSitterJSONRunestone
import TreeSitterMarkdownRunestone
import TreeSitterPythonRunestone
import TreeSitterYAMLRunestone

struct EditorView: View {
    @Environment(\.dismissPolyfill) var dismiss

    @State var text: String
    @State var originText: String
    var notTextFile = false
    var readFileError = false
    let fileInfo: FileInfo

    @State var isLoading = true

    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    init(fileInfo: FileInfo) {
        self.fileInfo = fileInfo
        guard let fileData = FileManager.default.contents(atPath: fileInfo.url.path) else {
            readFileError = true
            _text = State(initialValue: "")
            _originText = State(initialValue: "")
            return
        }

        if let fileString = String(data: fileData, encoding: .utf8) {
            _text = State(initialValue: fileString)
            _originText = State(initialValue: fileString)
        } else {
            notTextFile = true
            _text = State(initialValue: "")
            _originText = State(initialValue: "")
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

    var content: some View {
        ZStack {
            if notTextFile {
                Text("not a text file")
            } else if readFileError {
                Text("readFileError")
            } else {
                CodeEditorV2View(contentString: $text, language: {
                    guard let ext = fileInfo.fileName.split(separator: ".").last else {
                        return nil
                    }
                    return SourceCodeTypeV2[String(ext)]
                }())
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationTitle(Text(fileInfo.fileName))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    do {
                        try text.write(to: fileInfo.url, atomically: true, encoding: .utf8)
                        originText = text
                    } catch {}
                } label: {
                    Text(i18n("Save"))
                }
                .disabled(originText == text)
            }
        }
    }
}

let SourceCodeTypeV2: [String: TreeSitterLanguage] = [
    "js": .javaScript,
    "html": .html,
    "json": .json,
    "css": .css,
    "yaml": .yaml,
    "yml": .yaml,
    "md": .markdown,
    "py": .python
]
