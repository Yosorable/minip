export const sep = "/";

export function join(...segments: string[]): string {
  return normalize(segments.filter((s) => s.length > 0).join("/"));
}

export function resolve(...segments: string[]): string {
  let resolved = "";
  for (let i = segments.length - 1; i >= 0; i--) {
    resolved = segments[i] + "/" + resolved;
    if (segments[i].startsWith("/")) break;
  }
  return normalize("/" + resolved);
}

export function normalize(path: string): string {
  const isAbsolute = path.startsWith("/");
  const parts = path.split("/").filter((p) => p.length > 0);
  const result: string[] = [];

  for (const part of parts) {
    if (part === ".") continue;
    if (part === "..") {
      if (result.length > 0 && result[result.length - 1] !== "..") {
        result.pop();
      } else if (!isAbsolute) {
        result.push("..");
      }
    } else {
      result.push(part);
    }
  }

  let normalized = result.join("/");
  if (isAbsolute) normalized = "/" + normalized;
  return normalized || ".";
}

export function dirname(path: string): string {
  if (path.length === 0) return ".";
  const i = path.lastIndexOf("/");
  if (i === -1) return ".";
  if (i === 0) return "/";
  return path.slice(0, i);
}

export function basename(path: string, ext?: string): string {
  let base = path;
  const i = base.lastIndexOf("/");
  if (i !== -1) base = base.slice(i + 1);
  if (ext && base.endsWith(ext)) {
    base = base.slice(0, base.length - ext.length);
  }
  return base;
}

export function extname(path: string): string {
  const base = basename(path);
  const i = base.lastIndexOf(".");
  if (i <= 0) return "";
  return base.slice(i);
}

export function isAbsolute(path: string): boolean {
  return path.startsWith("/");
}

export function relative(from: string, to: string): string {
  const fromParts = normalize(from).split("/").filter((p) => p.length > 0);
  const toParts = normalize(to).split("/").filter((p) => p.length > 0);

  let common = 0;
  while (
    common < fromParts.length &&
    common < toParts.length &&
    fromParts[common] === toParts[common]
  ) {
    common++;
  }

  const ups = fromParts.length - common;
  const result = [
    ...Array(ups).fill(".."),
    ...toParts.slice(common),
  ];
  return result.join("/") || ".";
}
