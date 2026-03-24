import {
  bridge_default
} from "../chunk-GXHJCCLG.mjs";

// src/fs/common.ts
var S_IFMT = 61440;
var S_IFDIR = 16384;
var S_IFREG = 32768;
var S_IFLNK = 40960;
function enrichStats(file) {
  file.atime = new Date(file.atimeMs);
  file.mtime = new Date(file.mtimeMs);
  file.ctime = new Date(file.ctimeMs);
  file.birthtime = new Date(file.birthtimeMs);
  file.isDirectory = function() {
    return (this.mode & S_IFMT) === S_IFDIR;
  };
  file.isFile = function() {
    return (this.mode & S_IFMT) === S_IFREG;
  };
  file.isSymbolicLink = function() {
    return (this.mode & S_IFMT) === S_IFLNK;
  };
  return file;
}
async function access(path, mode) {
  return bridge_default.callNative({
    api: "fsAccess",
    data: {
      path,
      mode
    }
  }).then((res) => {
    const r = res;
    if (!r.hasData() || !r.data) {
      throw new Error(r.msg ?? "cannot access this file or directory");
    }
  });
}
function accessSync(path, mode) {
  const res = bridge_default.callNativeSync({
    api: "fsAccessSync",
    data: {
      path,
      mode
    }
  });
  if (!res.hasData() || !res.data) {
    throw new Error(res.msg ?? "cannot access this file or directory");
  }
}
function existsSync(path) {
  try {
    accessSync(path);
    return true;
  } catch {
    return false;
  }
}
async function unlink(path) {
  await bridge_default.callNative({
    api: "fsUnlink",
    data: {
      path
    }
  });
}
function unlinkSync(path) {
  bridge_default.callNativeSync({
    api: "fsUnlinkSync",
    data: {
      path
    }
  });
}
async function rename(oldPath, newPath) {
  await bridge_default.callNative({
    api: "fsRename",
    data: {
      oldPath,
      newPath
    }
  });
}
function renameSync(oldPath, newPath) {
  bridge_default.callNativeSync({
    api: "fsRenameSync",
    data: {
      oldPath,
      newPath
    }
  });
}
async function stat(path) {
  const res = await bridge_default.callNative({
    api: "fsStat",
    data: {
      path
    }
  });
  return enrichStats(res.data);
}
function statSync(path) {
  const res = bridge_default.callNativeSync({
    api: "fsStatSync",
    data: {
      path
    }
  });
  return enrichStats(res.data);
}
async function rm(path) {
  await bridge_default.callNative({
    api: "fsRm",
    data: {
      path
    }
  });
}
function rmSync(path) {
  bridge_default.callNativeSync({
    api: "fsRmSync",
    data: {
      path
    }
  });
}
async function cp(src, dest, recursive) {
  await bridge_default.callNative({
    api: "fsCp",
    data: {
      src,
      dest,
      recursive
    }
  });
}
function cpSync(src, dest, recursive) {
  bridge_default.callNativeSync({
    api: "fsCpSync",
    data: {
      src,
      dest,
      recursive
    }
  });
}

// src/fs/dir.ts
async function mkdir(path, recursive = false) {
  await bridge_default.callNative({
    api: "fsMkdir",
    data: {
      path,
      recursive
    }
  });
}
function mkdirSync(path, recursive = false) {
  bridge_default.callNativeSync({
    api: "fsMkdirSync",
    data: {
      path,
      recursive
    }
  });
}
function readdir(path) {
  return bridge_default.callNative({
    api: "fsReaddir",
    data: {
      path
    }
  }).then((res) => res).then((res) => res.data);
}
function readdirSync(path) {
  const res = bridge_default.callNativeSync({
    api: "fsReaddirSync",
    data: {
      path
    }
  });
  return res.data;
}
async function rmdir(path, recursive) {
  await bridge_default.callNative({
    api: "fsRmdir",
    data: {
      path,
      recursive
    }
  });
}
function rmdirSync(path, recursive) {
  bridge_default.callNativeSync({
    api: "fsRmdirSync",
    data: {
      path,
      recursive
    }
  });
}

// src/utils/utils.ts
function uint8ArrayToBase64(data, offset = 0, length = 0) {
  if (length === 0) {
    length = data.byteLength;
  }
  const slice = offset === 0 && length === data.byteLength ? data : data.subarray(offset, offset + length);
  let binary = "";
  for (let i = 0; i < slice.byteLength; i++) {
    binary += String.fromCharCode(slice[i]);
  }
  return btoa(binary);
}
function base64ToUint8Array(base64) {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}
function base64WriteToUint8Array(base64, buffer, offset) {
  const binaryString = atob(base64);
  for (let i = 0; i < binaryString.length; i++) {
    buffer[offset + i] = binaryString.charCodeAt(i);
  }
  return binaryString.length;
}

// src/fs/file.ts
function readFile(path, encoding) {
  return bridge_default.callNative({
    api: "fsReadFile",
    data: {
      path
    }
  }).then((res) => res.data).then((res) => {
    const bytes = base64ToUint8Array(res);
    return encoding ? new TextDecoder(encoding).decode(bytes) : bytes;
  });
}
function readFileSync(path, encoding) {
  const res = bridge_default.callNativeSync({
    api: "fsReadFileSync",
    data: {
      path
    }
  });
  const bytes = base64ToUint8Array(res.data);
  return encoding ? new TextDecoder(encoding).decode(bytes) : bytes;
}
function toBase64(data) {
  if (data instanceof Uint8Array) {
    return uint8ArrayToBase64(data);
  }
  return uint8ArrayToBase64(new TextEncoder().encode(data));
}
async function writeFile(path, data) {
  await bridge_default.callNative({
    api: "fsWriteFile",
    data: {
      path,
      data: toBase64(data)
    }
  });
}
function writeFileSync(path, data) {
  bridge_default.callNativeSync({
    api: "fsWriteFileSync",
    data: {
      path,
      data: toBase64(data)
    }
  });
}
async function appendFile(path, data) {
  await bridge_default.callNative({
    api: "fsAppendFile",
    data: {
      path,
      data: toBase64(data)
    }
  });
}
function appendFileSync(path, data) {
  bridge_default.callNativeSync({
    api: "fsAppendFileSync",
    data: {
      path,
      data: toBase64(data)
    }
  });
}
async function copyFile(src, dest) {
  await bridge_default.callNative({
    api: "fsCopyFile",
    data: {
      src,
      dest
    }
  });
}
function copyFileSync(src, dest) {
  bridge_default.callNativeSync({
    api: "fsCopyFileSync",
    data: {
      src,
      dest
    }
  });
}
async function truncate(path, length = 0) {
  await bridge_default.callNative({
    api: "fsTruncate",
    data: {
      path,
      length
    }
  });
}
function truncateSync(path, length = 0) {
  bridge_default.callNativeSync({
    api: "fsTruncateSync",
    data: {
      path,
      length
    }
  });
}

// src/fs/fd.ts
var OpenFlags = /* @__PURE__ */ ((OpenFlags2) => {
  OpenFlags2[OpenFlags2["O_RDONLY"] = 0] = "O_RDONLY";
  OpenFlags2[OpenFlags2["O_WRONLY"] = 1] = "O_WRONLY";
  OpenFlags2[OpenFlags2["O_RDWR"] = 2] = "O_RDWR";
  OpenFlags2[OpenFlags2["O_CREAT"] = 64] = "O_CREAT";
  OpenFlags2[OpenFlags2["O_EXCL"] = 128] = "O_EXCL";
  OpenFlags2[OpenFlags2["O_TRUNC"] = 512] = "O_TRUNC";
  OpenFlags2[OpenFlags2["O_APPEND"] = 1024] = "O_APPEND";
  return OpenFlags2;
})(OpenFlags || {});
function open(path, flags, mode) {
  return bridge_default.callNative({
    api: "fsOpen",
    data: {
      path,
      flags,
      mode
    }
  }).then((res) => res.data);
}
function openSync(path, flags, mode) {
  const res = bridge_default.callNativeSync({
    api: "fsOpenSync",
    data: {
      path,
      flags,
      mode
    }
  });
  return res.data;
}
async function close(fd) {
  await bridge_default.callNative({
    api: "fsClose",
    data: {
      fd
    }
  });
}
function closeSync(fd) {
  bridge_default.callNativeSync({
    api: "fsCloseSync",
    data: {
      fd
    }
  });
}
async function fstat(fd) {
  const res = await bridge_default.callNative({
    api: "fsFstat",
    data: {
      fd
    }
  });
  return enrichStats(res.data);
}
function fstatSync(fd) {
  const res = bridge_default.callNativeSync({
    api: "fsFstatSync",
    data: {
      fd
    }
  });
  return enrichStats(res.data);
}
async function ftruncate(fd, length = 0) {
  await bridge_default.callNative({
    api: "fsFtruncate",
    data: {
      fd,
      length
    }
  });
}
function ftruncateSync(fd, length = 0) {
  bridge_default.callNativeSync({
    api: "fsFtruncateSync",
    data: {
      fd,
      length
    }
  });
}
async function read(fd, buffer, offset, length, position) {
  const res = await bridge_default.callNative({
    api: "fsRead",
    data: {
      fd,
      length,
      position
    }
  });
  return base64WriteToUint8Array(res.data, buffer, offset);
}
function readSync(fd, buffer, offset, length, position) {
  const res = bridge_default.callNativeSync({
    api: "fsReadSync",
    data: {
      fd,
      length,
      position
    }
  });
  return base64WriteToUint8Array(res.data, buffer, offset);
}
function write(fd, buffer, offset, length, position) {
  const base64 = uint8ArrayToBase64(buffer, offset, length);
  return bridge_default.callNative({
    api: "fsWrite",
    data: {
      fd,
      data: base64,
      position
    }
  }).then((res) => res.data);
}
function writeSync(fd, buffer, offset, length, position) {
  const base64 = uint8ArrayToBase64(buffer, offset, length);
  return bridge_default.callNativeSync({
    api: "fsWriteSync",
    data: {
      fd,
      data: base64,
      position
    }
  }).data;
}
export {
  OpenFlags,
  access,
  accessSync,
  appendFile,
  appendFileSync,
  close,
  closeSync,
  copyFile,
  copyFileSync,
  cp,
  cpSync,
  enrichStats,
  existsSync,
  fstat,
  fstatSync,
  ftruncate,
  ftruncateSync,
  mkdir,
  mkdirSync,
  open,
  openSync,
  read,
  readFile,
  readFileSync,
  readSync,
  readdir,
  readdirSync,
  rename,
  renameSync,
  rm,
  rmSync,
  rmdir,
  rmdirSync,
  stat,
  statSync,
  truncate,
  truncateSync,
  unlink,
  unlinkSync,
  write,
  writeFile,
  writeFileSync,
  writeSync
};
//# sourceMappingURL=index.mjs.map