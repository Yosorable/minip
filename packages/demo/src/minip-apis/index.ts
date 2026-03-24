import type { ApiCategory } from "./types";
import route from "./route";
import events from "./events";
import http from "./http";
import ui from "./ui";
import media from "./media";
import kvStorage from "./kv-storage";
import memoryStorage from "./memory-storage";
import device from "./device";

const apis: ApiCategory[] = [
  route,
  events,
  http,
  ui,
  media,
  kvStorage,
  memoryStorage,
  { category: "SQLite", target: "index.html?page=SQLite" },
  device,
  { category: "MiniApp", target: "index.html?page=MiniApp" },
  { category: "FileSystem", target: "index.html?page=FileSystem" },
];

export default apis;
export type { ApiCategory, ApiItem } from "./types";
