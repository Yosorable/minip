import {
  sqliteCloseDB,
  sqliteCreateIterator,
  sqliteExecute,
  sqliteIteratorNext,
  sqliteIteratorRelease,
  sqliteOpenDB,
  sqlitePrepare
} from "../chunk-NHXKN5R3.mjs";
import {
  MinipError,
  MinipErrorCode
} from "../chunk-TZQ7ME6J.mjs";

// src/kysely/index.ts
import { Kysely as Kysely2, Migrator } from "kysely";

// src/kysely/core/sqlite-query-iterator.ts
var MinipSQLiteQueryIterator = class {
  dbKey;
  stmtKey;
  parameters;
  created = false;
  done = false;
  constructor(dbKey, stmtKey, parameters) {
    this.dbKey = dbKey;
    this.stmtKey = stmtKey;
    this.parameters = parameters;
  }
  async next() {
    if (this.done) return { value: void 0, done: true };
    try {
      if (!this.created) {
        await sqliteCreateIterator(this.dbKey, this.stmtKey, this.parameters);
        this.created = true;
      }
      const data = await sqliteIteratorNext(this.dbKey, this.stmtKey);
      if (data !== null) return { value: data, done: false };
      this.done = true;
      return { value: void 0, done: true };
    } catch (error) {
      this.done = true;
      try {
        await sqliteIteratorRelease(this.dbKey, this.stmtKey);
      } catch {
      }
      throw error;
    }
  }
  async return() {
    if (!this.done) {
      this.done = true;
      await sqliteIteratorRelease(this.dbKey, this.stmtKey);
    }
    return { value: void 0, done: true };
  }
  [Symbol.asyncIterator]() {
    return this;
  }
};

// src/kysely/core/sqlite-database.ts
var MinipSqliteDatabase = class {
  path;
  id;
  debug;
  constructor(path, debug) {
    this.path = path;
    this.id = -1;
    this.debug = debug;
  }
  async close() {
    if (this.id === -1) return;
    await sqliteCloseDB(this.id);
    this.id = -1;
  }
  async ensureOpen() {
    if (this.id === -1) {
      this.id = await sqliteOpenDB(this.path);
    }
    return this.id;
  }
  async execute(sql, parameters) {
    const dbKey = await this.ensureOpen();
    return sqliteExecute(dbKey, sql, parameters);
  }
  async prepare(sql) {
    const dbKey = await this.ensureOpen();
    const stmtRes = await sqlitePrepare(dbKey, sql);
    const stmtKey = stmtRes.stmtKey;
    return {
      reader: stmtRes.reader,
      iterate(parameters) {
        return new MinipSQLiteQueryIterator(dbKey, stmtKey, parameters);
      }
    };
  }
};

// src/kysely/core/sqlite-dialect.ts
import {
  SqliteAdapter,
  SqliteIntrospector,
  SqliteQueryCompiler
} from "kysely";

// src/kysely/core/sqlite-driver.ts
import {
  CompiledQuery as CompiledQuery2
} from "kysely";

// src/kysely/core/sqlite-connection.ts
import {
  SelectQueryNode
} from "kysely";
var MinipSqliteConnection = class {
  #db;
  constructor(db) {
    this.#db = db;
  }
  async executeQuery(compiledQuery) {
    const { sql, parameters } = compiledQuery;
    if (this.#db.debug) {
      console.debug(sql, parameters);
    }
    const res = await this.#db.execute(sql, parameters);
    if (res.reader === true) {
      return {
        rows: res.entityData ?? []
      };
    } else {
      const runRes = res.runRes;
      const numAffectedRows = runRes?.changes !== void 0 && runRes?.changes !== null ? BigInt(runRes.changes) : void 0;
      return {
        numAffectedRows,
        insertId: runRes?.lastInsertRowid !== void 0 && runRes?.lastInsertRowid !== null ? BigInt(runRes.lastInsertRowid) : void 0,
        rows: []
      };
    }
  }
  async *streamQuery(compiledQuery, _chunkSize) {
    const { sql, parameters, query } = compiledQuery;
    if (!SelectQueryNode.is(query)) {
      throw new MinipError(MinipErrorCode.NOT_SUPPORTED, "Sqlite driver only supports streaming of select queries");
    }
    const stmt = await this.#db.prepare(sql);
    const iter = stmt.iterate(parameters);
    for await (const row of iter) {
      yield {
        rows: [row]
      };
    }
  }
};

// src/kysely/core/sqlite-driver.ts
var MinipSqliteDriver = class {
  #config;
  #db;
  #connection;
  constructor(config) {
    this.#config = config;
  }
  async init() {
    this.#db = this.#config.database;
    this.#connection = new MinipSqliteConnection(this.#db);
    if (this.#config.onCreateConnection) {
      await this.#config.onCreateConnection(this.#connection);
    }
  }
  async acquireConnection() {
    return this.#connection;
  }
  async beginTransaction(connection, settings) {
    await connection.executeQuery(CompiledQuery2.raw("begin"));
  }
  async commitTransaction(connection) {
    await connection.executeQuery(CompiledQuery2.raw("commit"));
  }
  async rollbackTransaction(connection) {
    await connection.executeQuery(CompiledQuery2.raw("rollback"));
  }
  async releaseConnection(connection) {
  }
  async destroy() {
    await this.#db?.close();
  }
};

// src/kysely/core/sqlite-dialect.ts
var MinipSqliteDialect = class {
  #config;
  constructor(config) {
    this.#config = config;
  }
  createDriver() {
    return new MinipSqliteDriver(this.#config);
  }
  createQueryCompiler() {
    return new SqliteQueryCompiler();
  }
  createAdapter() {
    return new SqliteAdapter();
  }
  createIntrospector(db) {
    return new SqliteIntrospector(db);
  }
};

// src/kysely/index.ts
function openSqliteKyselyDB(props) {
  const dialect = new MinipSqliteDialect({
    database: new MinipSqliteDatabase(props.path, props.debug ?? false)
  });
  const db = new Kysely2({
    dialect
  });
  if (props.migratorProps) {
    const migrator = new Migrator({
      db,
      ...props.migratorProps
    });
    return {
      db,
      migrator
    };
  }
  return db;
}
export {
  openSqliteKyselyDB
};
//# sourceMappingURL=index.mjs.map