// src/bridge/error.ts
var MinipErrorCode = {
  INVALID_ARGUMENT: "INVALID_ARGUMENT",
  API_NOT_FOUND: "API_NOT_FOUND",
  NOT_SUPPORTED: "NOT_SUPPORTED",
  NOT_FOUND: "NOT_FOUND",
  ALREADY_EXISTS: "ALREADY_EXISTS",
  PERMISSION_DENIED: "PERMISSION_DENIED",
  INVALID_STATE: "INVALID_STATE",
  IO_ERROR: "IO_ERROR",
  DATABASE_ERROR: "DATABASE_ERROR",
  BRIDGE_UNAVAILABLE: "BRIDGE_UNAVAILABLE",
  BRIDGE_ERROR: "BRIDGE_ERROR",
  INVALID_RESPONSE: "INVALID_RESPONSE",
  INTERNAL_ERROR: "INTERNAL_ERROR"
};
var MinipError = class extends Error {
  code;
  api;
  details;
  cause;
  constructor(code, message, options = {}) {
    super(message);
    this.name = "MinipError";
    this.code = code;
    this.api = options.api;
    this.details = options.details;
    this.cause = options.cause;
  }
};

// src/bridge/runtime.ts
var MINIP_RUNTIME_VERSION = 1;

// src/bridge/index.ts
function runtime(api) {
  const bridge = typeof window === "undefined" ? void 0 : window.__minipRuntime;
  if (!bridge || bridge.version !== MINIP_RUNTIME_VERSION || typeof bridge.invoke !== "function" || typeof bridge.invokeSync !== "function") {
    throw new MinipError(
      MinipErrorCode.BRIDGE_UNAVAILABLE,
      "This SDK requires Minip's built-in bridge runtime v1. Update the Minip app.",
      { api }
    );
  }
  return bridge;
}
function transportError(cause, api) {
  if (cause instanceof MinipError) return cause;
  if (cause !== null && typeof cause === "object") {
    const error = cause;
    if (error.name === "MinipError" && typeof error.code === "string" && typeof error.message === "string") {
      return new MinipError(error.code, error.message, {
        api: error.api ?? api,
        details: error.details,
        cause: error.cause
      });
    }
  }
  return new MinipError(MinipErrorCode.BRIDGE_ERROR, cause instanceof Error ? cause.message : "The native bridge call failed", { api, cause });
}
var jsBridge = {
  async callNative(request) {
    try {
      return await runtime(request.api).invoke(request);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  },
  callNativeSync(request) {
    try {
      return runtime(request.api).invokeSync(request);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  }
};
var bridge_default = jsBridge;

export {
  MinipErrorCode,
  MinipError,
  bridge_default
};
//# sourceMappingURL=chunk-TZQ7ME6J.mjs.map