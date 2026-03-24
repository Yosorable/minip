import { previewImage, previewVideo } from "minip-bridge";
import img from "../assets/image.png";
import type { ApiCategory } from "./types";

const media: ApiCategory = {
  category: "Media",
  hideResBox: false,
  view: `<img src="${img}" id="preview-image-source" style="width: 50%; height: auto; margin: 0 auto;" />`,
  items: [
    {
      name: "preview image",
      exec: () => {
        const imgEl = document.querySelector(
          "#preview-image-source",
        ) as HTMLImageElement;
        previewImage(imgEl.src, {
          sourceImage: imgEl,
        });
      },
    },
    {
      name: "play video",
      exec: () => {
        previewVideo("https://media.w3.org/2010/05/sintel/trailer.mp4");
      },
    },
  ],
};

export default media;
