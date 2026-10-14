import jsBridge from "../bridge";

export async function mkdir(path: string, recursive = false): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsMkdir", data: { path, recursive } });
}

export async function readdir(path: string): Promise<string[]> {
  return jsBridge.callNative<string[]>({ api: "fsReaddir", data: { path } });
}

export async function rmdir(path: string, recursive = false): Promise<void> {
  return jsBridge.callNative<void>({ api: "fsRmdir", data: { path, recursive } });
}

export function mkdirSync(path: string, recursive = false): void {
  return jsBridge.callNativeSync<void>({ api: "fsMkdir", data: { path, recursive } });
}

export function readdirSync(path: string): string[] {
  return jsBridge.callNativeSync<string[]>({ api: "fsReaddir", data: { path } });
}

export function rmdirSync(path: string, recursive = false): void {
  return jsBridge.callNativeSync<void>({ api: "fsRmdir", data: { path, recursive } });
}
