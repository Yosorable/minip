import { setMemoryStorageIfNotExist } from "minip-bridge";
import { openSqliteKyselyDB } from "minip-bridge/kysely";
import { Kysely } from "kysely";
import { createSignal, onMount } from "solid-js";
import { Database } from "./database";
import migrations from "./migrations";

export default function SQLiteView() {
  const [msg, setMsg] = createSignal("");
  const [db, setDB] = createSignal<Kysely<Database>>();
  onMount(async () => {
    const start = Date.now();
    const { db: database, migrator } = openSqliteKyselyDB<Database>({
      path: "db.sqlite3",
      debug: true,
      migratorProps: {
        provider: {
          getMigrations() {
            return Promise.resolve(migrations);
          },
        },
      },
    });

    const once = await setMemoryStorageIfNotExist("migration-once", "1");
    if (once) {
      const res = await migrator?.migrateToLatest();
      if (res?.results) {
        console.debug(res?.results);
        setMsg("migrate res:\n" + JSON.stringify(res?.results, null, 2));
      } else if (res?.error) {
        // @ts-ignore
        const message = res?.error?.message;
        console.debug(message);
        setMsg("migrate error:\n" + message);
      }
    } else {
      setMsg("already migrated. ");
    }

    setDB(database);
    const elapsed = Date.now() - start;
    setMsg((curr) => curr + `\ninit cost: ${elapsed} ms`);
  });

  async function insert() {
    const start = Date.now();
    const res = await db()!
      .insertInto("person")
      .values([
        {
          first_name: "Jennifer",
          last_name: "Aniston",
          gender: "woman",
          age: 20,
        },
        {
          first_name: "Mike",
          last_name: "John",
          gender: "man",
          age: 22,
        },
      ])
      .executeTakeFirst();
    const elapsed = Date.now() - start;
    const obj = {
      insertId: res.insertId?.toString(),
      numInsertedOrUpdatedRows: res.numInsertedOrUpdatedRows?.toString(),
    };
    console.log(obj);
    setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(obj, null, 2));
  }

  async function duplicateID() {
    const start = Date.now();
    try {
      const res = await db()!
        .insertInto("person")
        .values([
          {
            id: 10,
            first_name: "Jennifer",
            last_name: "Aniston",
            gender: "woman",
            age: 20,
          },
          {
            id: 10,
            first_name: "Mike",
            last_name: "John",
            gender: "man",
            age: 22,
          },
        ])
        .executeTakeFirst();
      const elapsed = Date.now() - start;
      const obj = {
        insertId: res.insertId?.toString(),
        numInsertedOrUpdatedRows: res.numInsertedOrUpdatedRows?.toString(),
      };
      setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(obj, null, 2));
      console.log(obj);
    } catch (err) {
      const msg = (err as Error).message;
      setMsg(`error: ${msg}`);
      console.log(msg);
    }
  }

  async function select() {
    const start = Date.now();
    await db()!
      .selectFrom("person")
      .selectAll()
      .execute()
      .then((res) => {
        const elapsed = Date.now() - start;
        console.log(res);
        setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(res, null, 2));
      });
  }

  async function update() {
    const start = Date.now();
    await db()!
      .updateTable("person")
      .set({ first_name: Math.random().toString() })
      .where("id", "=", 1)
      .executeTakeFirst()
      .then((res) => {
        const elapsed = Date.now() - start;
        const obj = {
          numUpdatedRows: res.numUpdatedRows.toString(),
        };
        console.log(obj);
        setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(obj, null, 2));
      });
  }

  async function deleteFunc() {
    const start = Date.now();
    const result = await db()!.deleteFrom("person").limit(1).executeTakeFirst();
    const elapsed = Date.now() - start;
    const obj = {
      numDeletedRows: result.numDeletedRows.toString(),
    };
    console.log(obj);
    setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(obj, null, 2));
  }

  async function deleteAll() {
    const start = Date.now();
    const result = await db()!.deleteFrom("person").executeTakeFirst();
    const elapsed = Date.now() - start;
    const obj = {
      numDeletedRows: result.numDeletedRows.toString(),
    };
    console.log(obj);
    setMsg(`cost: ${elapsed} ms\n` + JSON.stringify(obj, null, 2));
  }

  async function streamQueryAll() {
    const start = Date.now();
    const stream = db()!.selectFrom("person").selectAll().stream();
    setMsg("");
    let startLine = Date.now();
    let cnt = 0;
    for await (const person of stream) {
      cnt++;
      const now = Date.now();
      const elapsedLine = now - startLine;
      startLine = now;
      setMsg(
        (curr) =>
          curr +
          `step ${cnt}, cost: ${elapsedLine} ms\n${JSON.stringify(
            person,
            null,
            2,
          )}\n`,
      );
    }
    const elapsed = Date.now() - start;
    setMsg((curr) => curr + `total cost: ${elapsed} ms\n`);
  }

  async function streamQueryOne() {
    const start = Date.now();
    const stream = db()!.selectFrom("person").selectAll().stream();
    setMsg("");
    let startLine = Date.now();
    let cnt = 0;
    for await (const person of stream) {
      cnt++;
      const now = Date.now();
      const elapsedLine = now - startLine;
      startLine = now;
      setMsg(
        (curr) =>
          curr +
          `step ${cnt}, cost: ${elapsedLine} ms\n${JSON.stringify(
            person,
            null,
            2,
          )}\n`,
      );
      if (cnt === 1) break;
    }
    const elapsed = Date.now() - start;
    setMsg((curr) => curr + `total cost: ${elapsed} ms\n`);
  }
  return (
    <div class="fade-in">
      <div
        class="res-div"
        style={{
          height: "300px",
        }}
      >
        {msg()}
      </div>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
        }}
      >
        <button onClick={select}>select</button>
        <button onClick={insert}>insert</button>
        <button onClick={update}>update</button>
        <button onClick={deleteFunc}>delete</button>
        <button onClick={deleteAll}>delete all</button>
      </div>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
        }}
      >
        <button onClick={duplicateID}>duplicate id</button>
        <button onClick={streamQueryAll}>stream query</button>
        <button onClick={streamQueryOne}>stream query one</button>
      </div>
    </div>
  );
}
