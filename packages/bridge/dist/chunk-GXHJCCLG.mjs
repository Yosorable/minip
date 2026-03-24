// src/bridge/index.ts
var jsBridge;
if (window.webkit?.messageHandlers?.MinipNativeInteraction) {
  const _callNative = window.webkit.messageHandlers.MinipNativeInteraction;
  jsBridge = {
    callNative(req) {
      return _callNative.postMessage(JSON.stringify(req)).then((res) => JSON.parse(res)).then((res) => {
        if (res.code === 0 /* SUCCESS */) {
          res.isSuccess = () => true;
          const hashData = res.data !== null && res.data !== void 0;
          res.hasData = () => hashData;
          return res;
        } else {
          throw new Error(res.msg ?? "Unknown error, res: ");
        }
      });
    },
    callNativeSync(req) {
      const res = prompt(JSON.stringify(req));
      if (res) {
        const r = JSON.parse(res);
        if (r.code === 0 /* SUCCESS */) {
          r.isSuccess = () => true;
          const hashData = r.data !== null && r.data !== void 0;
          r.hasData = () => hashData;
          return r;
        } else {
          throw new Error(r.msg ?? "Unknown error, res: ");
        }
      }
      throw new Error("Unknown error");
    }
  };
} else {
  jsBridge = {
    callNative() {
      return new Promise((_, reject) => {
        reject("Cannot find JavaScript Bridge!!!");
      });
    },
    callNativeSync() {
      return {
        code: 7 /* FAILED */,
        msg: "Cannot find JavaScript Bridge!!!"
      };
    }
  };
}
var bridge_default = jsBridge;

export {
  bridge_default
};
//# sourceMappingURL=chunk-GXHJCCLG.mjs.map