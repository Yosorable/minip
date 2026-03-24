import {
  closeApp,
  navigateBack,
  navigateTo,
  openSettings,
  openWebsite,
  redirectTo,
  showAppDetail,
} from "minip-bridge";
import type { ApiCategory } from "./types";

const route: ApiCategory = {
  category: "Route",
  items: [
    {
      name: "navigate",
      exec: () => {
        navigateTo({
          page: "index.html?page=api&category=Route",
          title: String(parseInt(String(Math.random() * 100))),
        });
      },
    },
    {
      name: "navigateBack",
      exec: () => {
        navigateBack();
      },
    },
    {
      name: "redirectTo",
      exec: () => {
        redirectTo({
          page: "index.html?page=404",
          title: "Redirect to 404",
        });
      },
    },
    {
      name: "location",
      exec: (setRes) => {
        setRes(window.location.href);
      },
    },
    {
      name: "open settings",
      exec: () => {
        openSettings();
      },
    },
    {
      name: "open website",
      exec: () => {
        openWebsite("https://www.bing.com");
      },
    },
    {
      name: "show app detail",
      exec: () => {
        showAppDetail();
      },
    },
    {
      name: "close app",
      exec: () => {
        closeApp();
      },
    },
  ],
};

export default route;
