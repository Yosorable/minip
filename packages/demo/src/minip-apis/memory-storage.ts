import {
  clearMemoryStorage,
  getMemoryStorage,
  removeMemoryStorage,
  setMemoryStorage,
  setMemoryStorageIfNotExist,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const memoryStorage: ApiCategory = {
  category: "Memory Storage",
  items: [
    {
      name: "get memory storage",
      exec: (setRes) => {
        const start = Date.now();
        getMemoryStorage("test")
          .then((res) => {
            const elapsed = Date.now() - start;
            setRes(res + `, cost: ${elapsed} ms`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "set memory storage",
      exec: (setRes) => {
        const start = Date.now();
        setMemoryStorage("test", String(Math.random()))
          .then(() => {
            const elapsed = Date.now() - start;
            setRes(`success, cost: ${elapsed} ms`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "set memory storage if not exist",
      exec: (setRes) => {
        const start = Date.now();
        setMemoryStorageIfNotExist("test", String(Math.random()))
          .then((res) => {
            const elapsed = Date.now() - start;
            setRes(`success, cost: ${elapsed} ms, res: ${res}`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "remove memory storage",
      exec: (setRes) => {
        const start = Date.now();
        removeMemoryStorage("test")
          .then(() => {
            const elapsed = Date.now() - start;
            setRes(`success, cost: ${elapsed} ms`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "clear memory storage",
      exec: (setRes) => {
        const start = Date.now();
        clearMemoryStorage()
          .then(() => {
            const elapsed = Date.now() - start;
            setRes(`success, cost: ${elapsed} ms`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
  ],
};

export default memoryStorage;
