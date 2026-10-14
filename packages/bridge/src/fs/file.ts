import jsBridge from "../bridge";
import { binaryResult, fileBytes } from "./validation";
import { MinipError, MinipErrorCode } from "../bridge";

function textDecoder(encoding: string | undefined, api: string): TextDecoder | undefined {
  if (encoding === undefined) return undefined;
  try {
    return new TextDecoder(encoding);
  } catch (cause) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "Unsupported text encoding", { api, cause });
  }
}

export function readFile(path: string): Promise<Uint8Array>;
export function readFile(path: string, encoding: string): Promise<string>;
export function readFile(path: string, encoding: string | undefined): Promise<Uint8Array | string>;
export async function readFile(path: string, encoding?: string): Promise<Uint8Array | string> {
  const decoder = textDecoder(encoding, "fsReadFile");
  const bytes = binaryResult(await jsBridge.callNative<Uint8Array>({ api: "fsReadFile", data: { path } }), "fsReadFile");
  return decoder ? decoder.decode(bytes) : bytes;
}

export function readFileSync(path: string): Uint8Array;
export function readFileSync(path: string, encoding: string): string;
export function readFileSync(path: string, encoding: string | undefined): Uint8Array | string;
export function readFileSync(path: string, encoding?: string): Uint8Array | string {
  const decoder = textDecoder(encoding, "fsReadFile");
  const bytes = binaryResult(jsBridge.callNativeSync<Uint8Array>({ api: "fsReadFile", data: { path } }), "fsReadFile");
  return decoder ? decoder.decode(bytes) : bytes;
}

export async function writeFile(path: string, data: Uint8Array | string): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsWriteFile", data: { path, data: fileBytes(data, "fsWriteFile") } });
}

export async function appendFile(path: string, data: Uint8Array | string): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsAppendFile", data: { path, data: fileBytes(data, "fsAppendFile") } });
}

export async function copyFile(src: string, dest: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsCopyFile", data: { src, dest } });
}

export async function truncate(path: string, length = 0): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsTruncate", data: { path, length } });
}

export function writeFileSync(path: string, data: Uint8Array | string): void {
  return jsBridge.callNativeSync<void>({ api: "fsWriteFile", data: { path, data: fileBytes(data, "fsWriteFile") } });
}

export function appendFileSync(path: string, data: Uint8Array | string): void {
  return jsBridge.callNativeSync<void>({ api: "fsAppendFile", data: { path, data: fileBytes(data, "fsAppendFile") } });
}

export function copyFileSync(src: string, dest: string): void {
  return jsBridge.callNativeSync<void>({ api: "fsCopyFile", data: { src, dest } });
}

export function truncateSync(path: string, length = 0): void {
  return jsBridge.callNativeSync<void>({ api: "fsTruncate", data: { path, length } });
}
