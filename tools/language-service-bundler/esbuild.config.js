const path = require('path');
const esbuild = require('esbuild');

const outputPath = path.resolve(__dirname, '../../minip/Resources/LanguageServiceBundles');
const emptyShim = path.resolve(__dirname, 'shims/node-empty.js');

// Map all Node builtins to an empty shim so they get inlined as {}
const builtins = require('module').builtinModules;
const alias = {};
for (const mod of builtins) {
  alias[mod] = emptyShim;
  alias[`node:${mod}`] = emptyShim;
}
// Also handle sub-paths like fs/promises
alias['fs/promises'] = emptyShim;

const shared = {
  bundle: true,
  minify: true,
  format: 'iife',
  platform: 'neutral',
  target: 'es2015',
  mainFields: ['module', 'main'],
  alias,
};

Promise.all([
  esbuild.build({
    ...shared,
    entryPoints: ['./src/html-bridge.js'],
    outfile: path.join(outputPath, 'htmlLanguageService.js'),
  }),
  esbuild.build({
    ...shared,
    entryPoints: ['./src/css-bridge.js'],
    outfile: path.join(outputPath, 'cssLanguageService.js'),
  }),
  esbuild.build({
    ...shared,
    entryPoints: ['./src/js-bridge.js'],
    outfile: path.join(outputPath, 'jsLanguageService.js'),
  }),
]).then(() => {
  console.log('All bundles built successfully.');
}).catch((e) => {
  console.error(e);
  process.exit(1);
});
