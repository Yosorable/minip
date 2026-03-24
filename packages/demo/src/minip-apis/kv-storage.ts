import {
  clearKVStorage,
  clearKVStorageSync,
  deleteKVStorage,
  deleteKVStorageSync,
  getKVStorage,
  getKVStorageSync,
  setKVStorage,
  setKVStorageSync,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const kvStorage: ApiCategory = {
  category: "KV Storage",
  items: [
    {
      name: "set kv storage",
      exec: (setRes) => {
        const start = Date.now();
        setKVStorage("test", String(Math.random()))
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
      name: "get kv storage",
      exec: (setRes) => {
        const start = Date.now();
        getKVStorage("test")
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
      name: "delete kv storage",
      exec: (setRes) => {
        const start = Date.now();
        deleteKVStorage("test")
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
      name: "clear kv storage",
      exec: (setRes) => {
        const start = Date.now();
        clearKVStorage()
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
      name: "set kv storage sync",
      exec: (setRes) => {
        const start = Date.now();
        setKVStorageSync("test", String(Math.random()));
        const elapsed = Date.now() - start;
        setRes(`success, cost: ${elapsed} ms`);
      },
    },
    {
      name: "get kv storage sync",
      exec: (setRes) => {
        const start = Date.now();
        const res = getKVStorageSync("test");
        const elapsed = Date.now() - start;
        setRes(`success, cost: ${elapsed} ms, ${JSON.stringify(res)}`);
      },
    },
    {
      name: "delete kv storage sync",
      exec: (setRes) => {
        const start = Date.now();
        deleteKVStorageSync("test");
        const elapsed = Date.now() - start;
        setRes(`success, cost: ${elapsed} ms`);
      },
    },
    {
      name: "clear kv storage sync",
      exec: (setRes) => {
        const start = Date.now();
        clearKVStorageSync();
        const elapsed = Date.now() - start;
        setRes(`success, cost: ${elapsed} ms`);
      },
    },
  ],
};

export default kvStorage;
