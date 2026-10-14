import Foundation

extension MinipApi {
    func fsAccess(param: Parameter) throws {
        let mode = try param.int("mode", default: 0)
        guard (0...4).contains(mode) else { throw MinipError.invalidArgument("mode") }
        _ = try param.fileSystem.access(path: param.string("path"), mode: mode)
    }

    func fsMkdir(param: Parameter) throws {
        try param.fileSystem.mkdir(path: param.string("path"), recursive: param.bool("recursive"))
    }

    func fsReaddir(param: Parameter) throws -> [String] {
        try param.fileSystem.readdir(path: param.string("path"))
    }

    func fsRmdir(param: Parameter) throws {
        try param.fileSystem.rmdir(path: param.string("path"), recursive: param.bool("recursive"))
    }

    func fsReadFile(param: Parameter) throws -> Data {
        try param.fileSystem.readFile(path: param.string("path"))
    }

    func fsWriteFile(param: Parameter) throws {
        try param.fileSystem.writeFile(path: param.string("path"), data: param.bytes("data"))
    }

    func fsAppendFile(param: Parameter) throws {
        try param.fileSystem.appendFile(path: param.string("path"), data: param.bytes("data"))
    }

    func fsCopyFile(param: Parameter) throws {
        try param.fileSystem.copyFile(src: param.string("src"), dest: param.string("dest"))
    }

    func fsUnlink(param: Parameter) throws {
        try param.fileSystem.unlink(path: param.string("path"))
    }

    func fsRename(param: Parameter) throws {
        try param.fileSystem.rename(oldPath: param.string("oldPath"), newPath: param.string("newPath"))
    }

    func fsStat(param: Parameter) throws -> FileSystemManager.FileStats {
        try param.fileSystem.stat(path: param.string("path"))
    }

    func fsTruncate(param: Parameter) throws {
        try param.fileSystem.truncate(path: param.string("path"), length: off_t(param.nonnegativeInt("length", default: 0)))
    }

    func fsRm(param: Parameter) throws {
        try param.fileSystem.rm(path: param.string("path"))
    }

    func fsCp(param: Parameter) throws {
        try param.fileSystem.cp(src: param.string("src"), dest: param.string("dest"), recursive: param.bool("recursive"))
    }

    func fsOpen(param: Parameter) throws -> Int32 {
        let mode = try param.nonnegativeInt("mode", default: 0o644)
        guard let fileMode = mode_t(exactly: mode) else { throw MinipError.invalidArgument("mode") }
        return try param.fileSystem.open(path: param.string("path"), flags: param.int32("flags"), mode: fileMode)
    }

    func fsClose(param: Parameter) throws {
        try param.fileSystem.close(fd: param.int32("fd"))
    }

    func fsFstat(param: Parameter) throws -> FileSystemManager.FileStats {
        try param.fileSystem.fstat(fd: param.int32("fd"))
    }

    func fsFtruncate(param: Parameter) throws {
        try param.fileSystem.ftruncate(fd: param.int32("fd"), length: off_t(param.nonnegativeInt("length", default: 0)))
    }

    func fsRead(param: Parameter) throws -> Data {
        try param.fileSystem.read(fd: param.int32("fd"), length: param.nonnegativeInt("length"), position: param.position())
    }

    func fsWrite(param: Parameter) throws -> Int {
        try param.fileSystem.write(fd: param.int32("fd"), data: param.bytes("data"), position: param.position())
    }
}
