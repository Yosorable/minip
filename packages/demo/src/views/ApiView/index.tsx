import { Show, createSignal } from "solid-js";
import apis from "../../minip-apis";

export default function ApiView(props: { category: string }) {
  const categoryDetail = apis.find((cat) => cat.category === props.category);
  const [res, setRes] = createSignal("");

  if (!categoryDetail) {
    return (
      <div style={{ "text-align": "center" }}>
        Error
      </div>
    );
  }
  if (categoryDetail.init) {
    categoryDetail.init((r) => {
      setRes(res() + r + "\n");
    });
  }
  return (
    <>
      <Show when={!categoryDetail.hideResBox}>
        <div class="res-div">{res()}</div>
      </Show>
      <div
        style={{
          display: "flex",
          "flex-direction": "column",
          gap: "5px",
          "margin-left": "8px",
          "margin-right": "8px",
          "margin-top": "10px",
        }}
      >
        {categoryDetail.items?.map((item) => (
          <button
            onClick={(e) =>
              item.exec(function (r) {
                if (typeof r === "string") {
                  setRes(r);
                  return;
                }
                setRes(JSON.stringify(r));
              }, e)
            }
          >
            {item.name}
          </button>
        ))}
      </div>
      <Show when={categoryDetail.view}>
        <div
          style={{
            display: "flex",
            "margin-left": "8px",
            "margin-right": "8px",
            "margin-top": "10px",
          }}
          innerHTML={categoryDetail.view}
        ></div>
      </Show>
      <div
        id="more"
        style={{
          display: "flex",
          "margin-left": "8px",
          "margin-right": "8px",
          "margin-top": "10px",
        }}
      ></div>
    </>
  );
}
