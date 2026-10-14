import { MinipError, MinipErrorCode } from "../bridge/error";
import { MINIP_RUNTIME_VERSION } from "../bridge/runtime";
import type { BridgeRequest, MinipRuntime } from "../bridge/runtime";
import { decodeReply, encodeRequest } from "./protocol";

interface WebKitCallable {
  postMessage(data: string): Promise<string>;
}

function handler(api: string): WebKitCallable {
  const bridge = (window as Window & {
    webkit?: { messageHandlers?: { MinipNativeInteractionV2?: WebKitCallable } };
  }).webkit?.messageHandlers?.MinipNativeInteractionV2;
  if (!bridge) {
    throw new MinipError(MinipErrorCode.BRIDGE_UNAVAILABLE, "The native bridge is unavailable", { api });
  }
  return bridge;
}

function transportError(cause: unknown, api: string): MinipError {
  if (cause instanceof MinipError) return cause;
  return new MinipError(
    MinipErrorCode.BRIDGE_ERROR,
    cause instanceof Error ? cause.message : "The native bridge call failed",
    { api, cause },
  );
}

const runtime: MinipRuntime = {
  version: MINIP_RUNTIME_VERSION,

  async invoke<T = void>(request: BridgeRequest): Promise<T> {
    const message = encodeRequest(request);
    const api = request.api;
    try {
      const reply = await handler(api).postMessage(message);
      return decodeReply<T>(reply, api);
    } catch (cause) {
      throw transportError(cause, api);
    }
  },

  invokeSync<T = void>(request: BridgeRequest): T {
    const message = encodeRequest(request);
    const api = request.api;
    try {
      handler(api);
      const reply = window.prompt(message);
      if (reply === null) {
        throw new MinipError(MinipErrorCode.BRIDGE_ERROR, "The synchronous bridge returned no response", { api });
      }
      return decodeReply<T>(reply, api);
    } catch (cause) {
      throw transportError(cause, api);
    }
  },
};

Object.defineProperty(window, "__minipRuntime", {
  value: Object.freeze(runtime),
  writable: false,
  configurable: false,
});
