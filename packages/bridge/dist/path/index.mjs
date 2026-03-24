// src/path/index.ts
var sep = "/";
function join(...segments) {
  return normalize(segments.filter((s) => s.length > 0).join("/"));
}
function resolve(...segments) {
  let resolved = "";
  for (let i = segments.length - 1; i >= 0; i--) {
    resolved = segments[i] + "/" + resolved;
    if (segments[i].startsWith("/")) break;
  }
  return normalize("/" + resolved);
}
function normalize(path) {
  const isAbsolute2 = path.startsWith("/");
  const parts = path.split("/").filter((p) => p.length > 0);
  const result = [];
  for (const part of parts) {
    if (part === ".") continue;
    if (part === "..") {
      if (result.length > 0 && result[result.length - 1] !== "..") {
        result.pop();
      } else if (!isAbsolute2) {
        result.push("..");
      }
    } else {
      result.push(part);
    }
  }
  let normalized = result.join("/");
  if (isAbsolute2) normalized = "/" + normalized;
  return normalized || ".";
}
function dirname(path) {
  if (path.length === 0) return ".";
  const i = path.lastIndexOf("/");
  if (i === -1) return ".";
  if (i === 0) return "/";
  return path.slice(0, i);
}
function basename(path, ext) {
  let base = path;
  const i = base.lastIndexOf("/");
  if (i !== -1) base = base.slice(i + 1);
  if (ext && base.endsWith(ext)) {
    base = base.slice(0, base.length - ext.length);
  }
  return base;
}
function extname(path) {
  const base = basename(path);
  const i = base.lastIndexOf(".");
  if (i <= 0) return "";
  return base.slice(i);
}
function isAbsolute(path) {
  return path.startsWith("/");
}
function relative(from, to) {
  const fromParts = normalize(from).split("/").filter((p) => p.length > 0);
  const toParts = normalize(to).split("/").filter((p) => p.length > 0);
  let common = 0;
  while (common < fromParts.length && common < toParts.length && fromParts[common] === toParts[common]) {
    common++;
  }
  const ups = fromParts.length - common;
  const result = [
    ...Array(ups).fill(".."),
    ...toParts.slice(common)
  ];
  return result.join("/") || ".";
}
export {
  basename,
  dirname,
  extname,
  isAbsolute,
  join,
  normalize,
  relative,
  resolve,
  sep
};
//# sourceMappingURL=index.mjs.map