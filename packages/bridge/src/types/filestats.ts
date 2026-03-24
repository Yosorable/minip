export interface FileStats {
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