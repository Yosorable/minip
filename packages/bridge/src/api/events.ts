export type PageShowReason = "show" | "foreground";
export type PageHideReason = "hide" | "destroy" | "background";

export interface AppPageShowEvent extends CustomEvent {
  detail: { reason: PageShowReason };
}

export interface AppPageHideEvent extends CustomEvent {
  detail: { reason: PageHideReason; isAppClosing?: boolean };
}

export function onAppPageShow(
  callback: (e: AppPageShowEvent) => void,
): () => void {
  const handler = callback as EventListener;
  window.addEventListener("appPageShow", handler);
  return () => window.removeEventListener("appPageShow", handler);
}

export function onAppPageHide(
  callback: (e: AppPageHideEvent) => void,
): () => void {
  const handler = callback as EventListener;
  window.addEventListener("appPageHide", handler);
  return () => window.removeEventListener("appPageHide", handler);
}
