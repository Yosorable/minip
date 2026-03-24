export interface ApiItem {
  name: string;
  exec: (setRes: (value: string) => void, event?: MouseEvent) => void;
}

export interface ApiCategory {
  category: string;
  items?: ApiItem[];
  init?: (setRes: (value: string) => void) => void;
  target?: string;
  hideResBox?: boolean;
  view?: string;
}
