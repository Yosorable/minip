//
//  FileBrowserView.swift
//  minip
//
//  Created by ByteDance on 2023/7/9.
//

import SwiftUI
import UniformTypeIdentifiers

struct EditorDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.json, .html, .javaScript, .text]
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
          throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
