// Resolves and concatenates TypeScript lib.d.ts files for a given ES target + DOM.
// Output: src/lib-es2020-dts.json (a JSON string ready to be required)

const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '../node_modules/typescript/lib');

function resolveLib(name, visited = new Set()) {
  if (visited.has(name)) return [];
  visited.add(name);

  const fileName = 'lib.' + name + '.d.ts';
  const filePath = path.join(libDir, fileName);
  if (!fs.existsSync(filePath)) return [];

  const content = fs.readFileSync(filePath, 'utf-8');

  // Resolve references first (depth-first)
  const refs = [];
  const re = /\/\/\/\s*<reference\s+lib="([^"]+)"\s*\/>/g;
  let m;
  while ((m = re.exec(content)) !== null) {
    refs.push(...resolveLib(m[1], visited));
  }

  // Strip reference directives and license headers from content
  const cleaned = content
    .replace(/\/\/\/\s*<reference[^>]*\/>\s*\n?/g, '')
    .replace(/\/\*![\s\S]*?\*\/\s*\n?/g, '')
    .trim();

  if (cleaned) {
    refs.push(cleaned);
  }
  return refs;
}

const targets = ['es2020', 'dom', 'dom.iterable', 'dom.asynciterable'];
const visited = new Set();
const parts = [];
for (const target of targets) {
  parts.push(...resolveLib(target, visited));
}
const combined = parts.join('\n\n');

const outPath = path.join(__dirname, '../src/lib-es2020-dts.json');
fs.writeFileSync(outPath, JSON.stringify(combined));

console.log(`Generated ${outPath} (${(combined.length / 1024).toFixed(1)}K)`);
