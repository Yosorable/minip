import {
  getClipboardData,
  getDeviceInfo,
  getDeviceInfoSync,
  scanQRCode,
  setClipboardData,
  vibrate,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const device: ApiCategory = {
  category: "Device",
  items: [
    {
      name: "get clipboard data",
      exec: (setRes) => {
        getClipboardData()
          .then((res) => setRes(res))
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "set clipboard data",
      exec: (setRes) => {
        setClipboardData(Math.random().toString())
          .then(() => setRes("success"))
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "vibrate",
      exec: (setRes) => {
        const types = ["light", "medium", "heavy"] as const;
        const type = types[Math.floor(Math.random() * 3)];
        setRes(type);
        vibrate(type);
      },
    },
    {
      name: "scan qrcode",
      exec: (setRes) => {
        scanQRCode()
          .then((res) => {
            if (res !== null && res !== undefined) {
              setRes(res);
            } else {
              setRes("canceled");
            }
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "get device info",
      exec: (setRes) => {
        getDeviceInfo()
          .then((res) => {
            setRes(JSON.stringify(res));
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "get device info sync",
      exec: (setRes) => {
        const res = getDeviceInfoSync();
        setRes(JSON.stringify(res));
      },
    },
  ],
};

export default device;
