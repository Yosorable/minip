import type { ApiCategory } from "./types";

const http: ApiCategory = {
  category: "HTTP",
  items: [
    {
      name: "get",
      exec: (setRes) => {
        fetch("miniphttps://www.bing.com")
          .then((res) => res.text())
          .then((res) => setRes(res))
          .catch((err) =>
            setRes(
              err ? (err.message ?? JSON.stringify(err)) : "Unknown error",
            ),
          );
      },
    },
  ],
};

export default http;
