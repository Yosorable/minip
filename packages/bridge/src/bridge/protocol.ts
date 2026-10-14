import { Decoder, Encoder } from "@msgpack/msgpack";
import { MinipError, MinipErrorCode } from "./error";

export interface BridgeRequest {
  api: string;
  data?: unknown;
}

const encoder = new Encoder({ useBigInt64: true, ignoreUndefined: true });
const decoder = new Decoder({ useBigInt64: true });
const minimumInteger = -(1n << 63n);
const maximumInteger = (1n << 64n) - 1n;
const maximumSafeInteger = BigInt(Number.MAX_SAFE_INTEGER);

export function bytesToString(bytes: Uint8Array): string {
  const chunks: string[] = [];
  for (let offset = 0; offset < bytes.length; offset += 8192) {
    chunks.push(String.fromCharCode(...bytes.subarray(offset, offset + 8192)));
  }
  return chunks.join("");
}

export function stringToBytes(value: string): Uint8Array {
  const bytes = new Uint8Array(value.length);
  for (let index = 0; index < value.length; index++) {
    const byte = value.charCodeAt(index);
    if (byte > 255) throw new Error("Bridge strings must contain only byte-valued code units");
    bytes[index] = byte;
  }
  return bytes;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return false;
  const prototype = Object.getPrototypeOf(value);
  return prototype === Object.prototype || prototype === null;
}

function validate(value: unknown, ancestors: Set<object>, depth = 0): void {
  if (depth > 100) throw new Error("API arguments are nested too deeply");
  if (value == null || typeof value === "string" || typeof value === "boolean") return;
  if (typeof value === "number") {
    if (!Number.isFinite(value)) throw new Error("API numbers must be finite");
    return;
  }
  if (typeof value === "bigint") {
    if (value < minimumInteger || value > maximumInteger) throw new Error("Integer exceeds MessagePack's 64-bit range");
    return;
  }
  if (value instanceof Uint8Array) return;
  if (!Array.isArray(value) && !isRecord(value)) throw new Error("Unsupported API argument type");
  if (ancestors.has(value)) throw new Error("API arguments must not contain circular references");
  ancestors.add(value);
  for (const child of Object.values(value)) validate(child, ancestors, depth + 1);
  ancestors.delete(value);
}

// Keep ordinary API numbers as numbers, without rounding large SQLite integers.
function normalizeIntegers(value: unknown): unknown {
  if (typeof value === "bigint") {
    return value >= -maximumSafeInteger && value <= maximumSafeInteger ? Number(value) : value;
  }
  if (Array.isArray(value)) {
    for (let i = 0; i < value.length; i++) value[i] = normalizeIntegers(value[i]);
  } else if (isRecord(value)) {
    for (const key of Object.keys(value)) value[key] = normalizeIntegers(value[key]);
  }
  return value;
}

export function encodeRequest(request: BridgeRequest): string {
  try {
    if (!request || typeof request.api !== "string" || request.api.length === 0) throw new Error("API name is required");
    if (request.data !== undefined && !isRecord(request.data)) throw new Error("API parameters must be an object");
    validate(request, new Set());
    return bytesToString(encoder.encode(request));
  } catch (cause) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, cause instanceof Error ? cause.message : "Invalid API arguments", { api: request?.api, cause });
  }
}

export function decodeReply<T>(value: unknown, api: string): T {
  let reply: unknown;
  try {
    if (typeof value !== "string" || value.length === 0) throw new Error("Expected a MessagePack response string");
    reply = normalizeIntegers(decoder.decode(stringToBytes(value)));
    if (!isRecord(reply) || typeof reply.ok !== "boolean") throw new Error("Invalid bridge response");
    if (reply.ok) {
      if ("error" in reply) throw new Error("A successful response must not contain an error");
      return reply.data as T;
    }
    if ("data" in reply || !isRecord(reply.error) || typeof reply.error.code !== "string" || !reply.error.code || typeof reply.error.message !== "string") {
      throw new Error("Invalid bridge error");
    }
    if (reply.error.details !== undefined && !isRecord(reply.error.details)) throw new Error("Invalid bridge error details");
  } catch (cause) {
    throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "The native bridge returned an invalid response", { api, cause });
  }
  const error = (reply as { error: { code: string; message: string; details?: Record<string, unknown> } }).error;
  throw new MinipError(error.code, error.message, { api, details: error.details });
}
