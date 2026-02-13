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
    private var openedFDs: Set<Int32> = []

    init(appInfo: AppInfo) {
        dataDirURL = Global.shared.projectDataFolderURL.appending(path: appInfo.appId).standardizedFileURL

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dataDirURL.path) {
            try? fileManager.createDirectory(at: dataDirURL, withIntermediateDirectories: true)
        }
    }

    // close all opened fd
    deinit {
        logger.info("[FileSystemManager] deinit, clearing all opened fds")
        for fd in openedFDs {
            let res = Darwin.close(fd)
            if res != 0 {
                logger.error("[FileSystemManager] close fd error, code: \(errno), info: \(String(cString: strerror(errno)))")
            }
        }
    }

    private func appPathToURL(_ path: String) throws -> URL {
        let res = dataDirURL.appending(path: path).standardizedFileURL

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

    // MARK: todo: file exist

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

    func stat(path: String) throws -> FileStats {
        let path = try appPathToURL(path).path

        var statInfo = Darwin.stat()
        if lstat(path, &statInfo) != 0 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        return statInfoToFileStat(statInfo: statInfo)
    }

    func truncate(path: String, length: off_t) throws {
        let path = try appPathToURL(path).path
        let fd = Darwin.open(path, O_WRONLY)
        if fd == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        defer { Darwin.close(fd) }
        if Darwin.ftruncate(fd, length) == -1 {
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

    // MARK: todo: file exist

    func cp(src: String, dest: String, recursive: Bool) throws {
        let fileManager = FileManager.default
        let srcURL = try appPathToURL(src)
        let destURL = try appPathToURL(dest)

        let attributes = try fileManager.attributesOfItem(atPath: srcURL.path)
        if let type = attributes[.type] as? FileAttributeType {
            if type == .typeDirectory {
                guard recursive else {
                    throw NSError(domain: "FileSystemManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot copy directory without recursive flag"])
                }

                try fileManager.createDirectory(atPath: destURL.path, withIntermediateDirectories: true, attributes: nil)

                let contents = try fileManager.contentsOfDirectory(atPath: srcURL.path)
                for item in contents {
                    try cp(src: src + "/" + item, dest: dest + "/" + item, recursive: recursive)
                }
            } else {
                try fileManager.copyItem(atPath: srcURL.path, toPath: destURL.path)
            }
        }
    }

    // MARK: file descriptor operations

    func open(path: String, flags: Int32, mode: mode_t = 0o644) throws -> Int32 {
        let path = try appPathToURL(path).path
        let fd = Darwin.open(path, convertOpenFlags(from: flags), mode)
        if fd == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        openedFDs.insert(fd)
        return fd
    }

    func close(fd: Int32) throws {
        let result = Darwin.close(fd)
        if result != 0 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
        openedFDs.remove(fd)
    }

    func fstat(fd: Int32) throws -> FileStats {
        var statInfo = Darwin.stat()
        if Darwin.fstat(fd, &statInfo) != 0 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        return statInfoToFileStat(statInfo: statInfo)
    }

    func ftruncate(fd: Int32, length: off_t) throws {
        if Darwin.ftruncate(fd, length) != 0 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }
    }

    func read(fd: Int32, length: Int, position: Int?) throws -> Data {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        defer { buffer.deallocate() }

        if let pos = position, lseek(fd, off_t(pos), SEEK_SET) == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        let bytesRead = Darwin.read(fd, buffer, length)
        if bytesRead == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        return Data(bytes: buffer, count: bytesRead)
    }

    func write(fd: Int32, data: Data, position: Int?) throws -> Int {
        if let pos = position, lseek(fd, off_t(pos), SEEK_SET) == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        let bytesWritten = data.withUnsafeBytes { buffer in
            Darwin.write(fd, buffer.baseAddress, buffer.count)
        }

        if bytesWritten == -1 {
            throw NSError(domain: "FileSystemManager", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: String(cString: strerror(errno))])
        }

        return bytesWritten
    }

    private func convertOpenFlags(from linuxFlags: Int32) -> Int32 {
        var darwinFlags: Int32 = 0

        if linuxFlags & 0 == 0 { // O_RDONLY
            darwinFlags |= O_RDONLY
        }
        if linuxFlags & 1 != 0 { // O_WRONLY
            darwinFlags |= O_WRONLY
        }
        if linuxFlags & 2 != 0 { // O_RDWR
            darwinFlags |= O_RDWR
        }

        // Linux → Darwin
        if linuxFlags & 64 != 0 { // O_CREAT
            darwinFlags |= O_CREAT // Darwin: 512
        }
        if linuxFlags & 128 != 0 { // O_EXCL
            darwinFlags |= O_EXCL // Darwin: 2048
        }
        if linuxFlags & 512 != 0 { // O_TRUNC
            darwinFlags |= O_TRUNC // Darwin: 1024
        }
        if linuxFlags & 1024 != 0 { // O_APPEND
            darwinFlags |= O_APPEND // Darwin: 8
        }

        return darwinFlags
    }
}

extension FileSystemManager {
    private func statInfoToFileStat(statInfo: Darwin.stat) -> FileStats {
        let atimeMs = Double(statInfo.st_atimespec.tv_sec) * 1000 + Double(statInfo.st_atimespec.tv_nsec) / 1000000
        let mtimeMs = Double(statInfo.st_mtimespec.tv_sec) * 1000 + Double(statInfo.st_mtimespec.tv_nsec) / 1000000
        let ctimeMs = Double(statInfo.st_ctimespec.tv_sec) * 1000 + Double(statInfo.st_ctimespec.tv_nsec) / 1000000
        let birthtimeMs = Double(statInfo.st_birthtimespec.tv_sec) * 1000 + Double(statInfo.st_birthtimespec.tv_nsec) / 1000000

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
}
