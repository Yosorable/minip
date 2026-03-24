import { createSignal, onCleanup, onMount } from "solid-js";

interface StorageItem {
  key: string;
  value: string | null;
}

export default function StorageStatus() {
  const [allItems, setAllItems] = createSignal<StorageItem[]>([]);
  const [eventCount, setEventCount] = createSignal(0);
  const [lastEvent, setLastEvent] = createSignal<string | null>(null);

  const refreshAll = () => {
    const items: StorageItem[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key) {
        items.push({ key, value: localStorage.getItem(key) });
      }
    }
    setAllItems(items);
  };

  onMount(() => {
    refreshAll();

    const handler = (e: StorageEvent) => {
      setEventCount((c) => c + 1);
      setLastEvent(
        `[${new Date().toLocaleTimeString()}] ${JSON.stringify(e.key)}: ${JSON.stringify(e.oldValue)} → ${JSON.stringify(e.newValue)}`,
      );
      refreshAll();
    };

    window.addEventListener("storage", handler);
    onCleanup(() => window.removeEventListener("storage", handler));
  });

  return (
    <div style={{ padding: "1rem" }}>
      <div
        style={{
          "font-size": ".8rem",
          color: "gray",
          "margin-bottom": ".5rem",
          "padding-left": "12px",
        }}
      >
        Storage Status (Settings Tab)
      </div>
      <div class="list-background" style={{ padding: "12px" }}>
        <p style={{ margin: "0 0 8px 0", "font-size": ".85rem" }}>
          This tab also listens for <code>storage</code> events and shows all
          localStorage contents.
        </p>
        <div
          style={{
            display: "flex",
            "justify-content": "space-between",
            "align-items": "center",
            "margin-bottom": "8px",
          }}
        >
          <span style={{ "font-size": ".85rem" }}>
            Storage events received: <b>{eventCount()}</b>
          </span>
          <button onclick={refreshAll}>Refresh</button>
        </div>
        {lastEvent() && (
          <div
            style={{
              "font-size": ".75rem",
              color: "gray",
              "margin-bottom": "8px",
            }}
          >
            Last: {lastEvent()}
          </div>
        )}
      </div>

      <div
        style={{
          "font-size": ".8rem",
          color: "gray",
          "margin-top": "1rem",
          "margin-bottom": ".5rem",
          "padding-left": "12px",
        }}
      >
        All localStorage Items ({allItems().length})
      </div>
      <div class="list-background" style={{ padding: "12px" }}>
        {allItems().length === 0 ? (
          <div
            style={{
              color: "gray",
              "font-style": "italic",
              "font-size": ".85rem",
            }}
          >
            localStorage is empty
          </div>
        ) : (
          allItems().map((item, i) => (
            <>
              <div
                style={{
                  display: "flex",
                  "justify-content": "space-between",
                  padding: "4px 0",
                  "font-size": ".85rem",
                }}
              >
                <code>{item.key}</code>
                <code style={{ color: "gray" }}>{item.value}</code>
              </div>
              {i < allItems().length - 1 && <hr />}
            </>
          ))
        )}
      </div>
    </div>
  );
}
