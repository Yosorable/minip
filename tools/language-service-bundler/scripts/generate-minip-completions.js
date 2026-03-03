const ts = require('typescript');
const fs = require('fs');
const path = require('path');

const packages = {
  'minip-bridge': path.resolve(__dirname, '../node_modules/minip-bridge/dist/index.d.mts'),
  'minip-bridge/fs': path.resolve(__dirname, '../node_modules/minip-bridge/dist/fs/index.d.mts'),
  'minip-bridge/path': path.resolve(__dirname, '../node_modules/minip-bridge/dist/path/index.d.mts'),
};

function getSignature(node, sourceFile) {
  const printer = ts.createPrinter({ removeComments: true });

  if (ts.isFunctionDeclaration(node)) {
    const params = node.parameters.map(p => {
      const name = p.name.getText(sourceFile);
      const optional = p.questionToken ? '?' : '';
      const type = p.type ? ': ' + p.type.getText(sourceFile) : '';
      return name + optional + type;
    }).join(', ');
    const ret = node.type ? node.type.getText(sourceFile) : 'void';
    return `(${params}) => ${ret}`;
  }

  if (ts.isVariableDeclaration(node)) {
    const type = node.type ? node.type.getText(sourceFile) : 'unknown';
    const init = node.initializer ? ' = ' + node.initializer.getText(sourceFile) : '';
    return type + init;
  }

  if (ts.isEnumDeclaration(node)) {
    return 'enum';
  }

  return '';
}

function getJSDoc(node, sourceFile) {
  const text = sourceFile.getFullText();
  const comments = ts.getLeadingCommentRanges(text, node.getFullStart());
  if (!comments) return undefined;

  for (const c of comments) {
    if (c.kind === ts.SyntaxKind.MultiLineCommentTrivia) {
      const raw = text.substring(c.pos, c.end);
      if (raw.startsWith('/**')) {
        return raw
          .replace(/^\/\*\*\s*/, '')
          .replace(/\s*\*\/$/, '')
          .replace(/^\s*\* ?/gm, '')
          .trim();
      }
    }
  }
  return undefined;
}

function getLSPKind(node) {
  if (ts.isFunctionDeclaration(node)) return 3; // Function
  if (ts.isVariableDeclaration(node)) {
    const declList = node.parent;
    if (declList && ts.isVariableDeclarationList(declList)) {
      if (declList.flags & ts.NodeFlags.Const) return 21; // Constant
    }
    return 6; // Variable
  }
  if (ts.isEnumDeclaration(node)) return 13; // Enum
  return 6; // Variable
}

function makeInsertText(node, sourceFile) {
  if (ts.isFunctionDeclaration(node)) {
    const name = node.name.getText(sourceFile);
    const requiredParams = node.parameters.filter(p => !p.questionToken && !p.initializer);
    if (requiredParams.length === 0) return name + '()';
    return name + '($0)';
  }
  return undefined;
}

function parseFile(filePath) {
  const source = fs.readFileSync(filePath, 'utf-8');
  const sourceFile = ts.createSourceFile(filePath, source, ts.ScriptTarget.Latest, true, ts.ScriptKind.MTS);
  const items = [];
  const exportedNames = new Set();

  // Find export statement to know what's actually exported
  ts.forEachChild(sourceFile, node => {
    if (ts.isExportDeclaration(node) && node.exportClause && ts.isNamedExports(node.exportClause)) {
      for (const el of node.exportClause.elements) {
        exportedNames.add(el.name.getText(sourceFile));
      }
    }
  });

  // Collect declarations
  const declarations = new Map();
  ts.forEachChild(sourceFile, node => {
    if (ts.isFunctionDeclaration(node) && node.name) {
      const name = node.name.getText(sourceFile);
      // For overloaded functions, keep only the first (most common) signature
      if (!declarations.has(name)) {
        declarations.set(name, node);
      }
    } else if (ts.isVariableStatement(node)) {
      for (const decl of node.declarationList.declarations) {
        if (ts.isIdentifier(decl.name)) {
          const name = decl.name.getText(sourceFile);
          declarations.set(name, decl);
        }
      }
    } else if (ts.isEnumDeclaration(node) && node.name) {
      const name = node.name.getText(sourceFile);
      declarations.set(name, node);
    }
  });

  // Build items for exported names
  for (const [name, node] of declarations) {
    if (exportedNames.size > 0 && !exportedNames.has(name)) continue;

    const item = {
      label: name,
      kind: getLSPKind(node),
      detail: getSignature(node, sourceFile),
    };

    const insertText = makeInsertText(node, sourceFile);
    if (insertText) {
      item.insertText = insertText;
      item.insertTextFormat = 2; // Snippet
    }

    const doc = getJSDoc(node, sourceFile);
    if (doc) {
      item.documentation = doc;
    }

    items.push(item);
  }

  return items;
}

// Main
const result = {};
for (const [pkg, filePath] of Object.entries(packages)) {
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(1);
  }
  result[pkg] = parseFile(filePath);
  console.log(`${pkg}: ${result[pkg].length} exports`);
}

const outPath = path.resolve(__dirname, '../src/minip-bridge-completions.json');
fs.writeFileSync(outPath, JSON.stringify(result, null, 2));
console.log(`Written to ${outPath}`);

// Also output raw .d.mts content for TypeScript type checking at runtime
const declarations = {};
for (const [pkg, filePath] of Object.entries(packages)) {
  declarations[pkg] = fs.readFileSync(filePath, 'utf-8');
}
const declPath = path.resolve(__dirname, '../src/minip-bridge-declarations.json');
fs.writeFileSync(declPath, JSON.stringify(declarations, null, 2));
console.log(`Declarations written to ${declPath}`);
