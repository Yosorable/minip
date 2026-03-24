const ts = require('typescript');
const completionData = require('./minip-bridge-completions.json');
const declarationFiles = require('./minip-bridge-declarations.json');

const CDN_BASE = 'https://cdn.jsdelivr.net/npm/minip-bridge/dist';

const importSnippets = [
  {
    label: 'import minip-bridge',
    kind: 15,
    detail: 'import * as minip from "minip-bridge"',
    insertText: 'import * as minip from "' + CDN_BASE + '/index.mjs"',
    filterText: 'import minip bridge',
    sortText: '!0',
  },
  {
    label: 'import minip-bridge/fs',
    kind: 15,
    detail: 'import * as fs from "minip-bridge/fs"',
    insertText: 'import * as fs from "' + CDN_BASE + '/fs/index.mjs"',
    filterText: 'import minip bridge fs',
    sortText: '!1',
  },
  {
    label: 'import minip-bridge/path',
    kind: 15,
    detail: 'import * as path from "minip-bridge/path"',
    insertText: 'import * as path from "' + CDN_BASE + '/path/index.mjs"',
    filterText: 'import minip bridge path',
    sortText: '!2',
  },
];

// --- Virtual file system ---

const pkgToVirtualPath = {
  'minip-bridge': '/node_modules/minip-bridge/index.d.ts',
  'minip-bridge/fs': '/node_modules/minip-bridge/fs/index.d.ts',
  'minip-bridge/path': '/node_modules/minip-bridge/path/index.d.ts',
};

const staticFiles = {};
for (const [pkg, content] of Object.entries(declarationFiles)) {
  const vpath = pkgToVirtualPath[pkg];
  if (vpath) staticFiles[vpath] = content;
}

staticFiles['/node_modules/minip-bridge/package.json'] = JSON.stringify({
  name: 'minip-bridge',
  exports: {
    '.': { types: './index.d.ts' },
    './fs': { types: './fs/index.d.ts' },
    './path': { types: './path/index.d.ts' },
  }
});

// Standard ES2020 + DOM lib.d.ts
var libEs2020 = require('./lib-es2020-dts.json');
staticFiles['/lib.d.ts'] = libEs2020;

const USER_FILE = '/src/user.js';

const TS_OPTIONS = {
  target: ts.ScriptTarget.ESNext,
  module: ts.ModuleKind.ESNext,
  moduleResolution: ts.ModuleResolutionKind.Bundler,
  allowJs: true,
  checkJs: false,
  noEmit: true,
  strict: false,
  skipLibCheck: true,
  lib: [],
  types: [],
};

// --- Rewrite CDN URLs to bare specifiers ---

function rewriteImports(code) {
  return code.replace(
    /(from\s+["'])(https?:\/\/[^"']*\/npm\/minip-bridge(?:@[^/"']*)?\/(dist\/(?:([^/"']+)\/)?index\.m?js))(["'])/g,
    function(match, prefix, url, distPath, subpkg, suffix) {
      var bare = subpkg ? 'minip-bridge/' + subpkg : 'minip-bridge';
      return prefix + bare + suffix;
    }
  );
}

// --- TypeScript Language Service ---

var currentUserCode = '';

function createLanguageServiceHost() {
  var files = {};

  var injectedLocalFiles = {};

  function updateUserFile(code) {
    currentUserCode = rewriteImports(code);
    if (!files[USER_FILE]) {
      files[USER_FILE] = { content: currentUserCode, version: 1 };
    } else {
      files[USER_FILE].content = currentUserCode;
      files[USER_FILE].version++;
    }
    // Clear previously injected local module stubs so they get regenerated
    for (var p in injectedLocalFiles) {
      delete files[p];
    }
    injectedLocalFiles = {};
  }

  // Init static files
  for (var path in staticFiles) {
    files[path] = { content: staticFiles[path], version: 1 };
  }
  files[USER_FILE] = { content: '', version: 1 };

  var host = {
    getScriptFileNames: function() {
      return Object.keys(files);
    },
    getScriptVersion: function(fileName) {
      return files[fileName] ? String(files[fileName].version) : '0';
    },
    getScriptSnapshot: function(fileName) {
      var f = files[fileName];
      if (!f) return undefined;
      return ts.ScriptSnapshot.fromString(f.content);
    },
    getCurrentDirectory: function() { return '/'; },
    getCompilationSettings: function() { return TS_OPTIONS; },
    getDefaultLibFileName: function() { return '/lib.d.ts'; },
    fileExists: function(f) { return !!files[f]; },
    readFile: function(f) { return files[f] ? files[f].content : undefined; },
    readDirectory: function() { return []; },
    directoryExists: function(d) {
      var keys = Object.keys(files);
      for (var i = 0; i < keys.length; i++) {
        if (keys[i].indexOf(d) === 0) return true;
      }
      return false;
    },
    getDirectories: function() { return []; },
    resolveModuleNames: function(moduleNames, containingFile) {
      return moduleNames.map(function(name) {
        var vpath = pkgToVirtualPath[name];
        if (vpath && files[vpath]) {
          return { resolvedFileName: vpath, isExternalLibraryImport: true };
        }
        // Resolve local relative imports
        if (name.startsWith('./') || name.startsWith('../')) {
          var dir = containingFile.substring(0, containingFile.lastIndexOf('/') + 1);
          var localPath = dir + name.replace(/^\.\//, '');
          if (!files[localPath]) {
            var escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            var namedRe = new RegExp('import\\s*\\{([^}]*)\\}\\s*from\\s*["\']' + escapedName + '["\']');
            var namedMatch = currentUserCode.match(namedRe);
            var parts = ['export default {} as any;'];
            if (namedMatch) {
              var names = namedMatch[1].split(',').map(function(s) { return s.trim().split(/\s+as\s+/)[0].trim(); }).filter(Boolean);
              for (var ni = 0; ni < names.length; ni++) {
                parts.push('export declare var ' + names[ni] + ': any;');
              }
            }
            files[localPath] = { content: parts.join('\n'), version: 1 };
            injectedLocalFiles[localPath] = true;
          }
          return { resolvedFileName: localPath, isExternalLibraryImport: false };
        }
        var resolved = ts.resolveModuleName(name, containingFile, TS_OPTIONS, host);
        return resolved.resolvedModule || undefined;
      });
    },
  };

  return { host: host, updateUserFile: updateUserFile };
}

var lsHost = createLanguageServiceHost();
var languageService = ts.createLanguageService(lsHost.host, ts.createDocumentRegistry());

// --- LSP kind mapping from TS ScriptElementKind ---

function tsKindToLSP(kind) {
  switch (kind) {
    case ts.ScriptElementKind.functionElement: return 3;
    case ts.ScriptElementKind.memberFunctionElement: return 2;
    case ts.ScriptElementKind.memberVariableElement: return 5;
    case ts.ScriptElementKind.memberGetAccessorElement: return 10;
    case ts.ScriptElementKind.memberSetAccessorElement: return 10;
    case ts.ScriptElementKind.variableElement: return 6;
    case ts.ScriptElementKind.localVariableElement: return 6;
    case ts.ScriptElementKind.constElement: return 21;
    case ts.ScriptElementKind.letElement: return 6;
    case ts.ScriptElementKind.classElement: return 7;
    case ts.ScriptElementKind.interfaceElement: return 8;
    case ts.ScriptElementKind.enumElement: return 13;
    case ts.ScriptElementKind.enumMemberElement: return 20;
    case ts.ScriptElementKind.moduleElement: return 9;
    case ts.ScriptElementKind.keyword: return 14;
    case ts.ScriptElementKind.typeElement: return 8;
    case ts.ScriptElementKind.primitiveType: return 25;
    case ts.ScriptElementKind.string: return 15;
    default: return 6;
  }
}

// --- Resolve package from import specifier (for import snippet dedup) ---

function resolvePackage(specifier) {
  if (completionData[specifier]) return specifier;

  var cdnMatch = specifier.match(/\/npm\/(minip-bridge)(?:@[^/]*)?\/(.*?)(?:\.m?js)?$/);
  if (cdnMatch) {
    var pkgName = cdnMatch[1];
    var rest = cdnMatch[2];
    var subpath = rest.replace(/^dist\/?/, '').replace(/\/?index$/, '');
    var key = subpath ? pkgName + '/' + subpath : pkgName;
    if (completionData[key]) return key;
  }

  for (var k of Object.keys(completionData)) {
    if (specifier.includes(k)) return k;
  }
  return null;
}

// --- Parse imports (regex, for import snippet dedup) ---

function parseImportedPackages(text) {
  var pkgs = new Set();
  var re = /from\s+["']([^"']+)["']/g;
  var m;
  while ((m = re.exec(text)) !== null) {
    var resolved = resolvePackage(m[1]);
    if (resolved) pkgs.add(resolved);
  }
  return pkgs;
}

// --- Helpers ---

function posToOffset(text, line, character) {
  var offset = 0;
  for (var i = 0; i < line; i++) {
    var nl = text.indexOf('\n', offset);
    if (nl === -1) break;
    offset = nl + 1;
  }
  return offset + character;
}

function getLinePrefix(text, line, character) {
  var offset = 0;
  for (var i = 0; i < line; i++) {
    var nl = text.indexOf('\n', offset);
    if (nl === -1) break;
    offset = nl + 1;
  }
  return text.substring(offset, offset + character);
}

// --- Expose global service ---

globalThis.JSLanguageService = {
  doComplete: function(uri, text, line, character) {
    try {
      lsHost.updateUserFile(text);

      var linePrefix = getLinePrefix(text, line, character);
      var offset = posToOffset(currentUserCode, line, character);

      // Inside import module specifier string: from "|"
      var textBefore = text.substring(0, posToOffset(text, line, character));
      var moduleStrMatch = textBefore.match(/(?:from|import)\s*["']([^"']*)$/);
      if (moduleStrMatch) {
        var moduleItems = [
          { label: CDN_BASE + '/index.mjs', kind: 9, detail: 'minip-bridge', filterText: 'minip-bridge' },
          { label: CDN_BASE + '/fs/index.mjs', kind: 9, detail: 'minip-bridge/fs', filterText: 'minip-bridge fs' },
          { label: CDN_BASE + '/path/index.mjs', kind: 9, detail: 'minip-bridge/path', filterText: 'minip-bridge path' },
        ];
        return JSON.stringify({ isIncomplete: false, items: moduleItems });
      }

      // Import snippets at line start
      if (/^\s*\S*$/.test(linePrefix) && /^\s*[im]/.test(linePrefix)) {
        var importedPkgs = parseImportedPackages(text);
        var snippetItems = [];
        for (var s = 0; s < importSnippets.length; s++) {
          var pkg = importSnippets[s].label.replace('import ', '');
          if (!importedPkgs.has(pkg)) {
            snippetItems.push(importSnippets[s]);
          }
        }
        if (snippetItems.length > 0) {
          // Also get TS completions and merge
          var tsResult = languageService.getCompletionsAtPosition(USER_FILE, offset, { includeCompletionsForModuleExports: false });
          var items = snippetItems.slice();
          if (tsResult && tsResult.entries) {
            for (var i = 0; i < tsResult.entries.length; i++) {
              var entry = tsResult.entries[i];
              items.push({
                label: entry.name,
                kind: tsKindToLSP(entry.kind),
                sortText: entry.sortText,
              });
            }
          }
          return JSON.stringify({ isIncomplete: false, items: items });
        }
      }

      // Use TypeScript Language Service for completions
      var completions = languageService.getCompletionsAtPosition(USER_FILE, offset, {
        includeCompletionsForModuleExports: false,
        includeCompletionsWithInsertText: true,
      });

      if (!completions || !completions.entries) {
        return JSON.stringify({ isIncomplete: false, items: [] });
      }

      var items = [];
      for (var i = 0; i < completions.entries.length; i++) {
        var entry = completions.entries[i];
        var item = {
          label: entry.name,
          kind: tsKindToLSP(entry.kind),
          sortText: entry.sortText,
        };

        // Get detail for top items (avoid fetching all for performance)
        if (i < 50) {
          var details = languageService.getCompletionEntryDetails(USER_FILE, offset, entry.name, undefined, undefined, undefined, undefined);
          if (details) {
            var displayParts = details.displayParts;
            if (displayParts) {
              item.detail = displayParts.map(function(p) { return p.text; }).join('');
            }
            if (details.documentation && details.documentation.length > 0) {
              item.documentation = details.documentation.map(function(p) { return p.text; }).join('');
            }
          }
        }

        if (entry.insertText) {
          item.insertText = entry.insertText;
        }

        // Include replacementSpan as textEdit so the client knows exactly what range to replace
        if (entry.replacementSpan) {
          var sourceFile = languageService.getProgram() && languageService.getProgram().getSourceFile(USER_FILE);
          if (sourceFile) {
            var rsStart = entry.replacementSpan.start;
            var rsEnd = rsStart + entry.replacementSpan.length;
            var startPos = ts.getLineAndCharacterOfPosition(sourceFile, rsStart);
            var endPos = ts.getLineAndCharacterOfPosition(sourceFile, rsEnd);
            item.textEdit = {
              range: {
                start: { line: startPos.line, character: startPos.character },
                end: { line: endPos.line, character: endPos.character },
              },
              newText: entry.insertText || entry.name,
            };
          }
        }

        items.push(item);
      }

      return JSON.stringify({ isIncomplete: false, items: items });
    } catch (e) {
      return JSON.stringify({ isIncomplete: false, items: [] });
    }
  },

  doSignatureHelp: function(uri, text, line, character) {
    try {
      lsHost.updateUserFile(text);
      var offset = posToOffset(currentUserCode, line, character);
      var help = languageService.getSignatureHelpItems(USER_FILE, offset, {});
      if (!help || !help.items || help.items.length === 0) {
        return JSON.stringify({ signatures: [], activeSignature: 0, activeParameter: 0 });
      }

      var signatures = [];
      for (var i = 0; i < help.items.length; i++) {
        var item = help.items[i];
        // Build parameter labels
        var params = [];
        var paramLabels = [];
        for (var j = 0; j < item.parameters.length; j++) {
          var p = item.parameters[j];
          var pLabel = p.displayParts.map(function(dp) { return dp.text; }).join('');
          params.push({ label: pLabel });
          paramLabels.push(pLabel);
        }
        // Build full signature label: funcName(param1, param2): returnType
        var prefix = item.prefixDisplayParts.map(function(dp) { return dp.text; }).join('');
        var suffix = item.suffixDisplayParts.map(function(dp) { return dp.text; }).join('');
        var label = prefix + paramLabels.join(', ') + suffix;
        var doc = item.documentation && item.documentation.length > 0
          ? item.documentation.map(function(dp) { return dp.text; }).join('')
          : undefined;
        signatures.push({ label: label, parameters: params, documentation: doc });
      }

      return JSON.stringify({
        signatures: signatures,
        activeSignature: help.selectedItemIndex || 0,
        activeParameter: help.argumentIndex || 0,
      });
    } catch (e) {
      return JSON.stringify({ signatures: [], activeSignature: 0, activeParameter: 0 });
    }
  },

  doValidation: function(uri, text) {
    try {
      lsHost.updateUserFile(text);

      var allDiags = languageService.getSyntacticDiagnostics(USER_FILE);

      var result = [];
      for (var i = 0; i < allDiags.length; i++) {
        var d = allDiags[i];
        if (!d.file) continue;

        var start = d.file.getLineAndCharacterOfPosition(d.start || 0);
        var end = d.file.getLineAndCharacterOfPosition((d.start || 0) + (d.length || 1));

        var msg = ts.flattenDiagnosticMessageText(d.messageText, '\n')
            .replace(/["'\\]\/node_modules\/minip-bridge(?:\/([^"'\\)]*?))?(?:\/index)?(?:\.d\.ts)?["'\\]/g, function(m, sub) {
              var q = m[0];
              return q + 'minip-bridge' + (sub ? '/' + sub : '') + q;
            });
        var severity = d.category === ts.DiagnosticCategory.Error ? 1
                     : d.category === ts.DiagnosticCategory.Warning ? 2 : 3;

        result.push({
          range: {
            start: { line: start.line, character: start.character },
            end: { line: end.line, character: end.character },
          },
          severity: severity,
          message: msg,
          source: 'ts',
        });
      }

      return JSON.stringify(result);
    } catch (e) {
      return JSON.stringify([]);
    }
  },
};
