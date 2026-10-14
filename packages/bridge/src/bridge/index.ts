import { MinipError, MinipErrorCode } from "./error";
import { MINIP_RUNTIME_VERSION } from "./runtime";
import type { BridgeRequest, MinipRuntime } from "./runtime";

export { MinipError, MinipErrorCode } from "./error";
export type { MinipErrorOptions } from "./error";

function runtime(api: string): MinipRuntime {
  const bridge = typeof window === "undefined" ? undefined : window.__minipRuntime;
  if (
    !bridge || bridge.version !== MINIP_RUNTIME_VERSION ||
    typeof bridge.invoke !== "function" || typeof bridge.invokeSync !== "function"
  ) {
    throw new MinipError(
      MinipErrorCode.BRIDGE_UNAVAILABLE,
      "This SDK requires Minip's built-in bridge runtime v1. Update the Minip app.",
      { api },
    );
  }
  return bridge;
}

function transportError(cause: unknown, api: string): MinipError {
  if (cause instanceof MinipError) return cause;
  // The app runtime and an SDK bundle have separate MinipError constructors.
  if (cause !== null && typeof cause === "object") {
    const error = cause as Partial<MinipError>;
    if (error.name === "MinipError" && typeof error.code === "string" && typeof error.message === "string") {
      return new MinipError(error.code, error.message, {
        api: error.api ?? api,
        details: error.details,
        cause: error.cause,
      });
    }
  }
  return new MinipError(MinipErrorCode.BRIDGE_ERROR, cause instanceof Error ? cause.message : "The native bridge call failed", { api, cause });
}

const jsBridge = {
  async callNative<T = void>(request: BridgeRequest): Promise<T> {
    try {
      return await runtime(request.api).invoke<T>(request);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  },

  callNativeSync<T = void>(request: BridgeRequest): T {
    try {
      return runtime(request.api).invokeSync<T>(request);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  },
};

export default jsBridge;
