import jsBridge from "../bridge";
import { MResponseWithData } from "../types";
import { DeviceInfo } from "../types/deviceinfo";

/**
 *
 * @param type medium as default
 */
export async function vibrate(
  type?: "light" | "medium" | "heavy",
): Promise<void> {
  await jsBridge.callNative({
    api: "vibrate",
    data: {
      type: type ?? "medium",
    },
  });
}

export async function getClipboardData(): Promise<string> {
  const res = await jsBridge.callNative({
    api: "getClipboardData",
  });
  return (res as MResponseWithData<string>).data;
}

export async function setClipboardData(data: string): Promise<void> {
  await jsBridge.callNative({
    api: "setClipboardData",
    data: {
      data,
    },
  });
}

export async function scanQRCode(): Promise<string | undefined | null> {
  const res = await jsBridge.callNative({ api: "scanQRCode" });
  return (res as MResponseWithData<string | undefined | null>).data;
}

export async function getDeviceInfo(): Promise<DeviceInfo> {
  const res = await jsBridge.callNative({ api: "getDeviceInfo" });
  return (res as MResponseWithData<DeviceInfo>).data;
}

export function getDeviceInfoSync(): DeviceInfo {
  const res = jsBridge.callNativeSync({
    api: "getDeviceInfoSync",
  }) as MResponseWithData<DeviceInfo>;
  return res.data;
}
