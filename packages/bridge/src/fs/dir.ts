import jsBridge from "../bridge";
import { MResponseWithData } from "../types";

export async function mkdir(path: string, recursive: boolean = false) {
  await jsBridge.callNative({
    api: "fsMkdir",
    data: {
      path,
      recursive
    }
  })
}

export function mkdirSync(path: string, recursive: boolean = false) {
  jsBridge.callNativeSync({
    api: "fsMkdirSync",
    data: {
      path,
      recursive
    }
  })
}

export function readdir(path: string): Promise<string[]> {
  return jsBridge.callNative({
    api: "fsReaddir",
    data: {
      path
    }
  }).then(res => res as MResponseWithData<string[]>)
    .then(res => res.data)
}

export function readdirSync(path: string): string[] {
  const res = jsBridge.callNativeSync({
    api: "fsReaddirSync",
    data: {
      path
    }
  }) as MResponseWithData<string[]>
  return res.data
}

export async function rmdir(path: string, recursive?: boolean) {
  await jsBridge.callNative({
    api: "fsRmdir",
    data: {
      path,
      recursive
    }
  })
}

export function rmdirSync(path: string, recursive?: boolean) {
  jsBridge.callNativeSync({
    api: "fsRmdirSync",
    data: {
      path,
      recursive
    }
  })
}
