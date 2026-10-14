# Migrating to Minip Bridge 2

Minip Bridge 2 requires the Minip app 1.0 or later. The new SDK reports
`BRIDGE_UNAVAILABLE` when its native handler is missing. To migrate an existing
HTML project, update its SDK import to `minip-bridge@2` and rebuild any bundled
JavaScript.

<!-- LEGACY_BRIDGE_COMPAT: Remove this paragraph when retiring SDK 1.x. -->
The app temporarily also accepts SDK 1.x requests through a separate JSON adapter.
Existing mini apps can keep using their bundled SDK while they migrate. SDK 2
continues to use MessagePack exclusively. See the
[compatibility removal guide](LEGACY_COMPATIBILITY.md) for the adapter's scope and
the marked code to remove after the transition period.

For browser modules, use:

```js
import * as minip from "https://cdn.jsdelivr.net/npm/minip-bridge@2/dist/index.mjs";
```

The MessagePack codec is included in the browser bundle. No extra import map or
runtime dependency URL is required for the main SDK or filesystem entry point.

## Results and errors

Every SDK 2 native API returns its value directly. Mutations without a result return
`void`; asynchronous APIs return `Promise<T>`. There is no public response envelope,
success code, `MResponse`, `MRequest`, `isSuccess()`, or `hasData()`.

Both synchronous and asynchronous failures are `MinipError` instances. Use `code`
for program logic and `message` for diagnostics. `api` identifies the requested API;
optional `details` contains native context, such as the invalid parameter or SQLite
error code. Transport failures can also expose the original `cause`.

```ts
import { MinipError, MinipErrorCode } from "minip-bridge";
import { readFile, readFileSync } from "minip-bridge/fs";

try {
  const bytes = await readFile("notes.txt"); // Uint8Array
  const text = readFileSync("notes.txt", "utf-8"); // string
  console.log(bytes.length, text);
} catch (error) {
  if (error instanceof MinipError && error.code === MinipErrorCode.NOT_FOUND) {
    console.log("The file does not exist yet.");
  } else {
    throw error;
  }
}
```

| Code | Meaning |
| --- | --- |
| `INVALID_ARGUMENT` | Missing, unsupported, or invalid API input |
| `API_NOT_FOUND` | Unknown native API name |
| `NOT_SUPPORTED` | Operation unavailable on the requested transport |
| `NOT_FOUND` | Requested resource does not exist |
| `ALREADY_EXISTS` | Creation conflicts with an existing resource |
| `PERMISSION_DENIED` | App or system permission denied |
| `INVALID_STATE` | Closed database, invalid file descriptor, or unavailable page |
| `IO_ERROR` | Filesystem or other I/O operation failed |
| `DATABASE_ERROR` | SQLite preparation or execution failed |
| `BRIDGE_UNAVAILABLE` | Required native handler is missing |
| `BRIDGE_ERROR` | WebKit transport failed or prompt returned no response |
| `INVALID_RESPONSE` | Native reply could not be decoded or validated |
| `INTERNAL_ERROR` | Unexpected native failure |

`MinipError.code` is a string so callers can handle future native error codes.
Do not branch on message text or native numeric error codes.

## Missing values and cancellation

| API or situation | Result |
| --- | --- |
| Missing KV or memory-storage key | `null` |
| Clipboard has no text | `null` |
| Picker or QR scanner canceled | `null` |
| Alert dismissed without choosing an action | `null` |
| Alert action, including a configured cancel action | `{ action, inputs }` |
| SQLite query with no rows | `[]` |
| SQLite iterator exhausted | `null` |
| Mutation succeeded without a result | `undefined` / `void` |
| Reading a missing file | Throws `MinipError` with `NOT_FOUND` |

Empty strings and empty binary values remain distinct from `null`. `existsSync`
returns `false` only for `NOT_FOUND`; other errors still throw.

## Binary data and integers

File APIs accept and return `Uint8Array`, transmitted using MessagePack's `bin`
type. Remove manual Base64 conversions. Buffer views retain their byte offset and
length; zero-length reads and writes are supported. Pass an encoding to `readFile`
or `readFileSync` to receive decoded text.

SQLite accepts `Uint8Array` parameters as BLOBs and returns BLOB columns as
`Uint8Array`. Empty BLOBs remain binary values; SQL NULL remains `null`. Strings
containing NUL and Unicode round-trip without truncation.

Signed and unsigned 64-bit integers are supported by the bridge. Decoded integers
within JavaScript's safe range become `number`; larger values become `bigint`.
Use a `bigint` input for exact integers beyond `Number.MAX_SAFE_INTEGER`. SQLite
parameters must fit its signed 64-bit integer range. SQLite row IDs and integer
columns may therefore be `number | bigint`.

API inputs support finite numbers, 64-bit bigints, strings, booleans, `null`, plain
objects, arrays, and `Uint8Array`. Object properties set to `undefined` are omitted;
`undefined` array elements become `null`. Date instances, functions, arbitrary
class instances, cyclic values, and MessagePack extensions are unsupported.

`sqliteOpenDB(path)` now returns the numeric database handle directly. Prepared
statements are consumed by `sqliteStatementAll` or `sqliteStatementRun`, or released
when an iterator finishes. Always close databases when finished. The bundled
Kysely adapter handles iterator completion and early release.

## SDK 2 native protocol

The asynchronous handler is `MinipNativeInteractionV2`. Synchronous calls use
`window.prompt` with the same codec and API names. SDK methods retain their `Sync`
suffix; native request names do not have one.

Each packet is one MessagePack value, transported as a string with each byte mapped
to the code unit U+0000 through U+00FF. The complete request and reply use this format,
including binary fields; no JSON or Base64 wrapper remains.

```ts
// Request
{ api: "fsReadFile", data: { path: "notes.txt" } }

// Success; omit data for void, include data: null for a nullable result
{ ok: true, data: new Uint8Array([0, 128, 255]) }

// Failure
{ ok: false, error: { code: "NOT_FOUND", message: "...", details: { /* optional */ } } }
```

Swift API implementations use return values and `throws` / `async throws`.
The dispatcher encodes business failures into the error envelope. WebKit's separate
error-message channel is reserved for failures that prevent encoding a reply.
Incoming frames are validated before reaching the MessagePack decoder.

## Validation

The workspace's pnpm patch for `@msgpack/msgpack` preserves `__proto__` map keys
as ordinary own properties without changing object prototypes. Keep this patch
when rebuilding the bundled SDK; `pnpm install` applies it automatically.

From the repository root:

```sh
pnpm install
pnpm bridge:build
pnpm demo:build
pnpm lsp:build
```

Build the Minip app with `ios/minip.xcodeproj`. Check compatibility API by API
using an existing Demo mini app bundled with SDK 1.x, and check the new version
using the current Demo in `packages/demo`, built with SDK 2.
