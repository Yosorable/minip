import {
  bridge_default
} from "./chunk-GXHJCCLG.mjs";

// src/api/sqlite.ts
async function sqliteOpenDB(path) {
  const res = await bridge_default.callNative({
    api: "sqliteOpenDB",
    data: {
      path
    }
  });
  return res.data.dbKey;
}
async function sqliteCloseDB(dbKey) {
  await bridge_default.callNative({
    api: "sqliteCloseDB",
    data: {
      dbKey
    }
  });
}
async function sqlitePrepare(dbKey, sql) {
  const res = await bridge_default.callNative({
    api: "sqlitePrepare",
    data: {
      dbKey,
      sql
    }
  });
  return res.data;
}
async function sqliteStatementAll(dbKey, stmtKey, parameters) {
  const res = await bridge_default.callNative({
    api: "sqliteStatementAll",
    data: {
      dbKey,
      stmtKey,
      parameters
    }
  });
  return res.data;
}
async function sqliteStatementRun(dbKey, stmtKey, parameters) {
  const res = await bridge_default.callNative({
    api: "sqliteStatementRun",
    data: {
      dbKey,
      stmtKey,
      parameters
    }
  });
  return res.data;
}
async function sqliteExecute(dbKey, sql, parameters) {
  const res = await bridge_default.callNative({
    api: "sqliteExecute",
    data: {
      dbKey,
      sql,
      parameters
    }
  });
  return res.data;
}
async function sqliteCreateIterator(dbKey, stmtKey, parameters) {
  await bridge_default.callNative({
    api: "sqliteCreateIterator",
    data: {
      dbKey,
      stmtKey,
      parameters
    }
  });
}
async function sqliteIteratorNext(dbKey, stmtKey) {
  const res = await bridge_default.callNative({
    api: "sqliteIteratorNext",
    data: {
      dbKey,
      stmtKey
    }
  });
  return res.data;
}
async function sqliteIteratorRelease(dbKey, stmtKey) {
  await bridge_default.callNative({
    api: "sqliteIteratorRelease",
    data: {
      dbKey,
      stmtKey
    }
  });
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
//# sourceMappingURL=chunk-4HUUDNXW.mjs.map