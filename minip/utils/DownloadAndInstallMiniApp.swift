//
//  InstallMiniApp.swift
//  minip
//
//  Created by LZY on 2024/12/9.
//

import Alamofire
import Foundation
import ZipArchive

func InstallMiniApp(pkgFile: URL, onSuccess: (()->Void)? = nil, onFailed: ((String)->Void)? = nil, signalAppListChangedOnSuccess: Bool = true) {
    let fileManager = FileManager.default

    let tempDirURL = fileManager.temporaryDirectory
    let unzipDirURL = tempDirURL.appendingPathComponent(UUID().uuidString)

    do {
        try fileManager.createDirectory(at: unzipDirURL, withIntermediateDirectories: true, attributes: nil)
        if !SSZipArchive.unzipFile(atPath: pkgFile.path, toDestination: unzipDirURL.path) {
            throw ErrorMsg(errorDescription: "unzipped failed")
        }

        guard let appJSONURL = try findAppJSON(in: unzipDirURL) else {
            throw ErrorMsg(errorDescription: "cannot find app.json")
        }
        try installByAppJSON(in: appJSONURL)
        onSuccess?()
        if signalAppListChangedOnSuccess {
            NotificationCenter.default.post(name: .appListUpdated, object: nil)
        }
        deleteFolder(at: unzipDirURL)
    } catch {
        onFailed?(error.localizedDescription)
    }
}

// download miniapp package and save to tmp folder
func DownloadMiniAppPackageToTmpFolder(_ downURL: String, onError: @escaping (ErrorMsg)->Void, onSuccess: @escaping (URL)->Void) {
    guard let downurl = URL(string: downURL) else {
        onError(ErrorMsg(errorDescription: "Error URL"))
        return
    }

    let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let destination: (URL, HTTPURLResponse)->(URL, DownloadRequest.Options) = { _, res in
        let pathComponent = res.suggestedFilename ?? "default.zip"

        let finalPath = docURL.appendingPolyfill(path: ".tmp").appendingPathComponent(pathComponent)
        return (finalPath, [.createIntermediateDirectories, .removePreviousFile])
    }
    let downloadReq = AF.download(downurl, to: destination)
        .response(completionHandler: { resp in
            if let err = resp.error {
                onError(ErrorMsg(errorDescription: err.localizedDescription))
                return
            } else if let tmpUrl = resp.fileURL {
                onSuccess(tmpUrl)
                return
            }
            onError(ErrorMsg(errorDescription: "Unknow error"))
        })
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

private func installByAppJSON(in appJSONURL: URL) throws {
    let decoder = JSONDecoder()
    do {
        let data = try Data(contentsOf: appJSONURL)
        guard let newAppInfo = try? decoder.decode(AppInfo.self, from: data) else {
            logger.error("[installByAppJSON] invalid app.json")
            throw ErrorMsg(errorDescription: "invalid app.json")
        }

        let parentFolderURL = appJSONURL.deletingLastPathComponent()

        let rootDirectory = Global.shared.documentsRootURL
        let targetFolderURL = rootDirectory.appendingPathComponent(newAppInfo.name)

        // safe delete old file by AppInfo.files
        if let filesList = newAppInfo.files {
            var toDeleteFiles = [URL]()
            var mp = [String: AppInfo.File]()
            for ele in filesList {
                mp[ele.path] = ele
            }

            let oldAppJsonPath = targetFolderURL.appendingPathComponent("app.json")

            if let oldAppJsonData = try? Data(contentsOf: oldAppJsonPath),
               let oldJson = try? decoder.decode(AppInfo.self, from: oldAppJsonData),
               let oldFilesList = oldJson.files
            {
                for ele in oldFilesList {
                    if !mp.keys.contains(ele.path) {
                        let tmpPath = targetFolderURL.appendingPolyfill(path: ele.path)
                        toDeleteFiles.append(tmpPath)
                    }
                }
                logger.debug("[installByAppJSON] delete files: \(toDeleteFiles)")
                try toDeleteFiles.forEach { ele in
                    try FileManager.default.removeItem(at: ele)
                }
            }
        }

        try copyFolder(from: parentFolderURL, to: targetFolderURL)

    } catch {
        logger.error("[installByAppJSON] \(error)")
        throw ErrorMsg(errorDescription: "\(error)")
    }
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
