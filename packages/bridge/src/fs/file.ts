import jsBridge from "../bridge";
import { MResponseWithData } from "../types";
import { base64ToUint8Array, uint8ArrayToBase64 } from "../utils/utils";

export function readFile(path: string, encoding?: string): Promise<Uint8Array | string> {
  return jsBridge.callNative({
    api: "fsReadFile",
    data: {
      path
    }
  }).then(res => (res as MResponseWithData<string>).data)
    .then(res => {
      const bytes = base64ToUint8Array(res)
      return encoding ? new TextDecoder(encoding).decode(bytes) : bytes
    })
}

export function readFileSync(path: string, encoding?: string): Uint8Array | string {
  const res = jsBridge.callNativeSync({
    api: "fsReadFileSync",
    data: {
      path
    }
  }) as MResponseWithData<string>
  const bytes = base64ToUint8Array(res.data)
  return encoding ? new TextDecoder(encoding).decode(bytes) : bytes
}

function toBase64(data: Uint8Array | string): string {
  if (data instanceof Uint8Array) {
    return uint8ArrayToBase64(data)
  }
  return uint8ArrayToBase64(new TextEncoder().encode(data))
}

export async function writeFile(path: string, data: Uint8Array | string) {
  await jsBridge.callNative({
    api: "fsWriteFile",
    data: {
      path,
      data: toBase64(data)
    }
  })
}

export function writeFileSync(path: string, data: Uint8Array | string) {
  jsBridge.callNativeSync({
    api: "fsWriteFileSync",
    data: {
      path,
      data: toBase64(data)
    }
  })
}

export async function appendFile(path: string, data: Uint8Array | string) {
  await jsBridge.callNative({
    api: "fsAppendFile",
    data: {
      path,
      data: toBase64(data)
    }
  })
}

export function appendFileSync(path: string, data: Uint8Array | string) {
  jsBridge.callNativeSync({
    api: "fsAppendFileSync",
    data: {
      path,
      data: toBase64(data)
    }
  })
}

export async function copyFile(src: string, dest: string) {
  await jsBridge.callNative({
    api: "fsCopyFile",
    data: {
      src,
      dest
    }
  })
}

export function copyFileSync(src: string, dest: string) {
  jsBridge.callNativeSync({
    api: "fsCopyFileSync",
    data: {
      src,
      dest
    }
  })
}

export async function truncate(path: string, length: number = 0) {
  await jsBridge.callNative({
    api: "fsTruncate",
    data: {
      path,
      length
    }
  })
}

export function truncateSync(path: string, length: number = 0) {
  jsBridge.callNativeSync({
    api: "fsTruncateSync",
    data: {
      path,
      length
    }
  })
}
