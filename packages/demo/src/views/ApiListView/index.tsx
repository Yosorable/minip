import { Show } from "solid-js";
import apis from "../../minip-apis";
import rightArrow from "../../assets/arrow-right.svg";
import { navigateTo } from "minip-bridge";

export default function ApiListView() {
  return (
    <>
      {/* <h1 style={{ "text-align": "center" }}>Minip Api Categories</h1> */}
      <div
        style={{
          "font-size": ".8rem",
          color: "gray",
          "margin-top": "1rem",
          "text-align": "left",
          "margin-left": "1rem",
          "padding-left": "12px",
        }}
      >
        Minip Api Categories
      </div>
      <div
        style={{
          margin: ".2rem 1rem 1rem 1rem",
        }}
        class="list-background"
      >
        <div>
          {apis.map((item, i) => (
            <>
              <div
                style={{
                  display: "flex",
                  "justify-content": "space-between",
                  "align-items": "center",
                  padding: "4px 13px",
                  margin: 0,
                  "min-height": "35px",
                }}
                onclick={() => {
                  if (item.target) {
                    navigateTo({
                      page: item.target,
                      title: item.category,
                    });
                  } else {
                    navigateTo({
                      page: `index.html?page=api&category=${encodeURIComponent(
                        item.category
                      )}`,
                      title: item.category,
                    });
                  }
                }}
              >
                <div>{item.category}</div>
                <div>
                  <img src={rightArrow} />
                </div>
              </div>
              <Show when={i !== apis.length - 1}>
                <hr />
              </Show>
            </>
          ))}
        </div>
      </div>
    </>
  );
}
