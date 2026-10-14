# Temporary SDK 1.x compatibility

<!-- LEGACY_BRIDGE_COMPAT: Delete this guide when retiring the temporary adapter. -->

Minip 1.0 temporarily supports the SDK 1.x JSON protocol while mini apps migrate to
SDK 2. All compatibility code and integration points use the searchable comment
marker `LEGACY_BRIDGE_COMPAT`. Remove the adapter in a future app release after the
migration period; it has no date-based shutdown.

## Scope

- `MinipNativeInteraction` accepts old asynchronous JSON requests.
- JSON-object prompts use the old synchronous path and its original API allowlist.
- `MinipNativeInteractionV2` and MessagePack prompts serve both the app's built-in
  runtime and published SDK 2 bundles with their own codec.
- Both paths call the current `MinipApi`, including its permissions, active-app
  checks, filesystem boundaries, and database ownership checks.

The adapter handles old `Sync` suffixes, Base64 filesystem fields, numeric
`code: 0` / `code: 7` responses, and the `msg` field. It also preserves:

- `fsAccess` returning `data: true` on success;
- `sqliteOpenDB` returning `data: { dbKey }` and creating parent directories;
- missing or null SQLite binding lists defaulting to `[]`;
- iterator completion and empty clipboard results omitting `data`;
- picker/QR cancellation omitting `data` and returning `msg: "Canceled"`;
- missing KV/memory values remaining `data: null`;
- older HUD `label` / `subTitle` aliases and case-insensitive HUD type names;
- the old ping response containing the request's `data.data` string.

The old JSON protocol retains its JavaScript number precision limits. Exact
64-bit integers and typed SQLite BLOB results require SDK 2. Malformed requests
receive a legacy error envelope; the adapter does not restore unsafe decoding,
missing permission checks, or requests that never completed.

## Manual verification

Use an existing Demo mini app bundled with SDK 1.x to check compatibility API by
API. Use the current Demo in `packages/demo`, built with SDK 2, to check the new
protocol and API behavior.

## Removal checklist

Locate every integration point from the repository root:

```sh
rg -n LEGACY_BRIDGE_COMPAT ios packages/bridge README.md
```

1. Delete `ios/minip/Bridge/LegacyBridgeAdapter.swift` and
   `ios/minip/MWebView/LegacyNativeInteraction.swift`.
2. Remove the marked handler registration in `MWebViewPool.swift` and the marked
   early JSON branch in `PromptSyncCallApi.swift`. Keep the V2 handler and codec.
3. Remove the marked migration/README paragraphs, this guide, and its entry in the
   package's `files` list. Rebuild and verify the SDK 2 Demo.
