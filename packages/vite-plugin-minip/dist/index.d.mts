import { PluginOption } from 'vite';

interface MinipPluginOptions {
    /**
     * URL scheme used by the install QR code shown on `vite preview`, producing
     * `<scheme>://install/<url>.zip`. Defaults to `"minip"` so scanning opens the
     * Minip app. Override if your host app registers a different scheme.
     */
    installScheme?: string;
}
declare function minipPlugin(options?: MinipPluginOptions): PluginOption;

export { type MinipPluginOptions, minipPlugin as default };
