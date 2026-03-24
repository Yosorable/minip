import { DatabaseConnection } from "kysely";
import { MinipSqliteDatabase } from "./sqlite-database";

export interface MinipSqliteDialectConfig {
  database: MinipSqliteDatabase;
  onCreateConnection?: (connection: DatabaseConnection) => Promise<void>;
}
