import jsBridge from "../bridge";
import { MinipError, MinipErrorCode } from "../bridge";
import type { FileStats } from "../types/filestats";
import { enrichStats } from "./common";
import { binaryResult, bufferRange } from "./validation";

export enum OpenFlags {
  O_RDONLY = 0,
  O_WRONLY = 1,
  O_RDWR = 2,
  O_CREAT = 64,
  O_EXCL = 128,
  O_TRUNC = 512,
  O_APPEND = 1024,
}

export async function open(path: string, flags: OpenFlags | number, mode?: number): Promise<number> {
  return jsBridge.callNative<number>({ api: "fsOpen", data: { path, flags, mode } });
}

export async function close(fd: number): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsClose", data: { fd } });
}

export async function fstat(fd: number): Promise<FileStats> {
  return enrichStats(await jsBridge.callNative<FileStats>({ api: "fsFstat", data: { fd } }));
}

export async function ftruncate(fd: number, length = 0): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsFtruncate", data: { fd, length } });
}

export async function read(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): Promise<number> {
  bufferRange(buffer, offset, length, "fsRead");
  const bytes = binaryResult(await jsBridge.callNative<Uint8Array>({ api: "fsRead", data: { fd, length, position } }), "fsRead");
  if (bytes.byteLength > length) throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Read returned more bytes than requested", { api: "fsRead" });
  buffer.set(bytes, offset);
  return bytes.byteLength;
}

export async function write(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): Promise<number> {
  const data = bufferRange(buffer, offset, length, "fsWrite");
  return jsBridge.callNative<number>({ api: "fsWrite", data: { fd, data, position } });
}

export function openSync(path: string, flags: OpenFlags | number, mode?: number): number {
  return jsBridge.callNativeSync<number>({ api: "fsOpen", data: { path, flags, mode } });
}

export function closeSync(fd: number): void {
  return jsBridge.callNativeSync<void>({ api: "fsClose", data: { fd } });
}

export function fstatSync(fd: number): FileStats {
  return enrichStats(jsBridge.callNativeSync<FileStats>({ api: "fsFstat", data: { fd } }));
}

export function ftruncateSync(fd: number, length = 0): void {
  return jsBridge.callNativeSync<void>({ api: "fsFtruncate", data: { fd, length } });
}

export function readSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): number {
  bufferRange(buffer, offset, length, "fsRead");
  const bytes = binaryResult(jsBridge.callNativeSync<Uint8Array>({ api: "fsRead", data: { fd, length, position } }), "fsRead");
  if (bytes.byteLength > length) throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Read returned more bytes than requested", { api: "fsRead" });
  buffer.set(bytes, offset);
  return bytes.byteLength;
}

export function writeSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): number {
  const data = bufferRange(buffer, offset, length, "fsWrite");
  return jsBridge.callNativeSync<number>({ api: "fsWrite", data: { fd, data, position } });
}
