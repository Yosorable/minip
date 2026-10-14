import {
  CompiledQuery,
  DatabaseConnection,
  QueryResult,
  SelectQueryNode,
} from "kysely";
import { MinipSqliteDatabase } from "./sqlite-database";
import { MinipError, MinipErrorCode } from "../../bridge";

export class MinipSqliteConnection implements DatabaseConnection {
  readonly #db: MinipSqliteDatabase;

  constructor(db: MinipSqliteDatabase) {
    this.#db = db;
  }
  async executeQuery<R>(compiledQuery: CompiledQuery): Promise<QueryResult<R>> {
    const { sql, parameters } = compiledQuery;
    if (this.#db.debug) {
      console.debug(sql, parameters);
    }
    const res = await this.#db.execute(sql, parameters);

    if (res.reader === true) {
      return {
        rows: (res.entityData ?? []) as R[],
      };
    } else {
      const runRes = res.runRes;
      const numAffectedRows =
        runRes?.changes !== undefined && runRes?.changes !== null
          ? BigInt(runRes.changes)
          : undefined;

      return {
        numAffectedRows,
        insertId:
          runRes?.lastInsertRowid !== undefined &&
          runRes?.lastInsertRowid !== null
            ? BigInt(runRes.lastInsertRowid)
            : undefined,
        rows: [],
      };
    }
  }
  async *streamQuery<R>(
    compiledQuery: CompiledQuery,
    _chunkSize: number,
  ): AsyncIterableIterator<QueryResult<R>> {
    const { sql, parameters, query } = compiledQuery;
    if (!SelectQueryNode.is(query)) {
      throw new MinipError(MinipErrorCode.NOT_SUPPORTED, "Sqlite driver only supports streaming of select queries");
    }
    const stmt = await this.#db.prepare(sql);
    const iter = stmt.iterate(parameters) as AsyncIterableIterator<R>;
    for await (const row of iter) {
      yield {
        rows: [row],
      };
    }
  }
}
