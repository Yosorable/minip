import {
  MinipError,
  MinipErrorCode,
  bridge_default
} from "../chunk-U2FR746Y.mjs";

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
  return bridge_default.callNative({ api: "fsAccess", data: { path, mode } });
}
function accessSync(path, mode) {
  return bridge_default.callNativeSync({ api: "fsAccess", data: { path, mode } });
}
function existsSync(path) {
  try {
    accessSync(path);
    return true;
  } catch (error) {
    if (error instanceof MinipError && error.code === MinipErrorCode.NOT_FOUND) return false;
    throw error;
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
    api: "fsUnlink",
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
    api: "fsRename",
    data: {
      oldPath,
      newPath
    }
  });
}
async function stat(path) {
  return enrichStats(await bridge_default.callNative({ api: "fsStat", data: { path } }));
}
function statSync(path) {
  return enrichStats(bridge_default.callNativeSync({ api: "fsStat", data: { path } }));
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
    api: "fsRm",
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
    api: "fsCp",
    data: {
      src,
      dest,
      recursive
    }
  });
}

// src/fs/dir.ts
async function mkdir(path, recursive = false) {
  return bridge_default.callNative({ api: "fsMkdir", data: { path, recursive } });
}
async function readdir(path) {
  return bridge_default.callNative({ api: "fsReaddir", data: { path } });
}
async function rmdir(path, recursive = false) {
  return bridge_default.callNative({ api: "fsRmdir", data: { path, recursive } });
}
function mkdirSync(path, recursive = false) {
  return bridge_default.callNativeSync({ api: "fsMkdir", data: { path, recursive } });
}
function readdirSync(path) {
  return bridge_default.callNativeSync({ api: "fsReaddir", data: { path } });
}
function rmdirSync(path, recursive = false) {
  return bridge_default.callNativeSync({ api: "fsRmdir", data: { path, recursive } });
}

// src/fs/validation.ts
function bufferRange(buffer, offset, length, api) {
  if (!(buffer instanceof Uint8Array) || !Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < 0 || length < 0 || offset > buffer.byteLength || length > buffer.byteLength - offset) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "Buffer offset and length must describe a valid byte range", { api });
  }
  return buffer.subarray(offset, offset + length);
}
function binaryResult(value, api) {
  if (!(value instanceof Uint8Array)) {
    throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Expected a binary file result", { api });
  }
  return value;
}
function fileBytes(value, api) {
  if (typeof value === "string") return new TextEncoder().encode(value);
  if (value instanceof Uint8Array) return value;
  throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "File data must be a string or Uint8Array", { api });
}

// src/fs/file.ts
function textDecoder(encoding, api) {
  if (encoding === void 0) return void 0;
  try {
    return new TextDecoder(encoding);
  } catch (cause) {
    throw new MinipError(MinipErrorCode.INVALID_ARGUMENT, "Unsupported text encoding", { api, cause });
  }
}
async function readFile(path, encoding) {
  const decoder = textDecoder(encoding, "fsReadFile");
  const bytes = binaryResult(await bridge_default.callNative({ api: "fsReadFile", data: { path } }), "fsReadFile");
  return decoder ? decoder.decode(bytes) : bytes;
}
function readFileSync(path, encoding) {
  const decoder = textDecoder(encoding, "fsReadFile");
  const bytes = binaryResult(bridge_default.callNativeSync({ api: "fsReadFile", data: { path } }), "fsReadFile");
  return decoder ? decoder.decode(bytes) : bytes;
}
async function writeFile(path, data) {
  return bridge_default.callNative({ api: "fsWriteFile", data: { path, data: fileBytes(data, "fsWriteFile") } });
}
async function appendFile(path, data) {
  return bridge_default.callNative({ api: "fsAppendFile", data: { path, data: fileBytes(data, "fsAppendFile") } });
}
async function copyFile(src, dest) {
  return bridge_default.callNative({ api: "fsCopyFile", data: { src, dest } });
}
async function truncate(path, length = 0) {
  return bridge_default.callNative({ api: "fsTruncate", data: { path, length } });
}
function writeFileSync(path, data) {
  return bridge_default.callNativeSync({ api: "fsWriteFile", data: { path, data: fileBytes(data, "fsWriteFile") } });
}
function appendFileSync(path, data) {
  return bridge_default.callNativeSync({ api: "fsAppendFile", data: { path, data: fileBytes(data, "fsAppendFile") } });
}
function copyFileSync(src, dest) {
  return bridge_default.callNativeSync({ api: "fsCopyFile", data: { src, dest } });
}
function truncateSync(path, length = 0) {
  return bridge_default.callNativeSync({ api: "fsTruncate", data: { path, length } });
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
async function open(path, flags, mode) {
  return bridge_default.callNative({ api: "fsOpen", data: { path, flags, mode } });
}
async function close(fd) {
  return bridge_default.callNative({ api: "fsClose", data: { fd } });
}
async function fstat(fd) {
  return enrichStats(await bridge_default.callNative({ api: "fsFstat", data: { fd } }));
}
async function ftruncate(fd, length = 0) {
  return bridge_default.callNative({ api: "fsFtruncate", data: { fd, length } });
}
async function read(fd, buffer, offset, length, position) {
  bufferRange(buffer, offset, length, "fsRead");
  const bytes = binaryResult(await bridge_default.callNative({ api: "fsRead", data: { fd, length, position } }), "fsRead");
  if (bytes.byteLength > length) throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Read returned more bytes than requested", { api: "fsRead" });
  buffer.set(bytes, offset);
  return bytes.byteLength;
}
async function write(fd, buffer, offset, length, position) {
  const data = bufferRange(buffer, offset, length, "fsWrite");
  return bridge_default.callNative({ api: "fsWrite", data: { fd, data, position } });
}
function openSync(path, flags, mode) {
  return bridge_default.callNativeSync({ api: "fsOpen", data: { path, flags, mode } });
}
function closeSync(fd) {
  return bridge_default.callNativeSync({ api: "fsClose", data: { fd } });
}
function fstatSync(fd) {
  return enrichStats(bridge_default.callNativeSync({ api: "fsFstat", data: { fd } }));
}
function ftruncateSync(fd, length = 0) {
  return bridge_default.callNativeSync({ api: "fsFtruncate", data: { fd, length } });
}
function readSync(fd, buffer, offset, length, position) {
  bufferRange(buffer, offset, length, "fsRead");
  const bytes = binaryResult(bridge_default.callNativeSync({ api: "fsRead", data: { fd, length, position } }), "fsRead");
  if (bytes.byteLength > length) throw new MinipError(MinipErrorCode.INVALID_RESPONSE, "Read returned more bytes than requested", { api: "fsRead" });
  buffer.set(bytes, offset);
  return bytes.byteLength;
}
function writeSync(fd, buffer, offset, length, position) {
  const data = bufferRange(buffer, offset, length, "fsWrite");
  return bridge_default.callNativeSync({ api: "fsWrite", data: { fd, data, position } });
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