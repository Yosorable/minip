import jsBridge from "../bridge";

export async function getMemoryStorage(key: string): Promise<string | null> {
  return jsBridge.callNative<string | null>({ api: "getMemoryStorage", data: { key } });
}

export async function setMemoryStorage(key: string, value: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "setMemoryStorage", data: { key, value } });
}

export async function setMemoryStorageIfNotExist(key: string, value: string): Promise<boolean> {
  return jsBridge.callNative<boolean>({ api: "setMemoryStorageIfNotExist", data: { key, value } });
}

export async function removeMemoryStorage(key: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "removeMemoryStorage", data: { key } });
}

export async function clearMemoryStorage(): Promise<void> {
  return jsBridge.callNative<void>({ api: "clearMemoryStorage" });
}
