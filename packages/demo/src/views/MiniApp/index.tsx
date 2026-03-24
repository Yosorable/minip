import { createSignal, onMount } from "solid-js";
import {
  getAppInfo,
  getInstalledAppList,
  getKVStorage,
  installApp,
  setKVStorage,
  updateCurrentApp,
} from "minip-bridge";

export default function MiniApp() {
  const key = "miniapp-download-url";
  const [res, setRes] = createSignal("");
  const [url, setURL] = createSignal("");
  const [isInstalling, setIsInstalling] = createSignal(false);
  onMount(() => {
    getKVStorage(key).then((res) => {
      setURL((curr) => res ?? curr);
    });
  });

  function install() {
    if (isInstalling()) return;
    setIsInstalling(true);
    setRes("Installing...");
    installApp(url())
      .then((r) => {
        setRes(JSON.stringify(r));
        setKVStorage(key, url());
      })
      .catch((err) =>
        setRes(err ? err.message ?? JSON.stringify(err) : "Unknown error"),
      )
      .finally(() => setIsInstalling(false));
  }
  return (
    <div class="fade-in">
      <div class="res-div">
        <div>{res()}</div>
      </div>
      <div>
        <input
          style={{
            width: "100%",
            "line-height": "2rem",
            "font-size": "1rem",
            "margin-top": ".5rem",
          }}
          value={url()}
          onChange={(e) => setURL(e.target.value)}
        />
      </div>
      <div
        style={{
          "margin-top": ".5rem",
          display: "flex",
          gap: "5px",
        }}
      >
        <button onClick={install} disabled={isInstalling()}>
          install
        </button>
        <button
          onClick={() => window.location.reload()}
          disabled={isInstalling()}
        >
          refresh
        </button>
      </div>

      <div>
        <button
          onClick={() =>
            getInstalledAppList().then((r) => {
              setRes(JSON.stringify(r));
            })
          }
        >
          app list
        </button>
      </div>

      <div>
        <button
          onClick={() =>
            getAppInfo().then((r) => {
              setRes(JSON.stringify(r));
            })
          }
        >
          current app info
        </button>
      </div>

      <div>
        <button
          onClick={() =>
            updateCurrentApp("https://minip-demo.lzyl.win/down")
              .then((r) => {
                setRes(JSON.stringify(r));
              })
              .catch((err) =>
                setRes(
                  err ? err.message ?? JSON.stringify(err) : "Unknown error",
                ),
              )
          }
        >
          update current app
        </button>
      </div>
    </div>
  );
}
