import jsBridge from "../bridge";
import { MResponseWithData } from "../types";

export async function getMemoryStorage(key: string): Promise<string> {
  const res = await jsBridge.callNative({
    api: "getMemoryStorage",
    data: { key },
  });
  return (res as MResponseWithData<string>).data;
}

export async function setMemoryStorage(
  key: string,
  value: string,
): Promise<void> {
  await jsBridge.callNative({
    api: "setMemoryStorage",
    data: { key, value },
  });
}

export async function setMemoryStorageIfNotExist(
  key: string,
  value: string,
): Promise<boolean> {
  const res = await jsBridge.callNative({
    api: "setMemoryStorageIfNotExist",
    data: { key, value },
  });
  return (res as MResponseWithData<boolean>).data;
}

export async function removeMemoryStorage(key: string): Promise<void> {
  await jsBridge.callNative({
    api: "removeMemoryStorage",
    data: { key },
  });
}

export async function clearMemoryStorage(): Promise<void> {
  await jsBridge.callNative({
    api: "clearMemoryStorage",
  });
}
