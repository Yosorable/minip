export type HUDType = "success" | "error" | "progress" | "banner";

/**
 * @param title works only in banner type,
 * otherwise it will be concatenated with the message parameter using "\n"
 * @param delay ms, doesn't work in banner and progress type
 * @param interaction enable or disable hud background mask, default value is true (hide mask),
 * doesn't work in banner type
 */
export interface ShowHUDRequest {
  type: HUDType;
  title?: string;
  message?: string;
  delay?: number;
  interaction?: boolean;
}

export interface AlertInput {
  key: string;
  title?: string;
  type: "text" | "number" | "password";
  defaultValue?: string
}

/**
 * @param title use key if not set
 * @param key callback arg
 */
export interface AlertAction {
  title?: string;
  style?: "cancel" | "destructive";
  key: string;
}
export interface AlertConfig {
  title?: string;
  message?: string;
  preferredStyle?: "alert" | "actionSheet";
  inputs?: AlertInput[];
  actions: AlertAction[];
}

export interface SingleColumnPickerConfig {
  index: number;
  column: string[];
}

export interface MultipleColumnsPickerConfig {
  index: number[];
  columns: string[][];
}

/**
 * @param dateFormat datetime format string, like: "yyyy-MM-dd", "HH:mm:ss"
 */
export interface DateAndTimePickerConfig {
  start?: string;
  end?: string;
  value?: string;
  dateFormat?: string;
}
