//
//  InstallMiniApp.swift
//  minip
//
//  Created by LZY on 2024/12/9.
//

import Foundation
import ZipArchive

// todo: 安装位置和数据存储位置分离？
func InstallMiniApp(pkgFile: URL, onSuccess: (()->Void)? = nil, onFailed: ((String)->Void)? = nil) {
    let fileManager = FileManager.default
    // 获取临时目录
    let tempDirURL = fileManager.temporaryDirectory
    // 创建解压目标目录
    let unzipDirURL = tempDirURL.appendingPathComponent(UUID().uuidString)
    do {
        try fileManager.createDirectory(at: unzipDirURL, withIntermediateDirectories: true, attributes: nil)
        if !SSZipArchive.unzipFile(atPath: pkgFile.path, toDestination: unzipDirURL.path) {
            throw ErrorMsg(errorDescription: "unzipped failed")
        }
        // 兼容两层压缩包
        guard let appJSONURL = try findAppJSON(in: unzipDirURL) else {
            throw ErrorMsg(errorDescription: "cannot find app.json")
        }
        try installByAppJSON(in: appJSONURL)
        onSuccess?()
        deleteFolder(at: unzipDirURL)
    } catch {
        onFailed?(error.localizedDescription)
    }
}

private func findAppJSON(in directory: URL) throws -> URL? {
    let fileManager = FileManager.default

    do {
        // 获取目录中的内容
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        // 检查根目录是否包含 app.json
        if let appJSONFile = contents.first(where: { $0.lastPathComponent == "app.json" }) {
            return appJSONFile
        }

        // 获取第一个子文件夹
        if let firstSubdirectory = contents.first(where: { $0.hasDirectoryPath }) {
            // 检查第一个子文件夹中是否包含 app.json
            let subContents = try fileManager.contentsOfDirectory(at: firstSubdirectory, includingPropertiesForKeys: nil)
            if let appJSONFileInSub = subContents.first(where: { $0.lastPathComponent == "app.json" }) {
                return appJSONFileInSub
            }
        }
    } catch {
        logger.error("检查目录时发生错误: \(error)")
        throw ErrorMsg(errorDescription: "检查目录时发生错误: \(error)")
    }

    // 如果没有找到，返回 nil
    return nil
}

private func installByAppJSON(in appJSONURL: URL) throws {
    do {
        // 读取 app.json 文件内容
        let data = try Data(contentsOf: appJSONURL)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let name = json["name"] as? String else {
            logger.error("app.json 文件格式无效或缺少 'name' 字段")
            throw ErrorMsg(errorDescription: "app.json 文件格式无效或缺少 'name' 字段")
        }

        // 确定 app.json 所在文件夹
        let parentFolderURL = appJSONURL.deletingLastPathComponent()

        // 确定目标路径：软件根目录 + name 字段
        let rootDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let targetFolderURL = rootDirectory.appendingPathComponent(name)

        // 移动文件夹
//        try FileManager.default.moveItem(at: parentFolderURL, to: targetFolderURL)
        try copyFolder(from: parentFolderURL, to: targetFolderURL)

    } catch {
        logger.error("安装时发生错误: \(error)")
        throw ErrorMsg(errorDescription: "安装时发生错误: \(error)")
    }
}

private func deleteFolder(at url: URL) {
    let fileManager = FileManager.default
    
    // 检查文件夹是否存在
    if fileManager.fileExists(atPath: url.path) {
        do {
            // 删除文件夹及其中的内容
            try fileManager.removeItem(at: url)
        } catch {
            logger.error("删除文件夹失败: \(error)")
        }
    } else {
        logger.info("文件夹不存在: \(url.path)")
    }
}

private func copyFolder(from sourceURL: URL, to destinationURL: URL) throws {
    let fileManager = FileManager.default
    
    // 确保目标文件夹存在
    if !fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    let sourceContents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil, options: [])
    
    for sourceFile in sourceContents {
        let destinationFile = destinationURL.appendingPathComponent(sourceFile.lastPathComponent)
        
        // 判断源文件是文件还是文件夹
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: sourceFile.path, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            // 如果是文件夹，递归调用copyFolder
            try copyFolder(from: sourceFile, to: destinationFile)
        } else {
            // 如果是文件，检查目标文件是否存在
            if fileManager.fileExists(atPath: destinationFile.path) {
                // 如果文件存在，则删除目标文件（替换）
                try fileManager.removeItem(at: destinationFile)
            }
            // 然后拷贝文件
            try fileManager.copyItem(at: sourceFile, to: destinationFile)
        }
    }
}
