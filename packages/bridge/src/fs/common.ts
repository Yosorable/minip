import jsBridge from "../bridge";
import { MResponseWithData } from "../types";
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
  return jsBridge
    .callNative({
      api: "fsAccess",
      data: {
        path,
        mode,
      },
    })
    .then((res) => {
      const r = res as MResponseWithData<boolean>;
      if (!r.hasData() || !r.data) {
        throw new Error(r.msg ?? "cannot access this file or directory");
      }
    });
}

export function accessSync(path: string, mode?: number) {
  const res = jsBridge.callNativeSync({
    api: "fsAccessSync",
    data: {
      path,
      mode,
    },
  }) as MResponseWithData<boolean>;
  if (!res.hasData() || !res.data) {
    throw new Error(res.msg ?? "cannot access this file or directory");
  }
}

export function existsSync(path: string): boolean {
  try {
    accessSync(path);
    return true;
  } catch {
    return false;
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
    api: "fsUnlinkSync",
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
    api: "fsRenameSync",
    data: {
      oldPath,
      newPath,
    },
  });
}

export async function stat(path: string) {
  const res = (await jsBridge.callNative({
    api: "fsStat",
    data: {
      path,
    },
  })) as MResponseWithData<FileStats>;

  return enrichStats(res.data);
}

export function statSync(path: string) {
  const res = jsBridge.callNativeSync({
    api: "fsStatSync",
    data: {
      path,
    },
  }) as MResponseWithData<FileStats>;

  return enrichStats(res.data);
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
    api: "fsRmSync",
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
    api: "fsCpSync",
    data: {
      src,
      dest,
      recursive,
    },
  });
}
