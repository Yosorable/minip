export interface DeviceInfo {
  language: string;
  model: string;
  system: string;
  screen: ScreenInfo;
  safeAreaInfo: SafeAreaInfo;
}

interface ScreenInfo {
  width: number;
  height: number;
}

interface SafeAreaInfo {
  left: number;
  right: number;
  top: number;
  bottom: number;
}
