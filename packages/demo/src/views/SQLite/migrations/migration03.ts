import { Kysely } from "kysely";

async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .alterTable("person")
    .addColumn("credit", "decimal", (col) => col.defaultTo(0.1 + 0.2).notNull())
    .execute();
}

async function down(db: Kysely<any>): Promise<void> {
  await db.schema.alterTable("person").dropColumn("credit").execute();
}

const migration03 = {
  name: "migration03",
  up,
  down,
};

export default migration03;
