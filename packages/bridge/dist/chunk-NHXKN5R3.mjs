import {
  bridge_default
} from "./chunk-TZQ7ME6J.mjs";

// src/api/sqlite.ts
async function sqliteOpenDB(path) {
  return bridge_default.callNative({ api: "sqliteOpenDB", data: { path } });
}
async function sqliteCloseDB(dbKey) {
  return bridge_default.callNative({ api: "sqliteCloseDB", data: { dbKey } });
}
async function sqlitePrepare(dbKey, sql) {
  return bridge_default.callNative({ api: "sqlitePrepare", data: { dbKey, sql } });
}
async function sqliteStatementAll(dbKey, stmtKey, parameters) {
  return bridge_default.callNative({ api: "sqliteStatementAll", data: { dbKey, stmtKey, parameters } });
}
async function sqliteStatementRun(dbKey, stmtKey, parameters) {
  return bridge_default.callNative({ api: "sqliteStatementRun", data: { dbKey, stmtKey, parameters } });
}
async function sqliteExecute(dbKey, sql, parameters) {
  return bridge_default.callNative({ api: "sqliteExecute", data: { dbKey, sql, parameters } });
}
async function sqliteCreateIterator(dbKey, stmtKey, parameters) {
  return bridge_default.callNative({ api: "sqliteCreateIterator", data: { dbKey, stmtKey, parameters } });
}
async function sqliteIteratorNext(dbKey, stmtKey) {
  return bridge_default.callNative({ api: "sqliteIteratorNext", data: { dbKey, stmtKey } });
}
async function sqliteIteratorRelease(dbKey, stmtKey) {
  return bridge_default.callNative({ api: "sqliteIteratorRelease", data: { dbKey, stmtKey } });
}

export {
  sqliteOpenDB,
  sqliteCloseDB,
  sqlitePrepare,
  sqliteStatementAll,
  sqliteStatementRun,
  sqliteExecute,
  sqliteCreateIterator,
  sqliteIteratorNext,
  sqliteIteratorRelease
};
//# sourceMappingURL=chunk-NHXKN5R3.mjs.map