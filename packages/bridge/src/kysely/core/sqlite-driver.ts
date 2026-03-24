import {
  CompiledQuery,
  DatabaseConnection,
  Driver,
  TransactionSettings,
} from "kysely";
import { MinipSqliteDialectConfig } from "./sqlite-dialect-config";
import { MinipSqliteConnection } from "./sqlite-connection";
import { MinipSqliteDatabase } from "./sqlite-database";

export class MinipSqliteDriver implements Driver {
  readonly #config: MinipSqliteDialectConfig;

  #db?: MinipSqliteDatabase;
  #connection?: MinipSqliteConnection;

  constructor(config: MinipSqliteDialectConfig) {
    this.#config = config;
  }

  async init() {
    this.#db = this.#config.database;
    this.#connection = new MinipSqliteConnection(this.#db);
    if (this.#config.onCreateConnection) {
      await this.#config.onCreateConnection(this.#connection);
    }
  }
  async acquireConnection(): Promise<MinipSqliteConnection> {
    return this.#connection!;
  }
  async beginTransaction(
    connection: DatabaseConnection,
    settings: TransactionSettings,
  ): Promise<void> {
    await connection.executeQuery(CompiledQuery.raw("begin"));
  }
  async commitTransaction(connection: DatabaseConnection): Promise<void> {
    await connection.executeQuery(CompiledQuery.raw("commit"));
  }
  async rollbackTransaction(connection: DatabaseConnection): Promise<void> {
    await connection.executeQuery(CompiledQuery.raw("rollback"));
  }
  async releaseConnection(connection: DatabaseConnection): Promise<void> {}
  async destroy(): Promise<void> {
    this.#db?.close();
  }
}
