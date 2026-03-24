import { MinipSqliteStatement } from "./sqlite-statement";
import {
  sqliteCloseDB,
  sqliteExecute,
  sqliteOpenDB,
  sqlitePrepare,
} from "../../api/sqlite";
import { MinipSQLiteQueryIterator } from "./sqlite-query-iterator";

export class MinipSqliteDatabase {
  path: string;
  id: number;
  debug: boolean;
  constructor(path: string, debug: boolean) {
    this.path = path;
    this.id = -1;
    this.debug = debug;
  }
  async close(): Promise<void> {
    if (this.id === -1) return;
    await sqliteCloseDB(this.id);
  }
  private async ensureOpen(): Promise<number> {
    if (this.id === -1) {
      this.id = await sqliteOpenDB(this.path);
    }
    return this.id;
  }
  async execute(sql: string, parameters: ReadonlyArray<unknown>) {
    const dbKey = await this.ensureOpen();
    return sqliteExecute(dbKey, sql, parameters);
  }
  async prepare(sql: string): Promise<MinipSqliteStatement> {
    const dbKey = await this.ensureOpen();
    const stmtRes = await sqlitePrepare(dbKey, sql);

    const stmtKey = stmtRes.stmtKey;

    return {
      reader: stmtRes.reader,
      iterate(parameters) {
        return new MinipSQLiteQueryIterator(dbKey, stmtKey, parameters);
      },
    };
  }
}
