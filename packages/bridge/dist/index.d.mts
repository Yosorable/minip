type HUDType = "success" | "error" | "progress" | "banner";
/**
 * @param title works only in banner type,
 * otherwise it will be concatenated with the message parameter using "\n"
 * @param delay ms, doesn't work in banner and progress type
 * @param interaction enable or disable hud background mask, default value is true (hide mask),
 * doesn't work in banner type
 */
interface ShowHUDRequest {
    type: HUDType;
    title?: string;
    message?: string;
    delay?: number;
    interaction?: boolean;
}
interface AlertInput {
    key: string;
    title?: string;
    type: "text" | "number" | "password";
    defaultValue?: string;
}
/**
 * @param title use key if not set
 * @param key callback arg
 */
interface AlertAction {
    title?: string;
    style?: "cancel" | "destructive";
    key: string;
}
interface AlertConfig {
    title?: string;
    message?: string;
    preferredStyle?: "alert" | "actionSheet";
    inputs?: AlertInput[];
    actions: AlertAction[];
}
interface SingleColumnPickerConfig {
    index: number;
    column: string[];
}
interface MultipleColumnsPickerConfig {
    index: number[];
    columns: string[][];
}
/**
 * @param dateFormat datetime format string, like: "yyyy-MM-dd", "HH:mm:ss"
 */
interface DateAndTimePickerConfig {
    start?: string;
    end?: string;
    value?: string;
    dateFormat?: string;
}

interface ShowAlertData {
    action: string;
    inputs: Record<string, string>;
}

interface AppInfo {
    name: string;
    appId: string;
    author?: string;
    website?: string;
    icon?: string;
    version?: string;
    description?: string;
    homepage: string;
    title?: string;
    pages?: PageConfig[];
    tabs?: TabConfig[];
    navigationBarStatus?: string;
    colorScheme?: string;
    backgroundColor?: string;
    navigationBarColor?: string;
    tintColor?: string;
    webServerEnabled?: boolean;
    landscape?: boolean;
    files?: File[];
}
interface PageConfig {
    path: string;
    title?: string;
    scrollable?: boolean;
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

interface DeviceInfo {
    language: string;
    brand: string;
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

declare function navigateTo(data: {
    page: string;
    title?: string;
}): Promise<void>;
declare function navigateBack(delta?: number): Promise<void>;
declare function redirectTo(data: {
    page: string;
    title?: string;
}): Promise<void>;
declare function openWebsite(url: string): Promise<void>;
declare function openSettings(): Promise<void>;

declare function closeApp(): Promise<void>;
declare function showAppDetail(): Promise<void>;
declare function installApp(url: string): Promise<void>;
declare function getInstalledAppList(): Promise<AppInfo[]>;
declare function getAppInfo(): Promise<AppInfo>;
declare function updateCurrentApp(url: string): Promise<void>;

declare function setNavigationBarTitle(title: string): Promise<void>;
declare function setNavigationBarColor(config: {
    foregroundColor: string;
    backgroundColor: string;
}): Promise<void>;
declare function enablePullDownRefresh(): Promise<void>;
declare function disablePullDownRefresh(): Promise<void>;
declare function onPullDownRefresh(callback: (e: Event) => any): void;
declare function startPullDownRefresh(): Promise<void>;
declare function stopPullDownRefresh(): Promise<void>;
declare function showHUD(req: ShowHUDRequest): Promise<void>;
declare function hideHUD(): Promise<void>;
declare function showAlert(config: AlertConfig): Promise<ShowAlertData | null>;
declare function previewImage(url: string, options?: {
    sourceImage?: HTMLImageElement;
}): Promise<void>;
declare function previewVideo(url: string): Promise<void>;
declare function showPicker(type: "singleColumn", data: SingleColumnPickerConfig): Promise<number | null>;
declare function showPicker(type: "multipleColumns", data: MultipleColumnsPickerConfig): Promise<number[] | null>;
declare function showPicker(type: "date" | "time", data: DateAndTimePickerConfig): Promise<string | null>;

declare function getKVStorage(key: string): Promise<string | null>;
declare function setKVStorage(key: string, value: string): Promise<void>;
declare function deleteKVStorage(key: string): Promise<void>;
declare function clearKVStorage(): Promise<void>;
declare function getKVStorageSync(key: string): string | null;
declare function setKVStorageSync(key: string, value: string): void;
declare function deleteKVStorageSync(key: string): void;
declare function clearKVStorageSync(): void;

declare function vibrate(type?: "light" | "medium" | "heavy"): Promise<void>;
declare function getClipboardData(): Promise<string | null>;
declare function setClipboardData(data: string): Promise<void>;
declare function scanQRCode(): Promise<string | null>;
declare function getDeviceInfo(): Promise<DeviceInfo>;
declare function getDeviceInfoSync(): DeviceInfo;

interface SQLiteRunResult {
    changes: number | bigint;
    lastInsertRowid: number | bigint;
}
type SQLiteExecutionResult = {
    reader: true;
    entityData: Record<string, unknown>[];
} | {
    reader: false;
    runRes: SQLiteRunResult;
};
declare function sqliteOpenDB(path: string): Promise<number>;
declare function sqliteCloseDB(dbKey: number): Promise<void>;
declare function sqlitePrepare(dbKey: number, sql: string): Promise<{
    stmtKey: number;
    reader: boolean;
}>;
declare function sqliteStatementAll(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<Record<string, unknown>[]>;
declare function sqliteStatementRun(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<SQLiteRunResult>;
declare function sqliteExecute(dbKey: number, sql: string, parameters: ReadonlyArray<unknown>): Promise<SQLiteExecutionResult>;
declare function sqliteCreateIterator(dbKey: number, stmtKey: number, parameters: ReadonlyArray<unknown>): Promise<void>;
declare function sqliteIteratorNext(dbKey: number, stmtKey: number): Promise<Record<string, unknown> | null>;
declare function sqliteIteratorRelease(dbKey: number, stmtKey: number): Promise<void>;

declare function getMemoryStorage(key: string): Promise<string | null>;
declare function setMemoryStorage(key: string, value: string): Promise<void>;
declare function setMemoryStorageIfNotExist(key: string, value: string): Promise<boolean>;
declare function removeMemoryStorage(key: string): Promise<void>;
declare function clearMemoryStorage(): Promise<void>;

type PageShowReason = "show" | "foreground";
type PageHideReason = "hide" | "destroy" | "background";
interface AppPageShowEvent extends CustomEvent {
    detail: {
        reason: PageShowReason;
    };
}
interface AppPageHideEvent extends CustomEvent {
    detail: {
        reason: PageHideReason;
        isAppClosing?: boolean;
    };
}
declare function onAppPageShow(callback: (e: AppPageShowEvent) => void): () => void;
declare function onAppPageHide(callback: (e: AppPageHideEvent) => void): () => void;

declare const MinipErrorCode: {
    readonly INVALID_ARGUMENT: "INVALID_ARGUMENT";
    readonly API_NOT_FOUND: "API_NOT_FOUND";
    readonly NOT_SUPPORTED: "NOT_SUPPORTED";
    readonly NOT_FOUND: "NOT_FOUND";
    readonly ALREADY_EXISTS: "ALREADY_EXISTS";
    readonly PERMISSION_DENIED: "PERMISSION_DENIED";
    readonly INVALID_STATE: "INVALID_STATE";
    readonly IO_ERROR: "IO_ERROR";
    readonly DATABASE_ERROR: "DATABASE_ERROR";
    readonly BRIDGE_UNAVAILABLE: "BRIDGE_UNAVAILABLE";
    readonly BRIDGE_ERROR: "BRIDGE_ERROR";
    readonly INVALID_RESPONSE: "INVALID_RESPONSE";
    readonly INTERNAL_ERROR: "INTERNAL_ERROR";
};
type MinipErrorCode = (typeof MinipErrorCode)[keyof typeof MinipErrorCode];
interface MinipErrorOptions {
    api?: string;
    details?: Record<string, unknown>;
    cause?: unknown;
}
/** An API or bridge failure. Branch on code, never on the message text. */
declare class MinipError extends Error {
    readonly code: string;
    readonly api?: string;
    readonly details?: Record<string, unknown>;
    readonly cause?: unknown;
    constructor(code: string, message: string, options?: MinipErrorOptions);
}

interface WebKitCallable {
    postMessage(data: string): Promise<string>;
}
declare global {
    interface Window {
        webkit?: {
            messageHandlers?: {
                MinipNativeInteractionV2?: WebKitCallable;
            };
        };
        __minipPreviewElement?: HTMLImageElement;
    }
}

export { type AlertAction, type AlertConfig, type AlertInput, type AppInfo, type AppPageHideEvent, type AppPageShowEvent, type DateAndTimePickerConfig, type DeviceInfo, type HUDType, MinipError, MinipErrorCode, type MinipErrorOptions, type MultipleColumnsPickerConfig, type PageHideReason, type PageShowReason, type SQLiteExecutionResult, type SQLiteRunResult, type ShowAlertData, type ShowHUDRequest, type SingleColumnPickerConfig, clearKVStorage, clearKVStorageSync, clearMemoryStorage, closeApp, deleteKVStorage, deleteKVStorageSync, disablePullDownRefresh, enablePullDownRefresh, getAppInfo, getClipboardData, getDeviceInfo, getDeviceInfoSync, getInstalledAppList, getKVStorage, getKVStorageSync, getMemoryStorage, hideHUD, installApp, navigateBack, navigateTo, onAppPageHide, onAppPageShow, onPullDownRefresh, openSettings, openWebsite, previewImage, previewVideo, redirectTo, removeMemoryStorage, scanQRCode, setClipboardData, setKVStorage, setKVStorageSync, setMemoryStorage, setMemoryStorageIfNotExist, setNavigationBarColor, setNavigationBarTitle, showAlert, showAppDetail, showHUD, showPicker, sqliteCloseDB, sqliteCreateIterator, sqliteExecute, sqliteIteratorNext, sqliteIteratorRelease, sqliteOpenDB, sqlitePrepare, sqliteStatementAll, sqliteStatementRun, startPullDownRefresh, stopPullDownRefresh, updateCurrentApp, vibrate };
