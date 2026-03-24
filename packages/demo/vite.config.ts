import { defineConfig } from "vite";
import solid from "vite-plugin-solid";
import minip from "./vite-plugin-minip";

export default defineConfig({
  plugins: [solid(), minip()],
  build: {
    target: "esnext",
  },
});
