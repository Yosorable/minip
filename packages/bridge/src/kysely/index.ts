import { Kysely, Migrator, MigratorProps } from "kysely";
import { MinipSqliteDatabase } from "./core/sqlite-database";
import { MinipSqliteDialect } from "./core/sqlite-dialect";

export interface MinipSqliteKyselyMigratorProps
  extends Omit<MigratorProps, "db"> {}

export interface OpenSqliteKyselyDBProps {
  path: string;
  debug?: boolean;
  migratorProps?: MinipSqliteKyselyMigratorProps;
}

export interface OpenSqliteKyselyDBWithMigrationProps
  extends OpenSqliteKyselyDBProps {}

export function openSqliteKyselyDB<T>(props: {
  path: string;
  debug?: boolean;
}): Kysely<T>;

export function openSqliteKyselyDB<T>(props: {
  path: string;
  debug?: boolean;
  migratorProps: MinipSqliteKyselyMigratorProps;
}): {
  db: Kysely<T>;
  migrator: Migrator;
};

export function openSqliteKyselyDB<T>(props: OpenSqliteKyselyDBProps) {
  const dialect = new MinipSqliteDialect({
    database: new MinipSqliteDatabase(props.path, props.debug ?? false),
  });
  const db = new Kysely<T>({
    dialect,
  });

  if (props.migratorProps) {
    const migrator = new Migrator({
      db,
      ...props.migratorProps,
    });
    return {
      db,
      migrator,
    };
  }

  return db;
}
