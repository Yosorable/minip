import { render } from "solid-js/web";
import "./index.css";
import App from "./App.tsx";

const root = document.getElementById("root");

root!.addEventListener("dblclick", (e) => e.preventDefault());
render(() => <App />, root!);
