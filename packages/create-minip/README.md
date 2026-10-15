# create-minip

Create a Vite frontend project ready to build and install in
[Minip](https://github.com/Yosorable/minip).

## Usage

Requires Node.js 20.19+ or 22.12+.

```sh
npm create minip@latest my-app
cd my-app
npm run dev
```

Choose a framework and JavaScript or TypeScript. The tool creates the project,
adds the Minip SDK and Vite plugin, generates `app.json`, and installs dependencies.
Then `dev` starts Vite and prints a development QR code. Scan it with Minip on
the same network to use native APIs while Vite updates the app as you edit.
Use a Minip app build that supports development sessions.

You can also select a template without prompts:

```sh
npm create minip@latest my-app -- --template vue-ts
pnpm create minip my-app --template react-ts
```

Use `--no-install` to install dependencies yourself. Run `--help` for the template
list. Existing non-empty directories are never overwritten; an otherwise empty
Git repository is also supported.

The package manager is detected from the command that launches the tool. npm,
pnpm, Yarn, and Bun are supported; direct Node invocations default to npm.

## Scope

Templates and framework dependencies come from the pinned `create-vite` package.
The framework and language choices are discovered from its bundled `template-*`
directories. Minip does not maintain copies of those templates. External framework
generators, SSR starters, and framework-specific variants such as React Compiler
are not offered by this tool.

The resulting project keeps the upstream framework source and build command.
Minip adds its plugin to the Vite configuration and a `pack` script. Use `dev`
for development inside Minip, `build` for the installation archive, and `pack`
for building and serving that archive. Browser preview remains available; native
APIs require Minip with bridge runtime version 1.

Development sessions do not install a project. Native storage and permissions
use `appId`, so development and installed copies with the same ID share native
data. Rescan after changing native settings in `app.json`, such as tabs or
navigation. Installing a built update still requires rebuilding and scanning.

Existing Vite projects can install
[`vite-plugin-minip`](https://www.npmjs.com/package/vite-plugin-minip) directly.
Minip itself is not restricted to the frameworks offered by the project creator.

## Maintaining and publishing

`create-vite` is pinned to 8.3.0 (Vite 7 templates) so a template change cannot
silently break initialization. The Vite 8 template set in create-vite 9.2.1
currently conflicts with Qwik's Vite peer dependency.
When updating it, verify the bundled templates and their generated Vite configs.
The `minip` field in this package's `package.json` specifies the SDK and plugin
versions written to generated projects.

For the initial release, publish `minip-bridge` 2.0.0 and `vite-plugin-minip` 1.0.0
before publishing `create-minip` 1.0.0. The generated dependencies must be available
on npm before users run the creator.
