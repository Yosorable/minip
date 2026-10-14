import jsBridge from "../bridge";

export interface SQLiteRunResult {
  changes: number | bigint;
  lastInsertRowid: number | bigint;
}

export type SQLiteExecutionResult =
  | { reader: true; entityData: Record<string, unknown>[] }
  | { reader: false; runRes: SQLiteRunResult };

export async function sqliteOpenDB(path: string): Promise<number> {
  return jsBridge.callNative<number>({ api: "sqliteOpenDB", data: { path } });
}

export async function sqliteCloseDB(dbKey: number): Promise<void> {
  return jsBridge.callNative<void>({ api: "sqliteCloseDB", data: { dbKey } });
}

export async function sqlitePrepare(dbKey: number, sql: string): Promise<{ stmtKey: number; reader: boolean }> {
  return jsBridge.callNative<{ stmtKey: number; reader: boolean }>({ api: "sqlitePrepare", data: { dbKey, sql } });
}

export async function sqliteStatementAll(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<Record<string, unknown>[]> {
  return jsBridge.callNative<Record<string, unknown>[]>({ api: "sqliteStatementAll", data: { dbKey, stmtKey, parameters } });
}

export async function sqliteStatementRun(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<SQLiteRunResult> {
  return jsBridge.callNative<SQLiteRunResult>({ api: "sqliteStatementRun", data: { dbKey, stmtKey, parameters } });
}

export async function sqliteExecute(dbKey: number, sql: string, parameters: ReadonlyArray<unknown>): Promise<SQLiteExecutionResult> {
  return jsBridge.callNative<SQLiteExecutionResult>({ api: "sqliteExecute", data: { dbKey, sql, parameters } });
}

export async function sqliteCreateIterator(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<void> {
  return jsBridge.callNative<void>({ api: "sqliteCreateIterator", data: { dbKey, stmtKey, parameters } });
}

export async function sqliteIteratorNext(dbKey: number, stmtKey: number): Promise<Record<string, unknown> | null> {
  return jsBridge.callNative<Record<string, unknown> | null>({ api: "sqliteIteratorNext", data: { dbKey, stmtKey } });
}

export async function sqliteIteratorRelease(dbKey: number, stmtKey: number): Promise<void> {
  return jsBridge.callNative<void>({ api: "sqliteIteratorRelease", data: { dbKey, stmtKey } });
}
