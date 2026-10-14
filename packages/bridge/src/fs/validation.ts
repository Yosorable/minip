import { MinipError, MinipErrorCode } from "../bridge";

export function bufferRange(buffer: Uint8Array, offset: number, length: number, api: string): Uint8Array {
  if (!(buffer instanceof Uint8Array) || !Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 || length < 0 || offset > buffer.byteLength || length > buffer.byteLength - offset) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "Buffer offset and length must describe a valid byte range", { api });
  }
  return buffer.subarray(offset, offset + length);
}

export function binaryResult(value: unknown, api: string): Uint8Array {
  if (!(value instanceof Uint8Array)) {
    throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Expected a binary file result", { api });
  }
  return value;
}

export function fileBytes(value: Uint8Array | string, api: string): Uint8Array {
  if (typeof value === "string") return new TextEncoder().encode(value);
  if (value instanceof Uint8Array) return value;
  throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "File data must be a string or Uint8Array", { api });
}
