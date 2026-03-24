//
//  Global.swift
//  minip
//
//  Created by LZY on 2025/3/18.
//

import Defaults
import Foundation

final class Global {
    static let shared = Global()

    // MARK: const

    let documentsRootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let documentsTrashURL: URL
    let dataFolderURL: URL
    let projectDataFolderURL: URL

    let sandboxRootURL = URL(fileURLWithPath: NSHomeDirectory())

    // MARK: variable

    var fileBrowserRootURL: URL

    private init() {
        documentsTrashURL = documentsRootURL.appending(component: ".Trash", directoryHint: .isDirectory)
        dataFolderURL = documentsRootURL.appending(component: ".data", directoryHint: .isDirectory)
        projectDataFolderURL = dataFolderURL.appending(component: "appdata", directoryHint: .isDirectory)
        fileBrowserRootURL = Defaults[.useSanboxRoot] ? sandboxRootURL : documentsRootURL
    }
}
