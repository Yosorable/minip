export enum MResponseStatusCode {
  SUCCESS = 0,
  FAILED = 7,
}

export interface MResponse {
  /**
   * Integer, 0 for succeeded, other for failed.
   * Auto reject in promise when failed.
   */
  code: MResponseStatusCode;
  /**
   * Error msg or other info.
   */
  msg?: string;

  isSuccess(): boolean;
}

export interface MResponseWithData<T> extends MResponse {
  data: T;
  hasData(): boolean;
}

export * from "./ui"