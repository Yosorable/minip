import jsBridge from "../bridge";
import { MinipError, MinipErrorCode } from "../bridge";
import { FileStats } from "../types/filestats";

const S_IFMT = 0o170000;
const S_IFDIR = 0o040000;
const S_IFREG = 0o100000;
const S_IFLNK = 0o120000;

export function enrichStats(file: FileStats): FileStats {
  file.atime = new Date(file.atimeMs);
  file.mtime = new Date(file.mtimeMs);
  file.ctime = new Date(file.ctimeMs);
  file.birthtime = new Date(file.birthtimeMs);

  file.isDirectory = function () {
    return (this.mode & S_IFMT) === S_IFDIR;
  };
  file.isFile = function () {
    return (this.mode & S_IFMT) === S_IFREG;
  };
  file.isSymbolicLink = function () {
    return (this.mode & S_IFMT) === S_IFLNK;
  };

  return file;
}

export async function access(path: string, mode?: number): Promise<void> {
  return jsBridge.callNative({ api: "fsAccess", data: { path, mode } });
}

export function accessSync(path: string, mode?: number): void {
  return jsBridge.callNativeSync({ api: "fsAccess", data: { path, mode } });
}

export function existsSync(path: string): boolean {
  try {
    accessSync(path);
    return true;
  } catch (error) {
    if (error instanceof MinipError && error.code === MinipErrorCode.NOT_FOUND) return false;
    throw error;
  }
}

export async function unlink(path: string) {
  await jsBridge.callNative({
    api: "fsUnlink",
    data: {
      path,
    },
  });
}

export function unlinkSync(path: string) {
  jsBridge.callNativeSync({
    api: "fsUnlink",
    data: {
      path,
    },
  });
}

export async function rename(oldPath: string, newPath: string) {
  await jsBridge.callNative({
    api: "fsRename",
    data: {
      oldPath,
      newPath,
    },
  });
}

export function renameSync(oldPath: string, newPath: string) {
  jsBridge.callNativeSync({
    api: "fsRename",
    data: {
      oldPath,
      newPath,
    },
  });
}

export async function stat(path: string): Promise<FileStats> {
  return enrichStats(await jsBridge.callNative<FileStats>({ api: "fsStat", data: { path } }));
}

export function statSync(path: string): FileStats {
  return enrichStats(jsBridge.callNativeSync<FileStats>({ api: "fsStat", data: { path } }));
}

export async function rm(path: string) {
  await jsBridge.callNative({
    api: "fsRm",
    data: {
      path,
    },
  });
}

export function rmSync(path: string) {
  jsBridge.callNativeSync({
    api: "fsRm",
    data: {
      path,
    },
  });
}

export async function cp(src: string, dest: string, recursive?: boolean) {
  await jsBridge.callNative({
    api: "fsCp",
    data: {
      src,
      dest,
      recursive,
    },
  });
}

export function cpSync(src: string, dest: string, recursive?: boolean) {
  jsBridge.callNativeSync({
    api: "fsCp",
    data: {
      src,
      dest,
      recursive,
    },
  });
}
