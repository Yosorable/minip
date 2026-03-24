import { Match, Switch, lazy } from "solid-js";
import ApiListView from "./views/ApiListView";
import ApiView from "./views/ApiView";
import PageNotFound from "./views/PageNotFound";

const params = new URLSearchParams(window.location.search);

function App() {
  const page = params.get("page");
  return (
    <div class="fade-in">
      <Switch fallback={<PageNotFound />}>
        <Match when={!page}>
          <ApiListView />
        </Match>
        <Match when={page === "api"}>
          <ApiView category={params.get("category")!} />
        </Match>
        <Match when={page === "Categories"}>
          {lazy(() => import("./views/StorageSender"))()}
        </Match>
        <Match when={page === "Profile"}>
          {lazy(() => import("./views/StorageReceiver"))()}
        </Match>
        <Match when={page === "Settings"}>
          {lazy(() => import("./views/StorageStatus"))()}
        </Match>
        <Match when={page === "MiniApp"}>
          {lazy(() => import("./views/MiniApp"))()}
        </Match>
        <Match when={page === "SQLite"}>
          {lazy(() => import("./views/SQLite"))()}
        </Match>
        <Match when={page === "FileSystem"}>
          {lazy(() => import("./views/FileSystem"))()}
        </Match>
      </Switch>
    </div>
  );
}

export default App;
