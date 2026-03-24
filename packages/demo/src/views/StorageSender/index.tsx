import { createSignal } from "solid-js";

export default function StorageSender() {
  const [input, setInput] = createSignal("");
  const [log, setLog] = createSignal<string[]>([]);

  const sendMessage = () => {
    const value = input() || `hello-${Date.now()}`;
    localStorage.setItem("cross-tab-test", value);
    setLog((prev) => [
      ...prev,
      `[${new Date().toLocaleTimeString()}] SET "cross-tab-test" = "${value}"`,
    ]);
    setInput("");
  };

  const clearStorage = () => {
    localStorage.removeItem("cross-tab-test");
    setLog((prev) => [
      ...prev,
      `[${new Date().toLocaleTimeString()}] REMOVED "cross-tab-test"`,
    ]);
  };

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
        Storage Sender (Categories Tab)
      </div>
      <div class="list-background" style={{ padding: "12px" }}>
        <p style={{ margin: "0 0 8px 0", "font-size": ".85rem" }}>
          Write to <code>localStorage</code>, then switch to Profile tab to see
          if <code>storage</code> event fires.
        </p>
        <input
          type="text"
          placeholder="Enter a value (or leave empty)"
          value={input()}
          onInput={(e) => setInput(e.target.value)}
          style={{
            width: "100%",
            padding: "8px",
            "border-radius": "8px",
            border: "1px solid gray",
            "font-size": "1rem",
            "margin-bottom": "8px",
          }}
        />
        <div style={{ display: "flex", gap: "8px" }}>
          <button onclick={sendMessage} style={{ flex: 1 }}>
            Set Value
          </button>
          <button onclick={clearStorage} style={{ flex: 1 }}>
            Remove Key
          </button>
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
        Send Log
      </div>
      <div class="res-div" style={{ "border-radius": "12px", padding: "8px" }}>
        {log().map((line) => (
          <div>{line}</div>
        ))}
      </div>
    </div>
  );
}
