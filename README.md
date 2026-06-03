# Minip

**MinipRuntime** is an embeddable iOS library that lets your app run web (HTML / CSS / JS) *mini apps* with a native-app-like experience. Each mini app runs in a managed `WKWebView` and talks to native features through a small JavaScript bridge.

Drop the Swift package into any iOS app, point it at a mini app package, and open it — no build toolchain or server of your own required.

## Requirements

- iOS 16+
- Swift 5.10+ / Xcode 16+

## Installation (Swift Package Manager)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Yosorable/minip.git", branch: "main"),
],
targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "MinipRuntime", package: "minip"),
    ]),
]
```

Or in Xcode: **File ▸ Add Package Dependencies…** and add the repo, then link the **MinipRuntime** product.

## Host integration

The entire host-facing API lives on the `MiniAppManager` facade plus the `AppInfo` value type and the `InstallMiniApp` function.

```swift
import MinipRuntime

// 1) Install a mini app package (a .zip with app.json + assets at its root)
//    into the runtime's store. Idempotent — re-installing overwrites.
InstallMiniApp(
    pkgFile: bundledZipURL,
    onSuccess: { openFirstMiniApp() },
    onFailed: { message in print("install failed: \(message)") }
)

// 2) List installed mini apps.
let apps = MiniAppManager.shared.getAppInfos()   // [AppInfo]

// 3) Open one — it is presented over `parent`.
func openFirstMiniApp() {
    guard let app = MiniAppManager.shared.getAppInfos().first,
          let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.keyWindow?.rootViewController else { return }
    MiniAppManager.shared.openMiniApp(parent: root, appInfo: app)
}
```

That's the whole happy path. See `ios/minip-demo` for a complete, runnable SwiftUI example.

### Configuration

```swift
// Where mini app data is stored. Defaults to <App>/Library/minip — kept out of
// Documents so it never shows up in the host's Files sharing / iCloud backups.
// Set this BEFORE opening or installing any mini app.
MiniAppManager.shared.miniAppsRootURL = myCustomURL

// Enable the Safari Web Inspector for mini app WebViews (debug builds).
MiniAppManager.shared.webViewInspectable = true

// Lift the WKWebView 60fps cap (high refresh rate). Default: true.
MiniAppManager.shared.enableWebView120FPS = true

// Optional: pre-warm a pooled WebView at an idle moment so the first
// open is faster. No-op once warmed; the pool also warms lazily.
MiniAppManager.shared.prewarmWebView()
```

### Deep links (host's responsibility)

The library does **not** own a URL scheme. If you want `myapp://…` deep links into a
mini app, register your scheme in `Info.plist`, handle the incoming URL in your
scene/app delegate, and call `getAppInfos()` + `openMiniApp(…)` (or `InstallMiniApp`)
yourself.

## What is a mini app?

A mini app is just a folder containing an `app.json` manifest and your web assets
(`index.html`, JS, CSS, images, …). A package is that folder zipped (with `app.json`
at the root). Minimal example:

```
my-miniapp/
├── app.json
└── index.html
```

```jsonc
// app.json (key fields)
{
  "name": "my-miniapp",          // unique folder name in the store
  "appId": "…uuid…",
  "displayName": "My Mini App",
  "homepage": "index.html",
  "navigationBarStatus": "display",  // or "hidden"
  "tabs": [                          // optional bottom tab bar
    { "path": "index.html", "title": "Home", "systemImage": "house" }
  ],
  "colorScheme": "auto",         // auto | light | dark
  "tintColor": "#5756CE",        // hex or CSS color name
  "webServerEnabled": false,     // see below
  "orientation": "all"           // all | portrait | landscape
}
```

### How pages are served

- **Default (custom scheme):** files are served to the `WKWebView` via a custom
  URL scheme handler — no server, works offline.
- **`webServerEnabled: true`:** the runtime starts a local HTTP server
  (`127.0.0.1`) and serves the mini app over a real `http://` origin. Use this for
  traditional web apps that cannot run from a `file://`-style origin (apps that rely
  on a real origin, absolute URLs, same-origin requests, secure context, etc.).

## Building a mini app (JavaScript)

Develop with any standard web stack (e.g. Vite + your framework) and produce static
HTML/JS — there's no on-device build step. Use the bridge SDK to reach native
features:

```bash
npm i minip-bridge
```

```javascript
import { navigateTo } from "minip-bridge";
navigateTo({ page: "settings.html", title: "Settings" });
```

The bridge exposes routing, UI, device info, media, KV storage, SQLite, and more.
See `packages/bridge` ([npm](https://www.npmjs.com/package/minip-bridge)) and the
`packages/demo` sample.

## Repository structure

```
minip/
├── Package.swift            # MinipRuntime (the embeddable Swift library)
├── ios/
│   ├── Sources/MinipRuntime # runtime source
│   └── minip-demo           # runnable SwiftUI demo host app
├── packages/
│   ├── bridge               # JS bridge SDK (npm: minip-bridge)
│   └── demo                 # sample mini app
└── android/                 # (reserved for a future Android runtime)
```

> Note: the Swift package manifest lives at the repo root (SwiftPM requires it
> there); the actual iOS sources are under `ios/`.

## Demo

Open `ios/minip-demo/minip-demo.xcodeproj` in Xcode and run. It bundles a sample
mini app (`packages/demo`) and opens it through `MinipRuntime` with a single button.

## Dependencies

Kept intentionally small; each provides a capability the platform doesn't give for free:

| Package | Purpose |
| --- | --- |
| [FlyingFox](https://github.com/swhitty/FlyingFox) | Local HTTP server for `webServerEnabled` mini apps |
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | Unzip mini app packages |
| [Kingfisher](https://github.com/onevcat/Kingfisher) | Image loading & caching |
| ProgressHUD | Lightweight progress / status HUD |

Key-value storage and the `sqlite` bridge API are backed by the system SQLite
(`libsqlite3`) — no extra dependency.

## License

MIT. See [LICENSE](LICENSE).
