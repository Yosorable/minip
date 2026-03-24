import { MigratorProps, Kysely, Migrator } from 'kysely';

interface MinipSqliteKyselyMigratorProps extends Omit<MigratorProps, "db"> {
}
interface OpenSqliteKyselyDBProps {
    path: string;
    debug?: boolean;
    migratorProps?: MinipSqliteKyselyMigratorProps;
}
interface OpenSqliteKyselyDBWithMigrationProps extends OpenSqliteKyselyDBProps {
}
declare function openSqliteKyselyDB<T>(props: {
    path: string;
    debug?: boolean;
}): Kysely<T>;
declare function openSqliteKyselyDB<T>(props: {
    path: string;
    debug?: boolean;
    migratorProps: MinipSqliteKyselyMigratorProps;
}): {
    db: Kysely<T>;
    migrator: Migrator;
};

export { type MinipSqliteKyselyMigratorProps, type OpenSqliteKyselyDBProps, type OpenSqliteKyselyDBWithMigrationProps, openSqliteKyselyDB };
