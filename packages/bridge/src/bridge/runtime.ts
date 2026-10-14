/** Version of the JavaScript runtime contract, independent of the wire protocol. */
export const MINIP_RUNTIME_VERSION = 1;

export interface BridgeRequest {
  api: string;
  /** A plain object containing the native API's parameters, when needed. */
  data?: unknown;
}

/** Provided by the Minip app before page scripts run. */
export interface MinipRuntime {
  readonly version: number;
  invoke<T = void>(request: BridgeRequest): Promise<T>;
  invokeSync<T = void>(request: BridgeRequest): T;
}

declare global {
  interface Window {
    __minipRuntime?: MinipRuntime;
    __minipPreviewElement?: HTMLImageElement;
  }
}
