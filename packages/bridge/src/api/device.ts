import jsBridge from "../bridge";
import type { DeviceInfo } from "../types";

export async function vibrate(type: "light" | "medium" | "heavy" = "medium"): Promise<void> {
  return jsBridge.callNative<void>({ api: "vibrate", data: { type } });
}

export async function getClipboardData(): Promise<string | null> {
  return jsBridge.callNative<string | null>({ api: "getClipboardData" });
}

export async function setClipboardData(data: string): Promise<void> {
  return jsBridge.callNative<void>({ api: "setClipboardData", data: { data } });
}

export async function scanQRCode(): Promise<string | null> {
  return jsBridge.callNative<string | null>({ api: "scanQRCode" });
}

export async function getDeviceInfo(): Promise<DeviceInfo> {
  return jsBridge.callNative<DeviceInfo>({ api: "getDeviceInfo" });
}

export function getDeviceInfoSync(): DeviceInfo {
  return jsBridge.callNativeSync<DeviceInfo>({ api: "getDeviceInfo" });
}
