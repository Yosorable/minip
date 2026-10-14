import {
  sqliteCloseDB,
  sqliteCreateIterator,
  sqliteExecute,
  sqliteIteratorNext,
  sqliteIteratorRelease,
  sqliteOpenDB,
  sqlitePrepare,
  sqliteStatementAll,
  sqliteStatementRun
} from "./chunk-NHXKN5R3.mjs";
import {
  MinipError,
  MinipErrorCode,
  bridge_default
} from "./chunk-TZQ7ME6J.mjs";

// src/api/route.ts
async function navigateTo(data) {
  await bridge_default.callNative({
    api: "navigateTo",
    data
  });
}
async function navigateBack(delta = 1) {
  await bridge_default.callNative({
    api: "navigateBack",
    data: {
      delta
    }
  });
}
async function redirectTo(data) {
  await bridge_default.callNative({
    api: "redirectTo",
    data
  });
}
async function openWebsite(url) {
  await bridge_default.callNative({
    api: "openWebsite",
    data: { url }
  });
}
async function openSettings() {
  await bridge_default.callNative({
    api: "openSettings"
  });
}

// src/api/app.ts
async function closeApp() {
  return bridge_default.callNative({ api: "closeApp" });
}
async function showAppDetail() {
  return bridge_default.callNative({ api: "showAppDetail" });
}
async function installApp(url) {
  return bridge_default.callNative({ api: "installApp", data: { url } });
}
async function getInstalledAppList() {
  return bridge_default.callNative({ api: "getInstalledAppList" });
}
async function getAppInfo() {
  return bridge_default.callNative({ api: "getAppInfo" });
}
async function updateCurrentApp(url) {
  return bridge_default.callNative({ api: "updateCurrentApp", data: { url } });
}

// src/api/ui.ts
async function setNavigationBarTitle(title) {
  await bridge_default.callNative({
    api: "setNavigationBarTitle",
    data: {
      title
    }
  });
}
async function setNavigationBarColor(config) {
  await bridge_default.callNative({
    api: "setNavigationBarColor",
    data: config
  });
}
async function enablePullDownRefresh() {
  await bridge_default.callNative({
    api: "enablePullDownRefresh"
  });
}
async function disablePullDownRefresh() {
  await bridge_default.callNative({
    api: "disablePullDownRefresh"
  });
}
function onPullDownRefresh(callback) {
  window.addEventListener("pulldownrefresh", callback);
}
async function startPullDownRefresh() {
  await bridge_default.callNative({
    api: "startPullDownRefresh"
  });
}
async function stopPullDownRefresh() {
  await bridge_default.callNative({
    api: "stopPullDownRefresh"
  });
}
async function showHUD(req) {
  await bridge_default.callNative({
    api: "showHUD",
    data: req
  });
}
async function hideHUD() {
  await bridge_default.callNative({
    api: "hideHUD"
  });
}
async function showAlert(config) {
  return bridge_default.callNative({
    api: "showAlert",
    data: config
  });
}
async function previewImage(url, options) {
  const img = options?.sourceImage;
  const rect = options?.sourceImage?.getBoundingClientRect();
  if (img != null) {
    window.__minipPreviewElement = img;
  }
  await bridge_default.callNative({
    api: "previewImage",
    data: {
      url,
      rect: rect ? { x: rect.x, y: rect.y, width: rect.width, height: rect.height } : void 0
    }
  });
}
async function previewVideo(url) {
  await bridge_default.callNative({
    api: "previewVideo",
    data: {
      url
    }
  });
}
async function showPicker(type, data) {
  if (data === null || typeof data !== "object" || Object.getPrototypeOf(data) !== Object.prototype && Object.getPrototypeOf(data) !== null) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "Picker data must be an object", { api: "showPicker" });
  }
  let callData;
  if ((type === "time" || type === "date") && !data.dateFormat) {
    callData = {
      type,
      data: {
        ...data,
        dateFormat: type === "date" ? "yyyy-MM-dd" : "HH:mm:ss"
      }
    };
  } else {
    callData = { type, data };
  }
  return bridge_default.callNative({
    api: "showPicker",
    data: callData
  });
}

// src/api/kvstorage.ts
async function getKVStorage(key) {
  return bridge_default.callNative({ api: "getKVStorage", data: { key } });
}
async function setKVStorage(key, value) {
  return bridge_default.callNative({ api: "setKVStorage", data: { key, value } });
}
async function deleteKVStorage(key) {
  return bridge_default.callNative({ api: "deleteKVStorage", data: { key } });
}
async function clearKVStorage() {
  return bridge_default.callNative({ api: "clearKVStorage" });
}
function getKVStorageSync(key) {
  return bridge_default.callNativeSync({ api: "getKVStorage", data: { key } });
}
function setKVStorageSync(key, value) {
  return bridge_default.callNativeSync({ api: "setKVStorage", data: { key, value } });
}
function deleteKVStorageSync(key) {
  return bridge_default.callNativeSync({ api: "deleteKVStorage", data: { key } });
}
function clearKVStorageSync() {
  return bridge_default.callNativeSync({ api: "clearKVStorage" });
}

// src/api/device.ts
async function vibrate(type = "medium") {
  return bridge_default.callNative({ api: "vibrate", data: { type } });
}
async function getClipboardData() {
  return bridge_default.callNative({ api: "getClipboardData" });
}
async function setClipboardData(data) {
  return bridge_default.callNative({ api: "setClipboardData", data: { data } });
}
async function scanQRCode() {
  return bridge_default.callNative({ api: "scanQRCode" });
}
async function getDeviceInfo() {
  return bridge_default.callNative({ api: "getDeviceInfo" });
}
function getDeviceInfoSync() {
  return bridge_default.callNativeSync({ api: "getDeviceInfo" });
}

// src/api/memory-cache.ts
async function getMemoryStorage(key) {
  return bridge_default.callNative({ api: "getMemoryStorage", data: { key } });
}
async function setMemoryStorage(key, value) {
  return bridge_default.callNative({ api: "setMemoryStorage", data: { key, value } });
}
async function setMemoryStorageIfNotExist(key, value) {
  return bridge_default.callNative({ api: "setMemoryStorageIfNotExist", data: { key, value } });
}
async function removeMemoryStorage(key) {
  return bridge_default.callNative({ api: "removeMemoryStorage", data: { key } });
}
async function clearMemoryStorage() {
  return bridge_default.callNative({ api: "clearMemoryStorage" });
}

// src/api/events.ts
function onAppPageShow(callback) {
  const handler = callback;
  window.addEventListener("appPageShow", handler);
  return () => window.removeEventListener("appPageShow", handler);
}
function onAppPageHide(callback) {
  const handler = callback;
  window.addEventListener("appPageHide", handler);
  return () => window.removeEventListener("appPageHide", handler);
}
export {
  MinipError,
  MinipErrorCode,
  clearKVStorage,
  clearKVStorageSync,
  clearMemoryStorage,
  closeApp,
  deleteKVStorage,
  deleteKVStorageSync,
  disablePullDownRefresh,
  enablePullDownRefresh,
  getAppInfo,
  getClipboardData,
  getDeviceInfo,
  getDeviceInfoSync,
  getInstalledAppList,
  getKVStorage,
  getKVStorageSync,
  getMemoryStorage,
  hideHUD,
  installApp,
  navigateBack,
  navigateTo,
  onAppPageHide,
  onAppPageShow,
  onPullDownRefresh,
  openSettings,
  openWebsite,
  previewImage,
  previewVideo,
  redirectTo,
  removeMemoryStorage,
  scanQRCode,
  setClipboardData,
  setKVStorage,
  setKVStorageSync,
  setMemoryStorage,
  setMemoryStorageIfNotExist,
  setNavigationBarColor,
  setNavigationBarTitle,
  showAlert,
  showAppDetail,
  showHUD,
  showPicker,
  sqliteCloseDB,
  sqliteCreateIterator,
  sqliteExecute,
  sqliteIteratorNext,
  sqliteIteratorRelease,
  sqliteOpenDB,
  sqlitePrepare,
  sqliteStatementAll,
  sqliteStatementRun,
  startPullDownRefresh,
  stopPullDownRefresh,
  updateCurrentApp,
  vibrate
};
//# sourceMappingURL=index.mjs.map