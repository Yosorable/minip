const htmlService = require('vscode-html-languageservice');
const cssService = require('vscode-css-languageservice');
const { TextDocument } = require('vscode-languageserver-textdocument');

const htmlLS = htmlService.getLanguageService();
const cssLS = cssService.getCSSLanguageService();

/**
 * Find the <style> region that contains the given offset.
 * Returns { start, end } offsets of the CSS content (between <style> and </style>),
 * or null if the offset is not inside a <style> tag.
 */
function findStyleRegion(text, offset) {
  const styleOpenRe = /<style[^>]*>/gi;
  let match;
  while ((match = styleOpenRe.exec(text)) !== null) {
    const contentStart = match.index + match[0].length;
    const closeIdx = text.indexOf('</style', contentStart);
    const contentEnd = closeIdx === -1 ? text.length : closeIdx;
    if (offset >= contentStart && offset <= contentEnd) {
      return { start: contentStart, end: contentEnd };
    }
  }
  return null;
}

/**
 * Find the <script> region that contains the given offset.
 * Returns { start, end } offsets of the JS content (between <script> and </script>),
 * or null if the offset is not inside a <script> tag.
 */
function findScriptRegion(text, offset) {
  const scriptOpenRe = /<script[^>]*>/gi;
  let match;
  while ((match = scriptOpenRe.exec(text)) !== null) {
    const contentStart = match.index + match[0].length;
    const closeIdx = text.indexOf('</script', contentStart);
    const contentEnd = closeIdx === -1 ? text.length : closeIdx;
    if (offset >= contentStart && offset <= contentEnd) {
      return { start: contentStart, end: contentEnd };
    }
  }
  return null;
}

/**
 * Convert a (line, character) position to an offset in the text.
 */
function posToOffset(text, line, character) {
  let offset = 0;
  for (let i = 0; i < line; i++) {
    const nl = text.indexOf('\n', offset);
    if (nl === -1) break;
    offset = nl + 1;
  }
  return offset + character;
}

globalThis.HTMLLanguageService = {
  doComplete: function(uri, text, line, character) {
    try {
      const offset = posToOffset(text, line, character);

      // Check if cursor is inside <script> — delegate to JS LS
      const scriptRegion = findScriptRegion(text, offset);
      if (scriptRegion && typeof globalThis.JSLanguageService !== 'undefined') {
        const jsText = text.substring(scriptRegion.start, scriptRegion.end);
        // Calculate local line/character within the script region
        const textBeforeScript = text.substring(0, scriptRegion.start);
        const scriptStartLine = (textBeforeScript.match(/\n/g) || []).length;
        const localLine = line - scriptStartLine;
        const localChar = localLine === 0 ? character - (textBeforeScript.length - textBeforeScript.lastIndexOf('\n') - 1) : character;
        const jsResultStr = globalThis.JSLanguageService.doComplete(uri, jsText, localLine, localChar);
        // Remap textEdit positions from JS-local to HTML-global
        const jsResult = JSON.parse(jsResultStr);
        if (jsResult && jsResult.items) {
          const jsDoc = TextDocument.create(uri + '.js', 'javascript', 1, jsText);
          const fullDoc = TextDocument.create(uri, 'html', 1, text);
          for (const item of jsResult.items) {
            if (item.textEdit && item.textEdit.range) {
              const r = item.textEdit.range;
              const startOff = jsDoc.offsetAt(r.start) + scriptRegion.start;
              const endOff = jsDoc.offsetAt(r.end) + scriptRegion.start;
              r.start = fullDoc.positionAt(startOff);
              r.end = fullDoc.positionAt(endOff);
            }
          }
        }
        return JSON.stringify(jsResult);
      }

      const styleRegion = findStyleRegion(text, offset);

      if (styleRegion) {
        // Cursor is inside <style> — delegate to CSS LS
        const cssText = text.substring(styleRegion.start, styleRegion.end);
        const cssDoc = TextDocument.create(uri + '.css', 'css', 1, cssText);
        const fullDoc = TextDocument.create(uri, 'html', 1, text);
        const localOffset = offset - styleRegion.start;
        const cssPos = cssDoc.positionAt(localOffset);
        const stylesheet = cssLS.parseStylesheet(cssDoc);
        const result = cssLS.doComplete(cssDoc, cssPos, stylesheet);
        // Remap textEdit positions from CSS-local to HTML-global
        if (result && result.items) {
          for (const item of result.items) {
            if (item.textEdit && item.textEdit.range) {
              const r = item.textEdit.range;
              const startOff = cssDoc.offsetAt(r.start) + styleRegion.start;
              const endOff = cssDoc.offsetAt(r.end) + styleRegion.start;
              r.start = fullDoc.positionAt(startOff);
              r.end = fullDoc.positionAt(endOff);
            }
          }
        }
        return JSON.stringify(result);
      }

      const doc = TextDocument.create(uri, 'html', 1, text);
      const pos = { line: line, character: character };
      const htmlDoc = htmlLS.parseHTMLDocument(doc);
      const result = htmlLS.doComplete(doc, pos, htmlDoc);
      return JSON.stringify(result);
    } catch (e) {
      return JSON.stringify({ isIncomplete: false, items: [] });
    }
  },

  doHover: function(uri, text, line, character) {
    try {
      const offset = posToOffset(text, line, character);
      const styleRegion = findStyleRegion(text, offset);

      if (styleRegion) {
        const cssText = text.substring(styleRegion.start, styleRegion.end);
        const cssDoc = TextDocument.create(uri + '.css', 'css', 1, cssText);
        const fullDoc = TextDocument.create(uri, 'html', 1, text);
        const localOffset = offset - styleRegion.start;
        const cssPos = cssDoc.positionAt(localOffset);
        const stylesheet = cssLS.parseStylesheet(cssDoc);
        const result = cssLS.doHover(cssDoc, cssPos, stylesheet);
        if (result && result.range) {
          const startOff = cssDoc.offsetAt(result.range.start) + styleRegion.start;
          const endOff = cssDoc.offsetAt(result.range.end) + styleRegion.start;
          result.range.start = fullDoc.positionAt(startOff);
          result.range.end = fullDoc.positionAt(endOff);
        }
        return JSON.stringify(result || null);
      }

      const doc = TextDocument.create(uri, 'html', 1, text);
      const pos = { line: line, character: character };
      const htmlDoc = htmlLS.parseHTMLDocument(doc);
      const result = htmlLS.doHover(doc, pos, htmlDoc);
      return JSON.stringify(result || null);
    } catch (e) {
      return JSON.stringify(null);
    }
  },

  doSignatureHelp: function(uri, text, line, character) {
    try {
      const offset = posToOffset(text, line, character);
      const scriptRegion = findScriptRegion(text, offset);
      if (scriptRegion && typeof globalThis.JSLanguageService !== 'undefined') {
        const jsText = text.substring(scriptRegion.start, scriptRegion.end);
        const textBeforeScript = text.substring(0, scriptRegion.start);
        const scriptStartLine = (textBeforeScript.match(/\n/g) || []).length;
        const localLine = line - scriptStartLine;
        const localChar = localLine === 0 ? character - (textBeforeScript.length - textBeforeScript.lastIndexOf('\n') - 1) : character;
        return globalThis.JSLanguageService.doSignatureHelp(uri, jsText, localLine, localChar);
      }
      return JSON.stringify({ signatures: [], activeSignature: 0, activeParameter: 0 });
    } catch (e) {
      return JSON.stringify({ signatures: [], activeSignature: 0, activeParameter: 0 });
    }
  },

  doValidation: function(uri, text) {
    // Validate CSS inside <style> tags
    try {
      const results = [];
      const styleOpenRe = /<style[^>]*>/gi;
      let match;
      while ((match = styleOpenRe.exec(text)) !== null) {
        const contentStart = match.index + match[0].length;
        const closeIdx = text.indexOf('</style', contentStart);
        const contentEnd = closeIdx === -1 ? text.length : closeIdx;
        const cssText = text.substring(contentStart, contentEnd);
        const cssDoc = TextDocument.create(uri + '.css', 'css', 1, cssText);
        const stylesheet = cssLS.parseStylesheet(cssDoc);
        const diagnostics = cssLS.doValidation(cssDoc, stylesheet);

        // Adjust positions: convert CSS-local positions back to HTML document positions
        const fullDoc = TextDocument.create(uri, 'html', 1, text);
        for (const diag of diagnostics) {
          const startOffset = cssDoc.offsetAt(diag.range.start) + contentStart;
          const endOffset = cssDoc.offsetAt(diag.range.end) + contentStart;
          diag.range.start = fullDoc.positionAt(startOffset);
          diag.range.end = fullDoc.positionAt(endOffset);
          results.push(diag);
        }
      }
      // Validate JS inside <script> tags
      if (typeof globalThis.JSLanguageService !== 'undefined') {
        const scriptOpenRe = /<script[^>]*>/gi;
        let sMatch;
        while ((sMatch = scriptOpenRe.exec(text)) !== null) {
          const sContentStart = sMatch.index + sMatch[0].length;
          const sCloseIdx = text.indexOf('</script', sContentStart);
          const sContentEnd = sCloseIdx === -1 ? text.length : sCloseIdx;
          const jsText = text.substring(sContentStart, sContentEnd);
          const jsResultStr = globalThis.JSLanguageService.doValidation(uri, jsText);
          const jsDiags = JSON.parse(jsResultStr);

          // Remap positions from JS-local to HTML-global
          const textBeforeScript = text.substring(0, sContentStart);
          const scriptStartLine = (textBeforeScript.match(/\n/g) || []).length;

          for (const diag of jsDiags) {
            diag.range.start.line += scriptStartLine;
            diag.range.end.line += scriptStartLine;
            results.push(diag);
          }
        }
      }

      return JSON.stringify(results);
    } catch (e) {
      return JSON.stringify([]);
    }
  }
};
