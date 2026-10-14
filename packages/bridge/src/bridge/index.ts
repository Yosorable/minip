import { MinipError, MinipErrorCode } from "./error";
import { BridgeRequest, decodeReply, encodeRequest } from "./protocol";

export { MinipError, MinipErrorCode } from "./error";
export type { MinipErrorOptions } from "./error";

interface WebKitCallable {
  postMessage(data: string): Promise<string>;
}

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        MinipNativeInteractionV2?: WebKitCallable;
      };
    };
    __minipPreviewElement?: HTMLImageElement;
  }
}

function handler(api: string): WebKitCallable {
  const bridge = typeof window === "undefined" ? undefined : window.webkit?.messageHandlers?.MinipNativeInteractionV2;
  if (!bridge) throw new MinipError(MinipErrorCode.BRIDGE_UNAVAILABLE, "Minip Bridge 2 requires Minip 1.0 or later", { api });
  return bridge;
}

function transportError(cause: unknown, api: string): MinipError {
  if (cause instanceof MinipError) return cause;
  return new MinipError(MinipErrorCode.BRIDGE_ERROR, cause instanceof Error ? cause.message : "The native bridge call failed", { api, cause });
}

const jsBridge = {
  async callNative<T = void>(request: BridgeRequest): Promise<T> {
    try {
      const bridge = handler(request.api);
      const reply = await bridge.postMessage(encodeRequest(request));
      return decodeReply<T>(reply, request.api);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  },

  callNativeSync<T = void>(request: BridgeRequest): T {
    try {
      handler(request.api);
      const reply = window.prompt(encodeRequest(request));
      if (reply === null) throw new MinipError(MinipErrorCode.BRIDGE_ERROR, "The synchronous bridge returned no response", { api: request.api });
      return decodeReply<T>(reply, request.api);
    } catch (cause) {
      throw transportError(cause, request.api);
    }
  },
};

export default jsBridge;
