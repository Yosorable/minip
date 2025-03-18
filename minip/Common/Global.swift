//
//  Global.swift
//  minip
//
//  Created by LZY on 2025/3/18.
//

import Foundation

final class Global {
    static let shared = Global()

    // MARK: const

    let documentsRootURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let documentsTrashURL: URL
    let projectsDataFolderURL: URL

    let sandboxRootURL = URL(fileURLWithPath: NSHomeDirectory())

    // MARK: variable

    var fileBrowserRootURL: URL

    private init() {
        documentsTrashURL = documentsRootURL.appendingPolyfill(path: ".Trash/")
        projectsDataFolderURL = documentsRootURL.appendingPolyfill(path: ".data/")
#if DEBUG
        fileBrowserRootURL = sandboxRootURL
#else
        fileBrowserRootURL = documentsRootURL
#endif
    }
}
