import {
  deleteKVStorageSync,
  enablePullDownRefresh,
  disablePullDownRefresh,
  getKVStorageSync,
  navigateTo,
  onAppPageShow,
  onAppPageHide,
  setKVStorageSync,
  startPullDownRefresh,
  stopPullDownRefresh,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const timeFormatOptions: Intl.DateTimeFormatOptions = {
  hour12: false,
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  fractionalSecondDigits: 3,
} as Intl.DateTimeFormatOptions;

function timestamp() {
  return new Date().toLocaleTimeString("en-US", timeFormatOptions);
}

const events: ApiCategory = {
  category: "Events",
  init: (setRes) => {
    const logKey = "event-log";
    const persistLog = (msg: string) => {
      try {
        const entry = `[${timestamp()}] ${msg}`;
        const prev = getKVStorageSync(logKey) ?? "";
        setKVStorageSync(logKey, prev + entry + "\n");
      } catch {
        // ignore — may fail if app is closing
      }
    };
    const log = (msg: string) => {
      setRes(`[${timestamp()}] ${msg}`);
    };
    window.addEventListener("pulldownrefresh", () => {
      log("pulldownrefresh");
      setTimeout(() => {
        stopPullDownRefresh();
      }, 2000);
    });
    onAppPageShow((e) => {
      log(`appPageShow (${e.detail.reason})`);
    });
    onAppPageHide((e) => {
      const { reason, isAppClosing } = e.detail;
      const msg = isAppClosing
        ? `appPageHide (${reason}, isAppClosing)`
        : `appPageHide (${reason})`;
      log(msg);
      persistLog(msg);
    });
  },
  items: [
    {
      name: "navigate (test events)",
      exec: () => {
        navigateTo({
          page: "index.html?page=api&category=Events",
          title: "Events",
        });
      },
    },
    {
      name: "view persist log",
      exec: (setRes) => {
        setRes("");
        try {
          const res = getKVStorageSync("event-log");
          setRes(res || "(empty)");
        } catch {
          setRes("(empty)");
        }
      },
    },
    {
      name: "clear persist log",
      exec: () => {
        deleteKVStorageSync("event-log");
      },
    },
    {
      name: "enable pulldown refresh",
      exec: () => {
        enablePullDownRefresh();
      },
    },
    {
      name: "disable pulldown refresh",
      exec: () => {
        disablePullDownRefresh();
      },
    },
    {
      name: "start pulldown refresh",
      exec: () => {
        startPullDownRefresh();
      },
    },
    {
      name: "stop pull down refresh",
      exec: () => {
        stopPullDownRefresh();
      },
    },
  ],
};

export default events;
