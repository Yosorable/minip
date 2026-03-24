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
} from "./chunk-4HUUDNXW.mjs";
import {
  bridge_default
} from "./chunk-GXHJCCLG.mjs";

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
  await bridge_default.callNative({
    api: "closeApp"
  });
}
async function showAppDetail() {
  await bridge_default.callNative({
    api: "showAppDetail"
  });
}
async function installApp(url) {
  await bridge_default.callNative({
    api: "installApp",
    data: {
      url
    }
  });
}
async function getInstalledAppList() {
  const res = await bridge_default.callNative({
    api: "getInstalledAppList"
  });
  return res.data;
}
async function getAppInfo() {
  const res = await bridge_default.callNative({
    api: "getAppInfo"
  });
  return res.data;
}
async function updateCurrentApp(url) {
  await bridge_default.callNative({
    api: "updateCurrentApp",
    data: {
      url
    }
  });
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
  const res = await bridge_default.callNative({
    api: "showAlert",
    data: config
  });
  return res.data;
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
      rect
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
  const res = await bridge_default.callNative({
    api: "showPicker",
    data: callData
  });
  return res.data;
}

// src/api/kvstorage.ts
async function getKVStorage(key) {
  const res = await bridge_default.callNative({
    api: "getKVStorage",
    data: { key }
  });
  return res.data;
}
async function setKVStorage(key, value) {
  await bridge_default.callNative({
    api: "setKVStorage",
    data: { key, value }
  });
}
async function deleteKVStorage(key) {
  await bridge_default.callNative({
    api: "deleteKVStorage",
    data: { key }
  });
}
async function clearKVStorage() {
  await bridge_default.callNative({
    api: "clearKVStorage"
  });
}
function getKVStorageSync(key) {
  const res = bridge_default.callNativeSync({
    api: "getKVStorageSync",
    data: { key }
  });
  return res.data;
}
function setKVStorageSync(key, value) {
  bridge_default.callNativeSync({
    api: "setKVStorageSync",
    data: { key, value }
  });
}
function deleteKVStorageSync(key) {
  bridge_default.callNativeSync({
    api: "deleteKVStorageSync",
    data: { key }
  });
}
function clearKVStorageSync() {
  bridge_default.callNativeSync({
    api: "clearKVStorageSync"
  });
}

// src/api/device.ts
async function vibrate(type) {
  await bridge_default.callNative({
    api: "vibrate",
    data: {
      type: type ?? "medium"
    }
  });
}
async function getClipboardData() {
  const res = await bridge_default.callNative({
    api: "getClipboardData"
  });
  return res.data;
}
async function setClipboardData(data) {
  await bridge_default.callNative({
    api: "setClipboardData",
    data: {
      data
    }
  });
}
async function scanQRCode() {
  const res = await bridge_default.callNative({ api: "scanQRCode" });
  return res.data;
}
async function getDeviceInfo() {
  const res = await bridge_default.callNative({ api: "getDeviceInfo" });
  return res.data;
}
function getDeviceInfoSync() {
  const res = bridge_default.callNativeSync({
    api: "getDeviceInfoSync"
  });
  return res.data;
}

// src/api/memory-cache.ts
async function getMemoryStorage(key) {
  const res = await bridge_default.callNative({
    api: "getMemoryStorage",
    data: { key }
  });
  return res.data;
}
async function setMemoryStorage(key, value) {
  await bridge_default.callNative({
    api: "setMemoryStorage",
    data: { key, value }
  });
}
async function setMemoryStorageIfNotExist(key, value) {
  const res = await bridge_default.callNative({
    api: "setMemoryStorageIfNotExist",
    data: { key, value }
  });
  return res.data;
}
async function removeMemoryStorage(key) {
  await bridge_default.callNative({
    api: "removeMemoryStorage",
    data: { key }
  });
}
async function clearMemoryStorage() {
  await bridge_default.callNative({
    api: "clearMemoryStorage"
  });
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