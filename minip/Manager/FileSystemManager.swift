//
//  FileSystemManager.swift
//  minip
//
//  Created by ByteDance on 2025/7/17.
//

import Darwin
import Foundation

class FileSystemManager {
    struct FileStats: Codable {
        let dev: UInt32
        let mode: mode_t
        let nlink: UInt16
        let uid: uid_t
        let gid: gid_t
        let rdev: UInt32
        let blksize: Int
        let ino: ino_t
        let size: off_t
        let blocks: blkcnt_t
        let atimeMs: Double
        let mtimeMs: Double
        let ctimeMs: Double
        let birthtimeMs: Double
    }

    private var dataDirURL: URL

    init(appInfo: AppInfo) {
        dataDirURL = Global.shared.projectDataFolderURL.appendingPolyfill(path: appInfo.appId).standardizedFileURL

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dataDirURL.path) {
            try? fileManager.createDirectory(at: dataDirURL, withIntermediateDirectories: true)
        }
    }

    // close all opened fd
    deinit {
        logger.info("[FileSystemManager] deinit")
    }

    private func appPathToURL(_ path: String) throws -> URL {
        let res = dataDirURL.appendingPolyfill(path: path).standardizedFileURL

        if !res.path.hasPrefix(dataDirURL.path) {
            throw NSError(domain: "FileSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "no premission"])
        }

        return res
    }

    func access(path: String, mode: Int = 0) throws -> Bool {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default

        switch mode {
        case 1:
            return fileManager.isReadableFile(atPath: path)
        case 2:
            return fileManager.isWritableFile(atPath: path)
        case 3:
            return fileManager.isReadableFile(atPath: path) && fileManager.isWritableFile(atPath: path)
        case 4:
            return fileManager.isExecutableFile(atPath: path)
        default:
            return fileManager.fileExists(atPath: path)
        }
    }

    func mkdir(path: String, recursive: Bool) throws {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            throw NSError(domain: "FileSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "exist"])
        }
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: recursive, attributes: nil)
    }

    func readDir(path: String) throws -> [String] {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default
        return try fileManager.contentsOfDirectory(atPath: path)
    }

    func rmdir(path: String, force: Bool) throws {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default

        if !force {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
                throw NSError(domain: "FileSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "not directory"])
            }
        }

        let contents = try fileManager.contentsOfDirectory(atPath: path)
        if !contents.isEmpty {
            throw NSError(domain: "FileSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "directory is not empty"])
        }

        try fileManager.removeItem(atPath: path)
    }

    func readFile(path: String) throws -> Data {
        let path = try appPathToURL(path).path
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func writeFile(path: String, data: Data) throws {
        try data.write(to: appPathToURL(path))
    }

    func appendFile(path: String, data: Data) throws {
        let fileManager = FileManager.default
        let url = try appPathToURL(path)
        let path = url.path

        if fileManager.fileExists(atPath: path) {
            let fileHandle = try FileHandle(forWritingTo: url)
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: url)
        }
    }

    func copyFile(src: String, dest: String) throws {
        let src = try appPathToURL(src).path
        let dest = try appPathToURL(dest).path
        let fileManager = FileManager.default
        try fileManager.copyItem(atPath: src, toPath: dest)
    }

    func unlink(path: String) throws {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default
        try fileManager.removeItem(atPath: path)
    }

    func rename(oldPath: String, newPath: String) throws {
        let oldPath = try appPathToURL(oldPath).path
        let newPath = try appPathToURL(newPath).path
        let fileManager = FileManager.default
        try fileManager.moveItem(atPath: oldPath, toPath: newPath)
    }

    // MARK: todo key

    func stat(path: String) throws -> FileStats {
        let url = try appPathToURL(path)
        let path = url.path
        let fileManager = FileManager.default

        let attributes = try fileManager.attributesOfItem(atPath: path)

        var statInfo = Darwin.stat()
        let result = lstat(path, &statInfo)
        if result != 0 {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil)
        }

        let atimeMs = Double(statInfo.st_atimespec.tv_sec) * 1000 +
            Double(statInfo.st_atimespec.tv_nsec) / 1000000
        let mtimeMs = Double(statInfo.st_mtimespec.tv_sec) * 1000 +
            Double(statInfo.st_mtimespec.tv_nsec) / 1000000
        let ctimeMs = Double(statInfo.st_ctimespec.tv_sec) * 1000 +
            Double(statInfo.st_ctimespec.tv_nsec) / 1000000

        let birthtimeMs: Double
        if #available(macOS 10.15, iOS 13.0, *) {
            birthtimeMs = ((attributes[.creationDate] as? Date)?.timeIntervalSince1970 ?? 0) * 1000
        } else {
            birthtimeMs = ctimeMs
        }

        return FileStats(
            dev: UInt32(statInfo.st_dev),
            mode: statInfo.st_mode,
            nlink: statInfo.st_nlink,
            uid: statInfo.st_uid,
            gid: statInfo.st_gid,
            rdev: UInt32(statInfo.st_rdev),
            blksize: Int(statInfo.st_blksize),
            ino: statInfo.st_ino,
            size: statInfo.st_size,
            blocks: statInfo.st_blocks,
            atimeMs: atimeMs,
            mtimeMs: mtimeMs,
            ctimeMs: ctimeMs,
            birthtimeMs: birthtimeMs
        )
    }

    func truncate(path: String, length: off_t) throws {
        let path = try appPathToURL(path).path
        let fd = open(path, O_WRONLY)
        if fd == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        defer { close(fd) }
        if ftruncate(fd, length) == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
    }

    func rm(path: String) throws {
        let path = try appPathToURL(path).path
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else {
            throw NSError(domain: "FileSystemManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "file not found"])
        }

        try fileManager.removeItem(atPath: path)
    }
}
