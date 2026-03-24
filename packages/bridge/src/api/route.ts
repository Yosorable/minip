import jsBridge from "../bridge";

export async function navigateTo(data: {
  page: string;
  title?: string;
}): Promise<void> {
  await jsBridge.callNative({
    api: "navigateTo",
    data: data,
  });
}

export async function navigateBack(delta: number = 1): Promise<void> {
  await jsBridge.callNative({
    api: "navigateBack",
    data: {
      delta,
    },
  });
}

export async function redirectTo(data: {
  page: string;
  title?: string;
}): Promise<void> {
  await jsBridge.callNative({
    api: "redirectTo",
    data: data,
  });
}

export async function openWebsite(url: string): Promise<void> {
  await jsBridge.callNative({
    api: "openWebsite",
    data: { url },
  });
}

export async function openSettings(): Promise<void> {
  await jsBridge.callNative({
    api: "openSettings",
  });
}
