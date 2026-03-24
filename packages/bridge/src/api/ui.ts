import jsBridge from "../bridge";
import {
  AlertConfig,
  DateAndTimePickerConfig,
  MResponseWithData,
  MultipleColumnsPickerConfig,
  ShowAlertData,
  ShowHUDRequest,
  SingleColumnPickerConfig,
} from "../types";

// navigation bar

export async function setNavigationBarTitle(title: string): Promise<void> {
  await jsBridge.callNative({
    api: "setNavigationBarTitle",
    data: {
      title,
    },
  });
}

export async function setNavigationBarColor(config: {
  foregroundColor: string;
  backgroundColor: string;
}): Promise<void> {
  await jsBridge.callNative({
    api: "setNavigationBarColor",
    data: config,
  });
}

// pulldown refresh

export async function enablePullDownRefresh(): Promise<void> {
  await jsBridge.callNative({
    api: "enablePullDownRefresh",
  });
}

export async function disablePullDownRefresh(): Promise<void> {
  await jsBridge.callNative({
    api: "disablePullDownRefresh",
  });
}

export function onPullDownRefresh(callback: (e: Event) => any) {
  window.addEventListener("pulldownrefresh", callback);
}

export async function startPullDownRefresh(): Promise<void> {
  await jsBridge.callNative({
    api: "startPullDownRefresh",
  });
}

export async function stopPullDownRefresh(): Promise<void> {
  await jsBridge.callNative({
    api: "stopPullDownRefresh",
  });
}

// HUD

export async function showHUD(req: ShowHUDRequest): Promise<void> {
  await jsBridge.callNative({
    api: "showHUD",
    data: req,
  });
}

export async function hideHUD(): Promise<void> {
  await jsBridge.callNative({
    api: "hideHUD",
  });
}

// alert
export async function showAlert(config: AlertConfig): Promise<ShowAlertData> {
  const res = await jsBridge.callNative({
    api: "showAlert",
    data: config,
  });
  return (res as MResponseWithData<ShowAlertData>).data;
}

// media
export async function previewImage(
  url: string,
  options?: {
    sourceImage?: HTMLImageElement;
  },
): Promise<void> {
  const img = options?.sourceImage;
  const rect = options?.sourceImage?.getBoundingClientRect();
  if (img != null) {
    window.__minipPreviewElement = img;
  }
  await jsBridge.callNative({
    api: "previewImage",
    data: {
      url,
      rect,
    },
  });
}

export async function previewVideo(url: string): Promise<void> {
  await jsBridge.callNative({
    api: "previewVideo",
    data: {
      url,
    },
  });
}

// picker
export function showPicker(
  type: "singleColumn",
  data: SingleColumnPickerConfig,
): Promise<number | null | undefined>;
export function showPicker(
  type: "multipleColumns",
  data: MultipleColumnsPickerConfig,
): Promise<number[] | null | undefined>;
export function showPicker(
  type: "date" | "time",
  data: DateAndTimePickerConfig,
): Promise<string | null | undefined>;

export async function showPicker(
  type: "singleColumn" | "multipleColumns" | "date" | "time",
  data:
    | SingleColumnPickerConfig
    | MultipleColumnsPickerConfig
    | DateAndTimePickerConfig,
): Promise<number | number[] | string | null | undefined> {
  let callData;
  if (
    (type === "time" || type === "date") &&
    !(data as DateAndTimePickerConfig).dateFormat
  ) {
    callData = {
      type,
      data: {
        ...data,
        dateFormat: type === "date" ? "yyyy-MM-dd" : "HH:mm:ss",
      },
    };
  } else {
    callData = { type, data };
  }
  const res = await jsBridge.callNative({
    api: "showPicker",
    data: callData,
  });
  return (
    res as MResponseWithData<number | number[] | string | null | undefined>
  ).data;
}
