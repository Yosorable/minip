import { Kysely } from "kysely";

async function up(db: Kysely<any>): Promise<void> {
  await db.schema
    .alterTable("person")
    .addColumn("age", "integer", (col) => col.defaultTo(0).notNull())
    .execute();
}

async function down(db: Kysely<any>): Promise<void> {
  await db.schema.alterTable("person").dropColumn("age").execute();
}

const migration02 = {
  name: "migration02",
  up,
  down,
};

export default migration02;
