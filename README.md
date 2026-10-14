# Minip

Minip is an app that allows you to run frontend applications on your phone, giving them a native app-like experience. You can interact with native features via a JavaScript bridge.

<a href="https://apps.apple.com/us/app/minip-editor/id6463115915" target="_blank"><img width="150" alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"/></a>

## Project Structure

- `ios/` — iOS app
- `packages/bridge/` — JavaScript SDK and the app's injected bridge runtime ([npm](https://www.npmjs.com/package/minip-bridge))
- `packages/demo/` — Demo mini app
- `packages/language-service-bundler/` — Language service for code editor

## Demo

Scan this QR code using the Minip App to install the demo:

![](assets/qrcode.jpg)

### Screenshots

|                                |                                |                                |
| ------------------------------ | ------------------------------ | ------------------------------ |
| ![](assets/screenshots/01.PNG) | ![](assets/screenshots/02.PNG) | ![](assets/screenshots/03.PNG) |

## Minip Bridge Quick Start

Install the bridge SDK:

```bash
npm i minip-bridge
```

```javascript
import { navigateTo } from "minip-bridge";
navigateTo({ page: "index.html", title: "title" });
```

This SDK build requires the app's built-in bridge runtime (contract version 1).
The runtime handles MessagePack encoding and native transport; the SDK provides
the public APIs, parameter handling, and TypeScript types. APIs return values
directly and throw `MinipError` for failures. Previously published SDKs with their
own MessagePack codec continue to work with the updated app.

Pages can also call native APIs without importing the SDK:

```javascript
window.__minipRuntime.invoke({
  api: "setKVStorage",
  data: { key: "theme", value: "dark" },
}).then(() => {
  const theme = window.__minipRuntime.invokeSync({
    api: "getKVStorage",
    data: { key: "theme" },
  });
  console.log(theme);
}).catch(error => console.error(error.code, error.message));
```

Raw calls use native API names and parameter objects. The app encodes requests and
decodes results, including `Uint8Array` and 64-bit integers. SDK-specific argument
defaults and convenience wrappers do not apply to raw calls.

<!-- LEGACY_BRIDGE_COMPAT: Remove this paragraph when retiring SDK 1.x. -->
Minip 1.0 temporarily accepts the SDK 1.x JSON bridge so existing mini apps can
continue running during migration. New projects should use SDK 2. See the
[compatibility removal guide](packages/bridge/LEGACY_COMPATIBILITY.md).

See the [Bridge 2 migration guide](packages/bridge/MIGRATION.md) for error handling,
the runtime contract, binary data, nullable results, and validation commands.
