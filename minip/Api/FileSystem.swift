//
//  FileSystem.swift
//  minip
//
//  Created by ByteDance on 2025/7/11.
//

import Darwin
import Foundation

extension MinipApi {
    func fsAccess(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        let mode = (data["mode"] as? Int) ?? 0

        do {
            try replyHandler(InteropUtils.succeedWithData(data: fs.access(path: path, mode: mode)).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsMkdir(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        let recursive = (data["recursive"] as? Bool) ?? false

        do {
            try fs.mkdir(path: path, recursive: recursive)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsReadDir(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            try replyHandler(InteropUtils.succeedWithData(data: fs.readDir(path: path)).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsRmdir(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        let force = data["force"] as? Bool
        do {
            try fs.rmdir(path: path, force: force ?? false)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsReadFile(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            let data = try fs.readFile(path: path)
            replyHandler(InteropUtils.succeedWithData(data: data.base64EncodedString()).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsWriteFile(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let fileDataBase64 = (data["data"] as? String) ?? ""
        do {
            try fs.writeFile(path: path, data: Data(base64Encoded: fileDataBase64) ?? Data())
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsAppendFile(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String, let fileDataBase64 = data["data"] as? String, let fileData = Data(base64Encoded: fileDataBase64) else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.appendFile(path: path, data: fileData)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsCopyFile(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let src = data["src"] as? String, let dest = data["dest"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.copyFile(src: src, dest: dest)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsUnlink(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.unlink(path: path)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsRename(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let oldPath = data["oldPath"] as? String, let newPath = data["newPath"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.rename(oldPath: oldPath, newPath: newPath)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsStat(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try replyHandler(InteropUtils.succeedWithData(data: fs.stat(path: path)).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsTruncate(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String, let length = data["length"] as? Int else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.truncate(path: path, length: off_t(length))
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsRm(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.rm(path: path)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsCp(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let src = data["src"] as? String, let dest = data["dest"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let recursive = data["recursive"] as? Bool
        do {
            try fs.cp(src: src, dest: dest, recursive: recursive ?? false)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsOpen(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String, let flags = data["flags"] as? Int32 else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let mode = data["mode"] as? UInt16
        do {
            try replyHandler(InteropUtils.succeedWithData(data: fs.open(path: path, flags: flags, mode: mode ?? 0o644)).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsClose(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let fd = data["fd"] as? Int32 else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.close(fd: fd)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsFstat(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let fd = data["fd"] as? Int32 else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try replyHandler(InteropUtils.succeedWithData(data: fs.fstat(fd: fd)).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsFtruncate(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let fd = data["fd"] as? Int32, let length = data["length"] as? Int else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        do {
            try fs.ftruncate(fd: fd, length: off_t(length))
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsRead(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let fd = data["fd"] as? Int32, let length = data["length"] as? Int else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let position = data["position"] as? Int
        do {
            let data = try fs.read(fd: fd, length: length, position: position)
            replyHandler(InteropUtils.succeedWithData(data: data.base64EncodedString()).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func fsWrite(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let fs = MiniAppManager.shared.getFSManager() else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let fd = data["fd"] as? Int32 else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let fileDataBase64 = (data["data"] as? String) ?? ""
        let position = data["position"] as? Int
        do {
            let bytesWritten = try fs.write(fd: fd, data: Data(base64Encoded: fileDataBase64) ?? Data(), position: position)
            replyHandler(InteropUtils.succeedWithData(data: bytesWritten).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }
}
