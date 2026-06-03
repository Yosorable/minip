// src/index.ts
import archiver from "archiver";
import fs from "fs";
import path from "path";
import qrcode from "qrcode";
import { randomUUID } from "crypto";
var configFile = "app.json";
function minipPlugin(options = {}) {
  const installScheme = options.installScheme ?? "minip";
  const plugin = {
    name: "minip-plugin",
    closeBundle() {
      function getRelativeFilePath(p, filepath) {
        const i = filepath.indexOf(p);
        return filepath.substring(i + p.length);
      }
      let appInfo;
      if (!fs.existsSync(configFile)) {
        appInfo = {
          appId: randomUUID(),
          name: path.basename(process.cwd()),
          homepage: "index.html"
        };
        fs.writeFileSync(configFile, JSON.stringify(appInfo, null, 2));
      } else {
        appInfo = JSON.parse(fs.readFileSync(configFile, "utf-8"));
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
      const files = [];
      const append = (filePath, file) => {
        if (fs.statSync(filePath).isDirectory()) {
          appendDirectory(filePath);
        } else {
          archive.file(filePath, { name: file });
          const relativePath = (file.startsWith(path.sep) ? file.slice(path.sep.length) : file).replaceAll(path.sep, "/");
          files.push({
            name: path.basename(filePath),
            path: relativePath
          });
        }
      };
      const appendDirectory = (dir) => {
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
            name: icon.replaceAll(path.sep, "/")
          });
        }
      }
      appInfo.files = files;
      archive.append(JSON.stringify(appInfo), { name: "app.json" });
      archive.finalize();
    },
    configurePreviewServer(server) {
      const { printUrls } = server;
      server.printUrls = () => {
        const { resolvedUrls } = server;
        if (resolvedUrls) {
          const appName = JSON.parse(fs.readFileSync(configFile, "utf-8")).name;
          const network = resolvedUrls.network;
          const installSchemes = [];
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
      const newConfig = {};
      if (config.base == null) {
        newConfig.base = "";
      }
      if (config.server?.host == null) {
        newConfig.server = {
          ...config.server,
          host: "0.0.0.0"
        };
      }
      if (Object.keys(newConfig).length > 0) {
        return newConfig;
      }
    }
  };
  return plugin;
}
export {
  minipPlugin as default
};
//# sourceMappingURL=index.mjs.map