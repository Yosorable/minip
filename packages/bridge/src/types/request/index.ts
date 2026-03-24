export interface MRequestBase {
  /**
   * Api name.
   */
  api: string;
}

export interface MRequestWithData<T> extends MRequestBase {
  data?: T;
}

export type MRequest<T> = MRequestBase | MRequestWithData<T>;

export * from "./ui";
