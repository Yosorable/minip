import jsBridge from "../bridge";
import { MResponseWithData } from "../types";

// async methods

export async function getKVStorage(key: string): Promise<string> {
  const res = await jsBridge.callNative({
    api: "getKVStorage",
    data: { key },
  });
  return (res as MResponseWithData<string>).data;
}

export async function setKVStorage(key: string, value: string): Promise<void> {
  await jsBridge.callNative({
    api: "setKVStorage",
    data: { key, value },
  });
}

export async function deleteKVStorage(key: string): Promise<void> {
  await jsBridge.callNative({
    api: "deleteKVStorage",
    data: { key },
  });
}

export async function clearKVStorage(): Promise<void> {
  await jsBridge.callNative({
    api: "clearKVStorage",
  });
}

// sync methods

export function getKVStorageSync(key: string): string {
  const res = jsBridge.callNativeSync({
    api: "getKVStorageSync",
    data: { key },
  }) as MResponseWithData<string>;
  return res.data;
}

export function setKVStorageSync(key: string, value: string): void {
  jsBridge.callNativeSync({
    api: "setKVStorageSync",
    data: { key, value },
  });
}

export function deleteKVStorageSync(key: string): void {
  jsBridge.callNativeSync({
    api: "deleteKVStorageSync",
    data: { key },
  });
}

export function clearKVStorageSync(): void {
  jsBridge.callNativeSync({
    api: "clearKVStorageSync",
  });
}
