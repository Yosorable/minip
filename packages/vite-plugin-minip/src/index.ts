// Vite plugin: package the built web app into a Minip mini app.
//
// On `vite build` it writes/reads `app.json`, zips `dist/` + the manifest into
// `dist/<name>.zip`, and records a `files` list. On `vite preview` it prints an
// install QR code (`<scheme>://install/<lan-url>.zip`) so you can install onto a
// phone by scanning. It also sets `base = ""` (relative paths) and exposes the
// preview server on the LAN by default.

import archiver from "archiver";
import fs from "fs";
import path from "path";
import qrcode from "qrcode";
import { randomUUID } from "crypto";
import type { PluginOption, PreviewServer, UserConfig } from "vite";

export interface MinipPluginOptions {
  /**
   * URL scheme used by the install QR code shown on `vite preview`, producing
   * `<scheme>://install/<url>.zip`. Defaults to `"minip"` so scanning opens the
   * Minip app. Override if your host app registers a different scheme.
   */
  installScheme?: string;
}

const configFile = "app.json";

interface FileInfo {
  name: string;
  path: string;
}

interface AppInfo {
  appId: string;
  homepage: string;
  icon?: string;
  files?: FileInfo[];
  name: string;
}

export default function minipPlugin(options: MinipPluginOptions = {}): PluginOption {
  const installScheme = options.installScheme ?? "minip";

  const plugin: PluginOption = {
    name: "minip-plugin",
    closeBundle() {
      function getRelativeFilePath(p: string, filepath: string) {
        const i = filepath.indexOf(p);
        return filepath.substring(i + p.length);
      }

      let appInfo: AppInfo;
      if (!fs.existsSync(configFile)) {
        appInfo = {
          appId: randomUUID(),
          name: path.basename(process.cwd()),
          homepage: "index.html",
        };
        fs.writeFileSync(configFile, JSON.stringify(appInfo, null, 2));
      } else {
        appInfo = JSON.parse(fs.readFileSync(configFile, "utf-8")) as AppInfo;
      }
      const outputDir = "dist";
      const zipFile = `dist/${appInfo.name}.zip`;

      if (fs.existsSync(zipFile)) {
        fs.unlinkSync(zipFile);
      }

      const output = fs.createWriteStream(zipFile);
      const archive = archiver("zip", { zlib: { level: 9 } });

      output.on("close", () => {
        console.log(
          `packaged success: ${zipFile} (size: ${(archive.pointer() / 1024).toFixed(2)} KiB)`
        );
      });

      archive.on("error", (err) => {
        throw err;
      });

      archive.pipe(output);

      const files: FileInfo[] = [];
      const append = (filePath: string, file: string) => {
        if (fs.statSync(filePath).isDirectory()) {
          appendDirectory(filePath);
        } else {
          archive.file(filePath, { name: file });
          const relativePath = (
            file.startsWith(path.sep) ? file.slice(path.sep.length) : file
          ).replaceAll(path.sep, "/");
          files.push({
            name: path.basename(filePath),
            path: relativePath,
          });
        }
      };

      const appendDirectory = (dir: string) => {
        fs.readdirSync(dir).forEach((file) => {
          const fp = path.resolve(dir, file);
          append(fp, getRelativeFilePath(outputDir, fp));
        });
      };

      fs.readdirSync(outputDir).forEach((file) => {
        append(path.resolve(outputDir, file), file);
      });
      let icon = appInfo.icon;
      if (icon) {
        icon = icon.startsWith(path.sep) ? icon.slice(path.sep.length) : icon;
        if (fs.existsSync(icon)) {
          archive.append(fs.readFileSync(icon), {
            name: icon.replaceAll(path.sep, "/"),
          });
        }
      }
      appInfo.files = files;
      archive.append(JSON.stringify(appInfo), { name: "app.json" });
      archive.finalize();
    },
    configurePreviewServer(server: PreviewServer) {
      const { printUrls } = server;
      server.printUrls = () => {
        const { resolvedUrls } = server;
        if (resolvedUrls) {
          const appName = JSON.parse(fs.readFileSync(configFile, "utf-8")).name;
          const network = resolvedUrls.network;
          const installSchemes: string[] = [];
          for (const url of network) {
            installSchemes.push(`${installScheme}://install/${url + appName}.zip`);
          }

          qrcode.toString(
            installSchemes.length === 1 ? installSchemes[0] : JSON.stringify(installSchemes),
            { type: "terminal", small: true },
            (err, str) => {
              if (err) throw err;
              printUrls();
              console.log("Scan this qrcode by Minip App");
              console.log(str);
            }
          );
        } else {
          printUrls();
        }
      };
    },
    config(config) {
      const newConfig: UserConfig = {};
      if (config.base == null) {
        newConfig.base = "";
      }

      if (config.server?.host == null) {
        newConfig.server = {
          ...config.server,
          host: "0.0.0.0",
        };
      }

      if (Object.keys(newConfig).length > 0) {
        return newConfig;
      }
    },
  };

  return plugin;
}
