//
//  Global.swift
//  minip
//
//  Created by LZY on 2025/3/18.
//

import Foundation

final class Global {
    static let shared = Global()

    /// Root directory for all miniapp runtime data — installed miniapps and the
    /// `.data` KV store. Defaults to `<App>/Library/minip`.
    ///
    /// Host apps may override this **before** opening or installing any miniapp.
    /// Keeping it under `Library` (not `Documents`) avoids surfacing miniapp data
    /// in the host app's Files-sharing / iCloud backups by default.
    var miniAppsRootURL: URL {
        didSet { Self.ensureDirectoryExists(miniAppsRootURL) }
    }

    var dataFolderURL: URL { miniAppsRootURL.appending(component: ".data", directoryHint: .isDirectory) }
    var projectDataFolderURL: URL { dataFolderURL.appending(component: "appdata", directoryHint: .isDirectory) }

    private init() {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        miniAppsRootURL = library.appending(component: "minip", directoryHint: .isDirectory)
        Self.ensureDirectoryExists(miniAppsRootURL)
    }

    private static func ensureDirectoryExists(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
