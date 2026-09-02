//
//  InstallMiniApp.swift
//  minip
//
//  Created by LZY on 2024/12/9.
//

import Foundation
import SwiftArchive

@MainActor
func InstallMiniApp(pkgFile: URL, onSuccess: (() -> Void)? = nil, onFailed: ((String) -> Void)? = nil, validateAppInfoFunc: ((AppInfo) -> Bool)? = nil, signalAppListChangedOnSuccess: Bool = true) async {
    let fileManager = FileManager.default

    let tempDirURL = fileManager.temporaryDirectory
    let unzipDirURL = tempDirURL.appendingPathComponent(UUID().uuidString)

    do {
        try fileManager.createDirectory(at: unzipDirURL, withIntermediateDirectories: true, attributes: nil)
        defer { deleteFolder(at: unzipDirURL) }

        let archive = try ArchiveReader(url: pkgFile, format: .zip)
        try await archive.extract(to: unzipDirURL)

        guard let appJSONURL = try findAppJSON(in: unzipDirURL) else {
            throw ErrorMsg(errorDescription: "cannot find app.json")
        }
        try installByAppJSON(in: appJSONURL, validateAppInfoFunc: validateAppInfoFunc)
        onSuccess?()
        if signalAppListChangedOnSuccess {
            NotificationCenter.default.post(name: .appListUpdated, object: nil)
        }
    } catch {
        onFailed?(error.localizedDescription)
    }
}

@discardableResult
func downloadFileToTmpFolder(
    _ downloadURL: URL,
    fallbackFilename: String = "default.zip",
    completion: @escaping (Result<URL, Error>) -> Void
) -> URLSessionDownloadTask {
    let completeOnMain: (Result<URL, Error>) -> Void = { result in
        DispatchQueue.main.async {
            completion(result)
        }
    }

    let task = URLSession.shared.downloadTask(with: downloadURL) { downloadedFileURL, response, error in
        if let error {
            completeOnMain(.failure(error))
            return
        }

        guard let downloadedFileURL else {
            completeOnMain(.failure(ErrorMsg(errorDescription: "Unknown download error")))
            return
        }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let temporaryDirectoryURL = documentsURL.appending(path: ".tmp", directoryHint: .isDirectory)
        let proposedFilename = response?.suggestedFilename.flatMap { $0.isEmpty ? nil : $0 } ?? fallbackFilename
        let filename = safeDownloadFilename(proposedFilename)
        let destinationURL = temporaryDirectoryURL.appending(component: filename, directoryHint: .notDirectory)

        do {
            try fileManager.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: downloadedFileURL, to: destinationURL)
            completeOnMain(.success(destinationURL))
        } catch {
            completeOnMain(.failure(error))
        }
    }
    task.resume()
    return task
}

private func safeDownloadFilename(_ proposedFilename: String) -> String {
    let filename = (proposedFilename as NSString).lastPathComponent
    guard !filename.isEmpty, filename != ".", filename != ".." else {
        return "default.zip"
    }
    return filename
}

// download miniapp package and save to tmp folder
func DownloadMiniAppPackageToTmpFolder(_ downURL: String, onError: @escaping (ErrorMsg) -> Void, onSuccess: @escaping (URL) -> Void) {
    guard let downurl = URL(string: downURL) else {
        onError(ErrorMsg(errorDescription: "Error URL"))
        return
    }

    downloadFileToTmpFolder(downurl) { result in
        switch result {
        case .success(let temporaryURL):
            onSuccess(temporaryURL)
        case .failure(let error):
            onError(ErrorMsg(errorDescription: error.localizedDescription))
        }
    }
}

private func findAppJSON(in directory: URL) throws->URL? {
    let fileManager = FileManager.default

    do {
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        if let appJSONFile = contents.first(where: { $0.lastPathComponent == "app.json" }) {
            return appJSONFile
        }

        if let firstSubdirectory = contents.first(where: { $0.hasDirectoryPath }) {
            let subContents = try fileManager.contentsOfDirectory(at: firstSubdirectory, includingPropertiesForKeys: nil)
            if let appJSONFileInSub = subContents.first(where: { $0.lastPathComponent == "app.json" }) {
                return appJSONFileInSub
            }
        }
    } catch {
        logger.error("[findAppJSON] \(error)")
        throw ErrorMsg(errorDescription: "[findAppJSON] \(error)")
    }

    return nil
}

private func installByAppJSON(in appJSONURL: URL, validateAppInfoFunc: ((AppInfo)->Bool)?) throws {
    let decoder = JSONDecoder()
    do {
        let data = try Data(contentsOf: appJSONURL)
        guard let newAppInfo = try? decoder.decode(AppInfo.self, from: data) else {
            logger.error("[installByAppJSON] invalid app.json")
            throw ErrorMsg(errorDescription: "invalid app.json")
        }

        if let validateAppInfoFunc = validateAppInfoFunc {
            if !validateAppInfoFunc(newAppInfo) {
                throw ErrorMsg(errorDescription: "invalid app, validate failed")
            }
        }

        let parentFolderURL = appJSONURL.deletingLastPathComponent()

        let rootDirectory = Global.shared.documentsRootURL
        let installedMatches = MiniAppManager.shared.getInstalledProjects().filter { $0.appId == newAppInfo.appId }
        let targetFolderURL: URL
        if installedMatches.count == 1 {
            targetFolderURL = installedMatches[0].rootURL
        } else if installedMatches.count > 1 {
            throw ErrorMsg(errorDescription: "multiple installed projects share the same appId")
        } else {
            guard !newAppInfo.name.isEmpty, !newAppInfo.name.contains("/") else {
                throw ErrorMsg(errorDescription: "invalid app name")
            }
            targetFolderURL = uniqueInstallDirectory(named: newAppInfo.name, in: rootDirectory)
        }

        // safe delete old file by AppInfo.files
        if let filesList = newAppInfo.files {
            var toDeleteFiles = [URL]()
            let newFilePaths = Set(filesList.map(\.path))

            let oldAppJsonPath = targetFolderURL.appendingPathComponent("app.json")

            if let oldAppJsonData = try? Data(contentsOf: oldAppJsonPath),
               let oldJson = try? decoder.decode(AppInfo.self, from: oldAppJsonData),
               let oldFilesList = oldJson.files
            {
                for ele in oldFilesList {
                    if !newFilePaths.contains(ele.path) {
                        let tmpPath = targetFolderURL.appending(path: ele.path)
                        toDeleteFiles.append(tmpPath)
                    }
                }
                logger.debug("[installByAppJSON] delete files: \(toDeleteFiles)")
                for ele in toDeleteFiles {
                    if FileManager.default.fileExists(atPath: ele.path(percentEncoded: false)) {
                        try FileManager.default.removeItem(at: ele)
                    } else {
                        logger.debug("[installByAppJSON] file not exist, skip delete: \(ele.path(percentEncoded: false))")
                    }
                }
            }
        }

        try copyFolder(from: parentFolderURL, to: targetFolderURL)

    } catch {
        logger.error("[installByAppJSON] \(error)")
        throw ErrorMsg(errorDescription: "\(error)")
    }
}

private func uniqueInstallDirectory(named name: String, in rootDirectory: URL) -> URL {
    let fileManager = FileManager.default
    var targetURL = rootDirectory.appending(component: name, directoryHint: .isDirectory)
    var suffix = 1
    while fileManager.fileExists(atPath: targetURL.path) {
        targetURL = rootDirectory.appending(component: "\(name) \(suffix)", directoryHint: .isDirectory)
        suffix += 1
    }
    return targetURL
}

private func deleteFolder(at url: URL) {
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: url.path) {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            logger.error("[deleteFolder] \(error)")
        }
    } else {
        logger.info("[deleteFolder] folder not exist: \(url.path)")
    }
}

private func copyFolder(from sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default

    if !fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
    }

    let sourceContents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil, options: [])

    for sourceFile in sourceContents {
        let destinationFile = destinationURL.appendingPathComponent(sourceFile.lastPathComponent)

        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: sourceFile.path, isDirectory: &isDirectory)

        if isDirectory.boolValue {
            try copyFolder(from: sourceFile, to: destinationFile)
        } else {
            if fileManager.fileExists(atPath: destinationFile.path) {
                try fileManager.removeItem(at: destinationFile)
            }
            try fileManager.copyItem(at: sourceFile, to: destinationFile)
        }
    }
}
