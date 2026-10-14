import { readFileSync } from "node:fs";
import { defineConfig } from "tsup";

const codecLicense = readFileSync("node_modules/@msgpack/msgpack/LICENSE", "utf8").trim();

export default defineConfig({
  entry: { "minip-runtime": "src/runtime/index.ts" },
  outDir: "../../ios/minip/Resources/BridgeRuntime",
  format: ["iife"],
  outExtension: () => ({ js: ".js" }),
  target: "es2020",
  noExternal: ["@msgpack/msgpack"],
  minify: true,
  sourcemap: false,
  dts: false,
  clean: true,
  banner: {
    js: `// Generated from packages/bridge/src/runtime. Rebuild with pnpm bridge:build.\n/*! @msgpack/msgpack\n${codecLicense}\n*/`,
  },
});
