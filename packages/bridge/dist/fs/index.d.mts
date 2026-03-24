interface FileStats {
    dev: number;
    ino: number;
    mode: number;
    nlink: number;
    uid: number;
    gid: number;
    rdev: number;
    size: number;
    blksize: number;
    blocks: number;
    atimeMs: number;
    mtimeMs: number;
    ctimeMs: number;
    birthtimeMs: number;
    atime: Date;
    mtime: Date;
    ctime: Date;
    birthtime: Date;
    isDirectory(): boolean;
    isFile(): boolean;
    isSymbolicLink(): boolean;
}

declare function enrichStats(file: FileStats): FileStats;
declare function access(path: string, mode?: number): Promise<void>;
declare function accessSync(path: string, mode?: number): void;
declare function existsSync(path: string): boolean;
declare function unlink(path: string): Promise<void>;
declare function unlinkSync(path: string): void;
declare function rename(oldPath: string, newPath: string): Promise<void>;
declare function renameSync(oldPath: string, newPath: string): void;
declare function stat(path: string): Promise<FileStats>;
declare function statSync(path: string): FileStats;
declare function rm(path: string): Promise<void>;
declare function rmSync(path: string): void;
declare function cp(src: string, dest: string, recursive?: boolean): Promise<void>;
declare function cpSync(src: string, dest: string, recursive?: boolean): void;

declare function mkdir(path: string, recursive?: boolean): Promise<void>;
declare function mkdirSync(path: string, recursive?: boolean): void;
declare function readdir(path: string): Promise<string[]>;
declare function readdirSync(path: string): string[];
declare function rmdir(path: string, recursive?: boolean): Promise<void>;
declare function rmdirSync(path: string, recursive?: boolean): void;

declare function readFile(path: string, encoding?: string): Promise<Uint8Array | string>;
declare function readFileSync(path: string, encoding?: string): Uint8Array | string;
declare function writeFile(path: string, data: Uint8Array | string): Promise<void>;
declare function writeFileSync(path: string, data: Uint8Array | string): void;
declare function appendFile(path: string, data: Uint8Array | string): Promise<void>;
declare function appendFileSync(path: string, data: Uint8Array | string): void;
declare function copyFile(src: string, dest: string): Promise<void>;
declare function copyFileSync(src: string, dest: string): void;
declare function truncate(path: string, length?: number): Promise<void>;
declare function truncateSync(path: string, length?: number): void;

declare enum OpenFlags {
    O_RDONLY = 0,
    O_WRONLY = 1,
    O_RDWR = 2,
    O_CREAT = 64,
    O_EXCL = 128,
    O_TRUNC = 512,
    O_APPEND = 1024
}
declare function open(path: string, flags: OpenFlags | number, mode?: number): Promise<number>;
declare function openSync(path: string, flags: OpenFlags | number, mode?: number): number;
declare function close(fd: number): Promise<void>;
declare function closeSync(fd: number): void;
declare function fstat(fd: number): Promise<FileStats>;
declare function fstatSync(fd: number): FileStats;
declare function ftruncate(fd: number, length?: number): Promise<void>;
declare function ftruncateSync(fd: number, length?: number): void;
declare function read(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): Promise<number>;
declare function readSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): number;
declare function write(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): Promise<number>;
declare function writeSync(fd: number, buffer: Uint8Array, offset: number, length: number, position?: number): number;

export { OpenFlags, access, accessSync, appendFile, appendFileSync, close, closeSync, copyFile, copyFileSync, cp, cpSync, enrichStats, existsSync, fstat, fstatSync, ftruncate, ftruncateSync, mkdir, mkdirSync, open, openSync, read, readFile, readFileSync, readSync, readdir, readdirSync, rename, renameSync, rm, rmSync, rmdir, rmdirSync, stat, statSync, truncate, truncateSync, unlink, unlinkSync, write, writeFile, writeFileSync, writeSync };
