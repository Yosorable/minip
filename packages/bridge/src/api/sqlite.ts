import jsBridge from "../bridge";
import { MResponseWithData } from "../types";

export async function sqliteOpenDB(path: string): Promise<number> {
  const res = await jsBridge.callNative({
    api: "sqliteOpenDB",
    data: {
      path,
    },
  });
  return (res as MResponseWithData<{ dbKey: number }>).data.dbKey;
}

export async function sqliteCloseDB(dbKey: number): Promise<void> {
  await jsBridge.callNative({
    api: "sqliteCloseDB",
    data: {
      dbKey,
    },
  });
}

export async function sqlitePrepare(
  dbKey: number,
  sql: string,
): Promise<{ stmtKey: number; reader: boolean }> {
  const res = await jsBridge.callNative({
    api: "sqlitePrepare",
    data: {
      dbKey,
      sql,
    },
  });
  return (res as MResponseWithData<{ stmtKey: number; reader: boolean }>).data;
}

export async function sqliteStatementAll(
  dbKey: number,
  stmtKey: number,
  parameters: ReadonlyArray<unknown>,
): Promise<unknown[]> {
  const res = await jsBridge.callNative({
    api: "sqliteStatementAll",
    data: {
      dbKey,
      stmtKey,
      parameters,
    },
  });
  return (res as MResponseWithData<unknown[]>).data;
}

export async function sqliteStatementRun(
  dbKey: number,
  stmtKey: number,
  parameters: ReadonlyArray<unknown>,
): Promise<{
  changes: number | bigint;
  lastInsertRowid: number | bigint;
}> {
  const res = await jsBridge.callNative({
    api: "sqliteStatementRun",
    data: {
      dbKey,
      stmtKey,
      parameters,
    },
  });
  return (
    res as MResponseWithData<{
      changes: number | bigint;
      lastInsertRowid: number | bigint;
    }>
  ).data;
}

export async function sqliteExecute(
  dbKey: number,
  sql: string,
  parameters: ReadonlyArray<unknown>,
): Promise<{
  reader: boolean;
  runRes?: {
    changes: number | bigint;
    lastInsertRowid: number | bigint;
  };
  entityData?: unknown[];
}> {
  const res = await jsBridge.callNative({
    api: "sqliteExecute",
    data: {
      dbKey,
      sql,
      parameters,
    },
  });
  return (
    res as MResponseWithData<{
      reader: boolean;
      runRes?: {
        changes: number | bigint;
        lastInsertRowid: number | bigint;
      };
      entityData?: unknown[];
    }>
  ).data;
}

export async function sqliteCreateIterator(
  dbKey: number,
  stmtKey: number,
  parameters: ReadonlyArray<unknown>,
): Promise<void> {
  await jsBridge.callNative({
    api: "sqliteCreateIterator",
    data: {
      dbKey,
      stmtKey,
      parameters,
    },
  });
}

export async function sqliteIteratorNext(
  dbKey: number,
  stmtKey: number,
): Promise<unknown | undefined> {
  const res = await jsBridge.callNative({
    api: "sqliteIteratorNext",
    data: {
      dbKey,
      stmtKey,
    },
  });
  return (res as MResponseWithData<unknown | undefined>).data;
}

export async function sqliteIteratorRelease(
  dbKey: number,
  stmtKey: number,
): Promise<void> {
  await jsBridge.callNative({
    api: "sqliteIteratorRelease",
    data: {
      dbKey,
      stmtKey,
    },
  });
}
