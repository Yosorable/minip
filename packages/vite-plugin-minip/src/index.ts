import { randomUUID } from "node:crypto";
import { createReadStream, createWriteStream, type ReadStream } from "node:fs";
import { lstat, readFile, readdir, rename, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { finished, pipeline } from "node:stream/promises";
import { renderUnicodeCompact } from "uqr";
import type { Plugin, ResolvedConfig, UserConfig } from "vite";
import { ZipFile } from "yazl";

export interface MinipPluginOptions {
  /** Manifest path relative to the Vite project root. Defaults to app.json. */
  manifest?: string;
  /** Print development and installation QR codes. Defaults to true. */
  qrCode?: boolean;
}

interface Manifest extends Record<string, unknown> {
  appId: string;
  name: string;
  homepage: string;
  icon?: string;
}

interface PackageFile {
  source: string;
  name: string;
}

async function exists(filename: string): Promise<boolean> {
  try {
    await lstat(filename);
    return true;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }
}

function relativePath(value: string, field: string): string {
  const normalized = value.replaceAll("\\", "/");
  if (
    !normalized ||
    normalized.startsWith("/") ||
    normalized.split("/").some((part) => part === ".." || part === "." || !part) ||
    /[:\x00-\x1f]/.test(normalized)
  ) {
    throw new Error(`[minip] ${field} must be a relative path inside the app.`);
  }
  return normalized;
}

async function readManifest(root: string, filename: string, create: boolean): Promise<Manifest> {
  if (create && !(await exists(filename))) {
    const manifest = {
      appId: randomUUID(),
      name: path.basename(root),
      homepage: "index.html",
      version: "0.0.1",
    };
    await writeFile(filename, `${JSON.stringify(manifest, null, 2)}\n`, { flag: "wx" });
  }

  let value: unknown;
  try {
    value = JSON.parse(await readFile(filename, "utf8"));
  } catch (error) {
    throw new Error(`[minip] Cannot read ${filename}. Check that it exists and contains valid JSON.`, { cause: error });
  }
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`[minip] ${filename} must contain a JSON object.`);
  }
  const manifest = value as Manifest;
  for (const field of ["appId", "name", "homepage"] as const) {
    if (typeof manifest[field] !== "string" || !manifest[field].trim()) {
      throw new Error(`[minip] ${field} must be a non-empty string in ${filename}.`);
    }
  }
  if (/[/\\\x00-\x1f]/.test(manifest.appId) || manifest.appId === "." || manifest.appId === "..") {
    throw new Error("[minip] appId must be a single path component without control characters.");
  }
  if (
    /[<>:"/\\|?*\x00-\x1f]/.test(manifest.name) ||
    manifest.name === "." || manifest.name === ".." ||
    /[. ]$/.test(manifest.name)
  ) {
    throw new Error("[minip] name must be a valid filename without directory separators.");
  }
  relativePath(manifest.homepage.split(/[?#]/, 1)[0], "homepage");
  if (manifest.icon !== undefined) {
    if (typeof manifest.icon !== "string") {
      throw new Error("[minip] icon must be a relative file path.");
    }
    manifest.icon = relativePath(manifest.icon.replace(/^\/+/, ""), "icon");
  }
  return manifest;
}

async function collectFiles(directory: string, archivePath: string): Promise<PackageFile[]> {
  const files: PackageFile[] = [];
  async function visit(current: string) {
    const entries = await readdir(current, { withFileTypes: true });
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      const source = path.join(current, entry.name);
      const name = path.relative(directory, source).split(path.sep).join("/");
      if (source === archivePath || name === "app.json" || /^\.minip-.*\.tmp$/.test(name)) continue;
      if (entry.isDirectory()) {
        await visit(source);
      } else if (entry.isFile()) {
        files.push({ source, name });
      } else {
        throw new Error(`[minip] Unsupported file in build output: ${source}`);
      }
    }
  }
  await visit(directory);
  return files;
}

async function packageApp(config: ResolvedConfig, manifestPath: string): Promise<void> {
  const manifest = await readManifest(config.root, manifestPath, true);
  const outDir = path.resolve(config.root, config.build.outDir);
  const archivePath = path.join(outDir, `${manifest.name}.zip`);
  const files = await collectFiles(outDir, archivePath);
  const homepage = relativePath(manifest.homepage.split(/[?#]/, 1)[0], "homepage");
  if (!files.some((file) => file.name === homepage)) {
    throw new Error(`[minip] Homepage ${homepage} was not found in ${outDir}.`);
  }

  if (manifest.icon && !files.some((file) => file.name === manifest.icon)) {
    const source = path.resolve(config.root, manifest.icon);
    if (!(await exists(source)) || !(await lstat(source)).isFile()) {
      throw new Error(`[minip] Icon ${manifest.icon} was not found in the build output or project root.`);
    }
    files.push({ source, name: manifest.icon });
  }
  files.sort((a, b) => a.name.localeCompare(b.name));
  const packedManifest = {
    ...manifest,
    files: files.map((file) => ({ name: path.posix.basename(file.name), path: file.name })),
  };

  const temporaryPath = path.join(outDir, `.minip-${randomUUID()}.tmp`);
  const archive = new ZipFile();
  const output = createWriteStream(temporaryPath);
  const inputs = new Set<ReadStream>();
  let failure: Error | undefined;
  const stop = (error: Error) => {
    if (failure) return;
    failure = error;
    for (const input of inputs) input.destroy();
    output.destroy(error);
  };
  archive.on("error", stop);
  const completed = pipeline(archive.outputStream, output);
  // Handle output errors immediately, including while file metadata is loading.
  void completed.catch(stop);
  try {
    for (const file of files) {
      const { size, mode, mtime } = await lstat(file.source);
      if (failure) throw failure;
      archive.addReadStreamLazy(file.name, { size, mode, mtime, compressionLevel: 9 }, (callback) => {
        if (failure) return;
        // Own the lazy input streams so a failed write can close every file.
        const input = createReadStream(file.source);
        inputs.add(input);
        input.on("error", stop);
        input.once("close", () => inputs.delete(input));
        callback(null, input);
      });
    }
    archive.addBuffer(Buffer.from(`${JSON.stringify(packedManifest, null, 2)}\n`), "app.json", { compressionLevel: 9 });
    archive.end();
    await completed;
    await rename(temporaryPath, archivePath);
  } catch (error) {
    stop(error instanceof Error ? error : new Error(String(error)));
    await completed.catch(() => {});
    await rm(temporaryPath, { force: true });
    throw error;
  } finally {
    await Promise.allSettled([...inputs].map((input) => {
      const closed = finished(input, { cleanup: true });
      input.destroy();
      return closed;
    }));
  }
  config.logger.info(`[minip] Packaged ${path.relative(config.root, archivePath)} (${(output.bytesWritten / 1024).toFixed(2)} KiB)`);
}

export default function minip(options: MinipPluginOptions = {}): Plugin[] {
  let config: ResolvedConfig;
  let manifestPath: string;
  let outputCount = 0;
  let writtenCount = 0;
  let buildFailed = false;
  let closing: Promise<void> | undefined;
  let finishClosing: (() => void) | undefined;

  const integration: Plugin = {
    name: "vite-plugin-minip",
    config(userConfig) {
      const defaults: UserConfig = {};
      if (userConfig.base == null) defaults.base = "./";
      if (userConfig.server?.host == null) defaults.server = { host: "0.0.0.0" };
      if (userConfig.preview?.host == null) {
        defaults.preview = { host: userConfig.server?.host ?? "0.0.0.0" };
      }
      return defaults;
    },
    configResolved(resolved) {
      config = resolved;
      manifestPath = path.resolve(config.root, options.manifest ?? "app.json");
      if (config.command === "build" && (config.build.ssr || config.build.lib)) {
        throw new Error("[minip] Build a frontend app with an HTML entry. SSR and library builds cannot be installed in Minip.");
      }
    },
    buildStart() {
      outputCount = 0;
      writtenCount = 0;
      buildFailed = false;
    },
    buildEnd(error) {
      if (error) buildFailed = true;
    },
    renderStart() {
      outputCount += 1;
    },
    renderError() {
      buildFailed = true;
    },
    closeBundle: {
      order: "pre",
      handler() {
        if (config.command !== "build" || writtenCount === 0) return;
        // Vite's watcher does not await bundle.close(). Keep the next build
        // from clearing the output while other close hooks and packaging run.
        closing = new Promise<void>((resolve) => { finishClosing = resolve; });
      },
    },
    watchChange() {
      return closing;
    },
    closeWatcher() {
      return closing;
    },
    async configureServer(server) {
      await readManifest(config.root, manifestPath, true);
      const manifestURL = new URL("__minip__/app.json", new URL(config.base, "http://minip.local/"));
      server.middlewares.use((request, response, next) => {
        let pathname: string;
        try {
          pathname = new URL(request.url ?? "/", "http://minip.local").pathname;
        } catch {
          return next();
        }
        if (pathname !== manifestURL.pathname) return next();
        response.setHeader("Content-Type", "application/json; charset=utf-8");
        response.setHeader("Cache-Control", "no-store");
        if (request.method !== "GET" && request.method !== "HEAD") {
          response.statusCode = 405;
          response.setHeader("Allow", "GET, HEAD");
          return response.end();
        }
        void readManifest(config.root, manifestPath, false).then(
          (app) => response.end(request.method === "HEAD" ? undefined : JSON.stringify({ version: 1, app })),
          (error: unknown) => {
            response.statusCode = 500;
            response.end(JSON.stringify({ error: String(error) }));
          },
        );
      });
      if (options.qrCode === false) return;
      const printUrls = server.printUrls.bind(server);
      server.printUrls = () => {
        printUrls();
        const urls = [...new Set(server.resolvedUrls?.network ?? [])];
        if (urls.length === 0) {
          config.logger.warn("[minip] No network address is available. Set server.host to '0.0.0.0' and connect your phone to the same network.");
          return;
        }
        const actions = urls.map((url) => `minip://dev/${encodeURIComponent(url)}`);
        config.logger.info(`[minip] Scan with Minip on the same network to develop with native APIs and hot updates:\n${urls.map((url) => `  ${url}`).join("\n")}`);
        printQRCode(config, actions);
      };
    },
    async configurePreviewServer(server) {
      const manifest = await readManifest(config.root, manifestPath, false);
      const archiveName = `${manifest.name}.zip`;
      const archivePath = path.resolve(config.root, config.build.outDir, archiveName);
      if (!(await exists(archivePath))) {
        throw new Error(`[minip] ${archivePath} does not exist. Build the app before previewing it.`);
      }
      const base = config.base === "./" || config.base === "" ? "/" : config.base;
      const downloadPath = decodeURIComponent(new URL(encodeURIComponent(archiveName), new URL(base, "http://minip.local")).pathname);
      server.middlewares.use((request, response, next) => {
        if (request.method !== "GET" && request.method !== "HEAD") return next();
        let pathname: string;
        try {
          pathname = decodeURIComponent(new URL(request.url ?? "/", "http://minip.local").pathname);
        } catch {
          return next();
        }
        if (pathname !== downloadPath) return next();
        response.setHeader("Content-Type", "application/zip");
        response.setHeader("Content-Disposition", "attachment");
        response.setHeader("Cache-Control", "no-store");
        if (request.method === "HEAD") return response.end();
        const stream = createReadStream(archivePath);
        stream.on("error", next);
        response.on("close", () => stream.destroy());
        stream.pipe(response);
      });
      if (options.qrCode === false) return;
      const printUrls = server.printUrls.bind(server);
      server.printUrls = () => {
        printUrls();
        const urls = [...new Set(server.resolvedUrls?.network ?? [])];
        if (urls.length === 0) {
          config.logger.warn("[minip] No network address is available. Set preview.host to '0.0.0.0' and connect your phone to the same network.");
          return;
        }
        const downloadUrls = urls.map((url) => new URL(encodeURIComponent(archiveName), url).href);
        const installUrls = downloadUrls.map((url) => `minip://install/${encodeURIComponent(url)}`);
        config.logger.info(`[minip] Scan with Minip on the same network to install:\n${downloadUrls.map((url) => `  ${url}`).join("\n")}`);
        printQRCode(config, installUrls);
      };
    },
  };

  const packaging: Plugin = {
    name: "vite-plugin-minip:package",
    apply: "build",
    enforce: "post",
    writeBundle: {
      order: "post",
      sequential: true,
      handler() {
        writtenCount += 1;
      },
    },
    closeBundle: {
      order: "post",
      sequential: true,
      async handler(error) {
        try {
          if (error || buildFailed || writtenCount === 0 || writtenCount !== outputCount) return;
          await packageApp(config, manifestPath);
        } catch (error) {
          if (!this.meta.watchMode) throw error;
          // A rejected close hook is otherwise unhandled by Vite's watcher.
          config.logger.error(`[minip] Packaging failed: ${error instanceof Error ? error.message : String(error)}`);
        } finally {
          finishClosing?.();
          finishClosing = undefined;
          closing = undefined;
        }
      },
    },
  };

  return [integration, packaging];
}

function printQRCode(config: ResolvedConfig, actions: string[]): void {
  const payload = actions.length === 1 ? actions[0] : JSON.stringify(actions);
  try {
    const code = renderUnicodeCompact(payload, { ecc: "M", border: 4 });
    // Compact blocks represent white pixels; fix both colors for any terminal theme.
    config.logger.info(code.split("\n").map((line) => `\x1b[37;40m${line}\x1b[0m`).join("\n"));
  } catch (error) {
    config.logger.warn(`[minip] Could not render the QR code: ${String(error)}`);
  }
}
