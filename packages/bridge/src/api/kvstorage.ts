import jsBridge from "../bridge";

export async function getKVStorage(key: string): Promise<string | null> {
  return jsBridge.callNative<string | null>({ api: "getKVStorage", data: { key } });
}

export async function setKVStorage(key: string, value: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "setKVStorage", data: { key, value } });
}

export async function deleteKVStorage(key: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "deleteKVStorage", data: { key } });
}

export async function clearKVStorage(): Promise<void> {
  return jsBridge.callNative<void>({ api: "clearKVStorage" });
}

export function getKVStorageSync(key: string): string | null {
  return jsBridge.callNativeSync<string | null>({ api: "getKVStorage", data: { key } });
}

export function setKVStorageSync(key: string, value: string): void {
  return jsBridge.callNativeSync<void>({ api: "setKVStorage", data: { key, value } });
}

export function deleteKVStorageSync(key: string): void {
  return jsBridge.callNativeSync<void>({ api: "deleteKVStorage", data: { key } });
}

export function clearKVStorageSync(): void {
  return jsBridge.callNativeSync<void>({ api: "clearKVStorage" });
}
