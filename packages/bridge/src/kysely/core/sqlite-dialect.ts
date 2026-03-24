import {
  DatabaseIntrospector,
  Dialect,
  DialectAdapter,
  Driver,
  Kysely,
  QueryCompiler,
  SqliteAdapter,
  SqliteIntrospector,
  SqliteQueryCompiler,
} from "kysely";
import { MinipSqliteDialectConfig } from "./sqlite-dialect-config";
import { MinipSqliteDriver } from "./sqlite-driver";

export class MinipSqliteDialect implements Dialect {
  readonly #config: MinipSqliteDialectConfig;

  constructor(config: MinipSqliteDialectConfig) {
    this.#config = config;
  }

  createDriver(): Driver {
    return new MinipSqliteDriver(this.#config);
  }
  createQueryCompiler(): QueryCompiler {
    return new SqliteQueryCompiler();
  }
  createAdapter(): DialectAdapter {
    return new SqliteAdapter();
  }
  createIntrospector(db: Kysely<any>): DatabaseIntrospector {
    return new SqliteIntrospector(db);
  }
}
