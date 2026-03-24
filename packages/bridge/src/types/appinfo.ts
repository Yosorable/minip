export interface AppInfo {
  name: string;
  appId: string;
  author?: string;
  website?: string;
  icon?: string;
  version?: string; // v{x.x.x}, like v0.0.1
  description?: string;
  homepage: string;
  title?: string; // homepage title
  pages?: PageConfig[]; // unused
  tabs?: TabConfig[];
  navigationBarStatus?: string; // display (default), hidden
  colorScheme?: string; // dark, light (default auto)

  // can be overridden in PageConfig
  backgroundColor?: string; // hex string
  navigationBarColor?: string;
  tintColor?: string; // hex string

  // web server
  webServerEnabled?: boolean;
  // orientation
  landscape?: boolean;

  // file list
  files?: File[];
}

interface PageConfig {
  path: string;
  title?: string;
  scrollable?: boolean;

  // override
  backgroundColor?: string;
  navigationBarColor?: string;
}

interface TabConfig {
  path: string;
  title: string;
  systemImage: string;
}

interface File {
  name: string;
  path: string;
  hash: string;
}
