import {
  access,
  accessSync,
  appendFile,
  appendFileSync,
  copyFile,
  copyFileSync,
  mkdir,
  mkdirSync,
  readdir,
  readdirSync,
  readFile,
  readFileSync,
  rename,
  renameSync,
  rm,
  rmdir,
  rmdirSync,
  rmSync,
  stat,
  statSync,
  truncate,
  truncateSync,
  unlink,
  unlinkSync,
  writeFile,
  writeFileSync,
} from "minip-bridge/fs";
import * as fs from "minip-bridge/fs";
import { createSignal } from "solid-js";

export default function FileSystem() {
  const [msg, setMsg] = createSignal("");
  const filename = "test.txt";
  const dirname = "tmp";
  const handlers: Record<string, (isAsync: boolean) => void> = {
    access: (isAsync) => {
      const start = Date.now();

      let func = access;
      if (!isAsync) {
        func = (path: string, mode?: number) => {
          return new Promise((resolve, reject) => {
            try {
              accessSync(path, mode);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename)
        .then(() => setMsg("access success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "write file": (isAsync) => {
      const start = Date.now();

      let func = writeFile;
      if (!isAsync) {
        func = (path: string, data: Uint8Array | string) => {
          return new Promise((resolve, reject) => {
            try {
              writeFileSync(path, data);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename, "hello world")
        .then(() => setMsg("write file success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "read file": (isAsync) => {
      const start = Date.now();

      let func = readFile;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              const data = readFileSync(path);
              resolve(data);
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename)
        .then((data) => {
          const text = new TextDecoder().decode(data as Uint8Array);
          setMsg(text);
        })
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "append file": (isAsync) => {
      const start = Date.now();

      let func = appendFile;
      if (!isAsync) {
        func = (path: string, data: Uint8Array | string) => {
          return new Promise((resolve, reject) => {
            try {
              appendFileSync(path, data);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename, "hello world")
        .then(() => setMsg("append file success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    truncate: (isAsync) => {
      const start = Date.now();

      let func = truncate;
      if (!isAsync) {
        func = (path: string, len?: number) => {
          return new Promise((resolve, reject) => {
            try {
              truncateSync(path, len);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename, 5)
        .then(() => setMsg("truncate success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "unlink file": (isAsync) => {
      const start = Date.now();

      let func = unlink;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              unlinkSync(path);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename)
        .then(() => setMsg("unlink file success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "read dir": (isAsync) => {
      const start = Date.now();

      let func = readdir;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              const data = readdirSync(path);
              resolve(data);
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func("/")
        .then((data) => {
          setMsg(JSON.stringify(data));
        })
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    mkdir: (isAsync) => {
      const start = Date.now();

      let func = mkdir;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              mkdirSync(path);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(dirname)
        .then(() => setMsg("mkdir success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    rmdir: (isAsync) => {
      const start = Date.now();

      let func = rmdir;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              rmdirSync(path);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(dirname)
        .then(() => setMsg("rmdir success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "file stat": (isAsync) => {
      const start = Date.now();

      let func = stat;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              const data = statSync(path);
              resolve(data);
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename)
        .then((data) => {
          let info = `isDirectory: ${data.isDirectory()}\n`;
          info += `isFile: ${data.isFile()}\n`;
          info += `isSymbolicLink: ${data.isSymbolicLink()}\n`;

          setMsg(info + JSON.stringify(data, null, 2));
        })
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    "copy file": (isAsync) => {
      const start = Date.now();

      let func = copyFile;
      if (!isAsync) {
        func = (src: string, dest: string) => {
          return new Promise((resolve, reject) => {
            try {
              copyFileSync(src, dest);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename, filename + ".copy")
        .then(() => setMsg("copy file success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    rename: (isAsync) => {
      const start = Date.now();

      let func = rename;
      if (!isAsync) {
        func = (oldPath: string, newPath: string) => {
          return new Promise((resolve, reject) => {
            try {
              renameSync(oldPath, newPath);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(filename + ".copy", filename)
        .then(() => setMsg("rename success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    rm: (isAsync) => {
      const start = Date.now();

      let func = rm;
      if (!isAsync) {
        func = (path: string) => {
          return new Promise((resolve, reject) => {
            try {
              rmSync(path);
              resolve();
            } catch (err) {
              reject(err);
            }
          });
        };
      }
      func(dirname)
        .then(() => setMsg("rm success"))
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
  };

  const fdHandlers: Record<string, () => void> = {
    open: () => {
      const start = Date.now();
      fs.open(filename, fs.OpenFlags.O_CREAT | fs.OpenFlags.O_APPEND)
        .then((fd) => {
          setMsg("fd: " + fd);
          return fs.close(fd);
        })
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    fstat: () => {
      const start = Date.now();
      fs.open(filename, fs.OpenFlags.O_RDONLY)
        .then((fd) =>
          fs.fstat(fd).then((data) => {
            let info = `isDirectory: ${data.isDirectory()}\n`;
            info += `isFile: ${data.isFile()}\n`;
            info += `isSymbolicLink: ${data.isSymbolicLink()}\n`;

            setMsg(info + JSON.stringify(data, null, 2));
            return fs.close(fd);
          }),
        )
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    ftruncate: () => {
      const start = Date.now();
      fs.open(filename, fs.OpenFlags.O_WRONLY)
        .then((fd) =>
          fs.ftruncate(fd, 5).then(() => {
            setMsg("ftruncate success");
            return fs.close(fd);
          }),
        )
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    read: () => {
      const start = Date.now();
      const buffer = new Uint8Array(20);
      fs.open(filename, fs.OpenFlags.O_RDONLY)
        .then((fd) =>
          fs.read(fd, buffer, 0, 20).then((readBytes) => {
            const text = new TextDecoder().decode(buffer.slice(0, readBytes));
            setMsg(`read success, read bytes: ${readBytes} , data: ${text}`);
            return fs.close(fd);
          }),
        )
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
    write: () => {
      const start = Date.now();
      const buffer = new TextEncoder().encode("hello, world!" + Date.now());
      fs.open(
        filename,
        fs.OpenFlags.O_WRONLY | fs.OpenFlags.O_CREAT | fs.OpenFlags.O_TRUNC,
      )
        .then((fd) =>
          fs.write(fd, buffer, 0, buffer.byteLength).then((writtenBytes) => {
            setMsg(`read success, written bytes: ${writtenBytes}`);
            return fs.close(fd);
          }),
        )
        .catch((err) =>
          setMsg(err ? (err.message ?? JSON.stringify(err)) : "Unknown error"),
        )
        .finally(() => {
          setMsg((curr) => `cost: ${Date.now() - start}ms\n` + curr);
        });
    },
  };

  return (
    <div class="fade-in">
      <div class="res-div">
        <div>{msg()}</div>
      </div>
      <h4>async</h4>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
          "flex-wrap": "wrap",
        }}
      >
        {Object.keys(handlers).map((key) => (
          <button onClick={() => handlers[key](true)}>{key}</button>
        ))}
      </div>
      <h4>sync</h4>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
          "flex-wrap": "wrap",
        }}
      >
        {Object.keys(handlers).map((key) => (
          <button onClick={() => handlers[key](false)}>{key}</button>
        ))}
      </div>
      <h4>file descriptor</h4>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
          "flex-wrap": "wrap",
        }}
      >
        {Object.keys(fdHandlers).map((key) => (
          <button onClick={() => fdHandlers[key]()}>{key}</button>
        ))}
      </div>
    </div>
  );
}
