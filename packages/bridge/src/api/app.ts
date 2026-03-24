import jsBridge from "../bridge";
import { AppInfo, MResponseWithData } from "../types";

export async function closeApp(): Promise<void> {
  await jsBridge.callNative({
    api: "closeApp",
  });
}

export async function showAppDetail(): Promise<void> {
  await jsBridge.callNative({
    api: "showAppDetail",
  });
}

export async function installApp(url: string): Promise<void> {
  await jsBridge.callNative({
    api: "installApp",
    data: {
      url,
    },
  });
}

export async function getInstalledAppList(): Promise<AppInfo[]> {
  const res = await jsBridge.callNative({
    api: "getInstalledAppList",
  });
  return (res as MResponseWithData<AppInfo[]>).data;
}

export async function getAppInfo(): Promise<AppInfo> {
  const res = await jsBridge.callNative({
    api: "getAppInfo",
  });
  return (res as MResponseWithData<AppInfo>).data;
}

export async function updateCurrentApp(url: string): Promise<void> {
  await jsBridge.callNative({
    api: "updateCurrentApp",
    data: {
      url,
    },
  });
}
