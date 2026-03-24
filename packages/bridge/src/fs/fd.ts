import jsBridge from "../bridge";
import { MResponseWithData } from "../types";
import { FileStats } from "../types/filestats";
import { uint8ArrayToBase64, base64WriteToUint8Array } from "../utils/utils";
import { enrichStats } from "./common";

export enum OpenFlags {
  O_RDONLY = 0,
  O_WRONLY = 1,
  O_RDWR = 2,
  O_CREAT = 64,
  O_EXCL = 128,
  O_TRUNC = 512,
  O_APPEND = 1024,
}

export function open(path: string, flags: OpenFlags | number, mode?: number) {
  return jsBridge.callNative({
    api: "fsOpen",
    data: {
      path,
      flags,
      mode,
    },
  }).then(res => (res as MResponseWithData<number>).data);
}

export function openSync(path: string, flags: OpenFlags | number, mode?: number) {
  const res = jsBridge.callNativeSync({
    api: "fsOpenSync",
    data: {
      path,
      flags,
      mode,
    },
  }) as MResponseWithData<number>
  return res.data
}

export async function close(fd: number) {
  await jsBridge.callNative({
    api: "fsClose",
    data: {
      fd,
    },
  })
}

export function closeSync(fd: number) {
  jsBridge.callNativeSync({
    api: "fsCloseSync",
    data: {
      fd,
    },
  })
}

export async function fstat(fd: number) {
  const res = await jsBridge.callNative({
    api: "fsFstat",
    data: {
      fd,
    },
  }) as MResponseWithData<FileStats>;

  return enrichStats(res.data);
}

export function fstatSync(fd: number) {
  const res = jsBridge.callNativeSync({
    api: "fsFstatSync",
    data: {
      fd,
    },
  }) as MResponseWithData<FileStats>;

  return enrichStats(res.data);
}

export async function ftruncate(fd: number, length: number = 0) {
  await jsBridge.callNative({
    api: "fsFtruncate",
    data: {
      fd,
      length
    }
  })
}

export function ftruncateSync(fd: number, length: number = 0) {
  jsBridge.callNativeSync({
    api: "fsFtruncateSync",
    data: {
      fd,
      length
    }
  })
}

export async function read(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number) {
  const res = await jsBridge.callNative({
    api: "fsRead",
    data: {
      fd,
      length,
      position,
    }
  }) as MResponseWithData<string>;
  return base64WriteToUint8Array(res.data, buffer, offset);
}

export function readSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number) {
  const res = jsBridge.callNativeSync({
    api: "fsReadSync",
    data: {
      fd,
      length,
      position,
    }
  }) as MResponseWithData<string>;
  return base64WriteToUint8Array(res.data, buffer, offset);
}

export function write(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number) {
  const base64 = uint8ArrayToBase64(buffer, offset, length);

  return jsBridge.callNative({
    api: "fsWrite",
    data: {
      fd,
      data: base64,
      position,
    }
  }).then(res => (res as MResponseWithData<number>).data);
}

export function writeSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number) {
  const base64 = uint8ArrayToBase64(buffer, offset, length);

  return (jsBridge.callNativeSync({
    api: "fsWriteSync",
    data: {
      fd,
      data: base64,
      position,
    }
  }) as MResponseWithData<number>).data;
}