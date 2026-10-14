import {
  sqliteCreateIterator,
  sqliteIteratorNext,
  sqliteIteratorRelease,
} from "../../api/sqlite";

export class MinipSQLiteQueryIterator
  implements AsyncIterableIterator<unknown>
{
  readonly dbKey: number;
  readonly stmtKey: number;
  readonly parameters: ReadonlyArray<unknown>;
  created: boolean = false;
  private done = false;

  constructor(
    dbKey: number,
    stmtKey: number,
    parameters: ReadonlyArray<unknown>,
  ) {
    this.dbKey = dbKey;
    this.stmtKey = stmtKey;
    this.parameters = parameters;
  }

  public async next(): Promise<IteratorResult<unknown>> {
    if (this.done) return { value: undefined, done: true };
    try {
      if (!this.created) {
        await sqliteCreateIterator(this.dbKey, this.stmtKey, this.parameters);
        this.created = true;
      }
      const data = await sqliteIteratorNext(this.dbKey, this.stmtKey);
      if (data !== null) return { value: data, done: false };
      this.done = true;
      return { value: undefined, done: true };
    } catch (error) {
      this.done = true;
      // Preparation already allocated a native statement, even if SDK validation
      // prevented iterator creation. Native cleanup is idempotent after SQL errors.
      try {
        await sqliteIteratorRelease(this.dbKey, this.stmtKey);
      } catch {
        // Keep the original query/transport error if cleanup is also unavailable.
      }
      throw error;
    }
  }

  public async return(): Promise<IteratorResult<unknown>> {
    if (!this.done) {
      this.done = true;
      await sqliteIteratorRelease(this.dbKey, this.stmtKey);
    }
    return { value: undefined, done: true };
  }

  [Symbol.asyncIterator](): AsyncIterableIterator<unknown> {
    return this;
  }
}
