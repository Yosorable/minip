import { createSignal, onCleanup, onMount } from "solid-js";

interface StorageEventRecord {
  time: string;
  key: string | null;
  oldValue: string | null;
  newValue: string | null;
  url: string;
}

export default function StorageReceiver() {
  const [events, setEvents] = createSignal<StorageEventRecord[]>([]);
  const [currentValue, setCurrentValue] = createSignal<string | null>(null);
  const [listening, setListening] = createSignal(false);

  onMount(() => {
    setCurrentValue(localStorage.getItem("cross-tab-test"));

    const handler = (e: StorageEvent) => {
      setEvents((prev) => [
        ...prev,
        {
          time: new Date().toLocaleTimeString(),
          key: e.key,
          oldValue: e.oldValue,
          newValue: e.newValue,
          url: e.url,
        },
      ]);
      if (e.key === "cross-tab-test") {
        setCurrentValue(e.newValue);
      }
    };

    window.addEventListener("storage", handler);
    setListening(true);
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
        Storage Receiver (Profile Tab)
      </div>
      <div class="list-background" style={{ padding: "12px" }}>
        <p style={{ margin: "0 0 8px 0", "font-size": ".85rem" }}>
          Listening for <code>window.onstorage</code> events from other tabs.
        </p>
        <div style={{ "font-size": ".85rem", "margin-bottom": "4px" }}>
          Status:{" "}
          <b style={{ color: listening() ? "green" : "red" }}>
            {listening() ? "Listening" : "Not started"}
          </b>
        </div>
        <div style={{ "font-size": ".85rem", "margin-bottom": "4px" }}>
          Current value of <code>"cross-tab-test"</code>:{" "}
          <b>{currentValue() ?? "(null)"}</b>
        </div>
        <div style={{ "font-size": ".85rem" }}>
          Events received: <b>{events().length}</b>
        </div>
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
        Event Log
      </div>
      <div
        class="res-div"
        style={{
          "border-radius": "12px",
          padding: "8px",
          height: "200px",
        }}
      >
        {events().length === 0 ? (
          <div style={{ color: "gray", "font-style": "italic" }}>
            No events yet. Go to Categories tab and set a value.
          </div>
        ) : (
          events().map((evt) => (
            <div style={{ "margin-bottom": "6px", "font-size": ".8rem" }}>
              <div>
                [{evt.time}] key: {JSON.stringify(evt.key)}
              </div>
              <div style={{ "padding-left": "1rem", color: "gray" }}>
                {JSON.stringify(evt.oldValue)} → {JSON.stringify(evt.newValue)}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
