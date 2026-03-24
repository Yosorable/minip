declare const sep = "/";
declare function join(...segments: string[]): string;
declare function resolve(...segments: string[]): string;
declare function normalize(path: string): string;
declare function dirname(path: string): string;
declare function basename(path: string, ext?: string): string;
declare function extname(path: string): string;
declare function isAbsolute(path: string): boolean;
declare function relative(from: string, to: string): string;

export { basename, dirname, extname, isAbsolute, join, normalize, relative, resolve, sep };
