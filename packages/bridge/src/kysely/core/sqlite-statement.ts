export interface MinipSqliteStatement {
  readonly reader: boolean;
  iterate(parameters: ReadonlyArray<unknown>): AsyncIterableIterator<unknown>;
}
