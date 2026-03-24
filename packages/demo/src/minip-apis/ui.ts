import {
  setNavigationBarColor,
  setNavigationBarTitle,
  showAlert,
  showHUD,
  showPicker,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const ui: ApiCategory = {
  category: "UI",
  items: [
    {
      name: "HUD",
      exec: () => {
        showHUD({
          type: "success",
          title: "success",
        });
      },
    },
    {
      name: "default alert",
      exec: (setRes) => {
        showAlert({
          title: "default alert",
          message: "message",
          preferredStyle: "alert",
          actions: [
            { title: "ok", key: "ok" },
            { title: "destructive", key: "destructive", style: "destructive" },
            { title: "cancel", key: "cancel", style: "cancel" },
          ],
        })
          .then((res) => {
            setRes(`selected ${JSON.stringify(res)}`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "action sheet alert",
      exec: (setRes) => {
        showAlert({
          title: "actionSheet",
          message: "message",
          preferredStyle: "actionSheet",
          actions: [
            { title: "ok", key: "ok" },
            { title: "destructive", key: "destructive", style: "destructive" },
            { title: "cancel", key: "cancel", style: "cancel" },
          ],
        })
          .then((res) => {
            setRes(`selected ${JSON.stringify(res)}`);
          })
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
    {
      name: "set navigation bar title",
      exec: (setRes) => {
        setNavigationBarTitle(Math.random().toString())
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
      name: "set navigation bar color",
      exec: (setRes) => {
        setNavigationBarColor({
          foregroundColor: "#F8F8F2",
          backgroundColor: "#663399",
        })
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
      name: "picker (single column)",
      exec: (setRes) => {
        const column = ["\u{1F34E}", "\u{1F95D}", "\u{1F353}", "\u{1F348}", "\u{1F351}"];
        showPicker("singleColumn", {
          column,
          index: 0,
        })
          .then((res) => {
            if (res != null) {
              setRes(`selected ${column[res]}, res: ${res}`);
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
      name: "picker (multiple columns)",
      exec: (setRes) => {
        const columns = [
          ["\u{1F34E}", "\u{1F95D}", "\u{1F353}"],
          ["\u{1F348}", "\u{1F351}"],
        ];
        showPicker("multipleColumns", {
          columns,
          index: [0, 1],
        })
          .then((res) => {
            if (res != null) {
              let msg = "";
              for (let index = 0; index < res.length; index++) {
                const i = res[index];
                msg += columns[index][i];
              }
              setRes(`selected ${msg}`);
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
      name: "picker (date)",
      exec: (setRes) => {
        showPicker("date", {
          dateFormat: "yyyy-MM-dd",
        })
          .then((res) => {
            if (res != null) {
              setRes(`selected ${res}`);
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
      name: "picker (time)",
      exec: (setRes) => {
        showPicker("time", {
          dateFormat: "HH:mm",
        })
          .then((res) => {
            if (res != null) {
              setRes(`selected ${res}`);
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
  ],
};

export default ui;
