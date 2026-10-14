import Foundation

extension MinipApi {
    func sqliteOpenDB(param: Parameter) throws -> Int {
        let url = try param.fileSystem.resolvedURL(for: param.string("path"))
        return try SQLiteDBManager.shared.openDB(path: url.path).dbKey
    }

    func sqliteCloseDB(param: Parameter) throws {
        try SQLiteDBManager.shared.closeDB(dbKey: param.int("dbKey"))
    }

    func sqlitePrepare(param: Parameter) throws -> SQLiteDBManager.prepareResult {
        try SQLiteDBManager.shared.prepareStmt(dbKey: param.int("dbKey"), sql: param.string("sql"))
    }

    func sqliteStatementAll(param: Parameter) throws -> [[String: BridgeValue]] {
        try SQLiteDBManager.shared.allStmt(dbKey: param.int("dbKey"), stmtKey: param.int("stmtKey"), parameters: param.array("parameters"))
    }

    func sqliteStatementRun(param: Parameter) throws -> SQLiteDBManager.runStmtResult {
        try SQLiteDBManager.shared.runStmt(dbKey: param.int("dbKey"), stmtKey: param.int("stmtKey"), parameters: param.array("parameters"))
    }

    func sqliteExecute(param: Parameter) throws -> BridgeValue {
        let (reader, run, rows) = try SQLiteDBManager.shared.execute(dbKey: param.int("dbKey"), sql: param.string("sql"), parameters: param.array("parameters"))
        if reader {
            return .object(["reader": .bool(true), "entityData": .array((rows ?? []).map(BridgeValue.object))])
        }
        guard let run else { throw MinipError(.internalError, "Missing SQLite execution result") }
        return .object(["reader": .bool(false), "runRes": .object([
            "changes": .signed(Int64(run.changes)),
            "lastInsertRowid": .signed(run.lastInsertRowid),
        ])])
    }

    func sqliteCreateIterator(param: Parameter) throws {
        try SQLiteDBManager.shared.iterateStmt(dbKey: param.int("dbKey"), stmtKey: param.int("stmtKey"), parameters: param.array("parameters"))
    }

    func sqliteIteratorNext(param: Parameter) throws -> [String: BridgeValue]? {
        try SQLiteDBManager.shared.iterateStmtNext(dbKey: param.int("dbKey"), stmtKey: param.int("stmtKey"))
    }

    func sqliteIteratorRelease(param: Parameter) throws {
        try SQLiteDBManager.shared.iterateStmtRelease(dbKey: param.int("dbKey"), stmtKey: param.int("stmtKey"))
    }
}
