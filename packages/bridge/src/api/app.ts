import jsBridge from "../bridge";
import type { AppInfo } from "../types";

export async function closeApp(): Promise<void> {
  return jsBridge.callNative<void>({ api: "closeApp" });
}

export async function showAppDetail(): Promise<void> {
  return jsBridge.callNative<void>({ api: "showAppDetail" });
}

export async function installApp(url: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "installApp", data: { url } });
}

export async function getInstalledAppList(): Promise<AppInfo[]> {
  return jsBridge.callNative<AppInfo[]>({ api: "getInstalledAppList" });
}

export async function getAppInfo(): Promise<AppInfo> {
  return jsBridge.callNative<AppInfo>({ api: "getAppInfo" });
}

export async function updateCurrentApp(url: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "updateCurrentApp", data: { url } });
}
